<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'muscle_group_id',
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
}
