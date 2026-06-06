<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    /**
     * Get orders for current user (customer).
     */
    public function myOrders(Request $request)
    {
        $orders = Order::where('user_id', $request->user()->id)
            ->with(['store', 'items'])
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json($orders);
    }

    /**
     * Get orders for store owner's stores.
     */
    public function storeOrders(Request $request)
    {
        $user = $request->user();

        if (!$user->isStoreOwner() && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $storeIds = $user->stores()->pluck('id');

        $status = $request->get('status');
        $query = Order::whereIn('store_id', $storeIds)
            ->with(['store', 'items', 'user']);

        if ($status) {
            $query->where('status', $status);
        }

        $orders = $query->orderBy('created_at', 'desc')->paginate(20);

        return response()->json($orders);
    }

    /**
     * Get a single order.
     */
    public function show(Request $request, Order $order)
    {
        $user = $request->user();

        // Check if user owns this order or owns the store
        $isOwner = $order->user_id === $user->id;
        $isStoreOwner = $user->stores()->where('id', $order->store_id)->exists();

        if (!$isOwner && !$isStoreOwner && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        return response()->json($order->load(['store', 'items', 'user']));
    }

    /**
     * Create a new order.
     * Supports:
     * - Single product: product_id + quantity
     * - Cart checkout: cart_id
     * - Multiple items: items array [{product_id, quantity}, ...]
     */
    public function store(Request $request)
    {
        $user = $request->user();

        // Common validation
        $validated = $request->validate([
            'full_name' => 'required|string|max:100',
            'phone' => 'required|string|max:20',
            'wilaya' => 'nullable|string|max:50',
            'commune' => 'nullable|string|max:100',
            'address' => 'nullable|string',
            'notes' => 'nullable|string',
            'delivery_type' => 'nullable|string|in:home,desk',
            // Single product order
            'product_id' => 'nullable|exists:products,id',
            'quantity' => 'nullable|integer|min:1',
            // Cart checkout
            'cart_id' => 'nullable|exists:carts,id',
            // Multi-item order
            'items' => 'nullable|array|min:1',
            'items.*.product_id' => 'exists:products,id',
            'items.*.quantity' => 'integer|min:1',
        ]);

        // Require location for home delivery
        $deliveryType = $validated['delivery_type'] ?? 'home';
        if ($deliveryType === 'home' && (empty($validated['wilaya']) || empty($validated['commune']))) {
            return response()->json(['error' => 'Wilaya and commune are required for home delivery'], 422);
        }

        $orderItems = [];
        $storeId = null;

        // Option 1: Cart checkout
        if (!empty($validated['cart_id'])) {
            $cart = \App\Models\Cart::with('items.product')->findOrFail($validated['cart_id']);

            // Verify ownership
            if ($cart->user_id !== $user?->id) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }

            if ($cart->items->isEmpty()) {
                return response()->json(['error' => 'Cart is empty'], 400);
            }

            $storeId = $cart->store_id;

            foreach ($cart->items as $item) {
                $product = $item->product;

                // Check stock
                if ($product->type !== 'service' && $product->stock < $item->quantity) {
                    return response()->json(['error' => "Insufficient stock for {$product->name}"], 400);
                }

                $unitPrice = $product->discount_price ?? $product->price;
                $orderItems[] = [
                    'product' => $product,
                    'quantity' => $item->quantity,
                    'unit_price' => $unitPrice,
                    'total_price' => $unitPrice * $item->quantity,
                ];
            }
        }
        // Option 2: Multi-item order
        elseif (!empty($validated['items'])) {
            foreach ($validated['items'] as $itemData) {
                $product = Product::findOrFail($itemData['product_id']);
                $quantity = $itemData['quantity'] ?? 1;

                // All items must be from same store
                if ($storeId === null) {
                    $storeId = $product->store_id;
                } elseif ($storeId !== $product->store_id) {
                    return response()->json(['error' => 'All items must be from the same store'], 400);
                }

                // Check stock
                if ($product->type !== 'service' && $product->stock < $quantity) {
                    return response()->json(['error' => "Insufficient stock for {$product->name}"], 400);
                }

                $unitPrice = $product->discount_price ?? $product->price;
                $orderItems[] = [
                    'product' => $product,
                    'quantity' => $quantity,
                    'unit_price' => $unitPrice,
                    'total_price' => $unitPrice * $quantity,
                ];
            }
        }
        // Option 3: Single product (backward compatible)
        elseif (!empty($validated['product_id'])) {
            $product = Product::findOrFail($validated['product_id']);
            $quantity = $validated['quantity'] ?? 1;
            $storeId = $product->store_id;

            // Check stock
            if ($product->type !== 'service' && $product->stock < $quantity) {
                return response()->json(['error' => 'Insufficient stock'], 400);
            }

            $unitPrice = $product->discount_price ?? $product->price;
            $orderItems[] = [
                'product' => $product,
                'quantity' => $quantity,
                'unit_price' => $unitPrice,
                'total_price' => $unitPrice * $quantity,
            ];
        } else {
            return response()->json(['error' => 'Either product_id, cart_id, or items is required'], 422);
        }

        // Calculate totals
        $subtotal = array_sum(array_column($orderItems, 'total_price'));

        // Create order
        $order = Order::create([
            'user_id' => $user?->id,
            'store_id' => $storeId,
            'full_name' => $validated['full_name'],
            'phone' => $validated['phone'],
            'wilaya' => $validated['wilaya'] ?? '',
            'commune' => $validated['commune'] ?? '',
            'address' => $validated['address'] ?? null,
            'notes' => $validated['notes'] ?? null,
            'subtotal' => $subtotal,
            'total' => $subtotal,
            'payment_method' => 'cod',
        ]);

        // Create order items and reduce stock
        foreach ($orderItems as $itemData) {
            $product = $itemData['product'];

            OrderItem::create([
                'order_id' => $order->id,
                'product_id' => $product->id,
                'product_name' => $product->name,
                'product_image' => $product->thumbnail,
                'quantity' => $itemData['quantity'],
                'unit_price' => $itemData['unit_price'],
                'total_price' => $itemData['total_price'],
            ]);

            // Reduce stock
            if ($product->type !== 'service') {
                $product->decrement('stock', $itemData['quantity']);
            }
        }

        // Clear cart if checkout was from cart
        if (!empty($validated['cart_id'])) {
            \App\Models\Cart::destroy($validated['cart_id']);
        }

        return response()->json([
            'message' => 'Order placed successfully',
            'order' => $order->load(['store', 'items']),
        ], 201);
    }

    /**
     * Update order status (store owner only).
     */
    public function updateStatus(Request $request, Order $order)
    {
        $user = $request->user();

        $isStoreOwner = $user->stores()->where('id', $order->store_id)->exists();

        if (!$isStoreOwner && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'status' => 'required|in:pending,confirmed,processing,shipped,delivered,cancelled',
        ]);

        // If cancelling, restore stock
        if ($validated['status'] === 'cancelled' && $order->status !== 'cancelled') {
            foreach ($order->items as $item) {
                Product::where('id', $item->product_id)->increment('stock', $item->quantity);
            }
        }

        $order->update(['status' => $validated['status']]);

        return response()->json([
            'message' => 'Order status updated',
            'order' => $order->fresh(['store', 'items']),
        ]);
    }

    /**
     * Get order statistics for store owner.
     */
    public function storeStats(Request $request)
    {
        $user = $request->user();

        if (!$user->isStoreOwner() && !$user->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $storeIds = $user->stores()->pluck('id');

        $stats = [
            'total_orders' => Order::whereIn('store_id', $storeIds)->count(),
            'pending_orders' => Order::whereIn('store_id', $storeIds)->where('status', 'pending')->count(),
            'total_revenue' => Order::whereIn('store_id', $storeIds)->where('status', 'delivered')->sum('total'),
            'orders_by_status' => [
                'pending' => Order::whereIn('store_id', $storeIds)->where('status', 'pending')->count(),
                'confirmed' => Order::whereIn('store_id', $storeIds)->where('status', 'confirmed')->count(),
                'processing' => Order::whereIn('store_id', $storeIds)->where('status', 'processing')->count(),
                'shipped' => Order::whereIn('store_id', $storeIds)->where('status', 'shipped')->count(),
                'delivered' => Order::whereIn('store_id', $storeIds)->where('status', 'delivered')->count(),
                'cancelled' => Order::whereIn('store_id', $storeIds)->where('status', 'cancelled')->count(),
            ],
        ];

        return response()->json($stats);
    }
}
