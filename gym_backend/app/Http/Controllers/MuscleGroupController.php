<?php

namespace App\Http\Controllers;

use App\Models\MuscleGroup;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

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
     *
     * Official (admin-curated) exercises in this group, plus any the
     * current user created themselves under it — never another user's.
     * This is also what the workout-start exercise picker calls, so a
     * user's own exercises show up there automatically, with no separate
     * endpoint needed.
     */
    public function exercises(Request $request, MuscleGroup $muscleGroup): JsonResponse
    {
        return response()->json(
            $muscleGroup->exercises()
                ->where(function ($query) use ($request) {
                    $query->whereNull('user_id')->orWhere('user_id', $request->user()->id);
                })
                ->orderBy('name_en')
                ->get()
        );
    }
}
