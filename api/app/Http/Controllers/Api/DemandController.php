<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Demand;
use App\Models\Store;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class DemandController extends Controller
{
    /**
     * Get all open demands with optional filters
     */
    public function index(Request $request)
    {
        $query = Demand::with(['user:id,username,profile_pic', 'offers.user:id,username,profile_pic', 'wilayaRelation', 'communeRelation'])
            ->open();

        // Filter by service category
        if ($request->has('category')) {
            $query->byCategory($request->category);
        }

        // Filter by service type
        if ($request->has('service_type')) {
            $query->where('service_type', $request->service_type);
        }

        // Filter by wilaya_id
        if ($request->has('wilaya_id')) {
            $query->byWilaya($request->wilaya_id);
        }

        // Search
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%");
            });
        }

        // Sort
        $sort = $request->get('sort', 'recent');
        switch ($sort) {
            case 'oldest':
                $query->orderBy('created_at', 'asc');
                break;
            case 'most_offers':
                $query->withCount('offers')->orderBy('offers_count', 'desc');
                break;
            default: // recent
                $query->orderBy('created_at', 'desc');
        }

        $limit = $request->get('limit', 50);
        $demands = $query->paginate($limit);

        return response()->json($demands);
    }

    /**
     * Get demand details with offers
     */
    public function show($id)
    {
        $demand = Demand::with([
            'user:id,username,profile_pic',
            'offers' => function ($query) {
                $query->with(['user:id,username,profile_pic', 'store:id,name,profile_image'])
                    ->orderBy('created_at', 'desc');
            }
        ])->findOrFail($id);

        return response()->json($demand);
    }

    /**
     * Create a new demand
     */
    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'phone' => 'required|string|max:20',
            'wilaya_id' => 'required|integer|exists:wilayas,id',
            'commune_id' => 'nullable|integer|exists:communes,id',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'images' => 'nullable|array|max:3',
            'images.*' => 'string|url',
            'service_category_id' => 'nullable|integer|exists:categories,id',
            'is_anonymous' => 'boolean',
        ]);

        $demand = Demand::create([
            'user_id' => Auth::id(),
            'title' => $request->title,
            'description' => $request->description,
            'phone' => $request->phone,
            'wilaya_id' => $request->wilaya_id,
            'commune_id' => $request->commune_id,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'images' => $request->images ?? [],
            'service_category_id' => $request->service_category_id,
            'status' => 'open',
            'is_anonymous' => $request->is_anonymous ?? false,
            'expires_at' => now()->addDays(30),
        ]);

        // Notify matching service providers
        $this->notifyMatchingStores($demand);

        return response()->json($demand->load('user:id,username,profile_pic'), 201);
    }

    /**
     * Notify stores that match the demand's service category
     */
    protected function notifyMatchingStores(Demand $demand)
    {
        // Only notify if demand has a service category
        if (!$demand->service_category_id) {
            return;
        }

        // Find stores that:
        // 1. Provide services (provides_services = true)
        // 2. Have matching service_category_ids (JSON array contains the category ID)
        // 3. Optionally in same wilaya
        $matchingStores = Store::where('provides_services', true)
            ->whereJsonContains('service_category_ids', $demand->service_category_id)
            ->get();

        // Send notification to each store owner
        foreach ($matchingStores as $store) {
            if ($store->owner && $store->owner->id !== $demand->user_id) {
                $store->owner->notify(new \App\Notifications\NewDemandNotification($demand));
            }
        }
    }

    /**
     * Update a demand
     */
    public function update(Request $request, $id)
    {
        $demand = Demand::where('user_id', Auth::id())->findOrFail($id);

        $request->validate([
            'title' => 'sometimes|string|max:255',
            'description' => 'sometimes|string',
            'phone' => 'sometimes|string|max:20',
            'wilaya_id' => 'sometimes|integer|exists:wilayas,id',
            'commune_id' => 'nullable|integer|exists:communes,id',
            'status' => 'sometimes|in:open,closed',
        ]);

        $demand->update($request->only([
            'title',
            'description',
            'phone',
            'wilaya_id',
            'commune_id',
            'status'
        ]));

        return response()->json($demand);
    }

    /**
     * Delete a demand
     */
    public function destroy($id)
    {
        $demand = Demand::where('user_id', Auth::id())->findOrFail($id);
        $demand->delete();

        return response()->json(['message' => 'Demand deleted successfully']);
    }

    /**
     * Get current user's demands
     */
    public function myDemands(Request $request)
    {
        $demands = Demand::with(['offers.user:id,username,profile_pic', 'offers.store:id,name,profile_image'])
            ->where('user_id', Auth::id())
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($demands);
    }

    /**
     * Close a demand (cancel before any offers accepted)
     */
    public function close($id)
    {
        $demand = Demand::where('user_id', Auth::id())->findOrFail($id);

        // Can only close if still open
        if ($demand->status !== 'open') {
            return response()->json(['error' => 'Cannot close a demand that is not open'], 400);
        }

        $demand->update(['status' => 'closed']);

        return response()->json($demand);
    }

    /**
     * Mark demand as completed (only when in_process)
     */
    public function complete($id)
    {
        $demand = Demand::where('user_id', Auth::id())->findOrFail($id);

        // Can only complete if in_process
        if ($demand->status !== 'in_process') {
            return response()->json(['error' => 'Can only complete demands that are in process'], 400);
        }

        $demand->update(['status' => 'completed']);

        return response()->json($demand);
    }

    /**
     * Cancel a demand (only when in_process)
     */
    public function cancel($id)
    {
        $demand = Demand::where('user_id', Auth::id())->findOrFail($id);

        // Can only cancel if in_process
        if ($demand->status !== 'in_process') {
            return response()->json(['error' => 'Can only cancel demands that are in process'], 400);
        }

        $demand->update(['status' => 'canceled']);

        return response()->json($demand);
    }
}
