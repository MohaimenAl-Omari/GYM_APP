<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['user_id', 'weight', 'weight_unit', 'logged_at'])]
class WeightLog extends Model
{
    // Same reasoning as WorkoutSet::$casts — decimal columns come back as
    // PHP strings from MySQL unless explicitly cast, which would break the
    // Flutter client's `(json['weight'] as num)` parsing on every reload.
    protected $casts = [
        'weight' => 'float',
        'logged_at' => 'date:Y-m-d',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
