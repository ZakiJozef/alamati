<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\SubscriptionPlan;

class SubscriptionPlanSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $plans = [
            [
                'name' => 'Free Trial',
                'slug' => 'free',
                'description' => 'Start your journey with a 15-day free trial. Perfect for testing the platform.',
                'price' => 0,
                'duration_days' => 15,
                'max_stores' => 1,
                'max_products' => 10,
                'max_portfolio' => 3,
                'is_active' => true,
                'sort_order' => 1,
            ],
            [
                'name' => 'Silver',
                'slug' => 'silver',
                'description' => 'Ideal for small businesses. Get started with essential features.',
                'price' => 3500,
                'duration_days' => 365,
                'max_stores' => 1,
                'max_products' => 10,
                'max_portfolio' => 3,
                'is_active' => true,
                'sort_order' => 2,
            ],
            [
                'name' => 'Gold',
                'slug' => 'gold',
                'description' => 'For growing businesses. Unlimited products, multiple stores, and sponsored zones.',
                'price' => 4500,
                'duration_days' => 365,
                'max_stores' => 10,
                'max_products' => -1, // -1 means unlimited
                'max_portfolio' => 10,
                'can_use_sponsored_zones' => true,
                'max_sections' => -1, // unlimited
                'is_active' => true,
                'sort_order' => 3,
            ],
        ];

        foreach ($plans as $plan) {
            SubscriptionPlan::updateOrCreate(
                ['slug' => $plan['slug']],
                $plan
            );
        }
    }
}
