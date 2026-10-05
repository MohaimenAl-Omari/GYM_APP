<?php

namespace App\Http\Controllers;

use App\Models\Exercise;
use App\Models\WorkoutSession;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;

class ExerciseController extends Controller
{
    public function show(Request $request, Exercise $exercise): JsonResponse
    {
        $this->authorizeVisible($request, $exercise);

        return response()->json($exercise);
    }

    /**
     * GET /api_v1/my-exercises
     *
     * Every exercise the current user created themselves, across all
     * muscle groups — powers the "My Exercises" screen. Official
     * (admin-curated) exercises never appear here.
     */
    public function mine(Request $request): JsonResponse
    {
        return response()->json(
            Exercise::where('user_id', $request->user()->id)
                ->orderBy('name_en')
                ->get()
        );
    }

    /**
     * POST /api_v1/exercises
     * Body (multipart): muscle_group_id, name, description?, photo?
     *
     * Lets a user add their own exercise — deliberately the simplest
     * shape that still fits this app's data model: one `name` (stored
     * into both name_en/name_ar, since a user's own exercise is usually
     * a proper noun or personal note that doesn't need translating) and
     * an optional photo (no GIF support here — a user isn't going to
     * have one, and asking for it would just add friction).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'muscle_group_id' => ['required', 'integer', 'exists:muscle_groups,id'],
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:2000'],
            'photo' => ['nullable', 'image', 'max:5120'],
        ]);

        $mediaPath = $request->hasFile('photo')
            ? $request->file('photo')->store('exercises/user-uploads', 'public')
            : null;

        $exercise = Exercise::create([
            'muscle_group_id' => $validated['muscle_group_id'],
            'user_id' => $request->user()->id,
            'name_en' => $validated['name'],
            'name_ar' => $validated['name'],
            'description_en' => $validated['description'] ?? null,
            'description_ar' => $validated['description'] ?? null,
            'media' => $mediaPath,
        ]);

        return response()->json($exercise, 201);
    }

    /**
     * PUT /api_v1/exercises/{exercise}
     * Body (multipart, all fields optional): muscle_group_id, name,
     * description, photo, remove_photo
     */
    public function update(Request $request, Exercise $exercise): JsonResponse
    {
        $this->authorizeOwner($request, $exercise);

        $validated = $request->validate([
            'muscle_group_id' => ['sometimes', 'integer', 'exists:muscle_groups,id'],
            'name' => ['sometimes', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'photo' => ['sometimes', 'nullable', 'image', 'max:5120'],
            'remove_photo' => ['sometimes', 'boolean'],
        ]);

        if (array_key_exists('muscle_group_id', $validated)) {
            $exercise->muscle_group_id = $validated['muscle_group_id'];
        }
        if (array_key_exists('name', $validated)) {
            $exercise->name_en = $validated['name'];
            $exercise->name_ar = $validated['name'];
        }
        if (array_key_exists('description', $validated)) {
            $exercise->description_en = $validated['description'];
            $exercise->description_ar = $validated['description'];
        }

        if ($request->hasFile('photo')) {
            if ($exercise->media) {
                Storage::disk('public')->delete($exercise->media);
            }
            $exercise->media = $request->file('photo')->store('exercises/user-uploads', 'public');
        } elseif ($request->boolean('remove_photo')) {
            if ($exercise->media) {
                Storage::disk('public')->delete($exercise->media);
            }
            $exercise->media = null;
        }

        $exercise->save();

        return response()->json($exercise);
    }

    /**
     * DELETE /api_v1/exercises/{exercise}
     *
     * Blocked (422, not a raw 500) if the user has already logged any
     * workout sets against this exercise — session_exercises.exercise_id
     * has a restrictive FK, so the delete would fail at the database
     * level anyway; this just turns that into a clear message instead of
     * a generic server error.
     */
    public function destroy(Request $request, Exercise $exercise): JsonResponse
    {
        $this->authorizeOwner($request, $exercise);

        if ($exercise->sessionExercises()->exists()) {
            return response()->json([
                'message' => 'This exercise has already been logged in a workout and can\'t be deleted.',
            ], 422);
        }

        if ($exercise->media) {
            Storage::disk('public')->delete($exercise->media);
        }

        $exercise->delete();

        return response()->json(['status' => true]);
    }

    /**
     * A user may only ever see official exercises (user_id null) or
     * their own — never another user's personal exercise, even by
     * guessing/incrementing an id.
     */
    private function authorizeVisible(Request $request, Exercise $exercise): void
    {
        abort_if(
            $exercise->user_id !== null && $exercise->user_id !== $request->user()->id,
            404
        );
    }

    private function authorizeOwner(Request $request, Exercise $exercise): void
    {
        abort_if(
            $exercise->user_id !== $request->user()->id,
            403,
            $exercise->user_id === null
                ? 'This is an official exercise and can\'t be edited.'
                : 'This exercise does not belong to you.'
        );
    }

    /**
     * GET /api_v1/exercises/{exercise}/last-performance
     *
     * Find $request->user()'s most recent WorkoutSession that has a
     * SessionExercise for this $exercise, and return that
     * session_exercise's sets. Returns { session_date: null, sets: [] }
     * if they've never logged it — that's a normal "no history yet"
     * state, not a 404.
     */
    public function lastPerformance(Request $request, Exercise $exercise): JsonResponse
    {
        $session = $request->user()->workoutSessions()
            ->latest()
            ->whereHas('sessionExercises', fn ($query) => $query->where('exercise_id', $exercise->id))
            ->with(['sessionExercises' => fn ($query) => $query->where('exercise_id', $exercise->id)->with('sets')])
            ->first();

        $sessionExercise = $session?->sessionExercises->first();

        if (!$sessionExercise) {
            return response()->json([
                'session_date' => null,
                'sets' => [],
            ]);
        }

        return response()->json([
            'session_date' => $session->date,
            'sets' => $sessionExercise->sets,
        ]);
    }

    /**
     * GET /api_v1/exercises/{exercise}/progress
     *
     * Every one of the user's past sessions that included this exercise,
     * oldest first, each with its logged sets — unlike lastPerformance()
     * this isn't limited to just the most recent one. Powers the Progress
     * screen's per-exercise strength trend (e.g. top set weight over time).
     */
    public function progress(Request $request, Exercise $exercise): JsonResponse
    {
        $sessions = $request->user()->workoutSessions()
            ->whereHas('sessionExercises', fn ($query) => $query->where('exercise_id', $exercise->id))
            ->with(['sessionExercises' => fn ($query) => $query->where('exercise_id', $exercise->id)->with('sets')])
            ->orderBy('date')
            ->get();

        return response()->json(
            $sessions->map(fn (WorkoutSession $session) => [
                'session_id' => $session->id,
                'date' => $session->date,
                'sets' => $session->sessionExercises->first()?->sets ?? [],
            ])->values()
        );
    }
}
