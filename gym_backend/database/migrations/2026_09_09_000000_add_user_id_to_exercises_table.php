<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * `null` user_id = an official, admin-curated exercise (unchanged
     * behavior — every exercise seeded so far has this). A real user_id
     * means a user created this exercise themselves, for their own use
     * only — see ExerciseController::store()/update()/destroy() and the
     * ownership checks added to MuscleGroupController::exercises() and
     * WorkoutSessionController's exercise_id validation. Cascade on
     * delete: if a user's account is ever deleted, their personal
     * exercises go with it rather than being orphaned as ownerless rows
     * that look official but aren't.
     */
    public function up(): void
    {
        Schema::table('exercises', function (Blueprint $table) {
            $table->foreignId('user_id')->nullable()->after('muscle_group_id')
                ->constrained()->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('exercises', function (Blueprint $table) {
            $table->dropConstrainedForeignId('user_id');
        });
    }
};
