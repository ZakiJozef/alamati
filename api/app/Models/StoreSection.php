<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StoreSection extends Model
{
    use HasFactory;

    // Section types
    const TYPE_SLIDER = 'slider';
    const TYPE_SPONSORED_SLIDER = 'sponsored_slider';
    const TYPE_FEATURED_TRENDING = 'featured_trending';
    const TYPE_SPONSORED_ZONE = 'sponsored_zone';
    const TYPE_COUNTDOWN = 'countdown';
    const TYPE_PRODUCT_GRID = 'product_grid';

    protected $fillable = [
        'store_id',
        'type',
        'title',
        'sort_order',
        'is_active',
        'config',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'config' => 'array',
    ];

    /**
     * Get the store that owns the section.
     */
    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    /**
     * Get the products in this section.
     */
    public function products()
    {
        return $this->belongsToMany(Product::class, 'store_section_products', 'section_id', 'product_id')
            ->withPivot('sort_order')
            ->orderBy('store_section_products.sort_order')
            ->withTimestamps();
    }

    /**
     * Check if this is a sponsored section type.
     */
    public function isSponsored(): bool
    {
        return in_array($this->type, [self::TYPE_SPONSORED_SLIDER, self::TYPE_SPONSORED_ZONE]);
    }

    /**
     * Get countdown end time from config (for countdown sections).
     */
    public function getCountdownEndAttribute()
    {
        if ($this->type !== self::TYPE_COUNTDOWN) {
            return null;
        }

        $endTime = $this->config['end_time'] ?? null;
        return $endTime ? \Carbon\Carbon::parse($endTime) : null;
    }

    /**
     * Check if countdown is still active.
     */
    public function isCountdownActive(): bool
    {
        $end = $this->countdown_end;
        return $end && $end->isFuture();
    }

    /**
     * Get available section types.
     */
    public static function getTypes(): array
    {
        return [
            self::TYPE_SLIDER => 'Product Slider',
            self::TYPE_SPONSORED_SLIDER => 'Sponsored Slider',
            self::TYPE_FEATURED_TRENDING => 'Featured / Trending / Top Rated',
            self::TYPE_SPONSORED_ZONE => 'Sponsored Zone',
            self::TYPE_COUNTDOWN => 'Countdown Sale',
            self::TYPE_PRODUCT_GRID => 'Product Grid',
        ];
    }

    /**
     * Get types that require Gold subscription.
     */
    public static function getSponsoredTypes(): array
    {
        return [
            self::TYPE_SPONSORED_SLIDER,
            self::TYPE_SPONSORED_ZONE,
        ];
    }
}
