<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Product;
use Illuminate\Http\Request;

class CartController extends Controller
{
    /**
     * Get current user's cart.
     */
    public function show(Request $request)
    {
        $user = $request->user();

        $cart = Cart::where('user_id', $user->id)
            ->with(['items.product.store', 'store'])
            ->first();

        if (!$cart) {
            return response()->json([
                'id' => null,
                'store' => null,
                'items' => [],
                'subtotal' => 0,
                'item_count' => 0,
            ]);
        }

        return response()->json($cart);
    }

    /**
     * Add item to cart.
     */
    public function addItem(Request $request)
    {
        $validated = $request->validate([
            'product_id' => 'required|exists:products,id',
            'quantity' => 'integer|min:1|max:99',
        ]);

        $user = $request->user();
        $product = Product::findOrFail($validated['product_id']);
        $quantity = $validated['quantity'] ?? 1;

        // Check stock for products (not services)
        if ($product->type !== 'service' && $product->stock < $quantity) {
            return response()->json(['error' => 'Insufficient stock'], 400);
        }

        // Clear cart if from different store
        Cart::clearIfDifferentStore($user->id, $product->store_id);

        // Get or create cart for this store
        $cart = Cart::getOrCreate($user->id, $product->store_id);

        // Check if item already exists
        $existingItem = $cart->items()->where('product_id', $product->id)->first();

        if ($existingItem) {
            $newQuantity = $existingItem->quantity + $quantity;

            // Check stock for updated quantity
            if ($product->type !== 'service' && $product->stock < $newQuantity) {
                return response()->json(['error' => 'Insufficient stock for requested quantity'], 400);
            }

            $existingItem->update(['quantity' => $newQuantity]);
        } else {
            CartItem::create([
                'cart_id' => $cart->id,
                'product_id' => $product->id,
                'quantity' => $quantity,
            ]);
        }

        // Reload cart with relationships
        $cart->load(['items.product.store', 'store']);

        return response()->json([
            'message' => 'Item added to cart',
            'cart' => $cart,
        ], 201);
    }

    /**
     * Update item quantity.
     */
    public function updateItem(Request $request, CartItem $item)
    {
        $user = $request->user();

        // Verify ownership
        if ($item->cart->user_id !== $user->id) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'quantity' => 'required|integer|min:1|max:99',
        ]);

        // Check stock
        $product = $item->product;
        if ($product->type !== 'service' && $product->stock < $validated['quantity']) {
            return response()->json(['error' => 'Insufficient stock'], 400);
        }

        $item->update(['quantity' => $validated['quantity']]);

        // Reload cart
        $cart = $item->cart->fresh(['items.product.store', 'store']);

        return response()->json([
            'message' => 'Item quantity updated',
            'cart' => $cart,
        ]);
    }

    /**
     * Remove item from cart.
     */
    public function removeItem(Request $request, CartItem $item)
    {
        $user = $request->user();

        // Verify ownership
        if ($item->cart->user_id !== $user->id) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $cart = $item->cart;
        $item->delete();

        // If cart is empty, delete it
        if ($cart->items()->count() === 0) {
            $cart->delete();
            return response()->json([
                'message' => 'Cart is now empty',
                'cart' => null,
            ]);
        }

        // Reload cart
        $cart->load(['items.product.store', 'store']);

        return response()->json([
            'message' => 'Item removed from cart',
            'cart' => $cart,
        ]);
    }

    /**
     * Clear entire cart.
     */
    public function clear(Request $request)
    {
        $user = $request->user();

        Cart::where('user_id', $user->id)->delete();

        return response()->json(['message' => 'Cart cleared']);
    }
}
