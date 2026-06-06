<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Subscription;
use App\Models\Store;
use Illuminate\Http\Request;

class AdminSubscriptionController extends Controller
{
    /**
     * List all subscription requests (for admin).
     */
    public function index(Request $request)
    {
        $this->authorizeAdmin($request);

        $query = Subscription::with(['user', 'plan', 'verifiedBy']);

        // Filter by status using proper scopes
        if ($request->has('status')) {
            $status = $request->status;
            if ($status === 'active') {
                $query->where('status', 'active');
            } elseif ($status === 'pending') {
                $query->pending();
            } elseif ($status === 'expired') {
                $query->where('status', 'expired');
            } else {
                $query->where('status', $status);
            }
        }

        // Filter by payment method
        if ($request->has('payment_method')) {
            $query->where('payment_method', $request->payment_method);
        }

        $subscriptions = $query->latest()->paginate(20);

        return response()->json($subscriptions);
    }

    /**
     * View subscription details.
     */
    public function show(Request $request, $id)
    {
        $this->authorizeAdmin($request);

        $subscription = Subscription::with(['user', 'plan', 'verifiedBy'])
            ->findOrFail($id);

        return response()->json($subscription);
    }

    /**
     * Approve and activate subscription.
     */
    public function approve(Request $request, $id)
    {
        $this->authorizeAdmin($request);

        $request->validate([
            'payment_method' => 'sometimes|in:ccp,baridimob,cash',
            'admin_notes' => 'nullable|string|max:500',
        ]);

        $subscription = Subscription::findOrFail($id);

        if ($subscription->isActive()) {
            return response()->json([
                'message' => 'Subscription is already active',
            ], 400);
        }

        // Update payment method if provided
        if ($request->has('payment_method')) {
            $subscription->update(['payment_method' => $request->payment_method]);
        }

        if ($request->has('admin_notes')) {
            $subscription->update(['admin_notes' => $request->admin_notes]);
        }

        // Activate the subscription
        $subscription->activate($request->user()->id);

        // Upgrade user to store owner if not already
        if (!$subscription->user->isStoreOwner() && !$subscription->user->isSuperAdmin()) {
            $subscription->user->update(['role' => 'store_owner']);
        }

        return response()->json([
            'message' => 'Subscription approved and activated',
            'subscription' => $subscription->fresh()->load(['user', 'plan']),
        ]);
    }

    /**
     * Reject subscription request.
     */
    public function reject(Request $request, $id)
    {
        $this->authorizeAdmin($request);

        $request->validate([
            'admin_notes' => 'required|string|max:500',
        ]);

        $subscription = Subscription::findOrFail($id);

        $subscription->update([
            'status' => Subscription::STATUS_CANCELLED,
            'admin_notes' => $request->admin_notes,
            'verified_by' => $request->user()->id,
            'verified_at' => now(),
        ]);

        return response()->json([
            'message' => 'Subscription request rejected',
            'subscription' => $subscription->fresh()->load(['user', 'plan']),
        ]);
    }

    /**
     * Validate/approve a store.
     */
    public function validateStore(Request $request, $storeId)
    {
        $this->authorizeAdmin($request);

        $store = Store::findOrFail($storeId);
        $store->update(['is_validated' => true]);

        return response()->json([
            'message' => 'Store validated and now visible to public',
            'store' => $store,
        ]);
    }

    /**
     * Invalidate/hide a store.
     */
    public function invalidateStore(Request $request, $storeId)
    {
        $this->authorizeAdmin($request);

        $store = Store::findOrFail($storeId);
        $store->update(['is_validated' => false]);

        return response()->json([
            'message' => 'Store hidden from public',
            'store' => $store,
        ]);
    }

    /**
     * Get subscription statistics.
     */
    public function stats(Request $request)
    {
        $this->authorizeAdmin($request);

        $stats = [
            'total' => Subscription::count(),
            'active' => Subscription::active()->count(),
            'pending' => Subscription::pending()->count(),
            'expired' => Subscription::where('status', 'expired')->count(),
            'by_plan' => Subscription::selectRaw('plan_id, count(*) as count')
                ->groupBy('plan_id')
                ->with('plan:id,name')
                ->get(),
            'by_payment_method' => Subscription::selectRaw('payment_method, count(*) as count')
                ->groupBy('payment_method')
                ->get(),
        ];

        return response()->json($stats);
    }

    /**
     * Authorize admin access.
     */
    private function authorizeAdmin(Request $request)
    {
        if (!$request->user()->isSuperAdmin()) {
            abort(403, 'Unauthorized - Admin access required');
        }
    }
}
