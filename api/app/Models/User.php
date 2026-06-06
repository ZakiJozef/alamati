<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'username',
        'email',
        'password',
        'profile_pic',
        'role',
        'pseudoname',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /**
     * Get the user's active subscription.
     */
    public function subscriptions()
    {
        return $this->hasMany(Subscription::class);
    }

    /**
     * Get the user's current active subscription.
     */
    public function activeSubscription()
    {
        return $this->hasOne(Subscription::class)
            ->where('status', 'active')
            ->where('expires_at', '>', now())
            ->latest();
    }

    /**
     * Get the stores owned by this user.
     */
    public function stores()
    {
        return $this->hasMany(Store::class, 'owner_id');
    }

    /**
     * Get the stores saved by this user.
     */
    public function savedStores()
    {
        return $this->belongsToMany(Store::class, 'saved_stores', 'user_id', 'store_id')
            ->withTimestamps();
    }

    /**
     * Get the user's reviews.
     */
    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    /**
     * Get connections (sent requests).
     */
    public function sentConnections()
    {
        return $this->hasMany(Connection::class, 'user_id');
    }

    /**
     * Get connections (received requests).
     */
    public function receivedConnections()
    {
        return $this->hasMany(Connection::class, 'connected_user_id');
    }

    /**
     * Get stores that this user follows.
     */
    public function followedStores()
    {
        return $this->belongsToMany(Store::class, 'store_followers', 'user_id', 'store_id')
            ->withTimestamps();
    }

    /**
     * Check if user is super admin.
     */
    public function isSuperAdmin(): bool
    {
        return $this->role === 'super_admin';
    }

    /**
     * Check if user is store owner.
     */
    public function isStoreOwner(): bool
    {
        return $this->role === 'store_owner';
    }

    /**
     * Get the display name (pseudoname or username).
     */
    public function getDisplayNameAttribute(): string
    {
        return $this->pseudoname ?? $this->username;
    }

    /**
     * Get stores where this user is an employee.
     */
    public function employeeAt()
    {
        return $this->hasMany(StoreEmployee::class);
    }

    /**
     * Check if user has a specific permission based on their role.
     */
    public function hasPermission(string $permission): bool
    {
        $permissions = Permission::forRole($this->role);
        return in_array($permission, $permissions);
    }

    /**
     * Check if user has permission for a specific store.
     * This checks both role-based permissions and employee-specific permissions.
     */
    public function hasStorePermission(Store $store, string $permission): bool
    {
        // Store owner always has all permissions for their stores
        if ($store->owner_id === $this->id) {
            return true;
        }

        // Super admin has all permissions
        if ($this->isSuperAdmin()) {
            return true;
        }

        // Check if user is an employee of this store with the permission
        $employee = StoreEmployee::where('store_id', $store->id)
            ->where('user_id', $this->id)
            ->first();

        if ($employee) {
            return $employee->hasPermission($permission);
        }

        return false;
    }

    /**
     * Get all permissions this user has based on their role.
     */
    public function getPermissions(): array
    {
        return Permission::forRole($this->role);
    }
}

