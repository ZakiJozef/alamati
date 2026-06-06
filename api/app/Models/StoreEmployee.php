<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StoreEmployee extends Model
{
    use HasFactory;

    protected $fillable = [
        'store_id',
        'user_id',
        'title',
        'permissions',
    ];

    protected $casts = [
        'permissions' => 'array',
    ];

    /**
     * Get the store.
     */
    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    /**
     * Get the user (employee).
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Check if employee has a specific permission.
     */
    public function hasPermission(string $permission): bool
    {
        return in_array($permission, $this->permissions ?? []);
    }
}
