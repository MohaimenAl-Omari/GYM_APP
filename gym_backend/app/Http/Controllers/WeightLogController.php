<?php

namespace App\Http\Controllers;

use App\Models\WeightLog;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

/**
 * Body-weight trend log for the Progress screen — separate from
 * users.weight, which stays the single "current" value shown on the
 * profile screen (see ProfileController::update).
 */
class WeightLogController extends Controller
{
    /**
     * GET /api_v1/weight-logs
     * Every reading the user has logged, oldest first (chart-friendly).
     */
    public function index(Request $request): JsonResponse
    {
        $logs = WeightLog::query()
            ->where('user_id', $request->user()->id)
            ->orderBy('logged_at')
            ->get(['id', 'weight', 'weight_unit', 'logged_at']);

        return response()->json($logs);
    }

    /**
     * POST /api_v1/weight-logs
     * Body: { weight: number, weight_unit: 'kg'|'lbs', logged_at?: 'YYYY-MM-DD' }
     * Also updates users.weight/weight_unit so the profile's "current"
     * value and the trend log never disagree with each other.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'weight' => ['required', 'numeric', 'min:1'],
            'weight_unit' => ['required', 'in:kg,lbs'],
            'logged_at' => ['nullable', 'date'],
        ]);

        $log = WeightLog::create([
            'user_id' => $request->user()->id,
            'weight' => $validated['weight'],
            'weight_unit' => $validated['weight_unit'],
            'logged_at' => $validated['logged_at'] ?? now()->toDateString(),
        ]);

        $request->user()->update([
            'weight' => $validated['weight'],
            'weight_unit' => $validated['weight_unit'],
        ]);

        return response()->json($log, 201);
    }
}
