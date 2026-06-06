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
        Schema::create('subscription_plans', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // Free Trial, Silver, Gold
            $table->string('slug')->unique(); // free, silver, gold
            $table->text('description')->nullable();
            $table->decimal('price', 10, 2)->default(0); // Price in DA
            $table->integer('duration_days')->default(365); // Duration in days
            $table->integer('max_stores')->default(1); // Max stores allowed
            $table->integer('max_products')->default(10); // Max products per store (-1 for unlimited)
            $table->integer('max_portfolio')->default(3); // Max portfolio items per store
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('subscription_plans');
    }
};
