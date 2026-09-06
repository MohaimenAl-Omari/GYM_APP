<?php

namespace App\Console\Commands;

use App\Console\Commands\Concerns\FuzzyMatchesExerciseNames;
use App\Models\Exercise;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;

/**
 * Backfills real `media` (static image) values onto seeded exercises using
 * RepDB's free-tier dataset (https://github.com/RepDB/exercise-dataset) —
 * free, unauthenticated, no daily quota, no API key. Recommended as the
 * primary static-image source: unlike wger (CC BY-SA, third-party
 * contributed photos of real people) RepDB's images are original AI-
 * generated illustrations RepDB commissioned itself, so there's no
 * per-image upstream-rights ambiguity — just RepDB's own free-tier license
 * (see LICENSE-DATA.md in that repo). Free for personal/commercial in-app
 * use, one requirement: attribution. See the reminder this command prints,
 * and app_translations.dart's `exercise_media_credit` key.
 *
 * Unlike exercises:fetch-gifs (RapidAPI/ExerciseDB), RepDB's images are
 * static (a "peak of the movement" pose, occasionally paired with a
 * "start" pose), not looping GIFs — this sets `media`, not `gif_url`. An
 * exercise that already has a GIF is left alone; a GIF set later still
 * wins over this (see Exercise::demoUrl).
 *
 * How matching works: same fuzzy word/character scorer as
 * exercises:fetch-from-wger (see Concerns\FuzzyMatchesExerciseNames) —
 * RepDB's names ("Barbell Bench Press") are close to standard gym
 * terminology, generally closer to ours than wger's, so match rates here
 * tend to be higher.
 *
 * Multiple local exercises can fuzzy-match the *same* RepDB entry (e.g.
 * "Flat Barbell Bench Press" and "Barbell Bench Press" both landing on
 * RepDB's one "Barbell Bench Press" illustration) — per requirement #8
 * (don't duplicate media for identical movements), the image for a given
 * RepDB exercise is only ever downloaded once per run and every local
 * exercise that matches it is pointed at that same stored file.
 *
 * Setup: none. No API key, no .env entry — this downloads the dataset's
 * exercises.json fresh from a public GitHub raw URL on every run (~2MB),
 * then only fetches individual images (~15-25KB each) for confident
 * matches.
 *   php artisan exercises:fetch-from-repdb --dry-run
 */
class ImportExerciseImagesFromRepDB extends Command
{
    use FuzzyMatchesExerciseNames;

    protected $signature = 'exercises:fetch-from-repdb
        {--dry-run : Show matches without downloading or saving anything}
        {--only= : Comma-separated exercise IDs to (re)process, instead of all}
        {--force : Re-process exercises that already have a real media image}
        {--delay=150 : Milliseconds to wait between image downloads}
        {--min-score=0.45 : Minimum fuzzy-match confidence (0-1) to accept a match}';

    protected $description = "Match seeded exercises against RepDB's free exercise dataset and backfill media (static image)";

    private const RAW_BASE = 'https://raw.githubusercontent.com/RepDB/exercise-dataset/main/';
    private const STORAGE_DIR = 'exercises';

    /** @var array<int, array{id: string, name: string, image_path: ?string}>|null */
    private ?array $datasetCache = null;

    /** Repdb exercise id => already-stored public path, filled in as we go this run. */
    private array $downloadedThisRun = [];

