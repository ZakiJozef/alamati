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
        Schema::table('stores', function (Blueprint $table) {
            // Add foreign key references to wilayas and communes tables
            $table->foreignId('wilaya_id')->nullable()->constrained('wilayas')->onDelete('set null')->after('state');
            $table->foreignId('commune_id')->nullable()->constrained('communes')->onDelete('set null')->after('wilaya_id');

            // Add indexes for faster lookups
            $table->index('wilaya_id');
            $table->index('commune_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('stores', function (Blueprint $table) {
            $table->dropForeign(['commune_id']);
            $table->dropForeign(['wilaya_id']);
            $table->dropColumn(['commune_id', 'wilaya_id']);
        });
    }
};
