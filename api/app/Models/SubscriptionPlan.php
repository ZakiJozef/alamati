<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SubscriptionPlan extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'slug',
        'description',
        'price',
        'duration_days',
        'max_stores',
        'max_products',
        'max_portfolio',
        'can_use_sponsored_zones',
        'max_sections',
        'is_active',
        'sort_order',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'is_active' => 'boolean',
        'can_use_sponsored_zones' => 'boolean',
    ];

    /**
     * Get all subscriptions using this plan.
     */
    public function subscriptions()
    {
        return $this->hasMany(Subscription::class, 'plan_id');
    }

    /**
     * Scope for active plans only.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    /**
     * Check if this is the free trial plan.
     */
    public function isFreeTrial(): bool
    {
        return $this->slug === 'free';
    }

    /**
     * Check if products are unlimited.
     */
    public function hasUnlimitedProducts(): bool
    {
        return $this->max_products === -1;
    }

    /**
     * Get formatted price.
     */
    public function getFormattedPriceAttribute(): string
    {
        if ($this->price == 0) {
            return 'Free';
        }
        return number_format((float) $this->price, 0) . ' DA';
    }

    /**
     * Get duration text.
     */
    public function getDurationTextAttribute(): string
    {
        if ($this->duration_days <= 30) {
            return $this->duration_days . ' days';
        }
        $months = intval($this->duration_days / 30);
        if ($months >= 12) {
            $years = intval($months / 12);
            return $years . ' year' . ($years > 1 ? 's' : '');
        }
        return $months . ' months';
    }
}
