<?php

namespace App\Http\Controllers;

use App\Models\Exercise;
use App\Models\WorkoutSession;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class ExerciseController extends Controller
{
    public function show(Exercise $exercise): JsonResponse
    {
        return response()->json($exercise);
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
