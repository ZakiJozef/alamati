<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\ProductReview;
use Illuminate\Http\Request;

class ProductReviewController extends Controller
{
    /**
     * Get reviews for a product.
     */
    public function index(Product $product)
    {
        $reviews = $product->reviews()
            ->with('user:id,username,pseudoname,profile_pic')
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json($reviews);
    }

    /**
     * Add a review to a product.
     */
    public function store(Request $request, Product $product)
    {
        $user = $request->user();

        // Check if user already reviewed this product
        $existing = ProductReview::where('product_id', $product->id)
            ->where('user_id', $user->id)
            ->first();

        if ($existing) {
            return response()->json(['error' => 'You have already reviewed this product'], 400);
        }

        $validated = $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        $review = ProductReview::create([
            'product_id' => $product->id,
            'user_id' => $user->id,
            'rating' => $validated['rating'],
            'comment' => $validated['comment'] ?? null,
        ]);

        return response()->json([
            'message' => 'Review added successfully',
            'review' => $review->load('user:id,username,pseudoname,profile_pic'),
        ], 201);
    }

    /**
     * Update a review.
     */
    public function update(Request $request, ProductReview $review)
    {
        if ($review->user_id !== $request->user()->id) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        $review->update($validated);

        return response()->json([
            'message' => 'Review updated',
            'review' => $review->fresh('user:id,username,pseudoname,profile_pic'),
        ]);
    }

    /**
     * Delete a review.
     */
    public function destroy(Request $request, ProductReview $review)
    {
        $user = $request->user();

        if ($review->user_id !== $user->id && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $review->delete();

        return response()->json(['message' => 'Review deleted']);
    }
}
