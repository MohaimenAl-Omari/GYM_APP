<?php

namespace App\Console\Commands;

use App\Models\Exercise;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

/**
 * Backfills real gif_url values onto seeded exercises using the
 * "EDB WITH IMAGES AND GIFS by AscendAPI" RapidAPI product
 * (https://rapidapi.com/ascendapi/api/edb-with-gifs-and-images-by-ascendapi).
 *
 * Why this runs as an Artisan command instead of inside the seeder: it needs
 * a live network call per exercise (fuzzy search, then fetch-by-id for the
 * gifUrls object), which isn't something you want re-running every time you
 * seed the database. Run it once after seeding, and re-run later only for
 * exercises that still show the placeholder icon.
 *
 * Setup:
 *   1. Subscribe (free Basic plan, no card) at the RapidAPI link above.
 *   2. Add EXERCISEDB_RAPIDAPI_KEY=... to .env
 *   3. php artisan exercises:fetch-gifs
 */
class FetchExerciseGifs extends Command
{
    protected $signature = 'exercises:fetch-gifs
        {--threshold=0.35 : Fuzzy search threshold (0 = exact, 1 = very loose)}
        {--dry-run : Show matches without saving them}
        {--only= : Comma-separated exercise IDs to (re)process, instead of all}
        {--force : Re-process exercises that already have a real gif_url}
        {--delay=800 : Milliseconds to wait between exercises}';

    protected $description = 'Match seeded exercises against the ExerciseDB API and backfill gif_url';

    private const BASE_URL = 'https://edb-with-gifs-and-images-by-ascendapi.p.rapidapi.com';

    // Rows whose gif_url already looks like this were successfully matched
    // by a previous run — skip them by default so re-running after hitting
    // the daily quota doesn't waste requests re-fetching the same ones.
    private const MATCHED_URL_PREFIX = 'https://assets.exercisedb.dev/';

    public function handle(): int
    {
        $apiKey = config('services.exercisedb.key');

        if (empty($apiKey)) {
            $this->error('EXERCISEDB_RAPIDAPI_KEY is not set in .env — add it and try again.');
            $this->line('Subscribe (free) at: https://rapidapi.com/ascendapi/api/edb-with-gifs-and-images-by-ascendapi');

            return self::FAILURE;
        }

        $query = Exercise::query()->orderBy('id');

        if ($only = $this->option('only')) {
            $query->whereIn('id', array_map('trim', explode(',', $only)));
        }

        if (!$this->option('force')) {
            $query->where(function ($q) {
                $q->whereNull('gif_url')
                    ->orWhere('gif_url', 'not like', self::MATCHED_URL_PREFIX . '%');
            });
        }

        $exercises = $query->get();
        $threshold = (float) $this->option('threshold');
        $dryRun = (bool) $this->option('dry-run');
        $delayMs = (int) $this->option('delay');

        if ($exercises->isEmpty()) {
            $this->info('Nothing to do — every exercise already has a matched gif_url. Use --force to re-check them.');

            return self::SUCCESS;
        }

        $matched = 0;
        $unmatched = [];
        $quotaExceeded = false;

        $this->info("Processing {$exercises->count()} exercises (threshold={$threshold})...");
        $bar = $this->output->createProgressBar($exercises->count());
        $bar->start();

        foreach ($exercises as $exercise) {
            $result = $this->fetchGifFor($exercise->name_en, $apiKey, $threshold);

            if ($result === 'quota_exceeded') {
                $quotaExceeded = true;
                break;
            }

            if ($result === null) {
                $unmatched[] = $exercise->name_en;
                $bar->advance();
                continue;
            }

            [$matchedName, $gifUrl] = $result;

            if (!$dryRun) {
                $exercise->update(['gif_url' => $gifUrl]);
            }

            $matched++;
            $bar->advance();

            usleep($delayMs * 1000);
        }

        $bar->finish();
        $this->newLine(2);

        if ($quotaExceeded) {
            $this->error('Daily request quota hit on the RapidAPI Basic plan — stopping here instead of burning through the rest of the list.');
            $this->line('Wait for the quota to reset (check the reset time on your RapidAPI dashboard, usually ~24h from first use), then just re-run:');
            $this->line('  php artisan exercises:fetch-gifs');
            $this->line('Already-matched exercises are skipped automatically, so it will only pick up where this run stopped.');
        }

        $this->info("Matched: {$matched}/{$exercises->count()}" . ($dryRun ? ' (dry run — nothing saved)' : ''));

        if (!empty($unmatched)) {
            $this->warn('No confident match found for:');
            foreach ($unmatched as $name) {
                $this->line("  - {$name}");
            }
            $this->line('Fill these in manually via the admin panel (Exercises → edit → upload media).');
        }

        return self::SUCCESS;
    }

