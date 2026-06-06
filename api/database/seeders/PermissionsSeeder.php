<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PermissionsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $permissions = [
            // Store permissions
            ['name' => 'store.view', 'display_name' => 'View Store', 'description' => 'View store details and analytics', 'group' => 'store'],
            ['name' => 'store.edit', 'display_name' => 'Edit Store', 'description' => 'Edit store details, hours, location', 'group' => 'store'],
            ['name' => 'store.delete', 'display_name' => 'Delete Store', 'description' => 'Delete the store', 'group' => 'store'],

            // Products permissions
            ['name' => 'products.view', 'display_name' => 'View Products', 'description' => 'View store products', 'group' => 'products'],
            ['name' => 'products.manage', 'display_name' => 'Manage Products', 'description' => 'Add, edit, delete products', 'group' => 'products'],

            // Chat permissions
            ['name' => 'chat.read', 'display_name' => 'Read Messages', 'description' => 'Read store messages', 'group' => 'chat'],
            ['name' => 'chat.reply', 'display_name' => 'Reply to Messages', 'description' => 'Reply to customer messages', 'group' => 'chat'],

            // Reviews permissions
            ['name' => 'reviews.view', 'display_name' => 'View Reviews', 'description' => 'View store reviews', 'group' => 'reviews'],
            ['name' => 'reviews.respond', 'display_name' => 'Respond to Reviews', 'description' => 'Respond to customer reviews', 'group' => 'reviews'],

            // Portfolio permissions
            ['name' => 'portfolio.manage', 'display_name' => 'Manage Portfolio', 'description' => 'Add, edit, delete portfolio items', 'group' => 'portfolio'],

            // Employee permissions (store owner only)
            ['name' => 'employees.view', 'display_name' => 'View Employees', 'description' => 'View store employees', 'group' => 'employees'],
            ['name' => 'employees.manage', 'display_name' => 'Manage Employees', 'description' => 'Add, edit, remove employees', 'group' => 'employees'],

            // Admin permissions
            ['name' => 'admin.users', 'display_name' => 'Manage Users', 'description' => 'View and manage all users', 'group' => 'admin'],
            ['name' => 'admin.stores', 'display_name' => 'Manage All Stores', 'description' => 'View and manage all stores', 'group' => 'admin'],
            ['name' => 'admin.reports', 'display_name' => 'View Reports', 'description' => 'View system reports and analytics', 'group' => 'admin'],
        ];

        foreach ($permissions as $permission) {
            DB::table('permissions')->updateOrInsert(
                ['name' => $permission['name']],
                array_merge($permission, [
                    'created_at' => now(),
                    'updated_at' => now(),
                ])
            );
        }

        // Assign default permissions to roles
        $rolePermissions = [
            'super_admin' => [
                'store.view',
                'store.edit',
                'store.delete',
                'products.view',
                'products.manage',
                'chat.read',
                'chat.reply',
                'reviews.view',
                'reviews.respond',
                'portfolio.manage',
                'employees.view',
                'employees.manage',
                'admin.users',
                'admin.stores',
                'admin.reports',
            ],
            'store_owner' => [
                'store.view',
                'store.edit',
                'store.delete',
                'products.view',
                'products.manage',
                'chat.read',
                'chat.reply',
                'reviews.view',
                'reviews.respond',
                'portfolio.manage',
                'employees.view',
                'employees.manage',
            ],
            'visitor' => [
                // Visitors have no special permissions
            ],
        ];

        foreach ($rolePermissions as $role => $permissionNames) {
            foreach ($permissionNames as $permissionName) {
                $permission = DB::table('permissions')->where('name', $permissionName)->first();
                if ($permission) {
                    DB::table('role_permissions')->updateOrInsert(
                        ['role' => $role, 'permission_id' => $permission->id],
                        [
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]
                    );
                }
            }
        }
    }
}
