<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('set null');
            $table->foreignId('store_id')->constrained()->onDelete('cascade');
            $table->string('order_number', 20)->unique();
            $table->enum('status', ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'])->default('pending');

            // Customer info
            $table->string('full_name', 100);
            $table->string('phone', 20);
            $table->string('wilaya', 50);
            $table->string('commune', 100);
            $table->text('address')->nullable();
            $table->text('notes')->nullable();

            // Totals
            $table->decimal('subtotal', 10, 2);
            $table->decimal('shipping_fee', 10, 2)->default(0);
            $table->decimal('total', 10, 2);
            $table->string('payment_method', 20)->default('cod'); // Cash on delivery

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
