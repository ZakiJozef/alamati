<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\Store;
use App\Models\FeaturedItem;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    /**
     * Get products for a store with search, filters, sorting, and pagination.
     * 
     * Query params:
     * - search: Search products by name/description
     * - category: Filter by category name
     * - min_price: Minimum price filter
     * - max_price: Maximum price filter
     * - discounted: 'true' to show only discounted items
     * - type: 'product', 'service', or 'all' (default: 'all')
     * - sort: 'latest', 'name', 'price_low', 'price_high', 'discount' (default: 'latest')
     * - per_page: Items per page (default: 20)
     */
    public function index(Store $store, Request $request)
    {
        $query = $store->products()->active()->with('unit');

        // Search filter
        if ($search = $request->get('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%");
            });
        }

        // Type filter (product/service)
        if ($type = $request->get('type')) {
            if ($type !== 'all') {
                $query->where('type', $type);
            }
        }

        // Category filter
        if ($category = $request->get('category')) {
            $query->where('category', $category);
        }

        // Price range filter (uses effective price: discount_price or price)
        if ($minPrice = $request->get('min_price')) {
            $query->whereRaw('COALESCE(discount_price, price) >= ?', [$minPrice]);
        }
        if ($maxPrice = $request->get('max_price')) {
            $query->whereRaw('COALESCE(discount_price, price) <= ?', [$maxPrice]);
        }

        // Discounted only filter
        if ($request->get('discounted') === 'true') {
            $query->whereNotNull('discount_price')
                ->whereColumn('discount_price', '<', 'price');
        }

        // Sorting
        $sort = $request->get('sort', 'latest');
        switch ($sort) {
            case 'name':
                $query->orderBy('name', 'asc');
                break;
            case 'price_low':
                $query->orderByRaw('COALESCE(discount_price, price) ASC');
                break;
            case 'price_high':
                $query->orderByRaw('COALESCE(discount_price, price) DESC');
                break;
            case 'discount':
                // Order by discount percentage (highest first)
                $query->whereNotNull('discount_price')
                    ->orderByRaw('((price - discount_price) / price) DESC');
                break;
            case 'latest':
            default:
                $query->latest();
                break;
        }

        // Get unique categories for filter options
        $categories = $store->products()
            ->active()
            ->whereNotNull('category')
            ->distinct()
            ->pluck('category');

        // Get price range for filter options
        $priceStats = $store->products()
            ->active()
            ->selectRaw('MIN(COALESCE(discount_price, price)) as min_price, MAX(COALESCE(discount_price, price)) as max_price')
            ->first();

        // Pagination
        $perPage = min($request->get('per_page', 20), 100); // Max 100 per page
        $products = $query->paginate($perPage);

        return response()->json([
            'data' => $products->items(),
            'meta' => [
                'current_page' => $products->currentPage(),
                'last_page' => $products->lastPage(),
                'per_page' => $products->perPage(),
                'total' => $products->total(),
            ],
            'filters' => [
                'categories' => $categories,
                'min_price' => $priceStats->min_price ?? 0,
                'max_price' => $priceStats->max_price ?? 100000,
            ],
        ]);
    }

    /**
     * Get a single product.
     */
    public function show(Product $product)
    {
        return response()->json($product->load(['store', 'unit']));
    }

    /**
     * Get all products for home page (paginated).
     * Also supports search and type filtering for admin.
     */
    public function allProducts(Request $request)
    {
        $search = $request->get('search');
        $type = $request->get('type', 'product');

        $query = Product::with(['store:id,name', 'unit'])
            ->where('type', $type)
            ->where('is_active', true);

        if ($search) {
            $query->where('name', 'like', "%{$search}%");
        }

        // Return all products (no limit)
        $products = $query->latest()->get();

        return response()->json($products);
    }

    /**
     * Get all services for home page (paginated).
     * Also supports search filtering for admin.
     */
    public function allServices(Request $request)
    {
        $search = $request->get('search');

        $query = Product::with(['store:id,name', 'unit'])
            ->where('type', 'service')
            ->where('is_active', true);

        if ($search) {
            $query->where('name', 'like', "%{$search}%");
        }

        // Return all services (no limit)
        $services = $query->latest()->get();

        return response()->json($services);
    }

    /**
     * Get trending/featured products for carousel.
     */
    public function trendingProducts()
    {
        $featured = FeaturedItem::with('product.store:id,name')
            ->active()
            ->inZone('trending_products')
            ->orderBy('display_order')
            ->get()
            ->pluck('product')
            ->filter();

        return response()->json($featured->values());
    }

    /**
     * Get trending/featured services for carousel.
     */
    public function trendingServices()
    {
        $featured = FeaturedItem::with('product.store:id,name')
            ->active()
            ->inZone('trending_services')
            ->orderBy('display_order')
            ->get()
            ->pluck('product')
            ->filter();

        return response()->json($featured->values());
    }

    /**
     * Admin: Get all featured items for management.
     */
    public function getFeatured(Request $request)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $zone = $request->get('zone', 'trending_products');

        $items = FeaturedItem::with('product.store:id,name')
            ->inZone($zone)
            ->orderBy('display_order')
            ->get();

        return response()->json($items);
    }

    /**
     * Admin: Add product to featured zone.
     */
    public function addFeatured(Request $request)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'product_id' => 'required|exists:products,id',
            'zone' => 'required|in:trending_products,trending_services',
            'display_order' => 'nullable|integer|min:0',
            'starts_at' => 'nullable|date',
            'ends_at' => 'nullable|date|after:starts_at',
        ]);

        $featured = FeaturedItem::updateOrCreate(
            [
                'product_id' => $validated['product_id'],
                'zone' => $validated['zone'],
            ],
            [
                'display_order' => $validated['display_order'] ?? 0,
                'is_active' => true,
                'starts_at' => $validated['starts_at'] ?? null,
                'ends_at' => $validated['ends_at'] ?? null,
            ]
        );

        return response()->json($featured->load('product'), 201);
    }

    /**
     * Admin: Remove product from featured zone.
     */
    public function removeFeatured(Request $request, FeaturedItem $featuredItem)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $featuredItem->delete();

        return response()->json(['message' => 'Removed from featured']);
    }

    /**
     * Admin: Update featured item order.
     */
    public function updateFeaturedOrder(Request $request)
    {
        if (!$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'items' => 'required|array',
            'items.*.id' => 'required|exists:featured_items,id',
            'items.*.display_order' => 'required|integer|min:0',
        ]);

        foreach ($validated['items'] as $item) {
            FeaturedItem::where('id', $item['id'])->update(['display_order' => $item['display_order']]);
        }

        return response()->json(['message' => 'Order updated']);
    }

    /**
     * Store a new product.
     */
    public function store(Request $request, Store $store)
    {
        // Check ownership or admin
        if ($store->owner_id !== $request->user()->id && !$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'description' => 'nullable|string',
            'price' => 'nullable|numeric|min:0',
            'price_unit_id' => 'nullable|exists:units,id',
            'discount_price' => 'nullable|numeric|min:0',
            'image' => 'nullable|string|max:500',
            'images' => 'nullable|array',
            'images.*' => 'string|max:500',
            'type' => 'in:product,service',
            'category' => 'nullable|string|max:50',
            'category_id' => 'nullable|integer|exists:categories,id',
            'subcategory_id' => 'nullable|integer|exists:categories,id',
            'stock' => 'nullable|integer|min:0',
            'is_active' => 'nullable|boolean',
        ]);

        $validated['store_id'] = $store->id;

        $product = Product::create($validated);

        return response()->json($product, 201);
    }

    /**
     * Update a product.
     */
    public function update(Request $request, Product $product)
    {
        $store = $product->store;

        // Check ownership or admin
        if ($store->owner_id !== $request->user()->id && !$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'name' => 'sometimes|string|max:100',
            'description' => 'nullable|string',
            'price' => 'nullable|numeric|min:0',
            'price_unit_id' => 'nullable|exists:units,id',
            'discount_price' => 'nullable|numeric|min:0',
            'image' => 'nullable|string|max:500',
            'images' => 'nullable|array',
            'images.*' => 'string|max:500',
            'type' => 'in:product,service',
            'category' => 'nullable|string|max:50',
            'category_id' => 'nullable|integer|exists:categories,id',
            'subcategory_id' => 'nullable|integer|exists:categories,id',
            'stock' => 'nullable|integer|min:0',
            'is_active' => 'nullable|boolean',
        ]);

        $product->update($validated);

        return response()->json($product);
    }

    /**
     * Delete a product.
     */
    public function destroy(Request $request, Product $product)
    {
        $store = $product->store;

        // Check ownership or admin
        if ($store->owner_id !== $request->user()->id && !$request->user()->isSuperAdmin()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $product->delete();

        return response()->json(['message' => 'Product deleted successfully']);
    }
}

