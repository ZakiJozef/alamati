<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Unit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class UnitController extends Controller
{
    /**
     * List all units (public - for dropdowns)
     */
    public function index(Request $request)
    {
        $query = Unit::query();

        // Filter by active status
        if ($request->has('active_only') && $request->active_only) {
            $query->active();
        }

        $units = $query->ordered()->get();

        return response()->json($units);
    }

    /**
     * Store a new unit (admin only)
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:50|unique:units,name',
            'symbol' => 'required|string|max:20|unique:units,symbol',
            'is_active' => 'boolean',
            'sort_order' => 'integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $unit = Unit::create([
            'name' => $request->name,
            'symbol' => $request->symbol,
            'is_active' => $request->is_active ?? true,
            'sort_order' => $request->sort_order ?? 0,
        ]);

        return response()->json($unit, 201);
    }

    /**
     * Show a single unit
     */
    public function show(Unit $unit)
    {
        return response()->json($unit);
    }

    /**
     * Update a unit (admin only)
     */
    public function update(Request $request, Unit $unit)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:50|unique:units,name,' . $unit->id,
            'symbol' => 'sometimes|required|string|max:20|unique:units,symbol,' . $unit->id,
            'is_active' => 'boolean',
            'sort_order' => 'integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $unit->update($request->only(['name', 'symbol', 'is_active', 'sort_order']));

        return response()->json($unit);
    }

    /**
     * Delete a unit (admin only)
     */
    public function destroy(Unit $unit)
    {
        // Check if unit is in use
        $productCount = $unit->products()->count();
        if ($productCount > 0) {
            return response()->json([
                'error' => "Cannot delete: {$productCount} products are using this unit."
            ], 409);
        }

        $unit->delete();

        return response()->json(['message' => 'Unit deleted successfully']);
    }

    /**
     * Reorder units (admin only)
     */
    public function reorder(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'units' => 'required|array',
            'units.*.id' => 'required|exists:units,id',
            'units.*.sort_order' => 'required|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        foreach ($request->units as $item) {
            Unit::where('id', $item['id'])->update(['sort_order' => $item['sort_order']]);
        }

        return response()->json(['message' => 'Units reordered successfully']);
    }
}
