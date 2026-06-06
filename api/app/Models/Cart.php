<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Cart extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'store_id',
        'session_id',
    ];

    protected $appends = ['subtotal', 'item_count'];

    /**
     * Get the user that owns the cart.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the store this cart belongs to.
     */
    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    /**
     * Get the cart items.
     */
    public function items()
    {
        return $this->hasMany(CartItem::class);
    }

    /**
     * Calculate cart subtotal.
     */
    public function getSubtotalAttribute(): float
    {
        return $this->items->sum(function ($item) {
            return $item->total_price;
        });
    }

    /**
     * Get total item count.
     */
    public function getItemCountAttribute(): int
    {
        return $this->items->sum('quantity');
    }

    /**
     * Get or create a cart for a user and store.
     */
    public static function getOrCreate(?int $userId, int $storeId, ?string $sessionId = null): Cart
    {
        $query = self::where('store_id', $storeId);

        if ($userId) {
            $query->where('user_id', $userId);
        } elseif ($sessionId) {
            $query->where('session_id', $sessionId);
        } else {
            throw new \InvalidArgumentException('Either user_id or session_id is required');
        }

        $cart = $query->first();

        if (!$cart) {
            $cart = self::create([
                'user_id' => $userId,
                'store_id' => $storeId,
                'session_id' => $sessionId,
            ]);
        }

        return $cart;
    }

    /**
     * Clear cart if it's from a different store.
     */
    public static function clearIfDifferentStore(?int $userId, int $newStoreId, ?string $sessionId = null): void
    {
        $query = self::query();

        if ($userId) {
            $query->where('user_id', $userId);
        } elseif ($sessionId) {
            $query->where('session_id', $sessionId);
        } else {
            return;
        }

        $query->where('store_id', '!=', $newStoreId)->delete();
    }
}
