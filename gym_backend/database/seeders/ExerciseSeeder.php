<?php

namespace Database\Seeders;

use App\Models\Exercise;
use App\Models\MuscleGroup;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

/**
 * Seeds the full exercise list. Each exercise is keyed to exactly one
 * muscle group (the schema doesn't support multiple), so exercises that
 * naturally show up under more than one heading in a typical gym list
 * (e.g. Romanian Deadlift under both Back and Hamstrings, Face Pull under
 * both Shoulders and Traps) are only seeded once, under their primary
 * group. The "Best Compound Exercises" list from the source isn't seeded
 * separately since every entry in it is already covered above (Bench
 * Press = Flat Barbell Bench Press, Squat = Back Squat, etc).
 *
 * `gif_url` is NOT a real, working URL by default — it's set to a
 * predictable path (`exercises/{slug}.gif`) so that once real GIF files
 * exist, dropping them into storage/app/public/exercises/ under the
 * matching slug makes them show up automatically. Until then, `demoUrl`
 * on the Flutter side falls back to `media` (nullable too) and then a
 * placeholder icon — so running this seeder as-is doesn't break the
 * exercise pages.
 *
 * Ways to attach real media after seeding, roughly in the order worth
 * trying:
 *   1. `php artisan exercises:fetch-from-repdb` — backfills real `media`
 *      (static image) values from RepDB's free dataset. No API key, no
 *      quota — just a public GitHub download. Recommended first pass; see
 *      app/Console/Commands/ImportExerciseImagesFromRepDB.php for match
 *      rate notes and why it deliberately leaves some exercises unmatched
 *      rather than risking the wrong photo.
 *   2. `php artisan exercises:fetch-from-wger` — same idea against wger's
 *      public database, for whatever #1 couldn't confidently match. No key
 *      either, but images are third-party-contributed (CC BY-SA) rather
 *      than RepDB's own commissioned illustrations.
 *   3. `php artisan exercises:fetch-gifs` — backfills real gif_url values
 *      (animated, not static) from the ExerciseDB API (needs
 *      EXERCISEDB_RAPIDAPI_KEY in .env and has a daily quota on the free
 *      tier; see app/Console/Commands/FetchExerciseGifs.php). A GIF here
 *      always wins over a static image from #1/#2 — see Exercise::demoUrl.
 *   4. Admin panel → Exercises → edit → upload an image/GIF file per
 *      exercise (stored on this server), or paste an external URL you
 *      already have the rights to link to directly.
 */
