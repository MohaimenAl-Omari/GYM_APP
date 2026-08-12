<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Validator;
use Illuminate\Http\Request;
use Laravel\Socialite\Facades\Socialite;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Google\Client;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;
use Firebase\JWT\JWT;
use Firebase\JWT\JWK;

class AuthController extends Controller
{
    public function googleLogin(Request $request)
    {
        $googleUser = Socialite::driver('google')->stateless()->userFromToken($request->token);
        $user = User::updateOrCreate(
            [
                'email' => $googleUser->email
            ],
            [
                'name' => $googleUser->name,
                'google_id' => $googleUser->id,
                'avatar' => $googleUser->avatar
            ]
        );
        $token = $user->createToken('mobile-app')->plainTextToken;
        return response()->json([
            'user' => $user,
            'token' => $token
        ]);
    }

    public function appleLogin(Request $request)
    {
        $googleUser = Socialite::driver('google')->stateless()->userFromToken($request->token);
        $user = User::updateOrCreate(
            [
                'email' => $googleUser->email
            ],
            [
                'name' => $googleUser->name,
                'google_id' => $googleUser->id,
                'avatar' => $googleUser->avatar
            ]
        );
        $token = $user->createToken('mobile-app')->plainTextToken;
        return response()->json([
            'user' => $user,
            'token' => $token
        ]);
    }

    public function signUp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name'     => 'required|string|max:255',
            'username' => 'required|string|max:30|alpha_dash|unique:users,username',
            'phone'    => 'required|string|max:20|unique:users,phone_number',
            'password' => 'required|string|min:8|confirmed',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
                'errors'  => $validator->errors(),
            ], 422);
        }
        $user = User::create([
            'name'         => $request->name,
            'username'     => $request->username,
            'phone_number' => $request->phone,
            'password'     => $request->password,
        ]);
        $token = $user->createToken('mobile')->plainTextToken;
        return response()->json([
            'status'  => true,
            'message' => 'Account created successfully',
            'user'    => $user,
            'token'   => $token,
        ], 201);
    }

    public function loginWithName(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'username'    => 'required|string',
            'password' => 'required',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
                'errors'  => $validator->errors(),
            ], 400);
        }
        $user = User::where('username', $request->username)->first();
        if ($user === null || $user->password === null || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'status'  => false,
                'message' => 'Invalid credentials',
            ], 401);
        }
        $user->tokens()->delete();
        $token = $user->createToken('name_login')->plainTextToken;
        return response()->json([
            'status'  => true,
            'message' => 'Login successful',
            'token'   => $token,
            'user'    => $user,
        ]);
    }

    public function google(Request $request)
    {
        $request->validate([
            'id_token' => 'required'
        ]);
        $client = new Client();

        try {
            $payload = $client->verifyIdToken($request->id_token);
        } catch (\Throwable $e) {
            Log::error('Google id_token verification threw', ['error' => $e->getMessage()]);
            $payload = false;
        }

        $allowedAudiences = array_filter([
            env('GOOGLE_CLIENT_ID'),
            env('GOOGLE_IOS_CLIENT_ID'),
        ]);

        if (!$payload || !in_array($payload['aud'] ?? null, $allowedAudiences, true)) {
            Log::warning('Google id_token rejected', [
                'allowed_audiences' => $allowedAudiences,
                'token_aud' => $payload['aud'] ?? null,
            ]);
            return response()->json([
                'message' => 'Invaild Token'
            ], 400);
        }
        $user = User::firstOrCreate(
            [
                'email' => $payload['email']
            ],
            [
                'name' => $payload['name'],
                'google_id' => $payload['sub'],
                'password' => bcrypt(Str::random(20))
            ]
        );
        $token = $user->createToken('mobile')->plainTextToken;
        return response()->json([
            'user' => $user,
            'token' => $token
        ]);
    }

    public function apple(Request $request)
    {
        $request->validate([
            'identity_token' => 'required',
        ]);
        try {
            $keys = Http::get('https://appleid.apple.com/auth/keys')->json();
            $claims = (array) JWT::decode($request->identity_token, JWK::parseKeySet($keys));
        } catch (\Throwable $e) {
            Log::error('Apple identity_token verification threw', ['error' => $e->getMessage()]);
            return response()->json([
                'message' => 'Invaild Token',
            ], 400);
        }
        $expectedAudience = env('APPLE_BUNDLE_ID');
        if (($claims['iss'] ?? null) !== 'https://appleid.apple.com'
            || ($claims['aud'] ?? null) !== $expectedAudience
        ) {
            Log::warning('Apple identity_token rejected', [
                'expected_audience' => $expectedAudience,
                'token_aud' => $claims['aud'] ?? null,
                'token_iss' => $claims['iss'] ?? null,
            ]);
            return response()->json([
                'message' => 'Invaild Token',
            ], 400);
        }
        $user = User::where('apple_id', $claims['sub'])->first();
        if (!$user && isset($claims['email'])) {
            $user = User::where('email', $claims['email'])->first();
        }
        if (!$user) {
            $user = User::create([
                'name' => $request->name ?? 'Apple User',
                'email' => $claims['email'] ?? null,
                'apple_id' => $claims['sub'],
                'password' => Hash::make(Str::random(32)),
            ]);
        } elseif (!$user->apple_id) {
            $user->apple_id = $claims['sub'];
            $user->save();
        }
        $token = $user->createToken('mobile')->plainTextToken;
        return response()->json([
            'user' => $user,
            'token' => $token,
        ]);
    }
}
