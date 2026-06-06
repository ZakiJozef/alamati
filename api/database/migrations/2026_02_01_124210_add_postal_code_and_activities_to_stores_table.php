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
            if (!Schema::hasColumn('stores', 'postal_code')) {
                $table->string('postal_code')->nullable()->after('address');
            }
            if (!Schema::hasColumn('stores', 'activities')) {
                $table->text('activities')->nullable()->after('description');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('stores', function (Blueprint $table) {
            if (Schema::hasColumn('stores', 'postal_code')) {
                $table->dropColumn('postal_code');
            }
            if (Schema::hasColumn('stores', 'activities')) {
                $table->dropColumn('activities');
            }
        });
    }
};
