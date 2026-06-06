<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Permission;
use App\Models\Store;
use App\Models\StoreEmployee;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class EmployeeController extends Controller
{
    /**
     * Get all employees for stores owned by current user.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        if (!$user->isStoreOwner() && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        // Get all stores owned by this user
        $storeIds = $user->stores()->pluck('id');

        // Get all employees for these stores
        $employees = StoreEmployee::whereIn('store_id', $storeIds)
            ->with(['user', 'store'])
            ->get()
            ->groupBy('user_id')
            ->map(function ($employeeRecords) {
                $firstRecord = $employeeRecords->first();
                return [
                    'user' => $firstRecord->user,
                    'stores' => $employeeRecords->map(fn($e) => [
                        'store_id' => $e->store_id,
                        'store_name' => $e->store->name,
                        'title' => $e->title,
                        'permissions' => $e->permissions,
                    ])->values(),
                ];
            })
            ->values();

        return response()->json($employees);
    }

    /**
     * Create a new employee user with store access.
     */
    public function store(Request $request)
    {
        $user = $request->user();

        if (!$user->isStoreOwner() && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
            'username' => 'nullable|string|max:50|unique:users,username',
            'title' => 'nullable|string|max:100',
            'permissions' => 'required|array',
            'store_ids' => 'required|array|min:1',
            'store_ids.*' => 'exists:stores,id',
        ]);

        // Verify user owns all the stores
        $ownedStoreIds = $user->stores()->pluck('id')->toArray();
        foreach ($validated['store_ids'] as $storeId) {
            if (!in_array($storeId, $ownedStoreIds) && !$user->isSuperAdmin()) {
                return response()->json(['error' => 'Unauthorized access to store ' . $storeId], 403);
            }
        }

        // Create the employee user account
        $username = $validated['username'] ?? explode('@', $validated['email'])[0];
        $employee = User::create([
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'username' => $username,
            'role' => 'visitor', // Employees have 'visitor' role but with store-specific permissions
        ]);

        // Add employee to each selected store
        foreach ($validated['store_ids'] as $storeId) {
            StoreEmployee::create([
                'store_id' => $storeId,
                'user_id' => $employee->id,
                'title' => $validated['title'],
                'permissions' => $validated['permissions'],
            ]);
        }

        return response()->json([
            'message' => 'Employee created successfully',
            'user' => $employee,
            'stores' => $validated['store_ids'],
        ], 201);
    }

    /**
     * Update employee permissions and store access.
     */
    public function update(Request $request, User $employee)
    {
        $user = $request->user();

        if (!$user->isStoreOwner() && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'title' => 'nullable|string|max:100',
            'permissions' => 'required|array',
            'store_ids' => 'required|array|min:1',
            'store_ids.*' => 'exists:stores,id',
        ]);

        // Verify user owns all the stores
        $ownedStoreIds = $user->stores()->pluck('id')->toArray();
        foreach ($validated['store_ids'] as $storeId) {
            if (!in_array($storeId, $ownedStoreIds) && !$user->isSuperAdmin()) {
                return response()->json(['error' => 'Unauthorized access to store ' . $storeId], 403);
            }
        }

        // Remove existing store assignments for stores the owner owns
        StoreEmployee::where('user_id', $employee->id)
            ->whereIn('store_id', $ownedStoreIds)
            ->delete();

        // Add new store assignments
        foreach ($validated['store_ids'] as $storeId) {
            StoreEmployee::create([
                'store_id' => $storeId,
                'user_id' => $employee->id,
                'title' => $validated['title'],
                'permissions' => $validated['permissions'],
            ]);
        }

        return response()->json([
            'message' => 'Employee updated successfully',
            'user' => $employee,
            'stores' => $validated['store_ids'],
        ]);
    }

    /**
     * Remove employee from all stores owned by current user.
     */
    public function destroy(Request $request, User $employee)
    {
        $user = $request->user();

        if (!$user->isStoreOwner() && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $ownedStoreIds = $user->stores()->pluck('id');

        StoreEmployee::where('user_id', $employee->id)
            ->whereIn('store_id', $ownedStoreIds)
            ->delete();

        return response()->json(['message' => 'Employee removed successfully']);
    }

    /**
     * Get available permissions for employees.
     */
    public function permissions()
    {
        // Return permissions that can be assigned to employees (exclude admin permissions)
        $permissions = Permission::where('group', '!=', 'admin')
            ->where('group', '!=', 'employees')
            ->get()
            ->groupBy('group')
            ->map(fn($items) => $items->map(fn($p) => [
                'name' => $p->name,
                'display_name' => $p->display_name,
                'description' => $p->description,
            ])->values());

        return response()->json($permissions);
    }

    /**
     * Get stores accessible by the current employee user.
     */
    public function myStoresAsEmployee(Request $request)
    {
        $user = $request->user();

        $employeeRecords = StoreEmployee::where('user_id', $user->id)
            ->with('store')
            ->get();

        $stores = $employeeRecords->map(fn($e) => [
            'store' => $e->store,
            'title' => $e->title,
            'permissions' => $e->permissions,
        ]);

        return response()->json($stores);
    }
}
