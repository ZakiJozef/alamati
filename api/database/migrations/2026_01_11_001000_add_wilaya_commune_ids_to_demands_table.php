<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('demands', function (Blueprint $table) {
            // Add foreign key references to wilayas and communes tables
            $table->foreignId('wilaya_id')->nullable()->constrained('wilayas')->onDelete('set null')->after('phone');
            $table->foreignId('commune_id')->nullable()->constrained('communes')->onDelete('set null')->after('wilaya_id');

            // Add indexes for performance
            $table->index('wilaya_id');
            $table->index('commune_id');
        });
    }

    public function down(): void
    {
        Schema::table('demands', function (Blueprint $table) {
            $table->dropForeign(['commune_id']);
            $table->dropForeign(['wilaya_id']);
            $table->dropColumn(['commune_id', 'wilaya_id']);
        });
    }
};
