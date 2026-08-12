<?php

namespace App\Http\Controllers;

use App\Models\Exercise;
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
}
