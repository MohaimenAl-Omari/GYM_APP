<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;
use Illuminate\Http\Request;
use Laravel\Socialite\Facades\Socialite;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Google\Client;
use Illuminate\Support\Str;

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
            'name'     => $request->name,
            'phone_number'    => $request->phone,
            'password' => $request->password,
        ]);
        $token = $user->createToken('mobile')->plainTextToken;
        return response()->json([
            'status'  => true,
            'message' => 'Account created successfully',
            'user'    => $user,
            'token'   => $token,
        ], 201);
    }

    public function loginWithPhone(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone'    => 'required|string',
            'password' => 'required',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'status'  => false,
                'message' => $validator->errors()->first(),
                'errors'  => $validator->errors(),
            ], 400);
        }
        $user = User::where('phone_number', $request->phone)->first();
        if ($user === null || $user->password === null || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'status'  => false,
                'message' => 'Invalid credentials',
            ], 401);
        }
        $user->tokens()->delete();
        $token = $user->createToken('mobile')->plainTextToken;
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
        $client = new Client([
            'client_id' => env('GOOGLE_CLIENT_ID')
        ]);
        $payload = $client->verifyIdToken($request->id_token);
        if (!$payload) {
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
}
