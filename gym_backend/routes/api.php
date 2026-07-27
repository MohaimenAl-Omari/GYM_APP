<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ProfileController;

Route::prefix('api_v1')->group(function () {
    Route::prefix('auth')->group(function () {
        Route::post('/google', [AuthController::class, 'google']);
        Route::post('/signUp', [AuthController::class, 'signUp']);
        Route::post('/login', [AuthController::class, 'loginWithPhone']);
    });

    Route::middleware('auth:sanctum')->prefix('user')->group(function () {
        Route::put('/profile', [ProfileController::class, 'update']);
    });
});


