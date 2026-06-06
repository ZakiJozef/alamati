<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->string('category', 50)->nullable()->after('type');
            $table->json('images')->nullable()->after('image'); // Array of image URLs
            $table->integer('stock')->default(0)->after('images');
            $table->boolean('is_active')->default(true)->after('stock');
            $table->decimal('discount_price', 10, 2)->nullable()->after('price');
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn(['category', 'images', 'stock', 'is_active', 'discount_price']);
        });
    }
};
