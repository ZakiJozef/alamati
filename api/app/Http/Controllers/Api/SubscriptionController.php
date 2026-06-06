<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Subscription;
use App\Models\SubscriptionPlan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SubscriptionController extends Controller
{
    /**
     * Get all available subscription plans.
     */
    public function plans()
    {
        $plans = SubscriptionPlan::active()
            ->orderBy('sort_order')
            ->orderBy('price')
            ->get();

        return response()->json($plans);
    }

    /**
     * Get current user's subscription.
     */
    public function mySubscription(Request $request)
    {
        $user = $request->user();

        $subscription = $user->activeSubscription()
            ->with('plan')
            ->first();

        if (!$subscription) {
            // Check for any subscription (including expired/pending)
            $subscription = $user->subscriptions()
                ->with('plan')
                ->latest()
                ->first();
        }

        return response()->json([
            'subscription' => $subscription,
            'has_active_subscription' => $subscription && $subscription->isActive(),
        ]);
    }

    /**
     * Subscribe to a plan.
     */
    public function subscribe(Request $request)
    {
        $request->validate([
            'plan_id' => 'required|exists:subscription_plans,id',
            'payment_method' => 'required|in:free,ccp,baridimob,cash',
            'payment_proof' => 'nullable|image|mimes:jpg,jpeg,png|max:5120', // Max 5MB
        ]);

        $user = $request->user();
        $plan = SubscriptionPlan::findOrFail($request->plan_id);

        // Check if user already has an active subscription
        $activeSubscription = $user->activeSubscription()->first();
        if ($activeSubscription) {
            return response()->json([
                'message' => 'You already have an active subscription',
                'subscription' => $activeSubscription,
            ], 400);
        }

        // Check if it's a free trial
        if ($plan->isFreeTrial()) {
            // Check if user has already used free trial
            $hasUsedTrial = $user->subscriptions()
                ->whereHas('plan', function ($q) {
                    $q->where('slug', 'free');
                })
                ->exists();

            if ($hasUsedTrial) {
                return response()->json([
                    'message' => 'You have already used your free trial',
                ], 400);
            }

            // Create and activate free trial
            $subscription = Subscription::create([
                'user_id' => $user->id,
                'plan_id' => $plan->id,
                'payment_method' => Subscription::PAYMENT_FREE,
            ]);
            $subscription->startFreeTrial();

            return response()->json([
                'message' => 'Free trial activated successfully',
                'subscription' => $subscription->load('plan'),
            ]);
        }

        // Handle payment proof upload for paid plans
        $paymentProofPath = null;
        if ($request->hasFile('payment_proof')) {
            $paymentProofPath = $request->file('payment_proof')->store('payment-proofs', 'public');
        }

        // Create pending subscription for paid plans
        $subscription = Subscription::create([
            'user_id' => $user->id,
            'plan_id' => $plan->id,
            'status' => Subscription::STATUS_PENDING,
            'payment_method' => $request->payment_method,
            'payment_proof' => $paymentProofPath,
        ]);

        return response()->json([
            'message' => 'Subscription request created. Awaiting payment verification.',
            'subscription' => $subscription->load('plan'),
        ]);
    }

    /**
     * Upgrade user role from visitor to store_owner.
     */
    public function upgradeToStoreOwner(Request $request)
    {
        $user = $request->user();

        // Check if user is already a store owner
        if ($user->isStoreOwner() || $user->isSuperAdmin()) {
            return response()->json([
                'message' => 'You are already a store owner',
            ], 400);
        }

        // Upgrade role
        $user->update(['role' => 'store_owner']);

        // Auto-subscribe to free trial if no subscription exists
        $activeSubscription = $user->activeSubscription()->first();
        if (!$activeSubscription) {
            $freePlan = SubscriptionPlan::where('slug', 'free')->first();
            if ($freePlan) {
                $subscription = Subscription::create([
                    'user_id' => $user->id,
                    'plan_id' => $freePlan->id,
                    'payment_method' => Subscription::PAYMENT_FREE,
                ]);
                $subscription->startFreeTrial();
            }
        }

        return response()->json([
            'message' => 'Congratulations! You are now a store owner.',
            'user' => $user->fresh()->load('activeSubscription.plan'),
        ]);
    }

    /**
     * Check subscription limits.
     */
    public function checkLimits(Request $request)
    {
        $user = $request->user();
        $subscription = $user->activeSubscription()->with('plan')->first();

        if (!$subscription) {
            return response()->json([
                'can_create_store' => false,
                'can_add_product' => false,
                'can_add_portfolio' => false,
                'message' => 'No active subscription',
            ]);
        }

        $plan = $subscription->plan;
        $storeCount = $user->stores()->count();

        // Get total products and portfolio across all stores
        $productCount = DB::table('products')
            ->whereIn('store_id', $user->stores()->pluck('id'))
            ->count();
        $portfolioCount = DB::table('portfolio_items')
            ->whereIn('store_id', $user->stores()->pluck('id'))
            ->count();

        return response()->json([
            'can_create_store' => $storeCount < $plan->max_stores,
            'can_add_product' => $plan->hasUnlimitedProducts() || $productCount < ($plan->max_products * $storeCount),
            'can_add_portfolio' => $portfolioCount < ($plan->max_portfolio * $storeCount),
            'limits' => [
                'stores' => ['current' => $storeCount, 'max' => $plan->max_stores],
                'products' => ['current' => $productCount, 'max' => $plan->hasUnlimitedProducts() ? -1 : $plan->max_products * $storeCount],
                'portfolio' => ['current' => $portfolioCount, 'max' => $plan->max_portfolio * $storeCount],
            ],
            'subscription' => $subscription,
        ]);
    }
}
