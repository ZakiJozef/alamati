<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Product;
use App\Models\Store;

class ServicesSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Get or create a store for services
        $store = Store::first();

        if (!$store) {
            $this->command->error('No store found. Please create a store first.');
            return;
        }

        $services = [
            [
                'name' => 'Plomberie Professionnelle',
                'description' => 'Service de plomberie professionnel pour tous vos besoins. Installation, réparation et maintenance de systèmes de plomberie résidentiels et commerciaux. Intervention rapide 24h/24.',
                'price' => 5000.00,
                'discount_price' => null,
                'type' => 'service',
                'category' => 'Plomberie',
                'is_active' => true,
                'image' => 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=800',
                'images' => json_encode([
                    'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=800',
                    'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=800',
                ]),
            ],
            [
                'name' => 'Maçonnerie et Construction',
                'description' => 'Services de maçonnerie professionnelle. Construction de murs, dalles, fondations et rénovation. Travail de qualité avec des matériaux premium. Devis gratuit disponible.',
                'price' => 15000.00,
                'discount_price' => 12000.00,
                'type' => 'service',
                'category' => 'Construction',
                'is_active' => true,
                'image' => 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800',
                'images' => json_encode([
                    'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800',
                    'https://images.unsplash.com/photo-1541976590-713941681591?w=800',
                ]),
            ],
            [
                'name' => 'Développement Web & Mobile',
                'description' => 'Création de sites web et applications mobiles sur mesure. Technologies modernes: React, Flutter, Laravel. Design responsive et SEO optimisé. Maintenance et support inclus.',
                'price' => 50000.00,
                'discount_price' => null,
                'type' => 'service',
                'category' => 'Informatique',
                'is_active' => true,
                'image' => 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=800',
                'images' => json_encode([
                    'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=800',
                    'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=800',
                ]),
            ],
            [
                'name' => 'Électricité Générale',
                'description' => 'Installation et réparation électrique. Mise aux normes, tableaux électriques, éclairage LED. Techniciens certifiés et intervention rapide.',
                'price' => 8000.00,
                'discount_price' => 6500.00,
                'type' => 'service',
                'category' => 'Électricité',
                'is_active' => true,
                'image' => 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800',
                'images' => json_encode([
                    'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800',
                    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
                ]),
            ],
            [
                'name' => 'Peinture et Décoration',
                'description' => 'Services de peinture intérieure et extérieure. Finitions parfaites, large choix de couleurs. Travail soigné et respect des délais.',
                'price' => 4000.00,
                'discount_price' => null,
                'type' => 'service',
                'category' => 'Décoration',
                'is_active' => true,
                'image' => 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=800',
                'images' => json_encode([
                    'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=800',
                    'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=800',
                ]),
            ],
            [
                'name' => 'Climatisation & Chauffage',
                'description' => 'Installation et maintenance de systèmes de climatisation et chauffage. Pompes à chaleur, climatiseurs split, entretien annuel.',
                'price' => 25000.00,
                'discount_price' => 22000.00,
                'type' => 'service',
                'category' => 'Climatisation',
                'is_active' => true,
                'image' => 'https://images.unsplash.com/photo-1631545806609-42c5e45c5b59?w=800',
                'images' => json_encode([
                    'https://images.unsplash.com/photo-1631545806609-42c5e45c5b59?w=800',
                ]),
            ],
            [
                'name' => 'Menuiserie sur Mesure',
                'description' => 'Fabrication et installation de menuiserie sur mesure. Portes, fenêtres, placards, cuisines. Bois massif et matériaux de qualité.',
                'price' => 35000.00,
                'discount_price' => null,
                'type' => 'service',
                'category' => 'Menuiserie',
                'is_active' => true,
                'image' => 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
                'images' => json_encode([
                    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
                ]),
            ],
            [
                'name' => 'Nettoyage Professionnel',
                'description' => 'Services de nettoyage résidentiel et commercial. Nettoyage en profondeur, vitres, tapis, après travaux. Équipe professionnelle.',
                'price' => 3000.00,
                'discount_price' => 2500.00,
                'type' => 'service',
                'category' => 'Nettoyage',
                'is_active' => true,
                'image' => 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800',
                'images' => json_encode([
                    'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800',
                ]),
            ],
            [
                'name' => 'Transport et Déménagement',
                'description' => 'Service de déménagement complet. Emballage, transport sécurisé, montage/démontage meubles. Prix compétitifs.',
                'price' => 12000.00,
                'discount_price' => null,
                'type' => 'service',
                'category' => 'Transport',
                'is_active' => true,
                'image' => 'https://images.unsplash.com/photo-1600518464441-9154a4dea21b?w=800',
                'images' => json_encode([
                    'https://images.unsplash.com/photo-1600518464441-9154a4dea21b?w=800',
                ]),
            ],
            [
                'name' => 'Jardinage et Espaces Verts',
                'description' => 'Entretien de jardins et espaces verts. Tonte, taille, plantation, arrosage automatique. Création de jardins sur mesure.',
                'price' => 6000.00,
                'discount_price' => 5000.00,
                'type' => 'service',
                'category' => 'Jardinage',
                'is_active' => true,
                'image' => 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800',
                'images' => json_encode([
                    'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800',
                ]),
            ],
            [
                'name' => 'Design Graphique',
                'description' => 'Création de logos, identité visuelle, supports marketing. Designs modernes et professionnels pour votre entreprise.',
                'price' => 15000.00,
                'discount_price' => null,
                'type' => 'service',
                'category' => 'Design',
                'is_active' => true,
                'image' => 'https://images.unsplash.com/photo-1626785774573-4b799315345d?w=800',
                'images' => json_encode([
                    'https://images.unsplash.com/photo-1626785774573-4b799315345d?w=800',
                ]),
            ],
            [
                'name' => 'Cours Particuliers',
                'description' => 'Cours particuliers à domicile. Mathématiques, physique, langues. Enseignants qualifiés et expérimentés. Tous niveaux.',
                'price' => 2000.00,
                'discount_price' => null,
                'type' => 'service',
                'category' => 'Éducation',
                'is_active' => true,
                'image' => 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800',
                'images' => json_encode([
                    'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800',
                ]),
            ],
        ];

        foreach ($services as $service) {
            Product::updateOrCreate(
                ['name' => $service['name'], 'store_id' => $store->id],
                array_merge($service, ['store_id' => $store->id])
            );
        }

        $this->command->info('Created ' . count($services) . ' services successfully!');
    }
}
