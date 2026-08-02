<?php

namespace App\Livewire\Admin;

use App\Models\Exercise;
use App\Models\MuscleGroup;
use App\Models\User;
use Livewire\Attributes\Layout;
use Livewire\Component;

#[Layout('layouts.admin')]
class Dashboard extends Component
{
    public function render()
    {
        return view('livewire.admin.dashboard', [
            'userCount' => User::count(),
            'muscleGroupCount' => MuscleGroup::count(),
            'exerciseCount' => Exercise::count(),
        ]);
    }
}
