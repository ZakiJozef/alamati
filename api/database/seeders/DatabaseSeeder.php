<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Store;
use App\Models\Product;
use App\Models\PortfolioItem;
use App\Models\Review;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Create users
        $admin = User::create([
            'username' => 'admin',
            'email' => 'admin@3alamati.com',
            'password' => Hash::make('password123'),
            'profile_pic' => 'https://api.dicebear.com/7.x/initials/svg?seed=Admin&backgroundColor=137fec',
            'role' => 'super_admin',
            'pseudoname' => 'Super Admin',
        ]);

        $storeOwner = User::create([
            'username' => 'karim_cafe',
            'email' => 'owner@coffeeshop.com',
            'password' => Hash::make('password123'),
            'profile_pic' => 'https://api.dicebear.com/7.x/initials/svg?seed=Karim+B&backgroundColor=22c55e',
            'role' => 'store_owner',
            'pseudoname' => 'Karim Boumediene',
        ]);

        $storeOwner2 = User::create([
            'username' => 'mohamed_auto',
            'email' => 'mohamed@autofix.dz',
            'password' => Hash::make('password123'),
            'profile_pic' => 'https://api.dicebear.com/7.x/initials/svg?seed=Mohamed+A&backgroundColor=f59e0b',
            'role' => 'store_owner',
            'pseudoname' => 'Mohamed Amrani',
        ]);

        $visitor = User::create([
            'username' => 'sara_user',
            'email' => 'user@example.com',
            'password' => Hash::make('password123'),
            'profile_pic' => 'https://api.dicebear.com/7.x/initials/svg?seed=Sara+K&backgroundColor=ec4899',
            'role' => 'visitor',
            'pseudoname' => 'Sara Khaled',
        ]);

        // ========== ALGER STORES ==========

        $cafeAlger = Store::create([
            'owner_id' => $storeOwner->id,
            'name' => 'Café El Djazair',
            'description' => 'Authentic Algerian coffee experience in the heart of Algiers. Traditional espresso, Turkish coffee, and fresh pastries.',
            'cover_image' => 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1559305616-3f99cd43e353?w=400',
            'address' => '15 Rue Didouche Mourad',
            'city' => 'Alger Centre',
            'state' => 'Alger',
            'category' => 'Food & Beverage',
            'phone' => '+213 21 63 45 78',
            'phones' => ['+213 21 63 45 78', '+213 555 123 456'],
            'email' => 'contact@cafeeldjazair.dz',
            'website' => 'https://cafeeldjazair.dz',
            'lat' => 36.7538,
            'lng' => 3.0588,
            'rating' => 4.9,
            'review_count' => 245,
            'is_open' => true,
            'is_featured' => true,
            'is_sponsored' => true,
            'social_links' => ['facebook' => 'cafeeldjazair', 'instagram' => 'cafeeldjazair_dz', 'whatsapp' => '+213555123456'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        Store::create([
            'owner_id' => $storeOwner2->id,
            'name' => 'AutoFix Sidi Moussa',
            'description' => 'Professional auto repair and maintenance. Specialized in European and Japanese vehicles.',
            'cover_image' => 'https://images.unsplash.com/photo-1487754180451-c456f719a1fc?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?w=400',
            'address' => 'Zone Industrielle Sidi Moussa',
            'city' => 'Sidi Moussa',
            'state' => 'Alger',
            'category' => 'Automotive',
            'phone' => '+213 21 50 67 89',
            'email' => 'contact@autofix.dz',
            'lat' => 36.6442,
            'lng' => 3.0825,
            'rating' => 4.7,
            'is_featured' => true,
            'social_links' => ['facebook' => 'autofixdz', 'instagram' => 'autofix_dz'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        $designStudio = Store::create([
            'owner_id' => $storeOwner->id,
            'name' => 'Pixel Studio Algiers',
            'description' => 'Creative digital agency specializing in branding, web design, and UI/UX. Making ideas visible.',
            'cover_image' => 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1560179707-f14e90ef3623?w=400',
            'address' => '42 Boulevard Mohammed V',
            'city' => 'Bab Ezzouar',
            'state' => 'Alger',
            'category' => 'Creative',
            'phone' => '+213 21 24 56 78',
            'email' => 'hello@pixelstudio.dz',
            'website' => 'https://pixelstudio.dz',
            'lat' => 36.7195,
            'lng' => 3.1808,
            'rating' => 5.0,
            'is_featured' => true,
            'is_sponsored' => true,
            'social_links' => ['instagram' => 'pixelstudio_dz', 'linkedin' => 'pixel-studio-algiers', 'behance' => 'pixelstudiodz'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        Store::create([
            'owner_id' => $storeOwner2->id,
            'name' => 'Barber House Hydra',
            'description' => 'Premium barbershop. Modern cuts, classic style, and grooming services.',
            'cover_image' => 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400',
            'address' => '8 Rue des Roses, Hydra',
            'city' => 'Hydra',
            'state' => 'Alger',
            'category' => 'Hair & Beauty',
            'phone' => '+213 23 47 89 12',
            'lat' => 36.7489,
            'lng' => 3.0234,
            'rating' => 4.8,
            'is_featured' => true,
            'social_links' => ['instagram' => 'barberhouse_hydra', 'tiktok' => 'barberhousehydra'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        Store::create([
            'owner_id' => $storeOwner->id,
            'name' => 'TechZone El Harrach',
            'description' => 'Computer sales, repair, and IT services. Gaming PCs, laptops, and accessories.',
            'cover_image' => 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?w=400',
            'address' => 'Centre Commercial El Harrach',
            'city' => 'El Harrach',
            'state' => 'Alger',
            'category' => 'Technology',
            'phone' => '+213 21 52 34 56',
            'email' => 'info@techzone.dz',
            'lat' => 36.7167,
            'lng' => 3.1333,
            'rating' => 4.5,
            'is_featured' => false,
            'social_links' => ['facebook' => 'techzonedz', 'instagram' => 'techzone_dz'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        // ========== ORAN STORES ==========

        Store::create([
            'owner_id' => $storeOwner->id,
            'name' => 'La Corniche Restaurant',
            'description' => 'Seafood restaurant with stunning Mediterranean views. Fresh fish daily, traditional and modern cuisine.',
            'cover_image' => 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?w=400',
            'address' => 'Front de Mer',
            'city' => 'Oran Centre',
            'state' => 'Oran',
            'category' => 'Food & Beverage',
            'phone' => '+213 41 33 45 67',
            'email' => 'reservation@lacorniche.dz',
            'lat' => 35.6969,
            'lng' => -0.6331,
            'rating' => 4.8,
            'is_featured' => true,
            'is_sponsored' => true,
            'social_links' => ['facebook' => 'lacornicheoran', 'instagram' => 'lacorniche_oran'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        Store::create([
            'owner_id' => $storeOwner2->id,
            'name' => 'Mode Express Oran',
            'description' => 'Fashion boutique with the latest trends. Men and women clothing, accessories, and shoes.',
            'cover_image' => 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?w=400',
            'address' => 'Rue Larbi Ben M\'hidi',
            'city' => 'Oran Centre',
            'state' => 'Oran',
            'category' => 'Retail',
            'phone' => '+213 41 29 87 65',
            'lat' => 35.6971,
            'lng' => -0.6308,
            'rating' => 4.6,
            'is_featured' => true,
            'social_links' => ['instagram' => 'modeexpress_oran', 'facebook' => 'modeexpressoran'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        Store::create([
            'owner_id' => $storeOwner->id,
            'name' => 'Clinique Dentaire Arzew',
            'description' => 'Modern dental clinic with the latest equipment. General dentistry, orthodontics, and cosmetic treatments.',
            'cover_image' => 'https://images.unsplash.com/photo-1629909613957-f178e3eab7f1?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=400',
            'address' => '23 Avenue de la Liberté',
            'city' => 'Arzew',
            'state' => 'Oran',
            'category' => 'Health',
            'phone' => '+213 41 47 23 45',
            'email' => 'rdv@cliniquedentaire-arzew.dz',
            'lat' => 35.8500,
            'lng' => -0.2833,
            'rating' => 4.9,
            'is_featured' => false,
            'social_links' => ['facebook' => 'cliniquedentairearzew'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        Store::create([
            'owner_id' => $storeOwner2->id,
            'name' => 'Sport Zone Es Senia',
            'description' => 'Sports equipment and activewear. Nike, Adidas, Puma certified retailer.',
            'cover_image' => 'https://images.unsplash.com/photo-1556906781-9a412961c28c?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
            'address' => 'Centre Commercial Es Senia',
            'city' => 'Es Senia',
            'state' => 'Oran',
            'category' => 'Retail',
            'phone' => '+213 41 58 90 12',
            'lat' => 35.6472,
            'lng' => -0.6278,
            'rating' => 4.4,
            'is_featured' => true,
            'social_links' => ['instagram' => 'sportzone_essenia'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        Store::create([
            'owner_id' => $storeOwner->id,
            'name' => 'Auto École Bir El Djir',
            'description' => 'Professional driving school. Cars, motorcycles, and trucks. 95% success rate.',
            'cover_image' => 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1602055639782-2b1c1a6dfed7?w=400',
            'address' => '15 Boulevard de la Révolution',
            'city' => 'Bir El Djir',
            'state' => 'Oran',
            'category' => 'Education',
            'phone' => '+213 41 80 12 34',
            'lat' => 35.7167,
            'lng' => -0.5500,
            'rating' => 4.7,
            'is_featured' => false,
            'social_links' => ['facebook' => 'autoecolebireldjir'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        // ========== BLIDA STORES ==========

        Store::create([
            'owner_id' => $storeOwner->id,
            'name' => 'Pâtisserie El Mitidja',
            'description' => 'Traditional Algerian pastries and French patisserie. Wedding cakes, special orders.',
            'cover_image' => 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400',
            'address' => 'Place du 1er Novembre',
            'city' => 'Blida Centre',
            'state' => 'Blida',
            'category' => 'Food & Beverage',
            'phone' => '+213 25 41 23 56',
            'lat' => 36.4697,
            'lng' => 2.8289,
            'rating' => 4.9,
            'is_featured' => true,
            'is_sponsored' => true,
            'social_links' => ['facebook' => 'patisserieelmitidja', 'instagram' => 'elmitidja_patisserie'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        Store::create([
            'owner_id' => $storeOwner2->id,
            'name' => 'Chréa Outdoor Adventures',
            'description' => 'Mountain excursions, hiking gear, and outdoor equipment. Certified mountain guides.',
            'cover_image' => 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1527004013197-933c4bb611b3?w=400',
            'address' => 'Route de Chréa',
            'city' => 'Chréa',
            'state' => 'Blida',
            'category' => 'Services',
            'phone' => '+213 25 49 78 90',
            'email' => 'adventure@chrea-outdoor.dz',
            'lat' => 36.4378,
            'lng' => 2.8794,
            'rating' => 4.8,
            'is_featured' => true,
            'social_links' => ['instagram' => 'chrea_adventures', 'facebook' => 'chreaoutdoor'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        Store::create([
            'owner_id' => $storeOwner->id,
            'name' => 'Pharmacie Centrale Boufarik',
            'description' => 'Pharmacy and parapharmacy. Medicine, cosmetics, baby products. Open 7/7.',
            'cover_image' => 'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=400',
            'address' => 'Avenue de l\'Indépendance',
            'city' => 'Boufarik',
            'state' => 'Blida',
            'category' => 'Health',
            'phone' => '+213 25 33 12 45',
            'lat' => 36.5747,
            'lng' => 2.9108,
            'rating' => 4.5,
            'is_featured' => false,
            'social_links' => ['facebook' => 'pharmaciecentraleboufarik'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        Store::create([
            'owner_id' => $storeOwner2->id,
            'name' => 'Fleuriste Les Roses de Mitidja',
            'description' => 'Fresh flowers, bouquets, and floral arrangements. Wedding decoration services.',
            'cover_image' => 'https://images.unsplash.com/photo-1487530811176-3780de880c2d?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400',
            'address' => 'Rue des Fleurs',
            'city' => 'Blida Centre',
            'state' => 'Blida',
            'category' => 'Retail',
            'phone' => '+213 25 42 78 90',
            'lat' => 36.4703,
            'lng' => 2.8277,
            'rating' => 4.7,
            'is_featured' => true,
            'social_links' => ['instagram' => 'rosesdemitidja', 'facebook' => 'lesrosesdemitidja'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        Store::create([
            'owner_id' => $storeOwner->id,
            'name' => 'Institut de Beauté Laaroussa',
            'description' => 'Beauty salon and spa. Hammam, facial treatments, hair styling, and bridal services.',
            'cover_image' => 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400',
            'address' => 'Cité 1000 Logements',
            'city' => 'Mouzaia',
            'state' => 'Blida',
            'category' => 'Hair & Beauty',
            'phone' => '+213 25 55 67 89',
            'lat' => 36.4656,
            'lng' => 2.6831,
            'rating' => 4.6,
            'is_featured' => false,
            'social_links' => ['instagram' => 'laaroussa_beaute'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        // ========== CHLEF STORES ==========

        Store::create([
            'owner_id' => $storeOwner->id,
            'name' => 'Restaurant El Asnam',
            'description' => 'Traditional Algerian cuisine. Couscous, rechta, and grilled meats. Family dining.',
            'cover_image' => 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
            'address' => 'Avenue Emir Abdelkader',
            'city' => 'Chlef Centre',
            'state' => 'Chlef',
            'category' => 'Food & Beverage',
            'phone' => '+213 27 77 12 34',
            'lat' => 36.1654,
            'lng' => 1.3339,
            'rating' => 4.7,
            'is_featured' => true,
            'is_sponsored' => true,
            'social_links' => ['facebook' => 'restaurantelasnam'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        Store::create([
            'owner_id' => $storeOwner2->id,
            'name' => 'Électro Ménager Plus',
            'description' => 'Home appliances. Refrigerators, washing machines, TVs. Delivery and installation included.',
            'cover_image' => 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
            'address' => 'Zone d\'activité Chettia',
            'city' => 'Chettia',
            'state' => 'Chlef',
            'category' => 'Retail',
            'phone' => '+213 27 79 45 67',
            'lat' => 36.1972,
            'lng' => 1.2611,
            'rating' => 4.4,
            'is_featured' => true,
            'social_links' => ['facebook' => 'electromenagerplus_chlef'],
            'map_url' => 'https://maps.app.goo.gl/WUxsRWmZMSECYtuDA',
        ]);

        Store::create([
            'owner_id' => $storeOwner->id,
            'name' => 'Lycée Privé El Nour',
            'description' => 'Private tutoring and preparation courses. Bac, BEM, primary school support.',
            'cover_image' => 'https://images.unsplash.com/photo-1523580494863-6f3031224c94?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=400',
            'address' => '45 Rue du Stade',
            'city' => 'Ténès',
            'state' => 'Chlef',
            'category' => 'Education',
            'phone' => '+213 27 76 89 01',
            'lat' => 36.5153,
            'lng' => 1.3067,
            'rating' => 4.8,
            'is_featured' => true,
            'social_links' => ['facebook' => 'lyceeprive_elnour'],
        ]);

        Store::create([
            'owner_id' => $storeOwner2->id,
            'name' => 'Garage Benali Ouled Fares',
            'description' => 'Auto mechanic specialized in diesel engines. Trucks, buses, agricultural equipment.',
            'cover_image' => 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1580828343064-fde4fc206bc6?w=400',
            'address' => 'RN4 Ouled Fares',
            'city' => 'Ouled Fares',
            'state' => 'Chlef',
            'category' => 'Automotive',
            'phone' => '+213 27 78 23 45',
            'lat' => 36.2333,
            'lng' => 1.0833,
            'rating' => 4.5,
            'is_featured' => false,
            'social_links' => ['facebook' => 'garagebenali'],
        ]);

        Store::create([
            'owner_id' => $storeOwner->id,
            'name' => 'Bijouterie El Andalous',
            'description' => 'Gold and silver jewelry. Traditional Algerian designs and modern styles. Custom orders.',
            'cover_image' => 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800',
            'profile_image' => 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=400',
            'address' => 'Marché Central',
            'city' => 'Chlef Centre',
            'state' => 'Chlef',
            'category' => 'Retail',
            'phone' => '+213 27 77 56 78',
            'lat' => 36.1658,
            'lng' => 1.3342,
            'rating' => 4.6,
            'is_featured' => true,
            'social_links' => ['instagram' => 'bijouterie_elandalous', 'facebook' => 'elandalousjewelry'],
        ]);

        // Create products for Café El Djazair
        Product::create(['store_id' => $cafeAlger->id, 'name' => 'Espresso Traditionnel', 'description' => 'Strong Algerian espresso with cardamom.', 'price' => 150, 'image' => 'https://images.unsplash.com/photo-1510707577719-ae7c14805e3a?w=400', 'type' => 'product']);
        Product::create(['store_id' => $cafeAlger->id, 'name' => 'Café Turc', 'description' => 'Turkish-style coffee, rich and aromatic.', 'price' => 200, 'image' => 'https://images.unsplash.com/photo-1512568400610-62da28bc8a13?w=400', 'type' => 'product']);
        Product::create(['store_id' => $cafeAlger->id, 'name' => 'Makroud', 'description' => 'Traditional semolina cookies with dates.', 'price' => 100, 'image' => 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400', 'type' => 'product']);
        Product::create(['store_id' => $cafeAlger->id, 'name' => 'Event Catering', 'description' => 'Coffee and pastry catering for events.', 'price' => 15000, 'image' => 'https://images.unsplash.com/photo-1511920170033-f8396924c348?w=400', 'type' => 'service']);

        // Create portfolio items for Pixel Studio
        PortfolioItem::create(['store_id' => $designStudio->id, 'title' => 'Sonatrach Brand Refresh', 'description' => 'Corporate branding project for energy sector.', 'image' => 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=600']);
        PortfolioItem::create(['store_id' => $designStudio->id, 'title' => 'E-commerce App', 'description' => 'Mobile shopping app for local marketplace.', 'image' => 'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=600']);
        PortfolioItem::create(['store_id' => $designStudio->id, 'title' => 'Restaurant Menu Design', 'description' => 'Menu and visual identity for upscale restaurant.', 'image' => 'https://images.unsplash.com/photo-1558655146-9f40138edfeb?w=600']);
        PortfolioItem::create(['store_id' => $designStudio->id, 'title' => 'Tourism Website', 'description' => 'Booking platform for Algerian destinations.', 'image' => 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=600']);

        // Create reviews
        Review::create(['store_id' => $cafeAlger->id, 'user_id' => $visitor->id, 'rating' => 5, 'comment' => 'Meilleur café d\'Alger! L\'ambiance est magnifique.']);
        Review::create(['store_id' => $designStudio->id, 'user_id' => $visitor->id, 'rating' => 5, 'comment' => 'Travail professionnel et équipe créative. Recommandé!']);

        // Save stores for visitor
        $visitor->savedStores()->attach([1, 2, 3, 5, 7, 10]);
    }
}
