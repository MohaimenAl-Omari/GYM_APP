<?php

namespace App\Console\Commands;

use App\Console\Commands\Concerns\FuzzyMatchesExerciseNames;
use App\Models\Exercise;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

/**
 * Backfills real `media` (static image) values onto seeded exercises using
 * wger's public exercise database (https://wger.de) — free, unauthenticated,
 * no daily quota. Images are licensed CC BY-SA (per-exercise, mostly 3.0/4.0
 * per the `license` field): commercial use is explicitly allowed, but it
 * requires attribution — add a credit somewhere in the app, e.g. "Exercise
 * images © wger.de contributors, CC BY-SA". See
 * https://wger.de/en/software/license.
 *
 * Unlike `exercises:fetch-gifs` (RapidAPI/ExerciseDB), wger's exercise
 * photos are static images, not looping GIFs — this sets `media`, not
 * `gif_url`. An exercise that ends up with both still shows the GIF first
 * (see Exercise::demoUrl / the Flutter Exercise.demoUrl getter) — running
 * this after exercises:fetch-gifs only fills in the exercises that command
 * couldn't match, it never overwrites a real GIF that's already there.
 *
 * How matching works: wger has no reliable name-search filter (confirmed
 * live — `/exercise/?name=` is silently ignored, and `/exercise/search/`,
 * `/exercisetranslation/` don't exist on this API version), and our
 * exercise names ("Flat Barbell Bench Press") won't exact-match wger's
 * phrasing anyway. So this pulls wger's full English name list once
 * (~5 paginated requests for ~862 exercises via `/exercise-translation/`,
 * cached in memory for the whole run) and fuzzy-matches each of our
 * exercises against it locally — a word-overlap score combined with a
 * character-similarity score (see bestMatchExerciseId/normalize below).
 * Only a match above --min-score is accepted; anything softer is reported
 * as unmatched rather than risking a wrong photo on the wrong exercise.
 * Once matched, the actual image comes from `/exerciseinfo/{id}/`, which
 * is the one endpoint confirmed (via a live --inspect run) to return
 * images nested alongside translations, license, etc.
 *
 * Setup: none. No API key, no .env entry — this is a public endpoint.
 *   php artisan exercises:fetch-from-wger --dry-run
 */
class FetchExerciseImagesFromWger extends Command
{
    use FuzzyMatchesExerciseNames;

    protected $signature = 'exercises:fetch-from-wger
        {--dry-run : Show matches without saving them}
        {--only= : Comma-separated exercise IDs to (re)process, instead of all}
        {--force : Re-process exercises that already have a real media image}
        {--delay=150 : Milliseconds to wait between per-exercise detail requests}
        {--min-score=0.45 : Minimum fuzzy-match confidence (0-1) to accept a match}
        {--inspect : Dump raw API responses for one exercise, then stop (diagnostic)}';

    protected $description = "Match seeded exercises against wger's free public exercise database and backfill media (static image)";

    private const BASE_URL = 'https://wger.de/api/v2';

    /** @var array<int, array{id: int, name: string}>|null */
    private ?array $translationsCache = null;

    public function handle(): int
    {
        if ($this->option('inspect')) {
            return $this->inspectFirst();
        }

        $query = Exercise::query()->orderBy('id');

        if ($only = $this->option('only')) {
            $query->whereIn('id', array_map('trim', explode(',', $only)));
        }

        if (!$this->option('force')) {
            $query->where(function ($q) {
                $q->whereNull('media')->orWhere('media', '');
            });
        }

        $exercises = $query->get();
        $dryRun = (bool) $this->option('dry-run');
        $delayMs = (int) $this->option('delay');
        $minScore = (float) $this->option('min-score');

        if ($exercises->isEmpty()) {
            $this->info('Nothing to do — every exercise already has a media image. Use --force to re-check them.');

            return self::SUCCESS;
        }

        // Loaded once up front (not lazily inside the loop) so the "Loading
        // wger's name list..." line doesn't interleave with the progress
        // bar, and so a failure here is obvious immediately.
        $this->loadAllTranslations();

        $matched = 0;
        $unmatched = [];

        $this->info("Matching {$exercises->count()} exercises against " . count($this->translationsCache) . ' wger exercise names...');
        $bar = $this->output->createProgressBar($exercises->count());
        $bar->start();

        foreach ($exercises as $exercise) {
            $imageUrl = $this->findImageFor($exercise->name_en, $minScore);

            if ($imageUrl === null) {
                $unmatched[] = $exercise->name_en;
                $bar->advance();
                continue;
            }

            if (!$dryRun) {
                $exercise->update(['media' => $imageUrl]);
            }

            $matched++;
            $bar->advance();
            usleep($delayMs * 1000);
        }

        $bar->finish();
        $this->newLine(2);

        $this->info("Matched: {$matched}/{$exercises->count()}" . ($dryRun ? ' (dry run — nothing saved)' : ''));

        if (!empty($unmatched)) {
            $this->warn('No confident match found for:');
            foreach ($unmatched as $name) {
                $this->line("  - {$name}");
            }
            $this->line('Either wger genuinely has nothing for these, the name is too different to match confidently, or the matched wger exercise has no image uploaded. Try a lower --min-score (e.g. --min-score=0.3) to see softer matches, or fill these in manually via the admin panel.');
        }

        if ($matched > 0 && !$dryRun) {
            $this->newLine();
            $this->comment('Reminder: these images are CC BY-SA — add a credit somewhere in the app, e.g. "Exercise images © wger.de contributors, CC BY-SA".');
        }

        return self::SUCCESS;
    }

