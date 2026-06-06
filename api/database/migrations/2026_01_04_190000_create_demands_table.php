<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('demands', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('title');
            $table->text('description');
            $table->string('phone');
            $table->string('wilaya');
            $table->string('commune')->nullable();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->json('images')->nullable();
            $table->string('service_category')->nullable();
            $table->string('service_type')->nullable();
            $table->enum('status', ['open', 'closed', 'expired'])->default('open');
            $table->boolean('is_anonymous')->default(false);
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();

            $table->index(['status', 'created_at']);
            $table->index('user_id');
            $table->index('service_category');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('demands');
    }
};