class ExerciseSeeder extends Seeder
{
    public function run(): void
    {
        $data = [
            'Chest' => [
                ['Incline Barbell Bench Press', 'بنش بار مائل'],
                ['Incline Dumbbell Press', 'بنش دمبل مائل'],
                ['Incline Machine Press', 'بنش مائل بالجهاز'],
                ['Low-to-High Cable Fly', 'فراشة كيبل من الأسفل للأعلى'],
                ['Flat Barbell Bench Press', 'بنش بار مسطح'],
                ['Flat Dumbbell Bench Press', 'بنش دمبل مسطح'],
                ['Machine Chest Press', 'ضغط صدر بالجهاز'],
                ['Push-ups', 'ضغط (بوش أب)'],
                ['Decline Bench Press', 'بنش هابط'],
                ['Chest Dips', 'غطس للصدر'],
                ['High-to-Low Cable Fly', 'فراشة كيبل من الأعلى للأسفل'],
            ],
            'Back' => [
                ['Pull-ups', 'العقلة'],
                ['Chin-ups', 'عقلة بقبضة معكوسة'],
                ['Lat Pulldown', 'سحب أمامي للظهر'],
                ['Straight Arm Pulldown', 'سحب بذراع مستقيمة'],
                ['Single Arm Lat Pulldown', 'سحب لات بيد واحدة'],
                ['Barbell Row', 'تجديف بار'],
                ['T-Bar Row', 'تجديف تي بار'],
                ['Seated Cable Row', 'تجديف كيبل جالس'],
                ['Chest Supported Row', 'تجديف مسنود بالصدر'],
                ['One Arm Dumbbell Row', 'تجديف دمبل بيد واحدة'],
                ['Deadlift', 'الرفعة الميتة'],
                ['Romanian Deadlift', 'ديدليفت روماني'],
                ['Hyperextensions', 'تمديد الظهر السفلي'],
                ['Good Mornings', 'جود مورنينغ'],
            ],
            'Shoulders' => [
                ['Barbell Overhead Press', 'ضغط كتف بار فوق الرأس'],
                ['Dumbbell Shoulder Press', 'ضغط كتف دمبل'],
                ['Arnold Press', 'ضغط أرنولد'],
                ['Front Raise', 'رفرفة أمامية'],
                ['Dumbbell Lateral Raise', 'رفرفة جانبية دمبل'],
                ['Cable Lateral Raise', 'رفرفة جانبية كيبل'],
                ['Machine Lateral Raise', 'رفرفة جانبية بالجهاز'],
                ['Lean Away Lateral Raise', 'رفرفة جانبية بالميل'],
                ['Reverse Pec Deck', 'بيك ديك عكسي'],
                ['Face Pull', 'سحب للوجه'],
                ['Rear Delt Fly', 'فراشة الكتف الخلفي'],
                ['Cable Rear Delt Fly', 'فراشة الكتف الخلفي بالكيبل'],
            ],
            'Biceps' => [
                ['Incline Dumbbell Curl', 'باي دمبل مائل'],
                ['Drag Curl', 'باي دراغ'],
                ['Close Grip EZ Bar Curl', 'باي بار EZ بقبضة ضيقة'],
                ['Preacher Curl', 'باي على مقعد الواعظ'],
                ['Spider Curl', 'باي سبايدر'],
                ['Wide Grip Barbell Curl', 'باي بار بقبضة واسعة'],
                ['Dumbbell Curl', 'باي دمبل'],
                ['Barbell Curl', 'باي بار'],
                ['Cable Curl', 'باي كيبل'],
                ['Hammer Curl', 'باي مطرقة'],
                ['Bayesian Curl', 'باي بايزيان'],
                ['Concentration Curl', 'باي تركيز'],
            ],
            'Triceps' => [
                ['Overhead Cable Extension', 'تراي كيبل فوق الرأس'],
                ['Overhead Dumbbell Extension', 'تراي دمبل فوق الرأس'],
                ['Skull Crushers', 'سكل كراشر'],
                ['Rope Pushdown', 'تراي حبل'],
                ['Straight Bar Pushdown', 'تراي بار مستقيم'],
                ['Close Grip Bench Press', 'بنش بقبضة ضيقة'],
                ['Reverse Grip Pushdown', 'تراي بقبضة معكوسة'],
                ['Diamond Push-ups', 'ضغط الماس'],
                ['Bench Dips', 'غطس على المقعد'],
            ],
            'Forearms' => [
                ['Wrist Curl', 'لف المعصم'],
                ['Reverse Wrist Curl', 'لف المعصم العكسي'],
                ['Reverse Curl', 'باي بقبضة معكوسة'],
                ['Zottman Curl', 'زوتمان كيرل'],
                ["Farmer's Walk", 'مشية المزارع'],
                ['Dead Hang', 'التعلق الثابت'],
                ['Plate Pinch', 'قرص الوزنة'],
            ],
            'Traps' => [
                ['Barbell Shrugs', 'هز الكتف بار'],
                ['Dumbbell Shrugs', 'هز الكتف دمبل'],
                ['Y Raise', 'رفرفة Y'],
                ['Prone Trap Raise', 'رفرفة الترابيس منبطح'],
            ],
            'Legs' => [
                ['Back Squat', 'سكوات خلفي'],
                ['Front Squat', 'سكوات أمامي'],
                ['Hack Squat', 'هاك سكوات'],
                ['Leg Press', 'ضغط الأرجل'],
                ['Leg Extension', 'تمديد الأرجل'],
                ['Bulgarian Split Squat', 'سكوات بلغاري'],
                ['Walking Lunges', 'لنجز متحرك'],
                ['Lying Leg Curl', 'ثني الأرجل مستلقي'],
                ['Seated Leg Curl', 'ثني الأرجل جالس'],
                ['Nordic Curl', 'نورديك كيرل'],
                ['Hip Thrust', 'دفع الحوض'],
                ['Cable Kickback', 'ركلة خلفية بالكيبل'],
                ['Sumo Deadlift', 'ديدليفت سومو'],
                ['Standing Calf Raise', 'رفع السمانة واقف'],
                ['Seated Calf Raise', 'رفع السمانة جالس'],
                ['Leg Press Calf Raise', 'رفع السمانة بجهاز الضغط'],
                ['Donkey Calf Raise', 'رفع السمانة (دونكي)'],
            ],
            'Abs' => [
                ['Crunch', 'كرنش'],
                ['Cable Crunch', 'كرنش كيبل'],
                ['Machine Crunch', 'كرنش بالجهاز'],
                ['Hanging Leg Raise', 'رفع الأرجل معلق'],
                ['Reverse Crunch', 'كرنش عكسي'],
                ['Lying Leg Raise', 'رفع الأرجل مستلقي'],
                ['Russian Twist', 'روسيان تويست'],
                ['Cable Wood Chop', 'تقطيع الحطب بالكيبل'],
                ['Side Plank', 'بلانك جانبي'],
                ['Bicycle Crunch', 'كرنش الدراجة'],
            ],
        ];

        foreach ($data as $groupNameEn => $exercises) {
            $muscleGroup = MuscleGroup::where('name_en', $groupNameEn)->first();

            if (!$muscleGroup) {
                $this->command?->warn("Skipping \"{$groupNameEn}\" — run MuscleGroupSeeder first.");
                continue;
            }

            foreach ($exercises as [$nameEn, $nameAr]) {
                $slug = Str::slug($nameEn);

                Exercise::firstOrCreate(
                    [
                        'muscle_group_id' => $muscleGroup->id,
                        'name_en' => $nameEn,
                    ],
                    [
                        'name_ar' => $nameAr,
                        'gif_url' => "exercises/{$slug}.gif",
                    ]
                );
            }
        }
    }
}