    public function handle(): int
    {
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

        if (!$this->loadDataset()) {
            return self::FAILURE;
        }

        $matched = 0;
        $reused = 0;
        $unmatched = [];

        $this->info("Matching {$exercises->count()} exercises against " . count($this->datasetCache) . ' RepDB exercises...');
        $bar = $this->output->createProgressBar($exercises->count());
        $bar->start();

        foreach ($exercises as $exercise) {
            $match = $this->bestNameMatch($exercise->name_en, $this->datasetCache, $minScore);

            if ($match === null || $match['image_path'] === null) {
                $unmatched[] = $exercise->name_en;
                $bar->advance();
                continue;
            }

            $wasCached = isset($this->downloadedThisRun[$match['id']]);
            $storedPath = $dryRun
                ? null
                : $this->storeImageFor($match['id'], $match['image_path']);

            if (!$dryRun && $storedPath === null) {
                // Download failed — treat like an unmatched exercise rather
                // than silently leaving `media` untouched with no feedback.
                $unmatched[] = "{$exercise->name_en} (matched \"{$match['name']}\" but the image download failed)";
                $bar->advance();
                continue;
            }

            if (!$dryRun) {
                $exercise->update(['media' => $storedPath]);
            }

            $matched++;
            $wasCached ? $reused++ : null;
            $bar->advance();

            if (!$wasCached) {
                usleep($delayMs * 1000);
            }
        }

        $bar->finish();
        $this->newLine(2);

        $this->info("Matched: {$matched}/{$exercises->count()}" . ($dryRun ? ' (dry run — nothing downloaded or saved)' : ''));

        if ($reused > 0) {
            $this->line("({$reused} of those reused an image already downloaded for another exercise this run — no duplicate file.)");
        }

        if (!empty($unmatched)) {
            $this->warn('No confident match found for:');
            foreach ($unmatched as $name) {
                $this->line("  - {$name}");
            }
            $this->line('Try a lower --min-score (e.g. --min-score=0.3) to see softer matches, run exercises:fetch-from-wger for a second opinion, or fill these in manually via the admin panel.');
        }

        if ($matched > 0 && !$dryRun) {
            $this->newLine();
            $this->comment('Reminder (RepDB free-tier license): keep the credit "Exercise data by RepDB (repdb.co)" visible somewhere in the app — already wired into the Settings screen via the exercise_media_credit translation key.');
        }

        return self::SUCCESS;
    }

    /**
     * Downloads exercises.json once per run and flattens it into the
     * {id, name, image_path} shape bestNameMatch() expects. `image_path`
     * prefers the "peak" pose (the clearest single frame of the movement),
     * falling back to "start", then whatever single image is present.
     */
    private function loadDataset(): bool
    {
        $this->line('Downloading RepDB exercise dataset (one-time, ~2MB)...');

        $response = Http::timeout(30)->get(self::RAW_BASE . 'exercises.json');

        if ($response->failed()) {
            $this->error("Failed downloading RepDB dataset: HTTP {$response->status()}");

            return false;
        }

        $exercises = $response->json('exercises') ?? [];
        $dataset = [];

        foreach ($exercises as $entry) {
            $id = $entry['id'] ?? null;
            $name = $entry['name_en'] ?? null;

            if (!$id || !$name) {
                continue;
            }

            $flat = $entry['images']['flat'] ?? [];
            $imagePath = $flat['peak'] ?? $flat['start'] ?? $flat['main'] ?? null;

            $dataset[] = [
                'id' => (string) $id,
                'name' => (string) $name,
                'image_path' => $imagePath,
            ];
        }

        $this->line('Loaded ' . count($dataset) . ' RepDB exercises.');

        $this->datasetCache = $dataset;

        return true;
    }

    /**
     * Downloads one RepDB image and stores it under storage/app/public,
     * returning the path to save on `media` — or null on failure. Within a
     * single run, a RepDB id already downloaded is reused instead of
     * fetched again (requirement: don't duplicate media for identical
     * movements). Across runs, an already-present file with the same name
     * is left as-is (idempotent re-runs, e.g. after --force).
     */
    private function storeImageFor(string $repdbId, string $imagePath): ?string
    {
        if (isset($this->downloadedThisRun[$repdbId])) {
            return $this->downloadedThisRun[$repdbId];
        }

        $extension = pathinfo($imagePath, PATHINFO_EXTENSION) ?: 'webp';
        $storedPath = self::STORAGE_DIR . "/repdb-{$repdbId}.{$extension}";

        if (Storage::disk('public')->exists($storedPath)) {
            return $this->downloadedThisRun[$repdbId] = $storedPath;
        }

        $response = Http::timeout(30)->get(self::RAW_BASE . $imagePath);

        if ($response->failed()) {
            return null;
        }

        Storage::disk('public')->put($storedPath, $response->body());

        return $this->downloadedThisRun[$repdbId] = $storedPath;
    }
}
