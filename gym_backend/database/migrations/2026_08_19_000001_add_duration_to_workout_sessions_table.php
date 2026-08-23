<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Persists what WorkoutSessionController::finish() already computes
     * (now()->diffInSeconds(created_at)) instead of only returning it —
     * needed so History can show a past session's duration without
     * recomputing it from timestamps after the fact.
     */
    public function up(): void
    {
        Schema::table('workout_sessions', function (Blueprint $table) {
            $table->unsignedInteger('duration_seconds')->nullable()->after('notes');
        });
    }

    public function down(): void
    {
        Schema::table('workout_sessions', function (Blueprint $table) {
            $table->dropColumn('duration_seconds');
        });
    }
};
