<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\StoreSection;

class Store extends Model
{
    use HasFactory;

    protected $fillable = [
        'owner_id',
        'name',
        'slug',
        'description',
        'cover_image',
        'profile_image',
        'address',
        'city',
        'state',
        'wilaya_id',
        'commune_id',
        'category',
        'category_id',
        'category_ids',
        'subcategory_id',
        'subcategory_ids',
        'provides_services',
        'service_category_ids',
        'phone',
        'phones',
        'email',
        'website',
        'map_url',
        'lat',
        'lng',
        'rating',
        'review_count',
        'follower_count',
        'is_open',
        'is_featured',
        'is_sponsored',
        'is_validated',
        'social_links',
        'business_hours',
        'postal_code',
        'activities',
    ];


    /**
     * Resolve the route binding for the model.
     *
     * @param  mixed  $value
     * @param  string|null  $field
     * @return \Illuminate\Database\Eloquent\Model|null
     */
    public function resolveRouteBinding($value, $field = null)
    {
        // If the value is numeric, assume it's an ID
        if (is_numeric($value)) {
            return $this->where('id', $value)->firstOrFail();
        }

        // Otherwise, assume it's a slug
        return $this->where('slug', $value)->firstOrFail();
    }


    protected $casts = [
        'phones' => 'array',
        'social_links' => 'array',
        'subcategory_ids' => 'array',
        'category_ids' => 'array',
        'service_category_ids' => 'array',
        'lat' => 'float',
        'lng' => 'float',
        'rating' => 'float',
        'is_open' => 'boolean',
        'is_featured' => 'boolean',
        'is_sponsored' => 'boolean',
        'is_validated' => 'boolean',
        'provides_services' => 'boolean',
        'category_id' => 'integer',
        'subcategory_id' => 'integer',
        'wilaya_id' => 'integer',
        'commune_id' => 'integer',
        'business_hours' => 'array',
        // 'activities' is stored as simple text (comma separated), no cast needed unless JSON but user said concat.
        // Wait user said "insert the values as concatination". So it is a string.
    ];

    /**
     * Get the category of the store.
     */
    public function categoryRelation()
    {
        return $this->belongsTo(Category::class, 'category_id');
    }

    /**
     * Get the subcategory of the store.
     */
    public function subcategoryRelation()
    {
        return $this->belongsTo(Category::class, 'subcategory_id');
    }

    /**
     * Get the wilaya (state) of the store.
     */
    public function wilaya()
    {
        return $this->belongsTo(Wilaya::class);
    }

    /**
     * Get the commune (city) of the store.
     */
    public function commune()
    {
        return $this->belongsTo(Commune::class);
    }

    /**
     * Get the owner of the store.
     */
    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    /**
     * Get the products for this store.
     */
    public function products()
    {
        return $this->hasMany(Product::class);
    }

    /**
     * Get the portfolio items for this store.
     */
    public function portfolioItems()
    {
        return $this->hasMany(PortfolioItem::class);
    }

    /**
     * Get the reviews for this store.
     */
    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    /**
     * Get the customizable sections for this store.
     */
    public function sections()
    {
        return $this->hasMany(StoreSection::class)->orderBy('sort_order');
    }

    /**
     * Get users who saved this store.
     */
    public function savedByUsers()
    {
        return $this->belongsToMany(User::class, 'saved_stores', 'store_id', 'user_id')
            ->withTimestamps();
    }

    /**
     * Get users who follow this store.
     */
    public function followers()
    {
        return $this->belongsToMany(User::class, 'store_followers', 'store_id', 'user_id')
            ->withTimestamps();
    }

    /**
     * Get the location string.
     */
    public function getLocationAttribute(): string
    {
        return collect([$this->city, $this->state])
            ->filter()
            ->implode(', ');
    }

    /**
     * Scope for featured stores.
     */
    public function scopeFeatured($query)
    {
        return $query->where('is_featured', true);
    }

    /**
     * Scope for sponsored stores.
     */
    public function scopeSponsored($query)
    {
        return $query->where('is_sponsored', true);
    }

    /**
     * Check if the store is saved by the currently authenticated user.
     */
    public function getIsSavedAttribute(): bool
    {
        $user = auth('sanctum')->user();

        if (!$user) {
            return false;
        }

        return $this->savedByUsers()->where('user_id', $user->id)->exists();
    }

    /**
     * Check if the store is followed by the currently authenticated user.
     */
    public function getIsFollowingAttribute(): bool
    {
        $user = auth('sanctum')->user();

        if (!$user) {
            return false;
        }

        return $this->followers()->where('user_id', $user->id)->exists();
    }

    /**
     * Append is_saved and is_following to JSON serialization.
     */
    protected $appends = ['is_saved', 'is_following'];

    /**
     * Update rating based on reviews.
     */
    public function updateRating()
    {
        $avgRating = $this->reviews()->avg('rating') ?? 0;
        $reviewCount = $this->reviews()->count();

        $this->update([
            'rating' => round($avgRating, 1),
            'review_count' => $reviewCount,
        ]);
    }

    /**
     * Update follower count.
     */
    public function updateFollowerCount()
    {
        $this->update([
            'follower_count' => $this->followers()->count(),
        ]);
    }
}

