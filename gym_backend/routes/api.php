<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\MuscleGroupController;
use App\Http\Controllers\ExerciseController;
use App\Http\Controllers\WorkoutSessionController;

Route::prefix('api_v1')->group(function () {
    Route::prefix('auth')->group(function () {
        Route::post('/google', [AuthController::class, 'google']);
        Route::post('/signUp', [AuthController::class, 'signUp']);
        Route::post('/apple', [AuthController::class, 'apple']);
        Route::post('/login', [AuthController::class, 'loginWithName']);
    });

    Route::middleware('auth:sanctum')->prefix('user')->group(function () {
        Route::get('/me', [ProfileController::class, 'me']);
        Route::put('/profile', [ProfileController::class, 'update']);
    });

    // Exercise library + workout logging — see docs/exercise-workout-api.md
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/muscle-groups', [MuscleGroupController::class, 'index']);
        Route::get('/muscle-groups/{muscleGroup}/exercises', [MuscleGroupController::class, 'exercises']);

        Route::get('/exercises/{exercise}', [ExerciseController::class, 'show']);
        Route::get('/exercises/{exercise}/last-performance', [ExerciseController::class, 'lastPerformance']);

        Route::prefix('workout-sessions')->group(function () {
            Route::get('/', [WorkoutSessionController::class, 'index']);
            Route::get('/{workoutSession}', [WorkoutSessionController::class, 'show']);
            Route::post('/', [WorkoutSessionController::class, 'store']);
            Route::post('/{workoutSession}/exercises', [WorkoutSessionController::class, 'addExercise']);
            Route::post('/{workoutSession}/sets', [WorkoutSessionController::class, 'storeSet']);
            Route::put('/{workoutSession}/sets/{set}', [WorkoutSessionController::class, 'updateSet']);
            Route::delete('/{workoutSession}/sets/{set}', [WorkoutSessionController::class, 'destroySet']);
            Route::put('/{workoutSession}/finish', [WorkoutSessionController::class, 'finish']);
        });
    });
});
