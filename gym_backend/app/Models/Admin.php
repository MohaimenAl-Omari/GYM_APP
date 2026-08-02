<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

/**
 * Admin panel account. Kept fully separate from the mobile app's `User`
 * model/table on purpose — admins never touch the mobile auth flows
 * (Google/Apple/phone) and mobile users never get admin access.
 */
#[Fillable(['name', 'email', 'password'])]
#[Hidden(['password', 'remember_token'])]
class Admin extends Authenticatable
{
    use Notifiable;

    protected function casts(): array
    {
        return [
            'password' => 'hashed',
        ];
    }
}
