<?php

namespace App\Console\Commands;

use App\Models\Exercise;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

/**
 * Imports GIFs from the "hasaneyldrm/exercises-dataset" GitHub repo
 * (https://github.com/hasaneyldrm/exercises-dataset) — the user downloaded
 * its 1,324-file `videos` folder (all .gif despite the name) onto their own
 * Mac. Same licensing situation as exercises:import-exercisedb-v1-sample:
 * the repo's code/JSON is MIT, but the media itself is © Gym visual
 * (gymvisual.com), redistributed "with permission" at reduced resolution —
 * commercial reuse needs a separate license from Gym visual. The user was
 * told this and chose to proceed anyway; this command doesn't vouch for it.
 *
 * In fact this dataset and exercisedb_v1_sample turned out to be the SAME
 * underlying media library — several of this repo's files share the exact
 * random-suffix filename exercisedb_v1_sample used (e.g. "...4dF3maG.gif"
 * for One Arm Hammer Preacher Curl in both). Every exercise already covered
 * by exercises:import-exercisedb-v1-sample is left out of the list below
 * entirely — re-adding it here would either be a same-file no-op or
 * overwrite a working GIF with nothing gained. hasWorkingGif() below is a
 * second line of defense: even if this list is ever re-run after something
 * else fills a gif_url in, it won't clobber real data without --force.
 *
 * Matching method: fuzzy-matched this app's exercise names against the
 * dataset's 1,324 candidates (see Concerns\FuzzyMatchesExerciseNames),
 * tested against the real manifest — NOT hand-picked from nothing. At
 * min-score 0.5 the matcher found 57 candidates; every one of those 57 was
 * manually reviewed against the matched exercise's actual name before being
 * added below (same standard as exercisedb_v1_sample), because the word-
 * overlap scoring can favor a shorter wrong candidate over a longer correct
 * one (e.g. it originally preferred "dumbbell one arm upright row" over the
 * correct "dumbbell one arm bent-over row" for "One Arm Dumbbell Row" —
 * fewer extra words scored higher despite being the wrong exercise). Of the
 * 57: 14 were already covered by exercisedb_v1_sample (dropped), 1 was too
 * ambiguous to trust ("Bulgarian Split Squat" only had a generic "split
 * squats" candidate with no rear-foot-elevated indication — dropped rather
 * than guess), 3 needed correcting to the right candidate by hand (Machine
 * Chest Press, One Arm Dumbbell Row, Y Raise — see notes below), leaving
 * the 38 below. "Low-to-High"/"High-to-Low Cable Fly" were in the raw
 * matches at a looser threshold but dropped automatically once min-score
 * was raised to 0.5 — the dataset has no angle-specific fly variant, and a
 * generic "cable low fly" isn't the same exercise as either.
 *
 * Descriptions: written from this dataset's own English instructions
 * (data/exercises.json → instructions.en), condensed into this app's
 * existing 2-sentence house style and translated into the same short/
 * informal Arabic ExerciseSeeder's other entries use — same approach as
 * exercisedb_v1_sample. Only fills description_en/description_ar when
 * empty (or with --force), same as gif_url.
 *
 * Setup: none, purely local — reads GIF files from --dir, no network call.
 *   php artisan exercises:import-hasaneyldrm-media --dir="/absolute/path/to/videos" --dry-run
 */