    private function findImageFor(string $exerciseName, float $minScore): ?string
    {
        $exerciseId = $this->bestMatchExerciseId($exerciseName, $minScore);

        if ($exerciseId === null) {
            return null;
        }

        $info = Http::get(self::BASE_URL . "/exerciseinfo/{$exerciseId}/", ['format' => 'json']);

        if ($info->failed()) {
            return null;
        }

        $images = $info->json('images') ?? [];

        if (empty($images)) {
            return null;
        }

        // Prefer the image explicitly marked "main" when wger provides
        // that flag; otherwise just take the first one returned.
        $main = collect($images)->first(fn ($img) => ($img['is_main'] ?? false) === true) ?? $images[0];

        return $main['image'] ?? null;
    }

    /**
     * Fetches every English exercise name wger has, once, and keeps it in
     * memory for the rest of the run. `/exercise-translation/` pages 200 at
     * a time; each page's `next` link already carries the full query
     * string, so subsequent requests just follow it as-is.
     */
    private function loadAllTranslations(): array
    {
        if ($this->translationsCache !== null) {
            return $this->translationsCache;
        }

        $this->line("Loading wger's full English exercise name list (one-time, a handful of requests)...");

        $translations = [];
        $url = self::BASE_URL . '/exercise-translation/';
        $params = ['language' => 2, 'limit' => 200, 'format' => 'json']; // 2 = English

        while ($url !== null) {
            $response = Http::get($url, $params);

            if ($response->failed()) {
                $this->error("Failed loading wger's name list: HTTP {$response->status()}");
                break;
            }

            foreach ($response->json('results') ?? [] as $translation) {
                if (!empty($translation['name']) && !empty($translation['exercise'])) {
                    $translations[] = [
                        'id' => (int) $translation['exercise'],
                        'name' => (string) $translation['name'],
                    ];
                }
            }

            $url = $response->json('next');
            $params = []; // the `next` URL already has every param baked in
        }

        $this->line('Loaded ' . count($translations) . ' wger exercise names.');

        return $this->translationsCache = $translations;
    }

    /**
     * Thin wrapper around the shared trait's bestNameMatch() — kept so the
     * rest of this file (which only ever needs the id) doesn't have to know
     * about the {id, name} shape the trait works with.
     */
    private function bestMatchExerciseId(string $exerciseName, float $minScore): ?int
    {
        $match = $this->bestNameMatch($exerciseName, $this->translationsCache, $minScore);

        return $match['id'] ?? null;
    }

    /**
     * Fires several plausible request shapes against wger for one exercise
     * and prints each raw response — kept around in case wger's API shape
     * ever changes again and this needs re-diagnosing the same way it was
     * built the first time.
     */
    private function inspectFirst(): int
    {
        $exercise = Exercise::query()->orderBy('id')->first();

        if (!$exercise) {
            $this->error('No exercises in the database to test with.');

            return self::FAILURE;
        }

        $this->info("Inspecting wger responses for: \"{$exercise->name_en}\"");
        $this->newLine();

        $attempts = [
            'GET /exercise-translation/?language=2&limit=3' => fn () => Http::get(
                self::BASE_URL . '/exercise-translation/',
                ['language' => 2, 'limit' => 3, 'format' => 'json']
            ),
            'GET /exerciseinfo/9/' => fn () => Http::get(
                self::BASE_URL . '/exerciseinfo/9/',
                ['format' => 'json']
            ),
        ];

        foreach ($attempts as $label => $makeRequest) {
            $this->line("--- {$label} ---");
            $response = $makeRequest();
            $this->line("HTTP {$response->status()}");
            $this->line(substr($response->body(), 0, 2500));
            $this->newLine();
        }

        return self::SUCCESS;
    }
}
