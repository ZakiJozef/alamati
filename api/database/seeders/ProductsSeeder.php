<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Product;
use App\Models\Store;

class ProductsSeeder extends Seeder
{
    public function run(): void
    {
        // Get first store
        $store = Store::first();
        if (!$store)
            return;

        // Clear existing products for this store
        Product::where('store_id', $store->id)->delete();

        // Create premium test products
        $products = [
            [
                'name' => 'جهاز مراقبة نوم الطفل - Baby Monitor V30',
                'description' => 'جهاز مراقبة صوتي ثنائي الاتجاه لغرفة الأطفال. يتميز بصوت واضح ومدى بعيد يصل إلى 300 متر. مثالي لراحة البال للوالدين.',
                'price' => 12000.00,
                'discount_price' => 10000.00,
                'image' => 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=600',
                'images' => [
                    'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=600',
                    'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=600',
                    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600',
                    'https://images.unsplash.com/photo-1596461404969-9ae70f2830c1?w=600',
                ],
                'type' => 'product',
                'category' => 'Bébé',
                'stock' => 15,
                'is_active' => true,
            ],
            [
                'name' => 'سماعات بلوتوث لاسلكية - Premium Wireless',
                'description' => 'سماعات لاسلكية عالية الجودة مع إلغاء الضوضاء. بطارية تدوم 30 ساعة. صوت ستيريو نقي ومريحة للارتداء طوال اليوم.',
                'price' => 8500.00,
                'discount_price' => 6500.00,
                'image' => 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600',
                'images' => [
                    'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600',
                    'https://images.unsplash.com/photo-1484704849700-f032a568e944?w=600',
                    'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=600',
                ],
                'type' => 'product',
                'category' => 'Électronique',
                'stock' => 25,
                'is_active' => true,
            ],
            [
                'name' => 'ساعة ذكية - Smart Watch Pro',
                'description' => 'ساعة ذكية متعددة الوظائف مع قياس ضربات القلب وتتبع النوم والرياضة. متوافقة مع Android و iOS. مقاومة للماء.',
                'price' => 15000.00,
                'image' => 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600',
                'images' => [
                    'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600',
                    'https://images.unsplash.com/photo-1434494878577-86c23bcb06b9?w=600',
                ],
                'type' => 'product',
                'category' => 'Électronique',
                'stock' => 10,
                'is_active' => true,
            ],
            [
                'name' => 'حقيبة ظهر عصرية - Urban Backpack',
                'description' => 'حقيبة ظهر أنيقة ومقاومة للماء. مثالية للعمل والسفر. تحتوي على جيوب متعددة وحجرة للحاسوب المحمول.',
                'price' => 4500.00,
                'image' => 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600',
                'images' => [
                    'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600',
                    'https://images.unsplash.com/photo-1622560480654-d96214fdc887?w=600',
                ],
                'type' => 'product',
                'category' => 'Mode',
                'stock' => 30,
                'is_active' => true,
            ],
            [
                'name' => 'خدمة تصميم الجرافيك',
                'description' => 'تصميم شعارات، هوية بصرية، ومنشورات السوشال ميديا. خبرة 10 سنوات في التصميم الاحترافي.',
                'price' => 5000.00,
                'image' => 'https://images.unsplash.com/photo-1626785774573-4b799315345d?w=600',
                'images' => [
                    'https://images.unsplash.com/photo-1626785774573-4b799315345d?w=600',
                    'https://images.unsplash.com/photo-1558655146-d09347e92766?w=600',
                ],
                'type' => 'service',
                'category' => 'Services',
                'stock' => 99,
                'is_active' => true,
            ],
            [
                'name' => 'كاميرا احترافية - DSLR Pro',
                'description' => 'كاميرا رقمية احترافية مع عدسة 24-70mm. مثالية للتصوير الفوتوغرافي والفيديو. دقة 45 ميجابكسل.',
                'price' => 85000.00,
                'discount_price' => 75000.00,
                'image' => 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=600',
                'images' => [
                    'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=600',
                    'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=600',
                    'https://images.unsplash.com/photo-1495745966610-2a67f2297e5e?w=600',
                ],
                'type' => 'product',
                'category' => 'Électronique',
                'stock' => 5,
                'is_active' => true,
            ],
        ];

        foreach ($products as $productData) {
            Product::create(array_merge($productData, ['store_id' => $store->id]));
        }

        $this->command->info('Created ' . count($products) . ' test products');
    }
}
