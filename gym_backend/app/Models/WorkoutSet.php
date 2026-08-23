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

    /**
     * `weight` is a decimal(5,2) column — MySQL's PDO driver always returns
     * DECIMAL values as PHP strings (to avoid float precision loss), so
     * without this cast, a freshly-created set (in-memory, still a real
     * number) and one reloaded from the database (a string) serialize to
     * JSON differently: `60.0` vs `"60.00"`. The Flutter client's
     * `(json['weight'] as num)` casts only accept the former, so any
     * endpoint that reloads sets from the DB — GET /workout-sessions/{id},
     * GET /exercises/{id}/last-performance — threw a client-side "type
     * 'String' is not a subtype of type 'num'" error while ones returning
     * a freshly-created model (POST .../sets) worked fine. Casting to
     * float here makes it consistently a JSON number everywhere.
     */
    protected $casts = [
        'weight' => 'float',
    ];

    public function sessionExercise(): BelongsTo
    {
        return $this->belongsTo(SessionExercise::class);
    }
}
