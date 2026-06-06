<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'store_id',
        'name',
        'description',
        'price',
        'price_unit_id',
        'discount_price',
        'image',
        'images',
        'type',
        'category',
        'category_id',
        'subcategory_id',
        'stock',
        'is_active',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'discount_price' => 'decimal:2',
        'images' => 'array',
        'is_active' => 'boolean',
        'category_id' => 'integer',
        'subcategory_id' => 'integer',
    ];

    protected $appends = ['average_rating', 'reviews_count', 'thumbnail'];

    /**
     * Get the category of the product.
     */
    public function categoryRelation()
    {
        return $this->belongsTo(Category::class, 'category_id');
    }

    /**
     * Get the subcategory of the product.
     */
    public function subcategoryRelation()
    {
        return $this->belongsTo(Category::class, 'subcategory_id');
    }

    /**
     * Get the store that owns this product.
     */
    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    /**
     * Get product reviews.
     */
    public function reviews()
    {
        return $this->hasMany(ProductReview::class);
    }

    /**
     * Get order items for this product.
     */
    public function orderItems()
    {
        return $this->hasMany(OrderItem::class);
    }

    /**
     * Get the price unit for this product/service.
     */
    public function unit()
    {
        return $this->belongsTo(Unit::class, 'price_unit_id');
    }

    /**
     * Get the thumbnail (first image or main image).
     */
    public function getThumbnailAttribute(): ?string
    {
        if ($this->images && count($this->images) > 0) {
            return $this->images[0];
        }
        return $this->image;
    }

    /**
     * Get average rating.
     */
    public function getAverageRatingAttribute(): float
    {
        return round($this->reviews()->avg('rating') ?? 0, 1);
    }

    /**
     * Get reviews count.
     */
    public function getReviewsCountAttribute(): int
    {
        return $this->reviews()->count();
    }

    /**
     * Get effective price (considering discount).
     */
    public function getEffectivePriceAttribute(): float
    {
        return $this->discount_price ?? $this->price;
    }

    /**
     * Scope active products.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}
