<?php

namespace Database\Seeders;

use App\Models\MuscleGroup;
use Illuminate\Database\Seeder;

class MuscleGroupSeeder extends Seeder
{
    public function run(): void
    {
        $groups = [
            ['name_en' => 'Chest', 'name_ar' => 'الصدر'],
            ['name_en' => 'Back', 'name_ar' => 'الظهر'],
            ['name_en' => 'Shoulders', 'name_ar' => 'الأكتاف'],
            ['name_en' => 'Biceps', 'name_ar' => 'البايسبس'],
            ['name_en' => 'Triceps', 'name_ar' => 'الترايسبس'],
            ['name_en' => 'Forearms', 'name_ar' => 'الساعد'],
            ['name_en' => 'Traps', 'name_ar' => 'الترابيس'],
            ['name_en' => 'Legs', 'name_ar' => 'الأرجل'],
            ['name_en' => 'Abs', 'name_ar' => 'البطن'],
        ];

        foreach ($groups as $group) {
            MuscleGroup::firstOrCreate(['name_en' => $group['name_en']], $group);
        }
    }
}
