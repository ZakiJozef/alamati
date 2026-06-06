<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Connection;
use App\Models\Message;
use App\Models\Store;
use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
    /**
     * Get all users (admin only).
     */
    public function index(Request $request)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $query = User::query();

        if ($role = $request->get('role')) {
            $query->where('role', $role);
        }

        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('username', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('pseudoname', 'like', "%{$search}%");
            });
        }

        return response()->json($query->paginate(20));
    }

    /**
     * Get a single user.
     */
    public function show(User $user)
    {
        return response()->json($user);
    }

    /**
     * Update current user's profile.
     */
    public function updateProfile(Request $request)
    {
        $validated = $request->validate([
            'username' => 'sometimes|string|max:50|unique:users,username,' . $request->user()->id,
            'pseudoname' => 'nullable|string|max:100',
            'profile_pic' => 'nullable|string|max:500',
        ]);

        $request->user()->update($validated);

        return response()->json($request->user());
    }

    /**
     * Get saved stores for current user.
     */
    public function savedStores(Request $request)
    {
        $stores = $request->user()->savedStores()->with(['owner'])->get();

        return response()->json($stores);
    }

    /**
     * Toggle save/unsave a store.
     */
    public function toggleSaveStore(Request $request, Store $store)
    {
        $user = $request->user();

        if ($user->savedStores()->where('store_id', $store->id)->exists()) {
            $user->savedStores()->detach($store->id);
            return response()->json(['saved' => false, 'message' => 'Store unsaved']);
        } else {
            $user->savedStores()->attach($store->id);
            return response()->json(['saved' => true, 'message' => 'Store saved']);
        }
    }

    /**
     * Get accepted connections.
     */
    public function connections(Request $request)
    {
        $userId = $request->user()->id;

        $connections = Connection::where('status', 'accepted')
            ->where(function ($q) use ($userId) {
                $q->where('user_id', $userId)
                    ->orWhere('connected_user_id', $userId);
            })
            ->with(['user', 'connectedUser'])
            ->get()
            ->map(function ($conn) use ($userId) {
                return $conn->user_id === $userId ? $conn->connectedUser : $conn->user;
            });

        return response()->json($connections);
    }

    /**
     * Get connection suggestions.
     */
    public function connectionSuggestions(Request $request)
    {
        $userId = $request->user()->id;

        $existingConnections = Connection::where('user_id', $userId)
            ->orWhere('connected_user_id', $userId)
            ->pluck('user_id')
            ->merge(
                Connection::where('user_id', $userId)
                    ->orWhere('connected_user_id', $userId)
                    ->pluck('connected_user_id')
            )
            ->push($userId);

        $suggestions = User::whereNotIn('id', $existingConnections)
            ->take(10)
            ->get();

        return response()->json($suggestions);
    }

    /**
     * Send a connection request.
     */
    public function sendConnectionRequest(Request $request, User $user)
    {
        if ($user->id === $request->user()->id) {
            return response()->json(['error' => 'Cannot connect to yourself'], 400);
        }

        $connection = Connection::firstOrCreate([
            'user_id' => $request->user()->id,
            'connected_user_id' => $user->id,
        ]);

        return response()->json($connection, 201);
    }

    /**
     * Accept or reject a connection request.
     */
    public function handleConnectionRequest(Request $request, Connection $connection)
    {
        if ($connection->connected_user_id !== $request->user()->id) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'status' => 'required|in:accepted,rejected',
        ]);

        $connection->update(['status' => $validated['status']]);

        return response()->json($connection);
    }

    /**
     * Get admin stats.
     */
    public function adminStats(Request $request)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $now = now();
        $weekAgo = $now->copy()->subWeek();
        $monthAgo = $now->copy()->subMonth();

        // Basic counts
        $totalUsers = User::count();
        $totalStores = Store::count();
        $totalReviews = \App\Models\Review::count();
        $totalMessages = Message::count();
        $totalOrders = \App\Models\Order::count();

        // Growth metrics
        $newUsersThisWeek = User::where('created_at', '>=', $weekAgo)->count();
        $newUsersThisMonth = User::where('created_at', '>=', $monthAgo)->count();
        $newStoresThisWeek = Store::where('created_at', '>=', $weekAgo)->count();
        $newStoresThisMonth = Store::where('created_at', '>=', $monthAgo)->count();
        $newOrdersThisMonth = \App\Models\Order::where('created_at', '>=', $monthAgo)->count();

        // Average review rating
        $avgRating = \App\Models\Review::avg('rating') ?? 0;

        // Users by role
        $usersByRole = [
            'super_admin' => User::where('role', 'super_admin')->count(),
            'store_owner' => User::where('role', 'store_owner')->count(),
            'visitor' => User::where('role', 'visitor')->count(),
        ];

        // Stores by category
        $storesByCategory = Store::selectRaw('category, count(*) as count')
            ->whereNotNull('category')
            ->groupBy('category')
            ->pluck('count', 'category')
            ->toArray();

        // Recent activity
        $recentStores = Store::with('owner:id,username,pseudoname')
            ->latest()
            ->take(5)
            ->get(['id', 'name', 'category', 'owner_id', 'created_at']);

        $recentUsers = User::latest()
            ->take(5)
            ->get(['id', 'username', 'pseudoname', 'email', 'role', 'created_at']);

        $recentReviews = \App\Models\Review::with(['user:id,username,pseudoname', 'store:id,name'])
            ->latest()
            ->take(5)
            ->get(['id', 'user_id', 'store_id', 'rating', 'comment', 'created_at']);

        // Daily user growth (last 7 days)
        $dailyGrowth = [];
        for ($i = 6; $i >= 0; $i--) {
            $date = $now->copy()->subDays($i)->format('Y-m-d');
            $dailyGrowth[] = [
                'date' => $date,
                'users' => User::whereDate('created_at', $date)->count(),
                'stores' => Store::whereDate('created_at', $date)->count(),
            ];
        }

        return response()->json([
            'totalUsers' => $totalUsers,
            'totalStores' => $totalStores,
            'totalReviews' => $totalReviews,
            'totalMessages' => $totalMessages,
            'totalOrders' => $totalOrders,
            'avgRating' => round($avgRating, 1),
            'growth' => [
                'usersThisWeek' => $newUsersThisWeek,
                'usersThisMonth' => $newUsersThisMonth,
                'storesThisWeek' => $newStoresThisWeek,
                'storesThisMonth' => $newStoresThisMonth,
                'ordersThisMonth' => $newOrdersThisMonth,
            ],
            'usersByRole' => $usersByRole,
            'storesByCategory' => $storesByCategory,
            'recentStores' => $recentStores,
            'recentUsers' => $recentUsers,
            'recentReviews' => $recentReviews,
            'dailyGrowth' => $dailyGrowth,
        ]);
    }

    /**
     * Update user role (admin only).
     */
    public function updateRole(Request $request, User $user)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        // Prevent admin from demoting themselves
        if ($user->id === $request->user()->id) {
            return response()->json(['error' => 'Cannot change your own role'], 400);
        }

        $validated = $request->validate([
            'role' => 'required|in:super_admin,store_owner,visitor',
        ]);

        $user->update(['role' => $validated['role']]);

        return response()->json($user);
    }

    /**
     * Delete a user (admin only).
     */
    public function destroy(Request $request, User $user)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        // Prevent admin from deleting themselves
        if ($user->id === $request->user()->id) {
            return response()->json(['error' => 'Cannot delete your own account'], 400);
        }

        $user->delete();

        return response()->json(['message' => 'User deleted successfully']);
    }
}
