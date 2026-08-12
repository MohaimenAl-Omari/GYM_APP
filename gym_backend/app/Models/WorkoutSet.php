<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Maps to the `sets` table. Named `WorkoutSet` instead of the default
 * `Set` model Laravel's naming convention would infer, purely so it isn't
 * confused with a generic "set" — hence the explicit $table override.
 */
#[Fillable(['session_exercise_id', 'set_number', 'reps', 'weight', 'weight_unit', 'rest_time'])]
class WorkoutSet extends Model
{
    protected $table = 'sets';

    public function sessionExercise(): BelongsTo
    {
        return $this->belongsTo(SessionExercise::class);
    }
}
