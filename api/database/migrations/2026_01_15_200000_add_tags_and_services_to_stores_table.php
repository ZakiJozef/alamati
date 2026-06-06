<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     * 
     * Adds fields to support:
     * - Multiple subcategory selections for stores (store tags)
     * - Service provider toggle and service category selections
     */
    public function up(): void
    {
        Schema::table('stores', function (Blueprint $table) {
            // Store subcategory tags - array of subcategory IDs this store specializes in
            $table->json('subcategory_ids')->nullable()->after('subcategory_id');

            // Service provider toggle - indicates if store also provides services
            $table->boolean('provides_services')->default(false)->after('subcategory_ids');

            // Service category IDs - array of service categories this store can respond to
            $table->json('service_category_ids')->nullable()->after('provides_services');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('stores', function (Blueprint $table) {
            $table->dropColumn(['subcategory_ids', 'provides_services', 'service_category_ids']);
        });
    }
};
