<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Store;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class StoreController extends Controller
{

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'description' => 'nullable|string',
            'cover_image' => 'nullable|string|max:500',
            'profile_image' => 'nullable|string|max:500',
            'address' => 'nullable|string|max:255',
            'city' => 'nullable|string|max:100',
            'state' => 'nullable|string|max:100',
            'wilaya_id' => 'nullable|integer|exists:wilayas,id',
            'commune_id' => 'nullable|integer|exists:communes,id',
            'category' => 'nullable|string|max:50',
            'category_id' => 'nullable|integer|exists:categories,id',
            'category_ids' => 'nullable|array',
            'category_ids.*' => 'integer|exists:categories,id',
            'subcategory_id' => 'nullable|integer|exists:categories,id',
            'subcategory_ids' => 'nullable|array',
            'subcategory_ids.*' => 'integer|exists:categories,id',
            'provides_services' => 'nullable|boolean',
            'service_category_ids' => 'nullable|array',
            'service_category_ids.*' => 'integer|exists:categories,id',
            'phone' => 'nullable|string|max:20',
            'phones' => 'nullable|array',
            'email' => 'nullable|email|max:100',
            'website' => 'nullable|string|max:255',
            'map_url' => 'nullable|string|max:500',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'is_open' => 'nullable|boolean',
            'social_links' => 'nullable|array',
            'business_hours' => 'nullable|array',
        ]);

        $validated['owner_id'] = $request->user()->id;
        $validated['slug'] = $this->generateUniqueSlug($validated['name']);

        $store = Store::create($validated);

        return response()->json($store, 201);
    }

    private function generateUniqueSlug($name)
    {
        $slug = Str::slug($name);
        $originalSlug = $slug;
        $count = 1;

        while (Store::where('slug', $slug)->exists()) {
            $slug = "{$originalSlug}-{$count}";
            $count++;
        }

        return $slug;
    }

    /**
     * Display a listing of stores.
     */
    public function index(Request $request)
    {
        $query = Store::with(['owner', 'reviews']);

        // Search
        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%")
                    ->orWhere('category', 'like', "%{$search}%");
            });
        }

        // Filter by category
        if ($category = $request->get('category')) {
            $query->where('category', $category);
        }

        // Filter by state (wilaya)
        if ($state = $request->get('state')) {
            $query->where('state', $state);
        }

        // Filter by city (also checks state for broader matching)
        if ($city = $request->get('city')) {
            $query->where(function ($q) use ($city) {
                $q->where('city', $city)
                    ->orWhere('state', $city);
            });
        }

        // Filter by wilaya_id (preferred over string-based city/state)
        if ($wilayaId = $request->get('wilaya_id')) {
            $query->where('wilaya_id', $wilayaId);
        }

        // Filter by commune_id
        if ($communeId = $request->get('commune_id')) {
            $query->where('commune_id', $communeId);
        }

        // Filter by minimum rating
        if ($minRating = $request->get('min_rating')) {
            $query->where('rating', '>=', $minRating);
        }

        // Sort
        $sort = $request->get('sort', 'newest');
        switch ($sort) {
            case 'name':
                $query->orderBy('name', 'asc');
                break;
            case 'rating':
                $query->orderByDesc('rating');
                break;
            case 'followers':
                $query->orderByDesc('follower_count');
                break;
            case 'oldest':
                $query->oldest();
                break;
            case 'newest':
            default:
                $query->latest();
                break;
        }

        // Paginate stores (20 per page for better performance)
        $perPage = $request->get('per_page', 20);
        $stores = $query->paginate($perPage);

        return response()->json($stores);
    }

    /**
     * Get featured stores.
     */
    public function featured()
    {
        $stores = Store::featured()
            ->with(['owner'])
            ->latest()
            ->take(10)
            ->get();

        return response()->json($stores);
    }

    /**
     * Get nearby stores based on coordinates.
     * Uses Haversine formula to calculate distance.
     */
    public function nearby(Request $request)
    {
        $lat = $request->get('lat');
        $lng = $request->get('lng');
        $radius = $request->get('radius', 20); // Default 20km radius

        if (!$lat || !$lng) {
            return response()->json(['error' => 'Latitude and longitude are required'], 400);
        }

        // Haversine formula to calculate distance in km
        $haversine = "(6371 * acos(cos(radians(?)) 
                     * cos(radians(lat)) 
                     * cos(radians(lng) - radians(?)) 
                     + sin(radians(?)) 
                     * sin(radians(lat))))";

        $query = Store::selectRaw("*, {$haversine} AS distance", [$lat, $lng, $lat])
            ->whereNotNull('lat')
            ->whereNotNull('lng')
            ->with(['owner']);

        // Only enforce radius if NOT filtering by region (Wilaya/Commune)
        if (!$request->has('wilaya') && !$request->has('commune')) {
            $query->having('distance', '<=', $radius);
        }

        // Filter by category_id (preferred) or category name (fallback)
        if ($categoryId = $request->get('category_id')) {
            $query->where('category_id', $categoryId);
        } elseif ($category = $request->get('category')) {
            $query->where('category', $category);
        }

        // Filter by subcategory_id
        if ($subcategoryId = $request->get('subcategory_id')) {
            $query->where('subcategory_id', $subcategoryId);
        }

        // Filter by wilaya (state)
        if ($wilaya = $request->get('wilaya')) {
            $query->where('state', $wilaya);
        }

        // Filter by commune (city)
        if ($commune = $request->get('commune')) {
            $query->where('city', $commune);
        }

        // Filter by minimum rating
        if ($minRating = $request->get('min_rating')) {
            $query->where('rating', '>=', $minRating);
        }

        // Filter by open status
        if ($request->has('is_open')) {
            $query->where('is_open', $request->boolean('is_open'));
        }

        // Search by name
        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%");
            });
        }

        // Order by distance
        $query->orderBy('distance');

        // Only limit if requested
        if ($request->has('limit')) {
            $query->take($request->get('limit'));
        }

        $stores = $query->get();

        return response()->json($stores);
    }

    /**
     * Get sponsored stores.
     */
    public function sponsored()
    {
        $stores = Store::sponsored()
            ->with(['owner'])
            ->latest()
            ->take(10)
            ->get();

        return response()->json($stores);
    }

    /**
     * Get all categories.
     */
    public function categories()
    {
        $categories = Store::distinct()
            ->whereNotNull('category')
            ->pluck('category');

        return response()->json($categories);
    }

    /**
     * Get all cities.
     */
    public function cities()
    {
        $cities = Store::distinct()
            ->whereNotNull('city')
            ->pluck('city');

        return response()->json($cities);
    }

    /**
     * Display the specified store.
     */
    public function show(Store $store)
    {
        $store->load(['owner', 'products', 'portfolioItems', 'reviews.user']);

        return response()->json($store);
    }



    /**
     * Update the specified store.
     */
    public function update(Request $request, Store $store)
    {
        // Check ownership or admin
        if ($store->owner_id !== $request->user()->id && !$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'name' => 'sometimes|string|max:100',
            'description' => 'nullable|string',
            'cover_image' => 'nullable|string|max:500',
            'profile_image' => 'nullable|string|max:500',
            'address' => 'nullable|string|max:255',
            'city' => 'nullable|string|max:100',
            'state' => 'nullable|string|max:100',
            'wilaya_id' => 'nullable|integer|exists:wilayas,id',
            'commune_id' => 'nullable|integer|exists:communes,id',
            'category' => 'nullable|string|max:100',
            'category_id' => 'nullable|integer|exists:categories,id',
            'category_ids' => 'nullable|array',
            'category_ids.*' => 'integer|exists:categories,id',
            'subcategory_id' => 'nullable|integer|exists:categories,id',
            'subcategory_ids' => 'nullable|array',
            'subcategory_ids.*' => 'integer|exists:categories,id',
            'provides_services' => 'nullable|boolean',
            'service_category_ids' => 'nullable|array',
            'service_category_ids.*' => 'integer|exists:categories,id',
            'phone' => 'nullable|string|max:20',
            'phones' => 'nullable|array',
            'email' => 'nullable|email|max:100',
            'website' => 'nullable|string|max:255',
            'map_url' => 'nullable|string|max:500',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'is_open' => 'nullable|boolean',
            'social_links' => 'nullable|array',
            'business_hours' => 'nullable|array',
            'slug' => 'nullable|string|max:255|unique:stores,slug,' . $store->id,
        ]);

        $store->update($validated);

        return response()->json($store);
    }

    /**
     * Remove the specified store.
     */
    public function destroy(Request $request, Store $store)
    {
        // Check ownership or admin
        if ($store->owner_id !== $request->user()->id && !$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $store->delete();

        return response()->json(['message' => 'Store deleted successfully']);
    }

    /**
     * Get stores owned by current user (or all stores for admin).
     */
    public function myStores(Request $request)
    {
        $user = $request->user();
        $query = Store::with(['products', 'portfolioItems', 'reviews', 'owner']);

        // Base constraint: Admin sees all, User sees own
        if (!$user->isSuperAdmin()) {
            $query->where('owner_id', $user->id);
        }

        // --- Filtering Logic (Mirrored from index) ---

        // Search
        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%")
                    ->orWhere('category', 'like', "%{$search}%");
            });
        }

        // Filter by category
        if ($category = $request->get('category')) {
            $query->where('category', $category);
        }

        // Filter by state (wilaya)
        if ($state = $request->get('state')) {
            $query->where('state', $state);
        }
        if ($wilayaId = $request->get('wilaya_id')) {
            $query->where('wilaya_id', $wilayaId);
        }

        // Filter by city
        if ($city = $request->get('city')) {
            $query->where('city', $city);
        }
        if ($communeId = $request->get('commune_id')) {
            $query->where('commune_id', $communeId);
        }

        // Filter by status
        if ($request->has('status')) {
            $status = $request->get('status');
            if ($status === 'open') {
                $query->where('is_open', true);
            } elseif ($status === 'closed') {
                $query->where('is_open', false);
            }
        }

        // Filter by minimum rating
        if ($minRating = $request->get('min_rating')) {
            $query->where('rating', '>=', $minRating);
        }

        // Sort
        $sort = $request->get('sort', 'newest');
        switch ($sort) {
            case 'name_asc':
                $query->orderBy('name', 'asc');
                break;
            case 'name_desc':
                $query->orderBy('name', 'desc');
                break;
            case 'rating_high':
                $query->orderByDesc('rating');
                break;
            case 'rating_low':
                $query->orderBy('rating', 'asc');
                break;
            case 'oldest':
                $query->oldest();
                break;
            case 'newest':
            default:
                $query->latest();
                break;
        }

        // Paginate
        $perPage = $request->get('limit', 10);
        $stores = $query->paginate($perPage);

        return response()->json($stores);
    }

    /**
     * Toggle follow status for a store.
     */
    public function toggleFollow(Request $request, Store $store)
    {
        $user = $request->user();

        // Check if already following
        $isFollowing = $store->followers()->where('user_id', $user->id)->exists();

        if ($isFollowing) {
            // Unfollow
            $store->followers()->detach($user->id);
        } else {
            // Follow
            $store->followers()->attach($user->id);
        }

        // Update cached follower count
        $store->updateFollowerCount();
        $store->refresh();

        return response()->json([
            'following' => !$isFollowing,
            'follower_count' => $store->follower_count,
        ]);
    }

    /**
     * Get followers of a store (owner or admin only).
     */
    public function followers(Request $request, Store $store)
    {
        // Check ownership or admin
        if ($store->owner_id !== $request->user()->id && !$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $followers = $store->followers()
            ->select('users.id', 'users.username', 'users.pseudoname', 'users.profile_pic')
            ->orderBy('store_followers.created_at', 'desc')
            ->paginate(20);

        return response()->json($followers);
    }

    /**
     * Get stores that the current user follows.
     */
    public function followedStores(Request $request)
    {
        $stores = $request->user()->followedStores()
            ->with(['owner'])
            ->get();

        return response()->json($stores);
    }

    /**
     * Admin: Get all stores for featured management.
     */
    public function adminListForFeatured(Request $request)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $query = Store::with(['owner:id,username,pseudoname']);

        // Search
        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('category', 'like', "%{$search}%");
            });
        }

        // Filter by featured status
        if ($request->has('featured')) {
            $query->where('is_featured', $request->boolean('featured'));
        }

        $stores = $query->orderByDesc('is_featured')
            ->orderByDesc('created_at')
            ->paginate($request->get('limit', 20));

        return response()->json($stores);
    }

    /**
     * Admin: Toggle featured status for a store.
     */
    public function toggleFeatured(Request $request, Store $store)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $store->is_featured = !$store->is_featured;
        $store->save();

        return response()->json([
            'message' => $store->is_featured ? 'Store marked as featured' : 'Store removed from featured',
            'is_featured' => $store->is_featured,
            'store' => $store->load('owner:id,username,pseudoname'),
        ]);
    }

    /**
     * Admin: Get all stores for sponsored management.
     */
    public function adminListForSponsored(Request $request)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $query = Store::with(['owner:id,username,pseudoname']);

        // Search
        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('category', 'like', "%{$search}%");
            });
        }

        // Filter by sponsored status
        if ($request->has('sponsored')) {
            $query->where('is_sponsored', $request->boolean('sponsored'));
        }

        $stores = $query->orderByDesc('is_sponsored')
            ->orderByDesc('created_at')
            ->paginate($request->get('limit', 20));

        return response()->json($stores);
    }

    /**
     * Admin: Toggle sponsored status for a store.
     */
    public function toggleSponsored(Request $request, Store $store)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $store->is_sponsored = !$store->is_sponsored;
        $store->save();

        return response()->json([
            'message' => $store->is_sponsored ? 'Store marked as sponsored' : 'Store removed from sponsored',
            'is_sponsored' => $store->is_sponsored,
            'store' => $store->load('owner:id,username,pseudoname'),
        ]);
    }
}