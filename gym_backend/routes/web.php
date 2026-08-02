<?php

use App\Http\Controllers\Admin\LogoutController;
use App\Livewire\Admin\Auth\Login;
use App\Livewire\Admin\Dashboard;
use App\Livewire\Admin\Exercises\Manager as ExercisesManager;
use App\Livewire\Admin\MuscleGroups\Manager as MuscleGroupsManager;
use App\Livewire\Admin\Users\Index as UsersIndex;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::prefix('admin')->name('admin.')->group(function () {
    Route::middleware('guest:admin')->group(function () {
        Route::get('/login', Login::class)->name('login');
    });

    Route::middleware('auth:admin')->group(function () {
        Route::redirect('/', '/admin/dashboard');
        Route::get('/dashboard', Dashboard::class)->name('dashboard');
        Route::get('/muscle-groups', MuscleGroupsManager::class)->name('muscle-groups');
        Route::get('/exercises', ExercisesManager::class)->name('exercises');
        Route::get('/users', UsersIndex::class)->name('users');
        Route::post('/logout', LogoutController::class)->name('logout');
    });
});
