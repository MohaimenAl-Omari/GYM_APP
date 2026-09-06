<?php

namespace App\Console\Commands;

use App\Models\Exercise;
use App\Models\MuscleGroup;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

/**
 * Imports the 30-GIF "exercisedb_v1_sample" batch the user placed in a
 * local Desktop folder (an ExerciseDB.io promotional sample — the user was
 * told this needs its own commercial license for production use and chose
 * to proceed anyway; this command does not itself vouch for that).
 *
 * Unlike exercises:fetch-from-repdb / exercises:fetch-from-wger /
 * exercises:import-local-media, this is NOT a generic fuzzy-matcher run
 * against the batch — with only 30 candidates covering mostly single-joint
 * machine/cable variants, fuzzy matching (even with the ambiguity guard)
 * let real wrong matches through uncontested (e.g. "Flat Barbell Bench
 * Press" → "Barbell Incline Bench Press", the literal opposite — nothing
 * else in a 30-item batch was close enough to trip the guard). So every
 * one of the 30 GIFs below was matched BY HAND against this app's actual
 * exercise list, checking that the equipment/variant shown doesn't
 * contradict the target exercise's name (e.g. a Smith-machine leg press
 * GIF was NOT used for "Seated Cable Row", which explicitly says Cable).
 *
 * Three outcomes per GIF:
 *   - REUSE: an existing seeded exercise's name already covers this exact
 *     movement (e.g. "barbell incline bench press" → the existing
 *     "Incline Barbell Bench Press") — just attaches the GIF, no new row.
 *   - NEW: no existing exercise covers this movement (e.g. "cable
 *     squatting curl", "kettlebell pistol squat") — creates one, keyed on
 *     [muscle_group_id, name_en] via firstOrCreate exactly like
 *     ExerciseSeeder does, so re-running this is always safe (requirement:
 *     don't duplicate).
 *   - SKIPPED (not listed below, see docblock note at the bottom of
 *     $EXERCISES): "smith leg press" (7zdxRTl) — the 45° sled leg press
 *     GIF already covers "Leg Press"; a second leg-press GIF would just be
 *     a duplicate of an exercise that already has one, not a new exercise.
 *
 * Every entry also carries an English + Arabic description (none of the
 * 96 originally-seeded exercises have one yet — ExerciseSeeder never set
 * description_en/description_ar) — written from this batch's own
 * instructions, translated into the same short/informal Arabic style
 * ExerciseSeeder's names already use. This command only backfills
 * descriptions for the ~29 exercises this batch actually touches; the
 * other ~67 pre-existing exercises still have none (out of scope here —
 * there's no source material for them in this batch to write from).
 *
 * Setup: none, purely local — reads GIF files from --dir, no network call.
 *   php artisan exercises:import-exercisedb-v1-sample --dir="/absolute/path/to/Exercises" --dry-run
 */
class ImportExercisedbV1Sample extends Command
{
    protected $signature = 'exercises:import-exercisedb-v1-sample
        {--dir= : Absolute path to the folder containing the 30 .gif files}
        {--dry-run : Show what would change without copying files or saving anything}
        {--force : Overwrite gif_url/descriptions even if already set}';

    protected $description = 'Hand-curated import of the exercisedb_v1_sample 30-GIF batch onto this app\'s exercise list';

