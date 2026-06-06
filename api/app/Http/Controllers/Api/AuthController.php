<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Register a new user.
     */
    public function register(Request $request)
    {
        $validated = $request->validate([
            'username' => 'required|string|max:50|unique:users',
            'email' => 'required|email|unique:users',
            'password' => 'required|string|min:6',
            'role' => 'in:visitor,store_owner',
            'pseudoname' => 'nullable|string|max:100',
        ]);

        $user = User::create([
            'username' => $validated['username'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role' => $validated['role'] ?? 'visitor',
            'pseudoname' => $validated['pseudoname'] ?? null,
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
        ], 201);
    }

    /**
     * Login user.
     */
    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials'],
            ]);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
        ]);
    }

    /**
     * Get current user info.
     */
    public function me(Request $request)
    {
        return response()->json($request->user());
    }

    /**
     * Logout user (revoke current token).
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out successfully']);
    }

    /**
     * Impersonate a user (super admin only).
     */
    public function impersonate(Request $request, User $user)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $token = $user->createToken('impersonation_token', ['impersonated_by' => $request->user()->id])->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
            'originalAdminId' => $request->user()->id,
        ]);
    }

    /**
     * Stop impersonation.
     */
    public function stopImpersonation(Request $request)
    {
        $adminId = $request->input('adminId');
        $admin = User::findOrFail($adminId);

        if (!$admin->isSuperAdmin()) {
            return response()->json(['error' => 'Invalid admin ID'], 400);
        }

        $request->user()->currentAccessToken()->delete();
        $token = $admin->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $admin,
            'token' => $token,
        ]);
    }

    /**
     * Update user profile.
     */
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'username' => 'nullable|string|max:50|unique:users,username,' . $user->id,
            'pseudoname' => 'nullable|string|max:100',
            'profile_pic' => 'nullable|string',
        ]);

        if (isset($validated['username'])) {
            $user->username = $validated['username'];
        }
        if (isset($validated['pseudoname'])) {
            $user->pseudoname = $validated['pseudoname'];
        }
        if (isset($validated['profile_pic'])) {
            $user->profile_pic = $validated['profile_pic'];
        }

        $user->save();

        return response()->json([
            'user' => $user,
            'message' => 'Profile updated successfully',
        ]);
    }

    /**
     * Change user password.
     */
    public function changePassword(Request $request)
    {
        $validated = $request->validate([
            'current_password' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = $request->user();

        if (!Hash::check($validated['current_password'], $user->password)) {
            throw ValidationException::withMessages([
                'current_password' => ['Current password is incorrect'],
            ]);
        }

        $user->password = Hash::make($validated['password']);
        $user->save();

        return response()->json([
            'message' => 'Password changed successfully',
        ]);
    }
}
