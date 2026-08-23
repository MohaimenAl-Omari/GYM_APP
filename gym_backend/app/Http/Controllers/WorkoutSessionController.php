<?php

namespace App\Http\Controllers;

use App\Models\SessionExercise;
use App\Models\SessionMuscleGroup;
use App\Models\WorkoutSession;
use App\Models\WorkoutSet;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/**
 * Everything about an active/finished workout session. See
 * docs/exercise-workout-api.md for request/response shapes — each set is
 * saved immediately (storeSet), not batched, so nothing is lost if the
 * app closes mid-workout.
 */
class WorkoutSessionController extends Controller
{
    /**
     * GET /api_v1/workout-sessions
     * The History tab's list view — every session the logged-in user has
     * ever started, most recent first, with just enough summary data
     * (muscle groups worked, exercise/set counts, volume) to render a list
     * row without the app having to fetch and total every session's sets
     * itself. Tap-through detail lives in show().
     */
    public function index(Request $request): JsonResponse
    {
        $sessions = WorkoutSession::query()
            ->where('user_id', $request->user()->id)
            ->with([
                'sessionMuscleGroups.muscleGroup',
                'sessionExercises.sets',
            ])
            ->orderByDesc('date')
            ->orderByDesc('id')
            ->get();

        return response()->json(
            $sessions->map(fn (WorkoutSession $session) => $this->summarize($session))
        );
    }

    /**
     * GET /api_v1/workout-sessions/{workoutSession}
     * Full breakdown for one past session — every exercise and every set
     * logged against it, for the History detail screen.
     */
    public function show(Request $request, WorkoutSession $workoutSession): JsonResponse
    {
        $this->authorizeSession($request, $workoutSession);

        $workoutSession->load([
            'sessionMuscleGroups.muscleGroup',
            'sessionExercises.exercise',
            'sessionExercises.sets',
        ]);

        return response()->json([
            ...$this->summarize($workoutSession),
            'notes' => $workoutSession->notes,
            'exercises' => $workoutSession->sessionExercises->map(fn (SessionExercise $sessionExercise) => [
                'session_exercise_id' => $sessionExercise->id,
                'exercise_id' => $sessionExercise->exercise_id,
                'name_en' => $sessionExercise->exercise?->name_en,
                'name_ar' => $sessionExercise->exercise?->name_ar,
                'gif_url' => $sessionExercise->exercise?->gif_url,
                'media' => $sessionExercise->exercise?->media,
                'order' => $sessionExercise->order,
                'sets' => $sessionExercise->sets->map(fn (WorkoutSet $set) => [
                    'id' => $set->id,
                    'set_number' => $set->set_number,
                    'reps' => $set->reps,
                    'weight' => $set->weight,
                    'weight_unit' => $set->weight_unit,
                    'rest_time' => $set->rest_time,
                ]),
            ]),
        ]);
    }

    /**
     * Shared shape between index (list row) and show (detail header) so
     * the two endpoints never disagree about how totals are computed.
     */
    private function summarize(WorkoutSession $session): array
    {
        $sets = $session->sessionExercises->flatMap(fn (SessionExercise $se) => $se->sets);

        return [
            'id' => $session->id,
            'date' => $session->date,
            'muscle_groups' => $session->sessionMuscleGroups->map(fn (SessionMuscleGroup $smg) => [
                'id' => $smg->muscleGroup?->id,
                'name_en' => $smg->muscleGroup?->name_en,
                'name_ar' => $smg->muscleGroup?->name_ar,
            ])->filter(fn ($mg) => $mg['id'] !== null)->values(),
            'exercise_count' => $session->sessionExercises->count(),
            'total_sets' => $sets->count(),
            'total_volume' => $sets->sum(fn (WorkoutSet $set) => $set->reps * $set->weight),
            // Null until finish() persists it — there's no separate
            // "in progress" status field, so null doubles as that signal.
            'duration_seconds' => $session->duration_seconds,
        ];
    }

