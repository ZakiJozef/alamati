<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SubscriptionPlan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class AdminSubscriptionPlanController extends Controller
{
    /**
     * List all subscription plans (admin view - includes inactive)
     */
    public function index(Request $request)
    {
        $plans = SubscriptionPlan::orderBy('sort_order')
            ->orderBy('price')
            ->withCount('subscriptions')
            ->get();

        return response()->json($plans);
    }

    /**
     * Store a new subscription plan
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:100|unique:subscription_plans,name',
            'slug' => 'nullable|string|max:50|unique:subscription_plans,slug',
            'description' => 'nullable|string|max:500',
            'price' => 'required|numeric|min:0',
            'duration_days' => 'required|integer|min:1',
            'max_stores' => 'required|integer|min:-1',
            'max_products' => 'required|integer|min:-1',
            'max_portfolio' => 'required|integer|min:-1',
            'max_sections' => 'integer|min:0',
            'can_use_sponsored_zones' => 'boolean',
            'is_active' => 'boolean',
            'sort_order' => 'integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $plan = SubscriptionPlan::create([
            'name' => $request->name,
            'slug' => $request->slug ?? Str::slug($request->name),
            'description' => $request->description,
            'price' => $request->price,
            'duration_days' => $request->duration_days,
            'max_stores' => $request->max_stores,
            'max_products' => $request->max_products,
            'max_portfolio' => $request->max_portfolio,
            'max_sections' => $request->max_sections ?? 5,
            'can_use_sponsored_zones' => $request->can_use_sponsored_zones ?? false,
            'is_active' => $request->is_active ?? true,
            'sort_order' => $request->sort_order ?? 0,
        ]);

        return response()->json($plan, 201);
    }

    /**
     * Update a subscription plan
     */
    public function update(Request $request, SubscriptionPlan $plan)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:100|unique:subscription_plans,name,' . $plan->id,
            'slug' => 'sometimes|nullable|string|max:50|unique:subscription_plans,slug,' . $plan->id,
            'description' => 'nullable|string|max:500',
            'price' => 'sometimes|required|numeric|min:0',
            'duration_days' => 'sometimes|required|integer|min:1',
            'max_stores' => 'sometimes|required|integer|min:-1',
            'max_products' => 'sometimes|required|integer|min:-1',
            'max_portfolio' => 'sometimes|required|integer|min:-1',
            'max_sections' => 'integer|min:0',
            'can_use_sponsored_zones' => 'boolean',
            'is_active' => 'boolean',
            'sort_order' => 'integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $plan->update($request->only([
            'name', 'slug', 'description', 'price', 'duration_days',
            'max_stores', 'max_products', 'max_portfolio', 'max_sections',
            'can_use_sponsored_zones', 'is_active', 'sort_order'
        ]));

        return response()->json($plan);
    }

    /**
     * Delete a subscription plan
     */
    public function destroy(SubscriptionPlan $plan)
    {
        // Check if plan has active subscriptions
        $activeCount = $plan->subscriptions()
            ->where('status', 'active')
            ->count();

        if ($activeCount > 0) {
            return response()->json([
                'error' => "Cannot delete: {$activeCount} active subscription(s) are using this plan."
            ], 409);
        }

        // Check for any subscriptions at all
        $totalCount = $plan->subscriptions()->count();
        if ($totalCount > 0) {
            return response()->json([
                'error' => "Cannot delete: {$totalCount} subscription(s) are linked to this plan. Consider deactivating instead."
            ], 409);
        }

        $plan->delete();

        return response()->json(['message' => 'Plan deleted successfully']);
    }

    /**
     * Toggle plan active status
     */
    public function toggleActive(SubscriptionPlan $plan)
    {
        $plan->update(['is_active' => !$plan->is_active]);

        return response()->json([
            'message' => 'Plan status updated',
            'is_active' => $plan->is_active
        ]);
    }

    /**
     * Reorder plans
     */
    public function reorder(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'plans' => 'required|array',
            'plans.*.id' => 'required|exists:subscription_plans,id',
            'plans.*.sort_order' => 'required|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        foreach ($request->plans as $item) {
            SubscriptionPlan::where('id', $item['id'])->update(['sort_order' => $item['sort_order']]);
        }

        return response()->json(['message' => 'Plans reordered successfully']);
    }
}
