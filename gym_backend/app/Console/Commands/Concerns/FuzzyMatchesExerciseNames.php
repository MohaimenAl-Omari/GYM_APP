<?php

namespace App\Console\Commands\Concerns;

/**
 * Shared fuzzy name-matching used by every "backfill exercise media from an
 * external source" command (wger, RepDB, ...). Each source has its own
 * naming convention that won't exact-match our seeded exercise names
 * ("Flat Barbell Bench Press" vs "Barbell Bench Press"), so every one of
 * these commands needs to rank a list of {id, name} candidates against one
 * of our exercise names and accept only a confident match.
 *
 * Score = word-overlap (Jaccard-like, dominant signal — handles extra
 * qualifiers one side has and the other doesn't) blended with a
 * character-similarity percentage (tiebreaker for near-identical wording).
 * Validated against 13 realistic our-name/their-name pairs in
 * /tmp/test_fuzzy_match.php before this was first shipped (see
 * FetchExerciseImagesFromWger) — not fancy, but transparent and tunable via
 * --min-score without another dependency.
 *
 * Two safeguards earned their way in after testing against RepDB's real
 * 601-exercise list (not just synthetic pairs):
 *
 *  - Light stemming in words(): without it, "Walking Lunges" scored HIGHER
 *    against the unrelated "Walking" than against the correct "Walking
 *    Lunge", purely because the plural "Lunges" didn't word-match the
 *    singular "Lunge" while the shorter, wrong candidate's char-similarity
 *    (as a full substring) won on a technicality.
 *
 *  - The ambiguity guard in bestNameMatch(): some of our exercise names are
 *    intentionally generic ("Deadlift", "Hammer Curl", "Barbell Row") while
 *    a source only lists equipment/stance-qualified variants ("Sumo
 *    Deadlift", "Cable Hammer Curl", "Barbell Upright Row" — a genuinely
 *    different exercise, not just a spelling variant). When the top two
 *    candidates score too close to call, no amount of tuning --min-score
 *    picks the "right" one reliably — so this reports it as unmatched
 *    instead of silently guessing. Still not perfect (word-overlap can
 *    under-value a modifier that changes the exercise entirely, like
 *    "Upright" vs "Bent-Over"), which is exactly why every command using
 *    this trait defaults to requiring a look at --dry-run output before
 *    saving anything.
 */
trait FuzzyMatchesExerciseNames
{
    /**
     * Matches within this margin of the top score are treated as a tie —
     * i.e. genuinely ambiguous, not "close enough". See the class docblock.
     */
    private const AMBIGUITY_MARGIN = 0.06;

    /**
     * Above this score a top match is trusted even if a second candidate is
     * within the ambiguity margin (near-exact/exact matches, where a
     * close-but-lower second place is normal noise, not real ambiguity).
     */
    private const AMBIGUITY_EXEMPT_ABOVE = 0.9;

    /**
     * @param array<int, array{id: mixed, name: string}> $candidates
     * @return array{id: mixed, name: string}|null
     */
    protected function bestNameMatch(string $needle, array $candidates, float $minScore): ?array
    {
        $needleWords = $this->words($needle);
        $needleNormalized = $this->normalize($needle);

        $best = null;
        $bestScore = 0.0;
        $secondBest = null;
        $secondBestScore = 0.0;

        foreach ($candidates as $candidate) {
            $score = $this->nameScore($needleWords, $needleNormalized, $candidate['name']);

            if ($score > $bestScore) {
                $secondBest = $best;
                $secondBestScore = $bestScore;
                $bestScore = $score;
                $best = $candidate;
            } elseif ($score > $secondBestScore) {
                $secondBestScore = $score;
                $secondBest = $candidate;
            }
        }

        if ($best === null || $bestScore < $minScore) {
            return null;
        }

        $ambiguous = $secondBest !== null
            && $secondBest['name'] !== $best['name']
            && ($bestScore - $secondBestScore) < self::AMBIGUITY_MARGIN
            && $bestScore < self::AMBIGUITY_EXEMPT_ABOVE;

        if ($ambiguous) {
            return null;
        }

        return $best;
    }

    /** @param string[] $needleWords */
    private function nameScore(array $needleWords, string $needleNormalized, string $candidateName): float
    {
        $candidateWords = $this->words($candidateName);

        $overlap = count(array_intersect($needleWords, $candidateWords));
        $union = count(array_unique(array_merge($needleWords, $candidateWords)));
        $wordScore = $union > 0 ? $overlap / $union : 0.0;

        similar_text($needleNormalized, $this->normalize($candidateName), $charPercent);

        return ($wordScore * 0.7) + (($charPercent / 100) * 0.3);
    }

    /**
     * Light stemming on top of the raw split: a trailing "s" is dropped
     * from any word longer than 2 characters (so "lunges"→"lunge",
     * "ups"→"up", "abs"→"ab" — 2-letter words like "up" are left alone so
     * there's always at least one character left), except words ending
     * "ss" ("press") which are left alone. Without this, a plural/singular
     * mismatch on an otherwise-identical word gets zero overlap credit —
     * see the class docblock for the concrete case that motivated it.
     *
     * @return string[]
     */
    protected function words(string $value): array
    {
        $words = array_values(array_filter(explode(' ', $this->normalize($value))));

        return array_map(
            fn ($word) => (strlen($word) > 2 && str_ends_with($word, 's') && !str_ends_with($word, 'ss'))
                ? substr($word, 0, -1)
                : $word,
            $words
        );
    }

    protected function normalize(string $value): string
    {
        $value = strtolower($value);
        $value = preg_replace('/[^a-z0-9\s]/', ' ', $value) ?? $value;
        $value = preg_replace('/\s+/', ' ', $value) ?? $value;

        return trim($value);
    }
}
