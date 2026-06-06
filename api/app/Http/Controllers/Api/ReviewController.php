<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Review;
use App\Models\Store;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    /**
     * Get reviews for a store.
     */
    public function index(Store $store)
    {
        $reviews = $store->reviews()
            ->with('user')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($reviews);
    }

    /**
     * Store a new review (or update existing).
     */
    public function store(Request $request, Store $store)
    {
        $validated = $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string',
        ]);

        $review = Review::updateOrCreate(
            [
                'store_id' => $store->id,
                'user_id' => $request->user()->id,
            ],
            $validated
        );

        return response()->json($review, 201);
    }

    /**
     * Delete a review.
     */
    public function destroy(Request $request, Review $review)
    {
        // Check ownership or admin
        if ($review->user_id !== $request->user()->id && !$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $review->delete();

        return response()->json(['message' => 'Review deleted successfully']);
    }
}
