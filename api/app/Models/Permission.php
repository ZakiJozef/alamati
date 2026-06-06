<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Permission extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'display_name',
        'description',
        'group',
    ];

    /**
     * Get all permissions for a role.
     */
    public static function forRole(string $role): array
    {
        return self::join('role_permissions', 'permissions.id', '=', 'role_permissions.permission_id')
            ->where('role_permissions.role', $role)
            ->pluck('permissions.name')
            ->toArray();
    }

    /**
     * Get all permissions grouped by category.
     */
    public static function grouped(): array
    {
        return self::all()
            ->groupBy('group')
            ->map(fn($items) => $items->map(fn($item) => [
                'name' => $item->name,
                'display_name' => $item->display_name,
                'description' => $item->description,
            ])->toArray())
            ->toArray();
    }
}
