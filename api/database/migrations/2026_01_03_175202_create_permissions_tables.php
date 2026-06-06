<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Permissions table - defines available permissions
        Schema::create('permissions', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique(); // e.g., 'store.edit', 'chat.read'
            $table->string('display_name'); // e.g., 'Edit Store'
            $table->string('description')->nullable();
            $table->string('group'); // e.g., 'store', 'chat', 'admin'
            $table->timestamps();
        });

        // Role permissions - assigns permissions to roles (admin-managed)
        Schema::create('role_permissions', function (Blueprint $table) {
            $table->id();
            $table->string('role'); // 'super_admin', 'store_owner', 'visitor'
            $table->foreignId('permission_id')->constrained()->onDelete('cascade');
            $table->timestamps();

            $table->unique(['role', 'permission_id']);
        });

        // Store employees - store owner can assign employees with specific permissions
        Schema::create('store_employees', function (Blueprint $table) {
            $table->id();
            $table->foreignId('store_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('title')->nullable(); // e.g., 'Manager', 'Assistant'
            $table->json('permissions')->nullable(); // Array of permission names
            $table->timestamps();

            $table->unique(['store_id', 'user_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('store_employees');
        Schema::dropIfExists('role_permissions');
        Schema::dropIfExists('permissions');
    }
};
