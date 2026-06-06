<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CategoryController extends Controller
{
    /**
     * Get all categories grouped by type.
     */
    public function index(Request $request)
    {
        $includeInactive = $request->boolean('include_inactive', false);

        $query = Category::with([
            'children' => function ($q) use ($includeInactive) {
                if (!$includeInactive) {
                    $q->where('is_active', true);
                }
                $q->orderBy('sort_order');
            }
        ])
            ->whereNull('parent_id')
            ->orderBy('sort_order');

        if (!$includeInactive) {
            $query->where('is_active', true);
        }

        $categories = $query->get();

        return response()->json([
            'store' => $categories->where('type', 'store')->values(),
            'product' => $categories->where('type', 'product')->values(),
            'service' => $categories->where('type', 'service')->values(),
        ]);
    }

    /**
     * Get categories by type.
     */
    public function byType(Request $request, string $type)
    {
        if (!in_array($type, ['store', 'product', 'service'])) {
            return response()->json(['error' => 'Invalid category type'], 400);
        }

        $includeInactive = $request->boolean('include_inactive', false);

        $query = Category::with([
            'children' => function ($q) use ($includeInactive) {
                if (!$includeInactive) {
                    $q->where('is_active', true);
                }
                $q->orderBy('sort_order');
            }
        ])
            ->where('type', $type)
            ->whereNull('parent_id')
            ->orderBy('sort_order');

        if (!$includeInactive) {
            $query->where('is_active', true);
        }

        return response()->json($query->get());
    }

    /**
     * Create a new category.
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'type' => 'required|in:store,product,service',
            'parent_id' => 'nullable|exists:categories,id',
            'name' => 'required|string|max:255',
            'name_en' => 'nullable|string|max:255',
            'emoji' => 'nullable|string|max:10',
            'icon' => 'nullable|string|max:100',
            'color' => 'nullable|string|max:20',
            'image_url' => 'nullable|url|max:500',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // If parent_id is set, ensure it matches the type
        if ($request->parent_id) {
            $parent = Category::find($request->parent_id);
            if ($parent && $parent->type !== $request->type) {
                return response()->json([
                    'error' => 'Parent category must be of the same type'
                ], 422);
            }
        }

        $category = Category::create([
            'type' => $request->type,
            'parent_id' => $request->parent_id,
            'name' => $request->name,
            'name_en' => $request->name_en,
            'emoji' => $request->emoji,
            'icon' => $request->icon,
            'color' => $request->color,
            'image_url' => $request->image_url,
            'sort_order' => $request->sort_order ?? 0,
            'is_active' => $request->is_active ?? true,
        ]);

        return response()->json($category->load('children'), 201);
    }

    /**
     * Update a category.
     */
    public function update(Request $request, Category $category)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'name_en' => 'nullable|string|max:255',
            'emoji' => 'nullable|string|max:10',
            'icon' => 'nullable|string|max:100',
            'color' => 'nullable|string|max:20',
            'image_url' => 'nullable|url|max:500',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $category->update($request->only([
            'name',
            'name_en',
            'emoji',
            'icon',
            'color',
            'image_url',
            'sort_order',
            'is_active'
        ]));

        return response()->json($category->load('children'));
    }

    /**
     * Delete a category.
     */
    public function destroy(Category $category)
    {
        // Check if there are stores/products using this category
        $inUse = false;
        $message = '';

        if ($category->type === 'store') {
            $count = \App\Models\Store::where('category', $category->name)->count();
            if ($count > 0) {
                $inUse = true;
                $message = "Cannot delete: {$count} stores are using this category.";
            }
        } elseif ($category->type === 'product') {
            $count = \App\Models\Product::where('category', $category->name)->count();
            if ($count > 0) {
                $inUse = true;
                $message = "Cannot delete: {$count} products are using this category.";
            }
        }

        if ($inUse) {
            return response()->json(['error' => $message], 409);
        }

        // Delete will cascade to children due to foreign key constraint
        $category->delete();

        return response()->json(['message' => 'Category deleted successfully']);
    }

    /**
     * Reorder categories.
     */
    public function reorder(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'categories' => 'required|array',
            'categories.*.id' => 'required|exists:categories,id',
            'categories.*.sort_order' => 'required|integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        foreach ($request->categories as $item) {
            Category::where('id', $item['id'])->update(['sort_order' => $item['sort_order']]);
        }

        return response()->json(['message' => 'Categories reordered successfully']);
    }
}
