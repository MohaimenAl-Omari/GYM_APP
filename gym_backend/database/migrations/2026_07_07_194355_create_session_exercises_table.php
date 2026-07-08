<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('session_exercises', function (Blueprint $table) {
            $table->id();
            $table->foreignId('session_id')->constrained('workout_sessions');
            $table->foreignId('exercise_id')->constrained();
            $table->integer('order'); // order of exercise
            $table->timestamps();
        });
    }


    public function down(): void
    {
        Schema::dropIfExists('session_exercises');
    }
};
