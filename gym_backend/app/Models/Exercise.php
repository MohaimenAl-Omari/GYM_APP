<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;

#[Fillable([
    'muscle_group_id',
    'user_id',
    'name_en',
    'name_ar',
    'description_en',
    'description_ar',
    'media',
    'gif_url',
])]
class Exercise extends Model
{
    use HasFactory;

    public function muscleGroup(): BelongsTo
    {
        return $this->belongsTo(MuscleGroup::class);
    }

    /**
     * Null = an official, admin-curated exercise (every exercise seeded
     * so far). Non-null = a user created this one themselves, for their
     * own use only — see ExerciseController::store()/update()/destroy()
     * and the ownership checks in MuscleGroupController::exercises() and
     * WorkoutSessionController's exercise_id validation.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Every SessionExercise row that ever logged this exercise, across
     * every user's workout sessions — used by ExerciseController::destroy()
     * to refuse deleting an exercise (own or, in principle, official) that
     * already has real workout history attached to it, since
     * session_exercises.exercise_id has a restrictive (non-cascading) FK.
     */
    public function sessionExercises(): HasMany
    {
        return $this->hasMany(SessionExercise::class);
    }

    /**
     * `media`/`gif_url` hold either a path relative to the `public` disk
     * (admin-uploaded file) or a full external URL (pasted directly, e.g.
     * a CDN-hosted demo GIF) — these two accessors resolve either shape
     * into something actually loadable. Deliberately *not* appended to
     * the model's JSON output: the mobile API contract keeps returning
     * the raw `media`/`gif_url` values unchanged (Exercise.dart resolves
     * them the same way, client-side), so nothing about the existing API
     * response shape changes. These exist purely for the admin panel's
     * own previews (list thumbnail, edit-modal existing-file preview),
     * which needed this exact same resolution and had nowhere else to
     * share it from.
     */
    protected function mediaUrl(): Attribute
    {
        return Attribute::make(
            get: fn () => $this->resolveUrl($this->media),
        );
    }

    protected function demoUrl(): Attribute
    {
        return Attribute::make(
            get: fn () => $this->resolveUrl($this->gif_url) ?? $this->resolveUrl($this->media),
        );
    }

    private function resolveUrl(?string $path): ?string
    {
        if (!$path) {
            return null;
        }

        return str_starts_with($path, 'http://') || str_starts_with($path, 'https://')
            ? $path
            : Storage::disk('public')->url($path);
    }
}
