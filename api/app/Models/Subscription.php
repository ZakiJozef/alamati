<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Subscription extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'plan_id',
        'status',
        'payment_method',
        'payment_proof',
        'payment_verified',
        'starts_at',
        'expires_at',
        'admin_notes',
        'verified_by',
        'verified_at',
    ];

    protected $casts = [
        'payment_verified' => 'boolean',
        'starts_at' => 'datetime',
        'expires_at' => 'datetime',
        'verified_at' => 'datetime',
    ];

    /**
     * Status constants.
     */
    const STATUS_PENDING = 'pending';
    const STATUS_ACTIVE = 'active';
    const STATUS_EXPIRED = 'expired';
    const STATUS_CANCELLED = 'cancelled';

    /**
     * Payment method constants.
     */
    const PAYMENT_FREE = 'free';
    const PAYMENT_CCP = 'ccp';
    const PAYMENT_BARIDIMOB = 'baridimob';
    const PAYMENT_CASH = 'cash';

    /**
     * Get the user who owns this subscription.
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the subscription plan.
     */
    public function plan()
    {
        return $this->belongsTo(SubscriptionPlan::class, 'plan_id');
    }

    /**
     * Get the admin who verified the payment.
     */
    public function verifiedBy()
    {
        return $this->belongsTo(User::class, 'verified_by');
    }

    /**
     * Check if subscription is active.
     */
    public function isActive(): bool
    {
        return $this->status === self::STATUS_ACTIVE
            && $this->expires_at
            && $this->expires_at->isFuture();
    }

    /**
     * Check if subscription is pending.
     */
    public function isPending(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }

    /**
     * Check if subscription has expired.
     */
    public function isExpired(): bool
    {
        return $this->status === self::STATUS_EXPIRED
            || ($this->expires_at && $this->expires_at->isPast());
    }

    /**
     * Get days remaining.
     */
    public function getDaysRemainingAttribute(): int
    {
        if (!$this->expires_at || $this->expires_at->isPast()) {
            return 0;
        }
        return Carbon::now()->diffInDays($this->expires_at);
    }

    /**
     * Scope for active subscriptions.
     */
    public function scopeActive($query)
    {
        return $query->where('status', self::STATUS_ACTIVE)
            ->where('expires_at', '>', now());
    }

    /**
     * Scope for pending subscriptions.
     */
    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    /**
     * Activate subscription.
     */
    public function activate(?int $verifiedByUserId = null): void
    {
        $this->update([
            'status' => self::STATUS_ACTIVE,
            'payment_verified' => true,
            'starts_at' => now(),
            'expires_at' => now()->addDays($this->plan->duration_days),
            'verified_by' => $verifiedByUserId,
            'verified_at' => now(),
        ]);
    }

    /**
     * Start free trial.
     */
    public function startFreeTrial(): void
    {
        $this->update([
            'status' => self::STATUS_ACTIVE,
            'payment_verified' => true,
            'payment_method' => self::PAYMENT_FREE,
            'starts_at' => now(),
            'expires_at' => now()->addDays($this->plan->duration_days),
        ]);
    }

    /**
     * Get status badge color.
     */
    public function getStatusColorAttribute(): string
    {
        return match ($this->status) {
            self::STATUS_ACTIVE => '#10B981',
            self::STATUS_PENDING => '#F59E0B',
            self::STATUS_EXPIRED => '#EF4444',
            self::STATUS_CANCELLED => '#6B7280',
            default => '#6B7280',
        };
    }

    /**
     * Get payment method label.
     */
    public function getPaymentMethodLabelAttribute(): string
    {
        return match ($this->payment_method) {
            self::PAYMENT_FREE => 'Free Trial',
            self::PAYMENT_CCP => 'CCP',
            self::PAYMENT_BARIDIMOB => 'BaridiMob',
            self::PAYMENT_CASH => 'Cash',
            default => $this->payment_method,
        };
    }
}