    /**
     * @var array<int, array{gif: string, name_en: string, name_ar: string, description_en: string, description_ar: string, muscle_group: string}>
     *
     * `muscle_group` is only used when the exercise doesn't exist yet
     * (creation path) — for a REUSE entry it's simply the group the
     * existing exercise already belongs to, kept here for readability.
     */
    private const EXERCISES = [
        // --- Reused onto existing seeded exercises (17) ---
        ['gif' => '2ORFMoR.gif', 'name_en' => 'Leg Press Calf Raise', 'name_ar' => 'رفع السمانة بجهاز الضغط', 'muscle_group' => 'Legs',
            'description_en' => 'Stand on the platform of a leg press or sled machine with your heels hanging off the edge and your toes planted. Push through the balls of your feet to raise your heels as high as possible, then lower back down under control.',
            'description_ar' => 'قف على قاعدة جهاز الضغط (السلد) بحيث تكون أطراف أصابعك على القاعدة وكعبيك خارجها. ادفع بمقدمة قدمك لرفع الكعبين لأعلى قدر ممكن، ثم انزل ببطء للوضع الأول.'],
        ['gif' => '2Qh2J1e.gif', 'name_en' => 'Leg Press', 'name_ar' => 'ضغط الأرجل', 'muscle_group' => 'Legs',
            'description_en' => 'Sit in the leg press machine with your back flat against the pad and your feet shoulder-width apart on the footplate. Push through your heels to extend your legs fully, then slowly bend your knees to lower the weight back down under control.',
            'description_ar' => 'اجلس في جهاز ضغط الأرجل مع إسناد ظهرك بالكامل على المسند وقدميك على القاعدة بعرض الكتفين. ادفع بكعبيك لتمديد رجليك بالكامل، ثم اثنِ ركبتيك ببطء لإنزال الوزن مرة أخرى.'],
        ['gif' => '3eGE2JC.gif', 'name_en' => 'Front Raise', 'name_ar' => 'رفرفة أمامية', 'muscle_group' => 'Shoulders',
            'description_en' => 'Stand holding a dumbbell in each hand in front of your thighs, palms facing your body. Keeping your arms straight, raise the dumbbells in front of you to shoulder height, then lower them back down with control.',
            'description_ar' => 'قف ممسكًا بدمبل في كل يد أمام فخذيك وراحة يدك للداخل. مع تثبيت ذراعيك مستقيمتين، ارفع الدمبل أمامك حتى مستوى الكتف، ثم أنزلهما ببطء.'],
        ['gif' => '3tAXPQ6.gif', 'name_en' => 'Reverse Wrist Curl', 'name_ar' => 'لف المعصم العكسي', 'muscle_group' => 'Forearms',
            'description_en' => 'Rest your forearms on a bench with your wrists hanging off the edge, holding a dumbbell or barbell with your palms facing down. Curl your wrists upward as far as you can, then slowly lower back to the starting position.',
            'description_ar' => 'ضع ساعديك على مقعد بحيث يتدلى معصماك خارج الحافة، ممسكًا بدمبل أو بار وراحة يدك للأسفل. ارفع معصميك للأعلى قدر الإمكان، ثم أنزلهما ببطء.'],
        ['gif' => '3TZduzM.gif', 'name_en' => 'Incline Barbell Bench Press', 'name_ar' => 'بنش بار مائل', 'muscle_group' => 'Chest',
            'description_en' => 'Lie back on an incline bench set at roughly 30-45 degrees and grip the barbell slightly wider than shoulder-width. Lower the bar under control to your upper chest, then press it back up until your arms are fully extended.',
            'description_ar' => 'استلقِ على مقعد مائل بزاوية 30-45 درجة وأمسك البار بقبضة أوسع قليلاً من الكتفين. أنزل البار ببطء حتى الجزء العلوي من صدرك، ثم ادفعه للأعلى حتى تمديد ذراعيك بالكامل.'],
        ['gif' => '5v7KYld.gif', 'name_en' => 'Incline Machine Press', 'name_ar' => 'بنش مائل بالجهاز', 'muscle_group' => 'Chest',
            'description_en' => 'Sit in an incline chest press machine (including a Smith machine set on an incline) with your back against the pad and grip the handles or bar at chest level. Press up and forward until your arms are extended, then return slowly to the starting position.',
            'description_ar' => 'اجلس في جهاز ضغط الصدر المائل (أو السميث على وضع مائل) مع إسناد ظهرك على المسند وأمسك المقابض أو البار عند مستوى الصدر. ادفع للأمام والأعلى حتى تمديد ذراعيك، ثم عد ببطء للوضع الأول.'],
        ['gif' => '6kSxYnw.gif', 'name_en' => 'Wrist Curl', 'name_ar' => 'لف المعصم', 'muscle_group' => 'Forearms',
            'description_en' => 'Sit and rest your forearms on your thighs or a bench with your wrists hanging off the edge, holding a barbell with an underhand grip. Curl your wrists upward as far as you can, then lower back down with control.',
            'description_ar' => 'اجلس وضع ساعديك على فخذيك أو على مقعد بحيث يتدلى معصماك خارج الحافة، ممسكًا بالبار بقبضة سفلية. ارفع معصميك للأعلى قدر الإمكان، ثم أنزلهما ببطء.'],
        ['gif' => '6MfS53i.gif', 'name_en' => 'Skull Crushers', 'name_ar' => 'سكل كراشر', 'muscle_group' => 'Triceps',
            'description_en' => 'Lie flat on a bench holding a weight with your arm(s) extended straight above your chest. Bend your elbows to lower the weight toward your forehead, keeping your upper arms still, then extend back up.',
            'description_ar' => 'استلقِ على مقعد ممسكًا بوزن وذراعك ممدودة فوق صدرك. اثنِ مرفقك لإنزال الوزن باتجاه جبهتك مع تثبيت أعلى ذراعك، ثم مدد ذراعك للأعلى مرة أخرى.'],
        ['gif' => '7F1DVzn.gif', 'name_en' => 'Lat Pulldown', 'name_ar' => 'سحب أمامي للظهر', 'muscle_group' => 'Back',
            'description_en' => 'Sit at the pulldown machine with your thighs secured under the pads and grip the bar wider than shoulder-width. Pull the bar down to your upper chest, squeezing your shoulder blades together, then release back up with control.',
            'description_ar' => 'اجلس في جهاز السحب الأمامي مع تثبيت فخذيك تحت الوسادة وأمسك البار بقبضة أوسع من الكتفين. اسحب البار لأسفل حتى أعلى صدرك مع ضم لوحي الكتف، ثم أعده للأعلى ببطء.'],
        ['gif' => '7inpWch.gif', 'name_en' => 'Concentration Curl', 'name_ar' => 'باي تركيز', 'muscle_group' => 'Biceps',
            'description_en' => 'Hold a dumbbell in one hand with your arm extended, bracing your elbow against your inner thigh (seated) or stabilizing it at your side (standing). Curl the weight up toward your shoulder, squeeze, then lower back down slowly.',
            'description_ar' => 'أمسك دمبل بيد واحدة وذراعك ممدودة، مع إسناد مرفقك على الفخذ الداخلي (جلوسًا) أو تثبيته بجانبك (وقوفًا). ارفع الوزن نحو كتفك، اضغط، ثم أنزله ببطء.'],
        ['gif' => '7saC5zz.gif', 'name_en' => 'High-to-Low Cable Fly', 'name_ar' => 'فراشة كيبل من الأعلى للأسفل', 'muscle_group' => 'Chest',
            'description_en' => 'Set the cable pulleys to the high position and stand facing away from the machine holding a handle in each hand. With a slight bend in your elbows, pull your hands down and together in front of you, then return under control.',
            'description_ar' => 'اضبط بكرات الكيبل على الوضع العلوي وقف ووجهك بعيدًا عن الجهاز ممسكًا بمقبض في كل يد. مع ثني بسيط في مرفقيك، اسحب يديك للأسفل وللأمام حتى تلتقيا، ثم عد ببطء.'],
        ['gif' => '8eqjhOl.gif', 'name_en' => 'Incline Dumbbell Press', 'name_ar' => 'بنش دمبل مائل', 'muscle_group' => 'Chest',
            'description_en' => 'Lie back on an incline bench holding a dumbbell in each hand at shoulder level. Press the dumbbells up until your arms are extended, then lower them back down under control.',
            'description_ar' => 'استلقِ على مقعد مائل ممسكًا بدمبل في كل يد عند مستوى الكتف. ادفع الدمبل للأعلى حتى تمديد ذراعيك، ثم أنزلهما ببطء.'],
        ['gif' => '8K0w2yA.gif', 'name_en' => 'Hanging Leg Raise', 'name_ar' => 'رفع الأرجل معلق', 'muscle_group' => 'Abs',
            'description_en' => 'Hang from a pull-up bar (or an assisted knee-raise station) with your arms fully extended. Engage your core to lift your knees or legs up toward your chest, then lower back down with control.',
            'description_ar' => 'تعلق من عارضة العقلة (أو جهاز رفع الركبة المساعد) وذراعاك ممدودتان بالكامل. شغّل عضلات بطنك لرفع ركبتيك أو رجليك نحو صدرك، ثم أنزلهما ببطء.'],
        ['gif' => '8oYqOt9.gif', 'name_en' => 'Cable Curl', 'name_ar' => 'باي كيبل', 'muscle_group' => 'Biceps',
            'description_en' => 'Stand or sit facing a cable machine holding the attachment with an underhand grip, arms extended. Curl your hands toward your shoulders by contracting your biceps, then lower back down under control.',
            'description_ar' => 'قف أو اجلس أمام جهاز الكيبل ممسكًا بالمقبض بقبضة سفلية وذراعاك ممدودتان. اثنِ ذراعيك نحو كتفيك بتقلص عضلة الباي، ثم أنزلهما ببطء.'],
        ['gif' => '8ozhUIZ.gif', 'name_en' => 'Standing Calf Raise', 'name_ar' => 'رفع السمانة واقف', 'muscle_group' => 'Legs',
            'description_en' => 'Stand with the balls of your feet on a raised platform or with a barbell across your upper back. Raise your heels as high as possible, pause at the top, then lower back down under control.',
            'description_ar' => 'قف بمقدمة قدميك على قاعدة مرتفعة أو مع وضع البار على أعلى ظهرك. ارفع كعبيك لأعلى قدر ممكن، توقف قليلاً، ثم أنزلهما ببطء.'],
        ['gif' => '8urJS9b.gif', 'name_en' => 'Hyperextensions', 'name_ar' => 'تمديد الظهر السفلي', 'muscle_group' => 'Back',
            'description_en' => 'Position yourself face-down on a hyperextension bench or stability ball with your hips supported and feet anchored. Lower your upper body forward, then engage your lower back to raise it back up until your body forms a straight line.',
            'description_ar' => 'استلقِ على وجهك على مقعد تمديد الظهر أو كرة استقرار مع إسناد وركيك وتثبيت قدميك. أنزل الجزء العلوي من جسمك للأمام، ثم شغّل أسفل ظهرك لرفعه حتى يصبح جسمك بخط مستقيم.'],
        ['gif' => '8xUv4J7.gif', 'name_en' => 'Cable Crunch', 'name_ar' => 'كرنش كيبل', 'muscle_group' => 'Abs',
            'description_en' => 'Kneel or sit facing a cable machine and hold the rope attachment behind your head. Engage your abs to curl your torso forward and down, then slowly return to the starting position.',
            'description_ar' => 'اجلس أو اركع أمام جهاز الكيبل وأمسك مقبض الحبل خلف رأسك. شغّل عضلات بطنك لثني جذعك للأمام وللأسفل، ثم عد ببطء للوضع الأول.'],

        // --- New exercises this batch introduces (12) ---
        ['gif' => '3XFdb1Z.gif', 'name_en' => 'Cable Squat Curl', 'name_ar' => 'باي سكوات كيبل', 'muscle_group' => 'Biceps',
            'description_en' => 'Hold a low cable handle with an underhand grip and arms extended. As you lower into a squat, curl the handle up toward your shoulders, then extend your arms as you stand back up.',
            'description_ar' => 'أمسك مقبض الكيبل السفلي بقبضة سفلية وذراعاك ممدودتان. أثناء نزولك لوضع السكوات، اثنِ ذراعيك وارفع المقبض نحو كتفيك، ثم مدد ذراعيك وأنت تقف مجددًا.'],
        ['gif' => '4dF3maG.gif', 'name_en' => 'One Arm Hammer Preacher Curl', 'name_ar' => 'باي مطرقة على مقعد الواعظ بيد واحدة', 'muscle_group' => 'Biceps',
            'description_en' => 'Sit at a preacher bench with your upper arm resting on the pad, holding a dumbbell with a neutral (palms-in) grip. Curl the dumbbell up toward your shoulder, squeeze, then lower back down slowly, keeping your upper arm still.',
            'description_ar' => 'اجلس على مقعد الواعظ مع إسناد أعلى ذراعك على الوسادة، ممسكًا بدمبل بقبضة محايدة (راحة اليد للداخل). ارفع الدمبل نحو كتفك، اضغط، ثم أنزله ببطء مع تثبيت أعلى ذراعك.'],
        ['gif' => '4dUn2iv.gif', 'name_en' => 'Close Grip Barbell Curl', 'name_ar' => 'باي بار بقبضة ضيقة', 'muscle_group' => 'Biceps',
            'description_en' => 'Stand holding a barbell with an underhand grip, hands close together near the center of the bar. Curl the bar up toward your shoulders while keeping your elbows tucked in, then lower back down under control.',
            'description_ar' => 'قف ممسكًا بالبار بقبضة سفلية ويديك قريبتين من منتصف البار. ارفع البار نحو كتفيك مع إبقاء مرفقيك قريبين من جسمك، ثم أنزله ببطء.'],
        ['gif' => '5bpPTHv.gif', 'name_en' => 'Kettlebell Pistol Squat', 'name_ar' => 'سكوات بيستول بالكيتل بيل', 'muscle_group' => 'Legs',
            'description_en' => 'Hold a kettlebell in front of your chest and stand on one leg with the other extended forward. Lower into a single-leg squat under control, then push through your standing heel to return to standing.',
            'description_ar' => 'أمسك الكيتل بيل أمام صدرك وقف على رجل واحدة مع تمديد الأخرى للأمام. انزل ببطء في سكوات على رجل واحدة، ثم ادفع بكعب رجلك الثابتة للعودة للوقوف.'],
        ['gif' => '05Cf2v8.gif', 'name_en' => 'Impossible Dips', 'name_ar' => 'غطس مستحيل', 'muscle_group' => 'Triceps',
            'description_en' => 'Support yourself between parallel bars with your arms extended, then bend your knees and cross your ankles behind you. Lower your body by bending your elbows until your upper arms are roughly parallel to the ground, then press back up.',
            'description_ar' => 'اسند جسمك بين متوازيين وذراعاك ممدودتان، ثم اثنِ ركبتيك واعبر كاحليك خلفك. أنزل جسمك بثني مرفقيك حتى يصبح أعلى ذراعيك موازيًا للأرض تقريبًا، ثم ادفع للأعلى مجددًا.'],
        ['gif' => '5uFK1xr.gif', 'name_en' => 'Barbell Seated Overhead Triceps Extension', 'name_ar' => 'تراي بار فوق الرأس جالس', 'muscle_group' => 'Triceps',
            'description_en' => 'Sit with your back straight, holding a barbell overhead with your hands shoulder-width apart. Lower the bar behind your head by bending your elbows, then extend your arms to press it back up.',
            'description_ar' => 'اجلس مع تثبيت ظهرك مستقيمًا، ممسكًا بالبار فوق رأسك ويديك بعرض الكتفين. أنزل البار خلف رأسك بثني مرفقيك، ثم مدد ذراعيك لدفعه للأعلى مجددًا.'],
        ['gif' => '6bOA1Oi.gif', 'name_en' => 'Weighted Side Bend (Stability Ball)', 'name_ar' => 'ثني جانبي بوزن على كرة الاستقرار', 'muscle_group' => 'Abs',
            'description_en' => 'Sit on a stability ball holding a weight in one hand with your other hand on your hip. Engage your core and bend sideways toward the weighted side, then return to the starting position and repeat on the other side.',
            'description_ar' => 'اجلس على كرة الاستقرار ممسكًا بوزن بيد واحدة واليد الأخرى على وركك. شغّل عضلات بطنك وانثنِ جانبيًا نحو جهة الوزن، ثم عد للوضع الأول وكرر للجهة الأخرى.'],
        ['gif' => '6cKQC5E.gif', 'name_en' => 'Dumbbell Upright Row', 'name_ar' => 'سحب عمودي دمبل', 'muscle_group' => 'Shoulders',
            'description_en' => 'Stand holding a dumbbell in front of your thighs with an overhand grip. Lift the dumbbell straight up toward your chin, leading with your elbow, then lower back down under control.',
            'description_ar' => 'قف ممسكًا بالدمبل أمام فخذيك بقبضة علوية. ارفع الدمبل عموديًا نحو ذقنك بحيث يقود المرفق الحركة، ثم أنزله ببطء.'],
        ['gif' => '6HiHHe0.gif', 'name_en' => 'Standing Barbell Rocking Calf Raise', 'name_ar' => 'رفع السمانة واقف بحركة الترجيح بالبار', 'muscle_group' => 'Legs',
            'description_en' => 'Stand with a barbell across your upper back and rock forward onto the balls of your feet. Raise your heels as high as possible, then lower back down and repeat for a continuous rocking rhythm.',
            'description_ar' => 'قف مع وضع البار على أعلى ظهرك وارجح للأمام على مقدمة قدميك. ارفع كعبيك لأعلى قدر ممكن، ثم أنزلهما وكرر بحركة ترجيح مستمرة.'],
        ['gif' => '6sMAmNv.gif', 'name_en' => 'Dumbbell Reverse Spider Curl', 'name_ar' => 'باي سبايدر عكسي دمبل', 'muscle_group' => 'Biceps',
            'description_en' => 'Stand holding a dumbbell in each hand with your palms facing your body. Keeping your upper arms still, curl the weights up toward your shoulders, squeeze, then lower back down slowly.',
            'description_ar' => 'قف ممسكًا بدمبل في كل يد وراحة يدك للداخل. مع تثبيت أعلى ذراعيك، ارفع الأوزان نحو كتفيك، اضغط، ثم أنزلهما ببطء.'],
        ['gif' => '6sYyrRX.gif', 'name_en' => 'Lying Bent-Knee Twist', 'name_ar' => 'لف الجذع مستلقيًا بركبتين مثنيتين', 'muscle_group' => 'Abs',
            'description_en' => 'Lie on your back with your knees bent and arms extended out to the sides. Keeping your knees together, slowly lower them to one side, then engage your core to bring them back to center and repeat on the other side.',
            'description_ar' => 'استلقِ على ظهرك مع ثني ركبتيك ومد ذراعيك للجانبين. مع إبقاء ركبتيك ملتصقتين، أنزلهما ببطء لجهة واحدة، ثم شغّل عضلات بطنك لإعادتهما للمنتصف وكرر للجهة الأخرى.'],
        ['gif' => '7I6LNUG.gif', 'name_en' => 'Lever Seated Row', 'name_ar' => 'تجديف جالس بجهاز الرافعة', 'muscle_group' => 'Back',
            'description_en' => 'Sit at a lever row machine with your chest against the pad and grip the handles with an overhand grip. Pull the handles toward your body, squeezing your shoulder blades together, then release back out under control.',
            'description_ar' => 'اجلس في جهاز التجديف بالرافعة مع إسناد صدرك على الوسادة وأمسك المقابض بقبضة علوية. اسحب المقابض نحو جسمك مع ضم لوحي الكتف، ثم حررهما ببطء للخارج.'],

        // NOT included: 7zdxRTl.gif ("smith leg press") — 2Qh2J1e already
        // covers "Leg Press"; a second leg-press GIF would just duplicate
        // an exercise that already has one rather than add a new exercise.
    ];

