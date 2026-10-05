<?php

namespace Tests\Feature;

use App\Models\Exercise;
use App\Models\MuscleGroup;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * End-to-end coverage of the app's core loop: start a session, add an
 * exercise, log sets, finish. This is the single most important user
 * journey in the app (see project memory: "Full workout-logging loop ...
 * is fully real end-to-end") and previously had zero automated coverage.
 *
 * The finish() assertions in particular guard against a real regression
 * fixed this session: WorkoutSessionController::finish() briefly computed
 * a negative, fractional duration_seconds that MySQL rejected outright
 * (SQLSTATE[22003] "Out of range value") — this test fails loudly if that
 * calculation breaks again.
 */
class WorkoutFlowTest extends TestCase
{
    use RefreshDatabase;

    private function authHeader(User $user): array
    {
        // Each simulated account switch needs a fresh request guard.
        $this->app['auth']->forgetGuards();
        $token = $user->createToken('test')->plainTextToken;
        return ['Authorization' => "Bearer $token"];
    }

    private function makeExercise(MuscleGroup $group): Exercise
    {
        return Exercise::create([
            'muscle_group_id' => $group->id,
            'name_en' => 'Bench Press',
            'name_ar' => 'ضغط بنش',
        ]);
    }

    public function test_retry_returns_original_set_without_duplicating_or_overwriting_it(): void
    {
        $user = User::factory()->create();
        $group = MuscleGroup::create(['name_en' => 'Chest', 'name_ar' => 'صدر']);
        $exercise = $this->makeExercise($group);
        $headers = $this->authHeader($user);
        $session = $this->withHeaders($headers)->postJson('/api/api_v1/workout-sessions', [
            'muscle_group_ids' => [$group->id],
            'exercise_ids' => [$exercise->id],
        ])->assertCreated();
        $url = '/api/api_v1/workout-sessions/'.$session->json('id').'/sets';
        $payload = [
            'session_exercise_id' => $session->json('session_exercises.0.id'),
            'client_request_id' => str_repeat('a', 32),
            'set_number' => 1, 'reps' => 10, 'weight' => 60, 'weight_unit' => 'kg',
        ];
        $first = $this->withHeaders($headers)->postJson($url, $payload)->assertCreated();
        $this->withHeaders($headers)->postJson($url, [...$payload, 'reps' => 99])
            ->assertCreated()->assertJsonPath('id', $first->json('id'))
            ->assertJsonPath('reps', 10);
        $this->assertDatabaseCount('sets', 1);

        // A retry ID never bypasses session ownership.
        $this->withHeaders($this->authHeader(User::factory()->create()))
            ->postJson($url, $payload)->assertForbidden();
        $this->assertDatabaseCount('sets', 1);

        $this->withHeaders($this->authHeader($user))->postJson($url, [
            ...$payload, 'client_request_id' => str_repeat('b', 32), 'set_number' => 2,
        ])->assertCreated();
        $this->assertDatabaseCount('sets', 2);
    }

    public function test_full_workout_logging_flow(): void
    {
        $user = User::factory()->create();
        $group = MuscleGroup::create(['name_en' => 'Chest', 'name_ar' => 'صدر']);
        $exercise = $this->makeExercise($group);
        $secondExercise = $this->makeExercise($group);
        $headers = $this->authHeader($user);

        // 1. Start a session.
        $startResponse = $this->withHeaders($headers)->postJson('/api/api_v1/workout-sessions', [
            'muscle_group_ids' => [$group->id],
            'exercise_ids' => [$exercise->id],
        ]);
        $startResponse->assertStatus(201);
        $sessionId = $startResponse->json('id');
        $this->assertNotNull($sessionId);
        $sessionExerciseId = $startResponse->json('session_exercises.0.id');
        $this->assertNotNull($sessionExerciseId);

        // 2. Add a second exercise mid-session.
        $addExerciseResponse = $this->withHeaders($headers)
            ->postJson("/api/api_v1/workout-sessions/{$sessionId}/exercises", [
                'exercise_id' => $secondExercise->id,
            ]);
        $addExerciseResponse->assertStatus(201);

        // 3. Log a set against the first exercise.
        $setResponse = $this->withHeaders($headers)
            ->postJson("/api/api_v1/workout-sessions/{$sessionId}/sets", [
                'session_exercise_id' => $sessionExerciseId,
                'set_number' => 1,
                'reps' => 10,
                'weight' => 60.5,
                'weight_unit' => 'kg',
                'rest_time' => 90,
            ]);
        $setResponse->assertStatus(201)
            ->assertJsonPath('reps', 10)
            ->assertJsonPath('weight', 60.5);

        // 4. Finish the session — this is the exact call that used to 500
        // (see class docblock). duration_seconds must come back as a
        // non-negative integer, not the negative float that broke it.
        $finishResponse = $this->withHeaders($headers)
            ->putJson("/api/api_v1/workout-sessions/{$sessionId}/finish");
        $finishResponse->assertStatus(200)
            ->assertJsonPath('total_sets', 1)
            ->assertJsonPath('total_volume', fn ($value) => is_numeric($value) && (float) $value === 605.0);
        $durationSeconds = $finishResponse->json('duration_seconds');
        $this->assertIsInt($durationSeconds);
        $this->assertGreaterThanOrEqual(0, $durationSeconds);

        $this->assertDatabaseHas('workout_sessions', [
            'id' => $sessionId,
            'duration_seconds' => $durationSeconds,
        ]);

        // 5. The finished session shows up correctly in history.
        $historyResponse = $this->withHeaders($headers)->getJson('/api/api_v1/workout-sessions');
        $historyResponse->assertStatus(200)
            ->assertJsonFragment(['id' => $sessionId, 'total_sets' => 1]);
    }

    public function test_a_user_cannot_access_another_users_session(): void
    {
        $owner = User::factory()->create();
        $intruder = User::factory()->create();
        $group = MuscleGroup::create(['name_en' => 'Back', 'name_ar' => 'ظهر']);
        $exercise = $this->makeExercise($group);

        $startResponse = $this->withHeaders($this->authHeader($owner))
            ->postJson('/api/api_v1/workout-sessions', [
                'muscle_group_ids' => [$group->id],
                'exercise_ids' => [$exercise->id],
            ]);
        $sessionId = $startResponse->json('id');

        $intruderResponse = $this->withHeaders($this->authHeader($intruder))
            ->getJson("/api/api_v1/workout-sessions/{$sessionId}");

        $intruderResponse->assertStatus(403);
    }

    public function test_starting_a_session_requires_at_least_one_exercise(): void
    {
        $user = User::factory()->create();
        $group = MuscleGroup::create(['name_en' => 'Legs', 'name_ar' => 'أرجل']);

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson('/api/api_v1/workout-sessions', [
                'muscle_group_ids' => [$group->id],
                'exercise_ids' => [],
            ]);

        $response->assertStatus(422);
    }
}