    /**
     * POST /api_v1/workout-sessions
     * Body: { muscle_group_ids: int[], exercise_ids: int[] }
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'muscle_group_ids' => ['required', 'array', 'min:1'],
            'muscle_group_ids.*' => ['integer', 'exists:muscle_groups,id'],
            'exercise_ids' => ['required', 'array', 'min:1'],
            'exercise_ids.*' => ['integer', 'exists:exercises,id'],
        ]);

        $session = DB::transaction(function () use ($request, $validated) {
            $session = WorkoutSession::create([
                'user_id' => $request->user()->id,
                'date' => now()->toDateString(),
            ]);

            foreach ($validated['muscle_group_ids'] as $muscleGroupId) {
                SessionMuscleGroup::create([
                    'session_id' => $session->id,
                    'muscle_group_id' => $muscleGroupId,
                ]);
            }

            // array_values() so the order the user picked exercises in
            // (the array's original index order) becomes 1, 2, 3...
            // regardless of how the request JSON keyed them.
            foreach (array_values($validated['exercise_ids']) as $index => $exerciseId) {
                SessionExercise::create([
                    'session_id' => $session->id,
                    'exercise_id' => $exerciseId,
                    'order' => $index + 1,
                ]);
            }

            return $session;
        });

        return response()->json($session->load('sessionExercises'), 201);
    }

    /**
     * POST /api_v1/workout-sessions/{workoutSession}/exercises
     * Body: { exercise_id: int }
     */
    public function addExercise(Request $request, WorkoutSession $workoutSession): JsonResponse
    {
        $this->authorizeSession($request, $workoutSession);

        $validated = $request->validate([
            'exercise_id' => ['required', 'integer', 'exists:exercises,id'],
        ]);

        $nextOrder = ($workoutSession->sessionExercises()->max('order') ?? 0) + 1;

        $sessionExercise = SessionExercise::create([
            'session_id' => $workoutSession->id,
            'exercise_id' => $validated['exercise_id'],
            'order' => $nextOrder,
        ]);

        return response()->json($sessionExercise, 201);
    }

    /**
     * POST /api_v1/workout-sessions/{workoutSession}/sets
     * Body: { session_exercise_id, set_number, reps, weight, weight_unit, rest_time }
     */
    public function storeSet(Request $request, WorkoutSession $workoutSession): JsonResponse
    {
        $this->authorizeSession($request, $workoutSession);

        $validated = $request->validate([
            'session_exercise_id' => [
                'required',
                'integer',
                Rule::exists('session_exercises', 'id')->where('session_id', $workoutSession->id),
            ],
            'set_number' => ['required', 'integer', 'min:1'],
            'reps' => ['required', 'integer', 'min:0'],
            'weight' => ['required', 'numeric', 'min:0'],
            'weight_unit' => ['required', Rule::in(['kg', 'lbs'])],
            'rest_time' => ['nullable', 'integer', 'min:0'],
        ]);

        $set = WorkoutSet::create($validated);

        return response()->json($set, 201);
    }

    /**
     * PUT /api_v1/workout-sessions/{workoutSession}/sets/{set}
     */
    public function updateSet(Request $request, WorkoutSession $workoutSession, WorkoutSet $set): JsonResponse
    {
        $this->authorizeSession($request, $workoutSession);
        $this->authorizeSet($workoutSession, $set);

        $validated = $request->validate([
            'set_number' => ['sometimes', 'integer', 'min:1'],
            'reps' => ['sometimes', 'integer', 'min:0'],
            'weight' => ['sometimes', 'numeric', 'min:0'],
            'weight_unit' => ['sometimes', Rule::in(['kg', 'lbs'])],
            'rest_time' => ['sometimes', 'nullable', 'integer', 'min:0'],
        ]);

        $set->update($validated);

        return response()->json($set);
    }

