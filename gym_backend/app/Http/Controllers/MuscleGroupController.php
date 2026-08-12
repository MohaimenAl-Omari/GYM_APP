<?php

namespace App\Http\Controllers;

use App\Models\MuscleGroup;
use Illuminate\Http\JsonResponse;

/**
 * Read-only browsing endpoints for the exercise library. See
 * docs/exercise-workout-api.md for the exact response shape expected by
 * the Flutter app (ExerciseService).
 */
class MuscleGroupController extends Controller
{
    /**
     * GET /api_v1/muscle-groups
     */
    public function index(): JsonResponse
    {
        return response()->json(
            MuscleGroup::orderBy('name_en')->get()
        );
    }

    /**
     * GET /api_v1/muscle-groups/{muscleGroup}/exercises
     */
    public function exercises(MuscleGroup $muscleGroup): JsonResponse
    {
        return response()->json(
            $muscleGroup->exercises()->orderBy('name_en')->get()
        );
    }
}
