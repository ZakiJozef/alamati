<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PortfolioItem;
use App\Models\Store;
use Illuminate\Http\Request;

class PortfolioController extends Controller
{
    /**
     * Get portfolio items for a store.
     */
    public function index(Store $store)
    {
        $items = $store->portfolioItems()->orderBy('created_at', 'desc')->get();
        return response()->json($items);
    }

    /**
     * Store a new portfolio item.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'store_id' => 'required|exists:stores,id',
            'title' => 'required|string|max:100',
            'description' => 'nullable|string',
            'image' => 'nullable|string|max:500',
            'images' => 'nullable|array|max:10',
            'images.*' => 'string|max:500',
        ]);

        $store = Store::findOrFail($validated['store_id']);

        // Check ownership or admin
        if ($store->owner_id !== $request->user()->id && !$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $portfolioItem = PortfolioItem::create($validated);

        return response()->json($portfolioItem, 201);
    }

    /**
     * Update a portfolio item.
     */
    public function update(Request $request, PortfolioItem $portfolioItem)
    {
        $store = $portfolioItem->store;

        // Check ownership or admin
        if ($store->owner_id !== $request->user()->id && !$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'title' => 'sometimes|string|max:100',
            'description' => 'nullable|string',
            'image' => 'nullable|string|max:500',
            'images' => 'nullable|array|max:10',
            'images.*' => 'string|max:500',
        ]);

        $portfolioItem->update($validated);

        return response()->json($portfolioItem);
    }

    /**
     * Delete a portfolio item.
     */
    public function destroy(Request $request, PortfolioItem $portfolioItem)
    {
        $store = $portfolioItem->store;

        // Check ownership or admin
        if ($store->owner_id !== $request->user()->id && !$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $portfolioItem->delete();

        return response()->json(['message' => 'Portfolio item deleted successfully']);
    }
}

