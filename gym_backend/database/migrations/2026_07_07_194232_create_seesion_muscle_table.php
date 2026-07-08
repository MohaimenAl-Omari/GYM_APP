<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('session_muscle_groups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('session_id')->constrained('workout_sessions');
            $table->foreignId('muscle_group_id')->constrained();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('session_muscle_groups');
    }
};
