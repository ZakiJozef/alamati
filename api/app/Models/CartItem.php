<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CartItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'cart_id',
        'product_id',
        'quantity',
    ];

    protected $appends = ['total_price', 'unit_price'];

    protected $with = ['product'];

    /**
     * Get the cart this item belongs to.
     */
    public function cart()
    {
        return $this->belongsTo(Cart::class);
    }

    /**
     * Get the product.
     */
    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    /**
     * Get the effective unit price.
     */
    public function getUnitPriceAttribute(): float
    {
        if (!$this->product)
            return 0.0;
        return (float) ($this->product->discount_price ?? $this->product->price);
    }

    /**
     * Calculate total price for this item.
     */
    public function getTotalPriceAttribute(): float
    {
        return $this->unit_price * $this->quantity;
    }
}
