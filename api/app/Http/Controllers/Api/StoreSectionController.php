<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Store;
use App\Models\StoreSection;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class StoreSectionController extends Controller
{
    /**
     * Get all sections for a store.
     */
    public function index(Store $store)
    {
        $sections = $store->sections()
            ->with('products')
            ->orderBy('sort_order')
            ->get();

        return response()->json($sections);
    }

    /**
     * Create a new section for a store.
     */
    public function store(Request $request, Store $store)
    {
        // Authorization check
        if ($store->owner_id !== Auth::id() && !Auth::user()?->is_admin) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'type' => 'required|string|in:' . implode(',', array_keys(StoreSection::getTypes())),
            'title' => 'nullable|string|max:100',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'nullable|boolean',
            'config' => 'nullable|array',
            'config.end_time' => 'nullable|date',
            'product_ids' => 'nullable|array',
            'product_ids.*' => 'exists:products,id',
        ]);

        // Check subscription for sponsored sections
        if (in_array($validated['type'], StoreSection::getSponsoredTypes())) {
            $subscription = $store->owner->activeSubscription;
            $plan = $subscription?->plan;

            if (!$plan || !$plan->can_use_sponsored_zones) {
                return response()->json([
                    'message' => 'Sponsored sections require Gold subscription',
                    'upgrade_required' => true,
                ], 403);
            }
        }

        // Check max sections limit
        $subscription = $store->owner->activeSubscription;
        $plan = $subscription?->plan;
        $maxSections = $plan?->max_sections ?? 5;

        if ($maxSections !== -1) {
            $currentCount = $store->sections()->count();
            if ($currentCount >= $maxSections) {
                return response()->json([
                    'message' => "Maximum $maxSections sections allowed for your plan",
                    'limit_reached' => true,
                ], 403);
            }
        }

        // Create the section
        $section = $store->sections()->create([
            'type' => $validated['type'],
            'title' => $validated['title'] ?? null,
            'sort_order' => $validated['sort_order'] ?? 0,
            'is_active' => $validated['is_active'] ?? true,
            'config' => $validated['config'] ?? null,
        ]);

        // Attach products if provided
        if (!empty($validated['product_ids'])) {
            $productData = [];
            foreach ($validated['product_ids'] as $index => $productId) {
                $productData[$productId] = ['sort_order' => $index];
            }
            $section->products()->attach($productData);
        }

        $section->load('products');

        return response()->json($section, 201);
    }

    /**
     * Update a section.
     */
    public function update(Request $request, Store $store, StoreSection $section)
    {
        // Verify section belongs to store
        if ($section->store_id !== $store->id) {
            return response()->json(['message' => 'Section not found'], 404);
        }

        // Authorization check
        if ($store->owner_id !== Auth::id() && !Auth::user()?->is_admin) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'type' => 'sometimes|string|in:' . implode(',', array_keys(StoreSection::getTypes())),
            'title' => 'nullable|string|max:100',
            'sort_order' => 'nullable|integer|min:0',
            'is_active' => 'nullable|boolean',
            'config' => 'nullable|array',
            'config.end_time' => 'nullable|date',
            'product_ids' => 'nullable|array',
            'product_ids.*' => 'exists:products,id',
        ]);

        // Check subscription if changing to sponsored type
        if (isset($validated['type']) && in_array($validated['type'], StoreSection::getSponsoredTypes())) {
            if (!$section->isSponsored()) {
                $subscription = $store->owner->activeSubscription;
                $plan = $subscription?->plan;

                if (!$plan || !$plan->can_use_sponsored_zones) {
                    return response()->json([
                        'message' => 'Sponsored sections require Gold subscription',
                        'upgrade_required' => true,
                    ], 403);
                }
            }
        }

        // Update section fields
        $section->update([
            'type' => $validated['type'] ?? $section->type,
            'title' => array_key_exists('title', $validated) ? $validated['title'] : $section->title,
            'sort_order' => $validated['sort_order'] ?? $section->sort_order,
            'is_active' => $validated['is_active'] ?? $section->is_active,
            'config' => $validated['config'] ?? $section->config,
        ]);

        // Update products if provided
        if (isset($validated['product_ids'])) {
            $productData = [];
            foreach ($validated['product_ids'] as $index => $productId) {
                $productData[$productId] = ['sort_order' => $index];
            }
            $section->products()->sync($productData);
        }

        $section->load('products');

        return response()->json($section);
    }

    /**
     * Delete a section.
     */
    public function destroy(Store $store, StoreSection $section)
    {
        // Verify section belongs to store
        if ($section->store_id !== $store->id) {
            return response()->json(['message' => 'Section not found'], 404);
        }

        // Authorization check
        if ($store->owner_id !== Auth::id() && !Auth::user()?->is_admin) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $section->delete();

        return response()->json(['message' => 'Section deleted']);
    }

    /**
     * Reorder sections.
     */
    public function reorder(Request $request, Store $store)
    {
        // Authorization check
        if ($store->owner_id !== Auth::id() && !Auth::user()?->is_admin) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'section_ids' => 'required|array',
            'section_ids.*' => 'exists:store_sections,id',
        ]);

        foreach ($validated['section_ids'] as $index => $sectionId) {
            StoreSection::where('id', $sectionId)
                ->where('store_id', $store->id)
                ->update(['sort_order' => $index]);
        }

        return response()->json(['message' => 'Sections reordered']);
    }

    /**
     * Get available section types for the store's subscription.
     */
    public function types(Store $store)
    {
        $allTypes = StoreSection::getTypes();
        $sponsoredTypes = StoreSection::getSponsoredTypes();

        $subscription = $store->owner->activeSubscription;
        $plan = $subscription?->plan;
        $canUseSponsored = $plan?->can_use_sponsored_zones ?? false;

        $result = [];
        foreach ($allTypes as $key => $label) {
            $result[] = [
                'type' => $key,
                'label' => $label,
                'is_sponsored' => in_array($key, $sponsoredTypes),
                'available' => !in_array($key, $sponsoredTypes) || $canUseSponsored,
            ];
        }

        return response()->json([
            'types' => $result,
            'can_use_sponsored_zones' => $canUseSponsored,
            'max_sections' => $plan?->max_sections ?? 5,
            'current_count' => $store->sections()->count(),
        ]);
    }
}