    public function handle(): int
    {
        $dir = $this->option('dir');

        if (!$dir) {
            $this->error('--dir is required (the folder containing the 30 .gif files).');

            return self::FAILURE;
        }

        if (!is_dir($dir)) {
            $this->error("--dir does not exist or is not a folder: {$dir}");

            return self::FAILURE;
        }

        $dryRun = (bool) $this->option('dry-run');
        $force = (bool) $this->option('force');

        $created = 0;
        $updated = 0;
        $skipped = 0;

        foreach (self::EXERCISES as $entry) {
            $sourcePath = rtrim($dir, '/') . '/' . $entry['gif'];

            if (!is_file($sourcePath)) {
                $this->warn("Missing file, skipping: {$entry['gif']} ({$entry['name_en']})");
                $skipped++;

                continue;
            }

            $muscleGroup = MuscleGroup::where('name_en', $entry['muscle_group'])->first();

            if (!$muscleGroup) {
                $this->warn("Muscle group \"{$entry['muscle_group']}\" not found — run MuscleGroupSeeder first. Skipping {$entry['name_en']}.");
                $skipped++;

                continue;
            }

            $exercise = Exercise::where('name_en', $entry['name_en'])->first();
            $isNew = $exercise === null;

            if ($isNew) {
                $this->line("[NEW]    {$entry['name_en']} ({$entry['muscle_group']}) <- {$entry['gif']}");

                if ($dryRun) {
                    $created++;

                    continue;
                }

                $exercise = new Exercise(['muscle_group_id' => $muscleGroup->id, 'name_en' => $entry['name_en']]);
            } else {
                $this->line("[REUSE]  {$entry['name_en']} <- {$entry['gif']}");
            }

            if ($dryRun) {
                $updated++;

                continue;
            }

            $storedPath = $this->storeGif($entry['gif'], $sourcePath);

            if ($force || !$this->hasWorkingGif($exercise)) {
                $exercise->gif_url = $storedPath;
            }

            if ($isNew || $force || empty($exercise->name_ar)) {
                $exercise->name_ar = $entry['name_ar'];
            }

            if ($force || empty($exercise->description_en)) {
                $exercise->description_en = $entry['description_en'];
            }

            if ($force || empty($exercise->description_ar)) {
                $exercise->description_ar = $entry['description_ar'];
            }

            $exercise->save();

            $isNew ? $created++ : $updated++;
        }

        $this->newLine();
        $this->info(
            ($dryRun ? '[dry run] ' : '') .
            "New exercises: {$created}, updated existing: {$updated}, skipped: {$skipped}"
        );

        if (!$dryRun && $created + $updated > 0) {
            $this->newLine();
            $this->comment('Reminder: these GIFs came from a promotional sample, not a confirmed-clear license — see the conversation where this was flagged.');
        }

        $this->reportExercisesWithoutGif();

        return self::SUCCESS;
    }