class ImportHasaneyldrmExerciseMedia extends Command
{
    protected $signature = 'exercises:import-hasaneyldrm-media
        {--dir= : Absolute path to the folder containing the dataset\'s .gif files}
        {--dry-run : Show what would change without copying files or saving anything}
        {--force : Overwrite gif_url/name_ar/descriptions even if already set}';

    protected $description = 'Backfill exercise GIFs + descriptions matched (and manually verified) against the hasaneyldrm/exercises-dataset repo';

    /**
     * @var array<int, array{gif: string, name_en: string, description_en: string, description_ar: string}>
     *
     * `name_en` must match an EXISTING exercise exactly — this command only
     * updates existing rows, it never creates new ones. With 1,324 source
     * candidates against ~108 of our exercises, the overwhelming majority
     * of the dataset simply doesn't correspond to anything in this app; the
     * right response to that is to leave those exercises alone, not to
     * import hundreds of exercises nobody asked for.
     */
    private const EXERCISES = [
        ['gif' => '0025-EIeI8Vf.gif', 'name_en' => 'Flat Barbell Bench Press',
            'description_en' => 'Lie flat on a bench with your feet planted on the ground and grip the barbell slightly wider than shoulder-width. Lower the bar under control to your mid-chest, then press it back up until your arms are fully extended.',
            'description_ar' => 'استلقِ على مقعد مسطح وقدماك على الأرض، وأمسك البار بقبضة أوسع قليلاً من الكتفين. أنزل البار ببطء حتى منتصف صدرك، ثم ادفعه للأعلى حتى تمديد ذراعيك بالكامل.'],
        ['gif' => '0289-SpYC0Kp.gif', 'name_en' => 'Flat Dumbbell Bench Press',
            'description_en' => 'Lie flat on a bench holding a dumbbell in each hand above your chest, palms facing forward. Lower the dumbbells to the sides of your chest with your elbows at about 90 degrees, then press them back up until your arms are extended.',
            'description_ar' => 'استلقِ على مقعد مسطح ممسكًا بدمبل في كل يد فوق صدرك وراحة يدك للأمام. أنزل الدمبل لجانبي صدرك بحيث تكون زاوية مرفقيك حوالي 90 درجة، ثم ادفعهما للأعلى حتى تمديد ذراعيك.'],
        // Matched candidate: "lever chest press" (0577) — not "machine inner
        // chest press", which the matcher preferred but is a distinct
        // squeeze-style machine, not a plain chest press.
        ['gif' => '0577-T0yTjgW.gif', 'name_en' => 'Machine Chest Press',
            'description_en' => 'Sit in the chest press machine with your back flat against the pad and grip the handles at chest level, elbows at about 90 degrees. Push the handles forward until your arms are extended, then return slowly to the starting position.',
            'description_ar' => 'اجلس في جهاز ضغط الصدر مع إسناد ظهرك بالكامل على المسند وأمسك المقابض عند مستوى الصدر بزاوية مرفقين حوالي 90 درجة. ادفع المقابض للأمام حتى تمديد ذراعيك، ثم عد ببطء للوضع الأول.'],
        ['gif' => '0662-I4hDWkc.gif', 'name_en' => 'Push-ups',
            'description_en' => 'Start in a high plank with your hands slightly wider than shoulder-width apart and your body in a straight line. Lower your chest toward the ground by bending your elbows, then push back up until your arms are extended.',
            'description_ar' => 'ابدأ بوضعية البلانك العالي ويداك أوسع قليلاً من الكتفين وجسمك بخط مستقيم. أنزل صدرك نحو الأرض بثني مرفقيك، ثم ادفع نفسك للأعلى حتى تمديد ذراعيك.'],
        ['gif' => '0251-9WTm7dq.gif', 'name_en' => 'Chest Dips',
            'description_en' => 'Support yourself on parallel bars with your arms fully extended. Lower your body by bending your elbows until your shoulders dip below them, then press back up to the starting position.',
            'description_ar' => 'اسند جسمك على متوازيين وذراعاك ممدودتان بالكامل. أنزل جسمك بثني مرفقيك حتى ينزل كتفاك تحت مستوى مرفقيك، ثم ادفع نفسك للأعلى للوضع الأول.'],
        ['gif' => '0652-lBDjFxJ.gif', 'name_en' => 'Pull-ups',
            'description_en' => 'Hang from a pull-up bar with an overhand grip and your arms fully extended. Pull your body up by driving your elbows down until your chest nears the bar, then lower back down under control.',
            'description_ar' => 'تعلق من عارضة العقلة بقبضة علوية وذراعاك ممدودتان بالكامل. اسحب جسمك للأعلى بدفع مرفقيك للأسفل حتى يقترب صدرك من العارضة، ثم انزل ببطء.'],
        ['gif' => '1326-T2mxWqc.gif', 'name_en' => 'Chin-ups',
            'description_en' => 'Hang from a bar with an underhand, shoulder-width grip and your arms extended. Pull your body up leading with your chest until your chin clears the bar, then lower back down under control.',
            'description_ar' => 'تعلق من العارضة بقبضة سفلية بعرض الكتفين وذراعاك ممدودتان. اسحب جسمك للأعلى بحيث يقود صدرك الحركة حتى يتجاوز ذقنك العارضة، ثم انزل ببطء.'],
        ['gif' => '0238-x69MAlq.gif', 'name_en' => 'Straight Arm Pulldown',
            'description_en' => "Stand facing a cable machine with a straight bar attached to the high pulley, arms straight and grip overhand. Keeping your arms locked, pull the bar down toward your thighs by engaging your lats, then let it return under control.",
            'description_ar' => 'قف أمام جهاز الكيبل والبار المستقيم مثبت في البكرة العلوية، وذراعاك مستقيمتان وقبضتك علوية. مع تثبيت ذراعيك، اسحب البار للأسفل نحو فخذيك بتشغيل عضلات الظهر العريضة، ثم دعه يعود ببطء.'],
        ['gif' => '0606-aaXr7ld.gif', 'name_en' => 'T-Bar Row',
            'description_en' => 'Set up at the T-bar row machine with your chest against the pad and grip the handles with an overhand grip. Pull the handles toward your torso, squeezing your shoulder blades together, then release back out under control.',
            'description_ar' => 'قف عند جهاز تجديف التي بار مع إسناد صدرك على الوسادة وأمسك المقابض بقبضة علوية. اسحب المقابض نحو جذعك مع ضم لوحي الكتف، ثم حررهما ببطء للخارج.'],
        ['gif' => '0861-fUBheHs.gif', 'name_en' => 'Seated Cable Row',
            'description_en' => 'Sit at the cable row station with your feet on the footrests and knees slightly bent, holding the handle with arms extended. Pull the handle toward your torso while keeping your back straight, then extend your arms back out under control.',
            'description_ar' => 'اجلس عند جهاز التجديف بالكيبل وقدماك على المسندين وركبتاك مثنيتان قليلاً، ممسكًا بالمقبض وذراعاك ممدودتان. اسحب المقبض نحو جذعك مع تثبيت ظهرك مستقيمًا، ثم مدد ذراعيك للخارج ببطء.'],
        // Matched candidate: "dumbbell one arm bent-over row" (0292) — not
        // "dumbbell one arm upright row", which the matcher preferred (it
        // has fewer extra words, so it out-scored the correct candidate)
        // but is a completely different exercise (shoulders, not back).
        ['gif' => '0292-C0MA9bC.gif', 'name_en' => 'One Arm Dumbbell Row',
            'description_en' => 'Place one knee and hand on a bench for support, holding a dumbbell in your other hand with your arm extended toward the floor. Pull the dumbbell up toward your hip, keeping your elbow close to your body, then lower back down under control.',
            'description_ar' => 'ضع ركبة ويدًا واحدة على مقعد للدعم، وأمسك بالدمبل باليد الأخرى وذراعك ممدودة نحو الأرض. اسحب الدمبل للأعلى نحو وركك مع إبقاء مرفقك قريبًا من جسمك، ثم أنزله ببطء.'],
        ['gif' => '0044-XlZ4lAC.gif', 'name_en' => 'Good Mornings',
            'description_en' => 'Stand with the barbell resting on your upper back, feet shoulder-width apart. Keeping your back straight, hinge forward at the hips until your torso is roughly parallel to the floor, then drive your hips forward to return to standing.',
            'description_ar' => 'قف مع وضع البار على أعلى ظهرك وقدماك بعرض الكتفين. مع تثبيت ظهرك مستقيمًا، انحنِ للأمام من الوركين حتى يصبح جذعك موازيًا للأرض تقريبًا، ثم ادفع وركيك للأمام للعودة للوقوف.'],
        ['gif' => '0091-kTbSH9h.gif', 'name_en' => 'Barbell Overhead Press',
            'description_en' => 'Sit or stand holding the barbell at shoulder level with an overhand grip slightly wider than shoulder-width. Press the bar straight overhead until your arms are fully extended, then lower it back to shoulder level under control.',
            'description_ar' => 'اجلس أو قف ممسكًا بالبار عند مستوى الكتف بقبضة علوية أوسع قليلاً من الكتفين. ادفع البار عموديًا للأعلى حتى تمديد ذراعيك بالكامل، ثم أنزله ببطء حتى مستوى الكتف.'],
        ['gif' => '0405-znQUdHY.gif', 'name_en' => 'Dumbbell Shoulder Press',
            'description_en' => 'Sit holding a dumbbell in each hand at shoulder height, palms facing forward. Press the dumbbells overhead until your arms are extended, then lower them back to shoulder height under control.',
            'description_ar' => 'اجلس ممسكًا بدمبل في كل يد عند مستوى الكتف وراحة يدك للأمام. ادفع الدمبل للأعلى حتى تمديد ذراعيك، ثم أنزلهما ببطء حتى مستوى الكتف.'],
        ['gif' => '0334-DsgkuIt.gif', 'name_en' => 'Dumbbell Lateral Raise',
            'description_en' => "Stand holding a dumbbell in each hand at your sides, palms facing your body. Raise your arms out to the sides until they're roughly parallel to the floor, then lower back down under control.",
            'description_ar' => 'قف ممسكًا بدمبل في كل يد بجانبيك وراحة يدك للداخل. ارفع ذراعيك للجانبين حتى تصبحا موازيتين للأرض تقريبًا، ثم أنزلهما ببطء.'],
        ['gif' => '0178-goJ6ezq.gif', 'name_en' => 'Cable Lateral Raise',
            'description_en' => "Stand beside a low cable pulley holding the handle with your working arm across your body. Raise your arm out to the side until it's roughly parallel to the floor, then lower back down under control.",
            'description_ar' => 'قف بجانب بكرة الكيبل السفلية ممسكًا بالمقبض بذراعك العاملة عبر جسمك. ارفع ذراعك للجانب حتى تصبح موازية للأرض تقريبًا، ثم أنزلها ببطء.'],
        ['gif' => '0318-ae9UoXQ.gif', 'name_en' => 'Incline Dumbbell Curl',
            'description_en' => 'Sit back on an incline bench holding a dumbbell in each hand, arms hanging straight down, palms forward. Curl the dumbbells up toward your shoulders by contracting your biceps, then lower back down under control.',
            'description_ar' => 'استلقِ للخلف على مقعد مائل ممسكًا بدمبل في كل يد وذراعاك متدليتان للأسفل وراحة يدك للأمام. اثنِ ذراعيك وارفع الدمبل نحو كتفيك بتقلص عضلة الباي، ثم أنزلهما ببطء.'],
        ['gif' => '0113-NdIb5Z1.gif', 'name_en' => 'Wide Grip Barbell Curl',
            'description_en' => 'Stand holding a barbell with an overhand grip wider than shoulder-width, arms hanging straight down. Curl the bar up toward your shoulders while keeping your upper arms still, then lower back down under control.',
            'description_ar' => 'قف ممسكًا بالبار بقبضة علوية أوسع من الكتفين وذراعاك متدليتان للأسفل. ارفع البار نحو كتفيك مع تثبيت أعلى ذراعيك، ثم أنزله ببطء.'],
        ['gif' => '0031-25GPyDY.gif', 'name_en' => 'Barbell Curl',
            'description_en' => 'Stand holding a barbell with an underhand, shoulder-width grip, elbows close to your torso. Curl the bar up toward your shoulders by contracting your biceps, then lower back down under control.',
            'description_ar' => 'قف ممسكًا بالبار بقبضة سفلية بعرض الكتفين ومرفقاك قريبان من جذعك. ارفع البار نحو كتفيك بتقلص عضلة الباي، ثم أنزله ببطء.'],
        ['gif' => '0313-slDvUAU.gif', 'name_en' => 'Hammer Curl',
            'description_en' => 'Stand holding a dumbbell in each hand with a neutral grip, palms facing your body. Curl the dumbbells up toward your shoulders while keeping your upper arms still, then lower back down under control.',
            'description_ar' => 'قف ممسكًا بدمبل في كل يد بقبضة محايدة وراحة يدك للداخل. ارفع الدمبل نحو كتفيك مع تثبيت أعلى ذراعيك، ثم أنزلهما ببطء.'],
        ['gif' => '0207-VjYliFZ.gif', 'name_en' => 'Reverse Grip Pushdown',
            'description_en' => 'Stand facing a cable machine with a straight bar attached to the high pulley, grip underhand and elbows close to your sides. Push the bar down until your arms are fully extended, then let it return under control.',
            'description_ar' => 'قف أمام جهاز الكيبل والبار المستقيم مثبت في البكرة العلوية، بقبضة سفلية ومرفقاك قريبان من جانبيك. ادفع البار للأسفل حتى تمديد ذراعيك بالكامل، ثم دعه يعود ببطء.'],
        ['gif' => '0283-soIB2rj.gif', 'name_en' => 'Diamond Push-ups',
            'description_en' => 'Start in a high plank with your hands close together under your chest, forming a diamond shape with your thumbs and index fingers. Lower your chest toward your hands by bending your elbows, then push back up to the starting position.',
            'description_ar' => 'ابدأ بوضعية البلانك العالي ويداك متقاربتان تحت صدرك بشكل يشبه الماس بين إبهاميك وسبابتيك. أنزل صدرك نحو يديك بثني مرفقيك، ثم ادفع نفسك للأعلى للوضع الأول.'],
        ['gif' => '0439-kXaIn5A.gif', 'name_en' => 'Zottman Curl',
            'description_en' => 'Stand holding a dumbbell in each hand, palms facing forward. Curl the dumbbells up to shoulder height, then rotate your wrists so your palms face down and lower them back to the start with that reversed grip.',
            'description_ar' => 'قف ممسكًا بدمبل في كل يد وراحة يدك للأمام. ارفع الدمبل حتى مستوى الكتف، ثم لف معصميك بحيث تصبح راحة يدك للأسفل وأنزلهما بهذه القبضة المعكوسة.'],
        ['gif' => '0095-dG7tG5y.gif', 'name_en' => 'Barbell Shrugs',
            'description_en' => 'Stand holding a barbell in front of your thighs with an overhand grip, arms straight. Shrug your shoulders straight up toward your ears as high as possible, then lower back down under control.',
            'description_ar' => 'قف ممسكًا بالبار أمام فخذيك بقبضة علوية وذراعاك مستقيمتان. ارفع كتفيك عموديًا نحو أذنيك لأعلى قدر ممكن، ثم أنزلهما ببطء.'],
        ['gif' => '0406-NJzBsGJ.gif', 'name_en' => 'Dumbbell Shrugs',
            'description_en' => 'Stand holding a dumbbell in each hand at your sides, palms facing your body. Shrug your shoulders straight up as high as possible, then lower back down under control.',
            'description_ar' => 'قف ممسكًا بدمبل في كل يد بجانبيك وراحة يدك للداخل. ارفع كتفيك عموديًا لأعلى قدر ممكن، ثم أنزلهما ببطء.'],
        // Matched candidate: "dumbbell incline y-raise" (3541) — preferred
        // over "band y-raise" since it matches the usual prone-incline
        // context this exercise is done in, not just the movement shape.
        ['gif' => '3541-PbzNu7c.gif', 'name_en' => 'Y Raise',
            'description_en' => "Lie face-down on an incline bench holding a light dumbbell in each hand, arms hanging down. Raise your arms out and up in a Y shape until they're roughly parallel to the floor, then lower back down under control.",
            'description_ar' => 'استلقِ على وجهك على مقعد مائل ممسكًا بدمبل خفيف في كل يد وذراعاك متدليتان للأسفل. ارفع ذراعيك للخارج وللأعلى بشكل حرف Y حتى تصبحا موازيتين للأرض تقريبًا، ثم أنزلهما ببطء.'],
        ['gif' => '0585-my33uHU.gif', 'name_en' => 'Leg Extension',
            'description_en' => 'Sit in the leg extension machine with your back against the pad and shins behind the padded lever. Extend your legs forward until they\'re straight, then lower back down under control.',
            'description_ar' => 'اجلس في جهاز تمديد الأرجل مع إسناد ظهرك على المسند وساقيك خلف الوسادة. مدد رجليك للأمام حتى تصبحا مستقيمتين، ثم أنزلهما ببطء.'],
        ['gif' => '1460-IZVHb27.gif', 'name_en' => 'Walking Lunges',
            'description_en' => 'Stand with your feet shoulder-width apart, then step forward into a lunge, lowering until your front knee is bent near 90 degrees. Push off and bring your back leg forward into the next lunge, alternating legs as you walk.',
            'description_ar' => 'قف وقدماك بعرض الكتفين، ثم اخطُ للأمام في وضعية اللنجز حتى تصل زاوية ركبتك الأمامية لحوالي 90 درجة. ادفع بقدمك وقدّم رجلك الخلفية للخطوة التالية، وتناوب بين الرجلين أثناء المشي.'],
        ['gif' => '0586-17lJ1kr.gif', 'name_en' => 'Lying Leg Curl',
            'description_en' => 'Lie face-down on the machine with your heels under the padded lever, legs straight. Curl your legs up toward your glutes by bending your knees, then lower back down under control.',
            'description_ar' => 'استلقِ على وجهك على الجهاز مع وضع كعبيك تحت الوسادة وساقيك مستقيمتان. اثنِ ركبتيك وارفع ساقيك نحو مؤخرتك، ثم أنزلهما ببطء.'],
        ['gif' => '0599-Zg3XY7P.gif', 'name_en' => 'Seated Leg Curl',
            'description_en' => 'Sit in the machine with your back against the pad and the backs of your lower legs against the padded lever. Curl your legs down and back by bending your knees, then extend back to the starting position under control.',
            'description_ar' => 'اجلس في الجهاز مع إسناد ظهرك على المسند وربلة ساقيك خلف الوسادة. اثنِ ركبتيك واسحب ساقيك للأسفل وللخلف، ثم مددهما ببطء للوضع الأول.'],
        ['gif' => '0860-HEJ6DIX.gif', 'name_en' => 'Cable Kickback',
            'description_en' => 'Stand facing a low cable pulley, hinge forward slightly at the hips with your upper arm close to your body and elbow bent 90 degrees. Extend your arm straight back by contracting your triceps, then return under control.',
            'description_ar' => 'قف أمام بكرة الكيبل السفلية وانحنِ قليلاً للأمام من الوركين مع إبقاء أعلى ذراعك قريبًا من جسمك ومرفقك مثنيًا بزاوية 90 درجة. مدد ذراعك للخلف بتقلص عضلة التراي، ثم عد ببطء.'],
        ['gif' => '0117-KgI0tqW.gif', 'name_en' => 'Sumo Deadlift',
            'description_en' => 'Stand with your feet wider than shoulder-width, toes turned out, and grip the barbell with your hands inside your knees. Keeping your back straight and chest up, drive through your heels to lift the bar by extending your hips and knees together.',
            'description_ar' => 'قف وقدماك أوسع من الكتفين وأصابع قدميك للخارج، وأمسك البار بيديك بين ركبتيك. مع تثبيت ظهرك مستقيمًا وصدرك للأعلى، ادفع بكعبيك لرفع البار بتمديد وركيك وركبتيك معًا.'],
        ['gif' => '0284-u5ESqzH.gif', 'name_en' => 'Donkey Calf Raise',
            'description_en' => 'Stand with the balls of your feet on a raised platform, hinged forward at the hips for support. Raise your heels as high as possible, then lower back down under control.',
            'description_ar' => 'قف بمقدمة قدميك على قاعدة مرتفعة، وانحنِ للأمام قليلاً من الوركين للدعم. ارفع كعبيك لأعلى قدر ممكن، ثم أنزلهما ببطء.'],
        ['gif' => '0872-nCU1Ekp.gif', 'name_en' => 'Reverse Crunch',
            'description_en' => 'Lie on your back with your knees bent and lifted so your thighs are roughly perpendicular to the floor. Curl your hips up off the floor toward your chest by contracting your abs, then lower back down under control.',
            'description_ar' => 'استلقِ على ظهرك مع ثني ركبتيك ورفعهما حتى تصبح فخذاك عموديتين على الأرض تقريبًا. شغّل عضلات بطنك لرفع وركيك عن الأرض نحو صدرك، ثم أنزلهما ببطء.'],
        ['gif' => '0865-9IxJdtC.gif', 'name_en' => 'Lying Leg Raise',
            'description_en' => 'Lie flat on your back with your legs extended and hands tucked under your glutes for support. Keeping your legs straight, raise them up toward the ceiling, then lower back down under control without letting them touch the floor.',
            'description_ar' => 'استلقِ على ظهرك ورجلاك ممدودتان ويداك تحت مؤخرتك للدعم. مع تثبيت رجليك مستقيمتين، ارفعهما نحو السقف، ثم أنزلهما ببطء دون لمس الأرض.'],
        ['gif' => '0687-XVDdcoj.gif', 'name_en' => 'Russian Twist',
            'description_en' => 'Sit on the floor with your knees bent, leaning back slightly with your feet lifted off the ground for balance. Twist your torso side to side, tapping the floor beside your hip on each side.',
            'description_ar' => 'اجلس على الأرض مع ثني ركبتيك، وانحنِ للخلف قليلاً مع رفع قدميك عن الأرض للتوازن. لف جذعك يمينًا ويسارًا وحاول لمس الأرض بجانب وركك في كل مرة.'],
        ['gif' => '0972-tZkGYZ9.gif', 'name_en' => 'Bicycle Crunch',
            'description_en' => 'Lie on your back with your hands behind your head and knees bent. Bring one knee toward your chest while twisting to touch it with your opposite elbow, then switch sides in a pedaling motion.',
            'description_ar' => 'استلقِ على ظهرك ويداك خلف رأسك وركبتاك مثنيتان. اجلب ركبة واحدة نحو صدرك مع لف جذعك للمسها بمرفقك المعاكس، ثم بدّل الجهة بحركة تشبه الدواسة.'],
        ['gif' => '2133-qPEzJjA.gif', 'name_en' => "Farmer's Walk",
            'description_en' => 'Stand holding a heavy dumbbell in each hand at your sides, shoulders back and core braced. Walk forward with controlled, steady steps for the desired distance or time, keeping your posture upright throughout.',
            'description_ar' => 'قف ممسكًا بدمبل ثقيل في كل يد بجانبيك وكتفاك للخلف وعضلات بطنك مشدودة. امشِ للأمام بخطوات ثابتة ومتحكم بها للمسافة أو الوقت المطلوب، مع الحفاظ على استقامة جسمك طوال الحركة.'],

        // NOT included (already covered by exercises:import-exercisedb-v1-sample,
        // same or different GIF of the same exercise — re-adding would be a
        // no-op or an unnecessary overwrite): Incline Barbell Bench Press,
        // Incline Machine Press, High-to-Low Cable Fly, Hanging Leg Raise,
        // Cable Curl, Standing Calf Raise, Hyperextensions, Leg Press,
        // Cable Squat Curl, One Arm Hammer Preacher Curl, Kettlebell Pistol
        // Squat, Impossible Dips, Barbell Seated Overhead Triceps Extension,
        // Weighted Side Bend (Stability Ball), Dumbbell Upright Row,
        // Dumbbell Reverse Spider Curl, Lying Bent-Knee Twist, Lever Seated
        // Row.
        //
        // NOT included (matched but not confident enough — see class
        // docblock): Bulgarian Split Squat.
    ];

    public function handle(): int
    {
        $dir = $this->option('dir');

        if (!$dir) {
            $this->error('--dir is required (the folder containing the dataset\'s .gif files).');

            return self::FAILURE;
        }

        if (!is_dir($dir)) {
            $this->error("--dir does not exist or is not a folder: {$dir}");

            return self::FAILURE;
        }

        $dryRun = (bool) $this->option('dry-run');
        $force = (bool) $this->option('force');

        $updated = 0;
        $skipped = 0;
        $notFound = 0;

        foreach (self::EXERCISES as $entry) {
            $sourcePath = rtrim($dir, '/') . '/' . $entry['gif'];

            if (!is_file($sourcePath)) {
                $this->warn("Missing file, skipping: {$entry['gif']} ({$entry['name_en']})");
                $skipped++;

                continue;
            }

            $exercise = Exercise::where('name_en', $entry['name_en'])->first();

            if (!$exercise) {
                $this->warn("No exercise named \"{$entry['name_en']}\" found in the database — skipping.");
                $notFound++;

                continue;
            }

            $needsGif = $force || !$this->hasWorkingGif($exercise);
            $needsDescriptionEn = $force || empty($exercise->description_en);
            $needsDescriptionAr = $force || empty($exercise->description_ar);

            if (!$needsGif && !$needsDescriptionEn && !$needsDescriptionAr) {
                $this->line("[SKIP]   {$entry['name_en']} already has a working GIF and descriptions.");
                $skipped++;

                continue;
            }

            $this->line("[UPDATE] {$entry['name_en']} <- {$entry['gif']}");

            if ($dryRun) {
                $updated++;

                continue;
            }

            if ($needsGif) {
                $exercise->gif_url = $this->storeGif($entry['gif'], $sourcePath);
            }

            if ($needsDescriptionEn) {
                $exercise->description_en = $entry['description_en'];
            }

            if ($needsDescriptionAr) {
                $exercise->description_ar = $entry['description_ar'];
            }

            $exercise->save();
            $updated++;
        }

        $this->newLine();
        $this->info(
            ($dryRun ? '[dry run] ' : '') .
            "Updated: {$updated}, skipped (already covered): {$skipped}, not found in DB: {$notFound}"
        );

        if (!$dryRun && $updated > 0) {
            $this->newLine();
            $this->comment('Reminder: these GIFs are © Gym visual (gymvisual.com), redistributed by this dataset without a confirmed commercial license — see the conversation where this was flagged.');
        }

        $this->reportExercisesWithoutGif();

        return self::SUCCESS;
    }

    private function storeGif(string $filename, string $sourcePath): string
    {
        $storedPath = 'exercises/hasaneyldrm-' . pathinfo($filename, PATHINFO_FILENAME) . '.gif';

        if (!Storage::disk('public')->exists($storedPath)) {
            Storage::disk('public')->put($storedPath, file_get_contents($sourcePath));
        }

        return $storedPath;
    }

    /**
     * `gif_url` being a non-empty string is NOT enough to call an exercise
     * "covered" — ExerciseSeeder sets every exercise's gif_url to a
     * predictable placeholder path (exercises/{slug}.gif) at seed time,
     * whether or not that file actually exists in storage yet. See the same
     * check in ImportExercisedbV1Sample for the full explanation.
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
     * `media` image) — deliberately about GIF coverage specifically, not
     * overall media coverage. Same pattern as ImportExercisedbV1Sample.
     */
    private function reportExercisesWithoutGif(): void
    {
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