    /**
     * @return array{0: string, 1: string}|'quota_exceeded'|null
     *   [matchedName, gifUrl] on success, 'quota_exceeded' to signal the
     *   caller to stop the whole run, or null if nothing usable was found.
     */
    private function fetchGifFor(string $exerciseName, string $apiKey, float $threshold)
    {
        $headers = [
            'X-RapidAPI-Key' => $apiKey,
            'X-RapidAPI-Host' => config('services.exercisedb.host'),
        ];

        $search = $this->requestWithBackoff(fn () => Http::withHeaders($headers)
            ->get(self::BASE_URL . '/api/v1/exercises/search', [
                'search' => $exerciseName,
                'threshold' => $threshold,
            ]));

        if ($search === 'quota_exceeded') {
            return 'quota_exceeded';
        }

        if ($search === null || $search->failed()) {
            if ($search !== null) {
                $this->newLine();
                $this->error("Search failed for \"{$exerciseName}\": HTTP {$search->status()} — {$search->body()}");
            }

            return null;
        }

        $candidates = $search->json('data') ?? [];

        if (empty($candidates)) {
            return null;
        }

        $exerciseId = $candidates[0]['exerciseId'] ?? null;
        $matchedName = $candidates[0]['name'] ?? null;

        if (!$exerciseId) {
            return null;
        }

        // Small gap between the two calls this exercise needs — firing them
        // back-to-back is what was tripping the per-second rate limit.
        usleep(300_000);

        $headers = [
            'X-RapidAPI-Key' => $apiKey,
            'X-RapidAPI-Host' => config('services.exercisedb.host'),
        ];

        $detail = $this->requestWithBackoff(fn () => Http::withHeaders($headers)
            ->get(self::BASE_URL . "/api/v1/exercises/{$exerciseId}"));

        if ($detail === 'quota_exceeded') {
            return 'quota_exceeded';
        }

        if ($detail === null || $detail->failed()) {
            return null;
        }

        $gifUrls = $detail->json('data.gifUrls') ?? [];
        // 480p is a good balance for a mobile list/detail view — small
        // enough to load fast, sharp enough on modern phone screens.
        $gifUrl = $gifUrls['480p'] ?? $gifUrls['360p'] ?? $gifUrls['720p'] ?? null;

        if (!$gifUrl) {
            return null;
        }

        return [$matchedName, $gifUrl];
    }

    /**
     * Retries transient 429s (per-second/minute throttling) with backoff.
     * A 429 whose body mentions the DAILY quota is not transient — no
     * amount of waiting within this run fixes it, so it's reported back as
     * 'quota_exceeded' so the caller stops immediately instead of grinding
     * through the rest of the list generating the same error 60+ times.
     *
     * @return \Illuminate\Http\Client\Response|'quota_exceeded'|null
     */
    private function requestWithBackoff(callable $makeRequest, int $maxAttempts = 4)
    {
        for ($attempt = 1; $attempt <= $maxAttempts; $attempt++) {
            $response = $makeRequest();

            if ($response->status() !== 429) {
                return $response;
            }

            $body = $response->body();

            if (str_contains($body, 'DAILY quota') || str_contains($body, 'exceeded the') && str_contains($body, 'quota')) {
                return 'quota_exceeded';
            }

            if ($attempt === $maxAttempts) {
                return $response;
            }

            // Short-term throttling — back off and try again.
            usleep(1_000_000 * $attempt);
        }

        return null;
    }
}
