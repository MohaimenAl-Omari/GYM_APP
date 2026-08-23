<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['user_id', 'date', 'notes', 'duration_seconds'])]
class WorkoutSession extends Model
{
    use HasFactory;

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function sessionMuscleGroups(): HasMany
    {
        return $this->hasMany(SessionMuscleGroup::class, 'session_id');
    }

    public function sessionExercises(): HasMany
    {
        return $this->hasMany(SessionExercise::class, 'session_id')->orderBy('order');
    }
}
