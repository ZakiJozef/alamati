<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeaturedItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'product_id',
        'zone',
        'display_order',
        'is_active',
        'starts_at',
        'ends_at',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
    ];

    /**
     * Get the product that is featured.
     */
    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    /**
     * Scope for active featured items.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true)
            ->where(function ($q) {
                $q->whereNull('starts_at')
                    ->orWhere('starts_at', '<=', now());
            })
            ->where(function ($q) {
                $q->whereNull('ends_at')
                    ->orWhere('ends_at', '>=', now());
            });
    }

    /**
     * Scope for a specific zone.
     */
    public function scopeInZone($query, $zone)
    {
        return $query->where('zone', $zone);
    }
}
