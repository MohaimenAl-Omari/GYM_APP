<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable([
    'name',
    'email',
    'password',
    'phone_number',
    'google_id',
    'apple_id',
    'age',
    'weight',
    'height',
    'weight_unit',
    'goal',
    'username'
])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * Get the attributes that should be cast.
     *
     * MySQL's PDO driver always returns decimal(N,M) columns as PHP strings
     * when a model is reloaded from the database. Without an explicit cast,
     * 'weight' and 'height' (both decimal(5,2)) serialize to JSON as strings
     * (e.g. "75.00"), which breaks Flutter's `as num?` casts on the client.
     * Casting them to float here keeps the API contract numeric. Same fix
     * already applied to WorkoutSet::weight and WeightLog::weight.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'weight' => 'float',
            'height' => 'float',
        ];
    }

    public function workoutSessions(): HasMany
    {
        return $this->hasMany(WorkoutSession::class);
    }
}
