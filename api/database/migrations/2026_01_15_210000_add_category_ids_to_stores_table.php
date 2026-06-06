<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     * 
     * Adds category_ids to support multiple main category selection for stores.
     */
    public function up(): void
    {
        Schema::table('stores', function (Blueprint $table) {
            // Multiple main category IDs - stores can now belong to multiple categories
            $table->json('category_ids')->nullable()->after('category_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('stores', function (Blueprint $table) {
            $table->dropColumn('category_ids');
        });
    }
};