    /**
     * DELETE /api_v1/workout-sessions/{workoutSession}/sets/{set}
     */
    public function destroySet(Request $request, WorkoutSession $workoutSession, WorkoutSet $set): JsonResponse
    {
        $this->authorizeSession($request, $workoutSession);
        $this->authorizeSet($workoutSession, $set);

        $set->delete();

        return response()->json(['status' => true]);
    }

    /**
     * PUT /api_v1/workout-sessions/{workoutSession}/finish
     * Optional body: { notes?: string }
     */
    public function finish(Request $request, WorkoutSession $workoutSession): JsonResponse
    {
        $this->authorizeSession($request, $workoutSession);
        $validated = $request->validate([
            'notes' => ['nullable', 'string'],
        ]);

        // Cast to a non-negative integer explicitly: Carbon's diffInSeconds
        // can return a negative float depending on argument order/timezone,
        // which MySQL rejects outright for an unsigned integer column.
        $durationSeconds = (int) round(abs($workoutSession->created_at->diffInSeconds(now())));
        $workoutSession->update([
            'duration_seconds' => $durationSeconds,
            ...(!empty($validated['notes']) ? ['notes' => $validated['notes']] : []),
        ]);

        $sets = WorkoutSet::whereHas(
            'sessionExercise',
            fn($query) => $query->where('session_id', $workoutSession->id)
        )->get();
        return response()->json([
            'id' => $workoutSession->id,
            'duration_seconds' => $durationSeconds,
            'total_sets' => $sets->count(),
            'total_volume' => $sets->sum(fn($set) => $set->reps * $set->weight),
        ]);
    }

    /**
     * PUT /api_v1/workout-sessions/{workoutSession}
     * Body: { notes: string|null }
     * Lets History edit a past session's notes after the fact — separate
     * from finish() so editing doesn't require re-finishing.
     */
    public function update(Request $request, WorkoutSession $workoutSession): JsonResponse
    {
        $this->authorizeSession($request, $workoutSession);
        $validated = $request->validate([
            'notes' => ['nullable', 'string'],
        ]);
        $workoutSession->update(['notes' => $validated['notes'] ?? null]);

        return response()->json([
            ...$this->summarize($workoutSession->load(['sessionMuscleGroups.muscleGroup', 'sessionExercises.sets'])),
            'notes' => $workoutSession->notes,
        ]);
    }

    /**
     * DELETE /api_v1/workout-sessions/{workoutSession}
     * Deletes the session and everything logged under it. Child rows
     * (session_muscle_groups, session_exercises, sets) have no cascade FK,
     * so they're removed manually in dependency order inside a
     * transaction — same manual-multi-row style as store().
     */
    public function destroy(Request $request, WorkoutSession $workoutSession): JsonResponse
    {
        $this->authorizeSession($request, $workoutSession);

        DB::transaction(function () use ($workoutSession) {
            $sessionExerciseIds = $workoutSession->sessionExercises()->pluck('id');
            WorkoutSet::whereIn('session_exercise_id', $sessionExerciseIds)->delete();
            $workoutSession->sessionExercises()->delete();
            $workoutSession->sessionMuscleGroups()->delete();
            $workoutSession->delete();
        });

        return response()->json(['status' => true]);
    }

    /**
     * Every session/set endpoint is scoped to the logged-in user — this
     * is what stops one account from reading or mutating another's
     * workout data via a guessed/incremented id.
     */
    private function authorizeSession(Request $request, WorkoutSession $workoutSession): void
    {
        abort_if(
            $workoutSession->user_id !== $request->user()->id,
            403,
            'This workout session does not belong to you.'
        );
    }

    private function authorizeSet(WorkoutSession $workoutSession, WorkoutSet $set): void
    {
        abort_if(
            $set->sessionExercise?->session_id !== $workoutSession->id,
            404,
            'Set not found in this session.'
        );
    }
}
