<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * Covers the app's real auth entry points: username/password signup and
 * login (see AuthController::signUp/loginWithName), plus the token-gated
 * /user/me endpoint every authenticated screen depends on. Google/Apple
 * login aren't covered here — they need a live third-party token to
 * verify and aren't practical to exercise in an automated test without
 * mocking that verification step.
 */
class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_with_username_and_password(): void
    {
        $response = $this->postJson('/api/api_v1/auth/signUp', [
            'name' => 'Test User',
            'username' => 'test_user',
            'phone' => '01000000000',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('status', true)
            ->assertJsonPath('user.username', 'test_user')
            ->assertJsonStructure(['token']);

        $this->assertDatabaseHas('users', ['username' => 'test_user']);
    }

    public function test_registration_fails_with_duplicate_username(): void
    {
        User::factory()->create(['username' => 'taken']);

        $response = $this->postJson('/api/api_v1/auth/signUp', [
            'name' => 'Another User',
            'username' => 'taken',
            'phone' => '01000000001',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(422);
    }

    public function test_registration_fails_when_passwords_do_not_match(): void
    {
        $response = $this->postJson('/api/api_v1/auth/signUp', [
            'name' => 'Test User',
            'username' => 'mismatch_user',
            'phone' => '01000000002',
            'password' => 'password123',
            'password_confirmation' => 'somethingElse',
        ]);

        $response->assertStatus(422);
    }

    public function test_user_can_login_with_correct_credentials(): void
    {
        User::factory()->create([
            'username' => 'login_user',
            'password' => Hash::make('correct-password'),
        ]);

        $response = $this->postJson('/api/api_v1/auth/login', [
            'username' => 'login_user',
            'password' => 'correct-password',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonStructure(['token', 'user']);
    }

    public function test_login_fails_with_wrong_password(): void
    {
        User::factory()->create([
            'username' => 'login_user2',
            'password' => Hash::make('correct-password'),
        ]);

        $response = $this->postJson('/api/api_v1/auth/login', [
            'username' => 'login_user2',
            'password' => 'wrong-password',
        ]);

        $response->assertStatus(401)
            ->assertJsonPath('status', false);
    }

    public function test_login_fails_for_unknown_username(): void
    {
        $response = $this->postJson('/api/api_v1/auth/login', [
            'username' => 'does_not_exist',
            'password' => 'whatever',
        ]);

        $response->assertStatus(401);
    }

    public function test_authenticated_user_can_fetch_their_own_profile(): void
    {
        $user = User::factory()->create(['username' => 'me_user']);
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->getJson('/api/api_v1/user/me');

        $response->assertStatus(200)
            ->assertJsonPath('user.username', 'me_user');
    }

    public function test_request_without_a_token_is_rejected(): void
    {
        $response = $this->getJson('/api/api_v1/user/me');

        $response->assertStatus(401);
    }

    public function test_request_with_an_invalid_token_is_rejected(): void
    {
        $response = $this->withHeader('Authorization', 'Bearer not-a-real-token')
            ->getJson('/api/api_v1/user/me');

        $response->assertStatus(401);
    }
}
