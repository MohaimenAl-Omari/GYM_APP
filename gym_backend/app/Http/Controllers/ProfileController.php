<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Validator;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function update(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'age'     => 'required|integer|min:14|max:100',
            'weight'    => 'required|numeric|min:1',
            'height' => 'required|numeric|min:1',
            'weight_unit' => 'required|in:kg,lbs',
            'goal' => 'required|string|in:lose_weight,build_muscle,improve_fitness,maintain_weight',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'errors' => $validator->errors(),
            ], 422);
        }
        $user = $request->user();
        $user->update([
            'age' => $request->age,
            'weight' => $request->weight,
            'height' => $request->height,
            'weight_unit' => $request->weight_unit,
            'goal' => $request->goal,
        ]);

        return response()->json([
            'status' => true,
            'message' => 'Profile updated successfuly',
            'user' => $user
        ]);
    }
}
