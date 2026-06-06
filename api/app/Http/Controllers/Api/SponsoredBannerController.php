<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SponsoredBanner;
use Illuminate\Http\Request;

class SponsoredBannerController extends Controller
{
    /**
     * Get all active banners (public).
     */
    public function index()
    {
        $banners = SponsoredBanner::active()
            ->ordered()
            ->get();

        return response()->json($banners);
    }

    /**
     * Get all banners for admin management.
     */
    public function adminIndex(Request $request)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $banners = SponsoredBanner::ordered()->get();

        return response()->json($banners);
    }

    /**
     * Store a new banner (admin only).
     */
    public function store(Request $request)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'image_url' => 'required|string|max:500',
            'link_url' => 'nullable|string|max:500',
            'is_active' => 'nullable|boolean',
            'display_order' => 'nullable|integer|min:0',
            'starts_at' => 'nullable|date',
            'ends_at' => 'nullable|date|after:starts_at',
        ]);

        $banner = SponsoredBanner::create($validated);

        return response()->json($banner, 201);
    }

    /**
     * Update a banner (admin only).
     */
    public function update(Request $request, SponsoredBanner $sponsoredBanner)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'title' => 'sometimes|string|max:255',
            'image_url' => 'sometimes|string|max:500',
            'link_url' => 'nullable|string|max:500',
            'is_active' => 'nullable|boolean',
            'display_order' => 'nullable|integer|min:0',
            'starts_at' => 'nullable|date',
            'ends_at' => 'nullable|date',
        ]);

        $sponsoredBanner->update($validated);

        return response()->json($sponsoredBanner);
    }

    /**
     * Delete a banner (admin only).
     */
    public function destroy(Request $request, SponsoredBanner $sponsoredBanner)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $sponsoredBanner->delete();

        return response()->json(['message' => 'Banner deleted successfully']);
    }
}