    private function storeGif(string $filename, string $sourcePath): string
    {
        $storedPath = 'exercises/local-' . pathinfo($filename, PATHINFO_FILENAME) . '.gif';

        if (!Storage::disk('public')->exists($storedPath)) {
            Storage::disk('public')->put($storedPath, file_get_contents($sourcePath));
        }

        return $storedPath;
    }

    /**
     * `gif_url` being a non-empty string is NOT enough to call an exercise
     * "covered" — ExerciseSeeder sets every exercise's gif_url to a
     * predictable placeholder path (exercises/{slug}.gif) at seed time,
     * whether or not that file actually exists in storage yet. Checking
     * `empty($exercise->gif_url)` alone would treat every seeded exercise
     * as already having a GIF and skip overwriting the placeholder with a
     * real one — exactly backwards. This checks whether the value is
     * either a real external URL (always trusted, can't verify a remote
     * file from here without a network call) or a local path that
     * genuinely exists on the public disk.
     */
    private function hasWorkingGif(Exercise $exercise): bool
    {
        $path = $exercise->gif_url;

        if (empty($path)) {
            return false;
        }

        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return true;
        }

        return Storage::disk('public')->exists($path);
    }

    /**
     * Satisfies the standing ask: at the end, list every exercise that
     * still has no WORKING gif_url (regardless of whether it has a static
     * `media` image) — this is deliberately about GIF coverage
     * specifically, not overall media coverage.
     */
    private function reportExercisesWithoutGif(): void
    {
        // Can't express "does the local file actually exist" in SQL, so
        // this pulls every exercise and filters with the same
        // hasWorkingGif() check used above — deliberately not just a
        // whereNull/where('', '') query, which would miss every exercise
        // still sitting on ExerciseSeeder's unfulfilled placeholder path.
        $missing = Exercise::query()
            ->orderBy('muscle_group_id')
            ->with('muscleGroup')
            ->get()
            ->reject(fn (Exercise $exercise) => $this->hasWorkingGif($exercise));

        $this->newLine();

        if ($missing->isEmpty()) {
            $this->info('Every exercise now has a gif_url. Nothing left without a GIF.');

            return;
        }

        $this->warn("Exercises still without a GIF ({$missing->count()}):");

        foreach ($missing->groupBy(fn ($e) => $e->muscleGroup->name_en ?? 'Unknown') as $groupName => $exercises) {
            $this->line("  {$groupName}:");
            foreach ($exercises as $exercise) {
                $hasImage = !empty($exercise->media) ? ' (has a static image)' : '';
                $this->line("    - {$exercise->name_en}{$hasImage}");
            }
        }
    }
}
