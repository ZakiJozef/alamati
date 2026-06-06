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
        Schema::table('demands', function (Blueprint $table) {
            // Make wilaya and commune nullable since we now use wilaya_id and commune_id
            $table->string('wilaya')->nullable()->change();
            $table->string('commune')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('demands', function (Blueprint $table) {
            $table->string('wilaya')->nullable(false)->change();
            $table->string('commune')->nullable(false)->change();
        });
    }
};
