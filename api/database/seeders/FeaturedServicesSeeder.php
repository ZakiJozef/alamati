<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Product;
use App\Models\FeaturedItem;

class FeaturedServicesSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get first 6 services
        $services = Product::where('type', 'service')
            ->where('is_active', true)
            ->take(6)
            ->get();

        foreach ($services as $index => $service) {
            FeaturedItem::updateOrCreate(
                [
                    'product_id' => $service->id,
                    'zone' => 'trending_services',
                ],
                [
                    'display_order' => $index,
                    'is_active' => true,
                ]
            );
        }

        $this->command->info('Added ' . $services->count() . ' services to trending carousel!');
    }
}
