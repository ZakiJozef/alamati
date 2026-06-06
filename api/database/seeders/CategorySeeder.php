<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Store Categories
        $storeCategories = [
            [
                'emoji' => '🍽️',
                'name' => 'Alimentation & Boissons',
                'subcategories' => [
                    'Épicerie',
                    'Supérette',
                    'Boulangerie / Pâtisserie',
                    'Boucherie / Poissonnerie',
                    'Cafétéria / Salon de thé',
                    'Restaurant',
                    'Fast-food',
                    'Glacier',
                ]
            ],
            [
                'emoji' => '👗',
                'name' => 'Mode & Accessoires',
                'subcategories' => [
                    'Vêtements',
                    'Chaussures',
                    'Bijouterie',
                    'Maroquinerie',
                    'Accessoires de mode',
                    'Tenues traditionnelles',
                ]
            ],
            [
                'emoji' => '💄',
                'name' => 'Beauté & Bien-être',
                'subcategories' => [
                    'Cosmétique',
                    'Parfumerie',
                    'Salon de coiffure',
                    'Institut de beauté',
                    'Spa / Hammam',
                    'Produits naturels',
                ]
            ],
            [
                'emoji' => '📱',
                'name' => 'Électronique & Technologie',
                'subcategories' => [
                    'Téléphonie',
                    'Informatique',
                    'Accessoires électroniques',
                    'Gaming',
                    'Audio & Vidéo',
                ]
            ],
            [
                'emoji' => '🏠',
                'name' => 'Maison & Déco',
                'subcategories' => [
                    'Meubles',
                    'Décoration',
                    'Articles de cuisine',
                    'Luminaires',
                    'Literie',
                ]
            ],
            [
                'emoji' => '🛠️',
                'name' => 'Bricolage & Services techniques',
                'subcategories' => [
                    'Bricolage',
                    'Plomberie',
                    'Électricité',
                    'Peinture',
                    'Climatisation',
                ]
            ],
            [
                'emoji' => '🚗',
                'name' => 'Auto & Moto',
                'subcategories' => [
                    'Garage automobile',
                    'Pièces auto',
                    'Accessoires auto',
                    'Lavage auto',
                    'Location de véhicules',
                ]
            ],
            [
                'emoji' => '🧑‍💼',
                'name' => 'Services Professionnels',
                'subcategories' => [
                    'Services informatiques',
                    'Design & création',
                    'Marketing & communication',
                    'Comptabilité',
                    'Services juridiques',
                ]
            ],
            [
                'emoji' => '🏠',
                'name' => 'Services à Domicile',
                'subcategories' => [
                    'Nettoyage',
                    'Réparation',
                    'Déménagement',
                    'Jardinage',
                    'Maintenance générale',
                ]
            ],
            [
                'emoji' => '🎓',
                'name' => 'Éducation & Culture',
                'subcategories' => [
                    'Librairie',
                    'Papeterie',
                    'Centre de formation',
                    'Cours particuliers',
                ]
            ],
            [
                'emoji' => '🏥',
                'name' => 'Santé & Médical',
                'subcategories' => [
                    'Pharmacie',
                    'Parapharmacie',
                    'Cabinet médical',
                    'Opticien',
                    'Matériel médical',
                ]
            ],
            [
                'emoji' => '👶',
                'name' => 'Bébé & Enfant',
                'subcategories' => [
                    'Articles bébé',
                    'Jouets',
                    'Vêtements enfant',
                    'Crèche / Garderie',
                ]
            ],
            [
                'emoji' => '🐾',
                'name' => 'Animaux',
                'subcategories' => [
                    'Animalerie',
                    'Produits pour animaux',
                    'Clinique vétérinaire',
                ]
            ],
            [
                'emoji' => '🏋️',
                'name' => 'Sport & Loisirs',
                'subcategories' => [
                    'Salle de sport',
                    'Articles de sport',
                    'Club sportif',
                ]
            ],
            [
                'emoji' => '🎮',
                'name' => 'Divertissement & Loisirs',
                'subcategories' => [
                    'Jeux vidéo',
                    'Loisirs & hobbies',
                    'Événementiel',
                ]
            ],
            [
                'emoji' => '✈️',
                'name' => 'Voyage & Services',
                'subcategories' => [
                    'Agence de voyage',
                    'Hébergement',
                    'Transport touristique',
                ]
            ],
            [
                'emoji' => '🏢',
                'name' => 'Immobilier',
                'subcategories' => [
                    'Agence immobilière',
                    'Promotion immobilière',
                ]
            ],
            [
                'emoji' => '🏭',
                'name' => 'Industrie & B2B',
                'subcategories' => [
                    'Fournitures industrielles',
                    'Équipements professionnels',
                ]
            ],
            [
                'emoji' => '🛍️',
                'name' => 'Autres',
                'subcategories' => [
                    'Boutique spécialisée',
                    'Produits artisanaux',
                    'Cadeaux & souvenirs',
                    'Multi-services',
                ]
            ],
        ];

        $this->seedCategories($storeCategories, 'store');

        // Product Categories
        $productCategories = [
            [
                'emoji' => '🏪',
                'name' => 'Alimentation & Boissons',
                'subcategories' => [
                    'Épiceries & Supérettes',
                    'Boulangeries & Pâtisseries',
                    'Fruits & Légumes',
                    'Boucheries & Poissonneries',
                    'Produits laitiers',
                    'Produits bio & naturels',
                    'Boissons & Jus',
                    'Cafés, Thés & Chocolats',
                    'Produits importés',
                ]
            ],
            [
                'emoji' => '👗',
                'name' => 'Mode & Habillement',
                'subcategories' => [
                    'Vêtements Homme',
                    'Vêtements Femme',
                    'Vêtements Enfant',
                    'Chaussures',
                    'Sacs & Maroquinerie',
                    'Sous-vêtements',
                    'Tenues traditionnelles',
                    'Accessoires de mode',
                ]
            ],
            [
                'emoji' => '💄',
                'name' => 'Beauté & Bien-être',
                'subcategories' => [
                    'Parfums',
                    'Cosmétiques & maquillage',
                    'Produits capillaires',
                    'Soins visage & corps',
                    'Instituts de beauté',
                    'Salons de coiffure',
                    'Spas & Hammams',
                    'Produits naturels',
                ]
            ],
            [
                'emoji' => '📱',
                'name' => 'Électronique & High-Tech',
                'subcategories' => [
                    'Téléphones & Smartphones',
                    'Accessoires mobiles',
                    'Ordinateurs & Tablettes',
                    'Périphériques & accessoires',
                    'TV & Audio',
                    'Caméras & Sécurité',
                    'Gaming & Consoles',
                    'Réseaux & Internet',
                ]
            ],
            [
                'emoji' => '🏠',
                'name' => 'Maison & Déco',
                'subcategories' => [
                    'Meubles',
                    'Décoration intérieure',
                    'Luminaires',
                    'Rideaux & Tapis',
                    'Literie',
                    'Articles de cuisine',
                    'Rangement & Organisation',
                    'Jardin & Extérieur',
                ]
            ],
            [
                'emoji' => '🔧',
                'name' => 'Bricolage & Construction',
                'subcategories' => [
                    'Outils & Matériel',
                    'Électricité',
                    'Plomberie',
                    'Peinture & Revêtements',
                    'Menuiserie',
                    'Matériaux de construction',
                    'Serrurerie',
                    'Services de réparation',
                ]
            ],
            [
                'emoji' => '🚗',
                'name' => 'Auto & Moto',
                'subcategories' => [
                    'Véhicules (vente)',
                    'Pièces détachées',
                    'Accessoires auto',
                    'Pneus & Batteries',
                    'Lavage auto',
                    'Mécanique & Diagnostic',
                    'Location de véhicules',
                    'Moto & Scooters',
                ]
            ],
            [
                'emoji' => '🧑‍💻',
                'name' => 'Services Professionnels',
                'subcategories' => [
                    'Développement web & mobile',
                    'Design graphique',
                    'Marketing digital',
                    'Comptabilité & Finance',
                    'Services juridiques',
                    'Ressources humaines',
                    'Conseil & Business',
                    'Traduction & rédaction',
                ]
            ],
            [
                'emoji' => '🛠️',
                'name' => 'Services à Domicile',
                'subcategories' => [
                    'Plomberie',
                    'Électricité',
                    'Peinture',
                    'Nettoyage',
                    'Déménagement',
                    'Climatisation & chauffage',
                    'Réparation électroménager',
                    'Jardinage',
                ]
            ],
            [
                'emoji' => '🎓',
                'name' => 'Éducation & Formation',
                'subcategories' => [
                    'Cours particuliers',
                    'Langues',
                    'Informatique',
                    'Formation professionnelle',
                    'Coaching',
                    'Soutien scolaire',
                    'Centres de formation',
                    'Préparation examens',
                ]
            ],
            [
                'emoji' => '🏥',
                'name' => 'Santé & Médical',
                'subcategories' => [
                    'Pharmacies',
                    'Parapharmacie',
                    'Cliniques & cabinets',
                    'Analyses médicales',
                    'Opticiens',
                    'Matériel médical',
                    'Soins à domicile',
                    'Bien-être & thérapies',
                ]
            ],
            [
                'emoji' => '👶',
                'name' => 'Bébé & Enfant',
                'subcategories' => [
                    'Vêtements bébé',
                    'Jouets',
                    'Poussettes & accessoires',
                    'Produits d\'hygiène',
                    'Meubles bébé',
                    'Éducation & loisirs',
                    'Garde d\'enfants',
                ]
            ],
            [
                'emoji' => '🐾',
                'name' => 'Animaux',
                'subcategories' => [
                    'Nourriture animaux',
                    'Accessoires animaux',
                    'Vétérinaires',
                    'Toilettage',
                    'Dressage',
                    'Animaux domestiques',
                ]
            ],
            [
                'emoji' => '🏋️',
                'name' => 'Sport & Loisirs',
                'subcategories' => [
                    'Fitness & Musculation',
                    'Sports collectifs',
                    'Sports individuels',
                    'Vêtements sport',
                    'Équipements sportifs',
                    'Clubs & salles de sport',
                    'Loisirs & hobbies',
                ]
            ],
            [
                'emoji' => '🎮',
                'name' => 'Jeux, Culture & Divertissement',
                'subcategories' => [
                    'Jeux vidéo',
                    'Consoles',
                    'Jeux de société',
                    'Livres & librairies',
                    'Musique & instruments',
                    'Cinéma & événements',
                    'Arts & artisanat',
                ]
            ],
            [
                'emoji' => '✈️',
                'name' => 'Voyage & Services Touristiques',
                'subcategories' => [
                    'Agences de voyage',
                    'Hôtels & hébergement',
                    'Location vacances',
                    'Transport touristique',
                    'Guides & excursions',
                    'Billetterie',
                ]
            ],
            [
                'emoji' => '🏢',
                'name' => 'Immobilier',
                'subcategories' => [
                    'Vente immobilière',
                    'Location immobilière',
                    'Agences immobilières',
                    'Gestion de biens',
                    'Promotion immobilière',
                ]
            ],
            [
                'emoji' => '🛍️',
                'name' => 'Boutiques & Magasins Spécialisés',
                'subcategories' => [
                    'Produits artisanaux',
                    'Produits locaux',
                    'Import-export',
                    'Cadeaux & souvenirs',
                    'Articles personnalisés',
                ]
            ],
            [
                'emoji' => '⚙️',
                'name' => 'Industrie & B2B',
                'subcategories' => [
                    'Machines & équipements',
                    'Fournitures industrielles',
                    'Sécurité & protection',
                    'Logistique & transport',
                    'Services industriels',
                ]
            ],
        ];

        $this->seedCategories($productCategories, 'product');

        // Service Categories
        $serviceCategories = [
            [
                'name' => 'Construction',
                'icon' => 'construction',
                'color' => '#795548',
                'image_url' => 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400',
                'subcategories' => [
                    ['name' => 'Maçonnerie', 'name_en' => 'Masonry'],
                    ['name' => 'Gros œuvre', 'name_en' => 'Main structural work'],
                    ['name' => 'Charpente bois et tuile', 'name_en' => 'Wooden framework and tiling'],
                    ['name' => 'Démolition', 'name_en' => 'Demolition'],
                    ['name' => 'Terrassement', 'name_en' => 'Earthworks/Excavation'],
                    ['name' => 'Construction de piscine', 'name_en' => 'Pool construction'],
                    ['name' => 'Couvre-joint de dilatation', 'name_en' => 'Expansion joint covers'],
                    ['name' => 'Carottage', 'name_en' => 'Core drilling'],
                ],
            ],
            [
                'name' => 'Plomberie et Froid',
                'icon' => 'plumbing',
                'color' => '#2196F3',
                'image_url' => 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400',
                'subcategories' => [
                    ['name' => 'Plomberie', 'name_en' => 'Plumbing'],
                    ['name' => 'Réparation chauffage', 'name_en' => 'Heating repair'],
                    ['name' => 'Réparation frigo', 'name_en' => 'Fridge repair'],
                    ['name' => 'Réparation machine à laver', 'name_en' => 'Washing machine repair'],
                    ['name' => 'Réparation lave vaisselle', 'name_en' => 'Dishwasher repair'],
                    ['name' => 'Climatisation', 'name_en' => 'AC repair & installation'],
                    ['name' => 'Réparation four/cuisinière', 'name_en' => 'Oven and stove repair'],
                    ['name' => 'Réparation robots ménagers', 'name_en' => 'Food processor repair'],
                    ['name' => 'Réparation machine à café', 'name_en' => 'Coffee machine repair'],
                    ['name' => 'Chambres froides', 'name_en' => 'Cold room maintenance'],
                ],
            ],
            [
                'name' => 'Sécurité et Électricité',
                'icon' => 'electrical_services',
                'color' => '#FFC107',
                'image_url' => 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400',
                'subcategories' => [
                    ['name' => 'Électricité', 'name_en' => 'Electricity'],
                    ['name' => 'Caméras de surveillance', 'name_en' => 'CCTV installation'],
                    ['name' => 'Alarmes anti-intrusion', 'name_en' => 'Intruder alarms'],
                    ['name' => 'Systèmes anti-incendie', 'name_en' => 'Fire safety systems'],
                    ['name' => 'Portail électrique', 'name_en' => 'Electric gates'],
                    ['name' => 'Interphone/Visiophone', 'name_en' => 'Intercom and video entry'],
                    ['name' => 'Domotique', 'name_en' => 'Smart Home'],
                    ['name' => 'Parabole', 'name_en' => 'Satellite dish'],
                ],
            ],
            [
                'name' => 'Informatique et Réseaux',
                'icon' => 'computer',
                'color' => '#9C27B0',
                'image_url' => 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=400',
                'subcategories' => [
                    ['name' => 'Programmation web', 'name_en' => 'Web programming'],
                    ['name' => 'Programmation mobile', 'name_en' => 'Mobile programming'],
                    ['name' => 'Réseaux informatiques', 'name_en' => 'Computer networks'],
                    ['name' => 'Cybersécurité', 'name_en' => 'Cybersecurity'],
                    ['name' => 'Réparation ordinateurs', 'name_en' => 'Computer repair'],
                    ['name' => 'Réparation téléphone', 'name_en' => 'Phone repair'],
                    ['name' => 'Réparation TV', 'name_en' => 'TV repair'],
                    ['name' => 'Rédaction web', 'name_en' => 'Web content writing'],
                ],
            ],
            [
                'name' => 'Image et Marketing',
                'icon' => 'campaign',
                'color' => '#E91E63',
                'image_url' => 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400',
                'subcategories' => [
                    ['name' => 'Impression numérique', 'name_en' => 'Digital printing'],
                    ['name' => 'Photographie', 'name_en' => 'Photography'],
                    ['name' => 'Vidéographie', 'name_en' => 'Videography'],
                    ['name' => 'Impression textile', 'name_en' => 'Textile printing'],
                    ['name' => 'Découpe CNC', 'name_en' => 'CNC cutting'],
                    ['name' => 'Community Management', 'name_en' => 'Community Management'],
                    ['name' => 'Infographie', 'name_en' => 'Graphic design'],
                    ['name' => 'Montage vidéo', 'name_en' => 'Video editing'],
                    ['name' => 'Voix off', 'name_en' => 'Voiceover'],
                    ['name' => 'Publicité digitale', 'name_en' => 'Digital ads'],
                    ['name' => 'Traduction', 'name_en' => 'Translation'],
                ],
            ],
            [
                'name' => 'Événements et Mariages',
                'icon' => 'celebration',
                'color' => '#FF5722',
                'image_url' => 'https://images.unsplash.com/photo-1519741497674-611481863552?w=400',
                'subcategories' => [
                    ['name' => 'Habilleuse de mariées', 'name_en' => 'Bridal dresser (Machta)'],
                    ['name' => 'Gâteaux sur commande', 'name_en' => 'Custom cakes'],
                    ['name' => 'Cuisinier', 'name_en' => 'Chef/Cook'],
                    ['name' => 'Maquillage et coiffure', 'name_en' => 'Makeup and hair'],
                    ['name' => 'Couture sur mesure', 'name_en' => 'Custom tailoring'],
                    ['name' => 'Cake design', 'name_en' => 'Cake design'],
                    ['name' => 'Décoration des fêtes', 'name_en' => 'Party decoration'],
                    ['name' => 'Clown/Animation', 'name_en' => 'Clown/Entertainment'],
                ],
            ],
            [
                'name' => 'Étude et Ingénierie',
                'icon' => 'architecture',
                'color' => '#607D8B',
                'image_url' => 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=400',
                'subcategories' => [
                    ['name' => 'Architecture', 'name_en' => 'Architecture'],
                    ['name' => 'Génie civil', 'name_en' => 'Civil engineering'],
                    ['name' => 'Étude de sol', 'name_en' => 'Soil analysis'],
                    ['name' => 'Topographie', 'name_en' => 'Topography'],
                    ['name' => 'Panneaux solaires', 'name_en' => 'Solar panels'],
                    ['name' => 'Travaux publics', 'name_en' => 'Public works'],
                ],
            ],
            [
                'name' => 'Santé',
                'icon' => 'medical_services',
                'color' => '#4CAF50',
                'image_url' => 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=400',
                'subcategories' => [
                    ['name' => 'Soins infirmiers', 'name_en' => 'Home nursing care'],
                    ['name' => 'Garde malade', 'name_en' => 'Caregiver'],
                    ['name' => 'Médecin à domicile', 'name_en' => 'Home doctor visits'],
                    ['name' => 'Transport sanitaire', 'name_en' => 'Medical transport'],
                    ['name' => 'Hijama', 'name_en' => 'Cupping therapy'],
                    ['name' => 'Psychologue en ligne', 'name_en' => 'Online psychologist'],
                    ['name' => 'Médecine alternative', 'name_en' => 'Alternative medicine'],
                    ['name' => 'Kinésithérapie', 'name_en' => 'Home physiotherapy'],
                ],
            ],
            [
                'name' => 'Conseil et Consultation',
                'icon' => 'support_agent',
                'color' => '#3F51B5',
                'image_url' => 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=400',
                'subcategories' => [
                    ['name' => 'Conseil juridique', 'name_en' => 'Legal advice'],
                    ['name' => 'Comptabilité', 'name_en' => 'Accounting'],
                ],
            ],
            [
                'name' => 'Métallerie',
                'icon' => 'hardware',
                'color' => '#757575',
                'image_url' => 'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=400',
                'subcategories' => [
                    ['name' => 'Soudure', 'name_en' => 'Welding'],
                    ['name' => 'Ferronnerie', 'name_en' => 'Ironwork'],
                    ['name' => 'Serrurerie', 'name_en' => 'Locksmithing'],
                    ['name' => 'Charpente métallique', 'name_en' => 'Metal framework'],
                ],
            ],
            [
                'name' => 'Entretien et Nettoyage',
                'icon' => 'cleaning_services',
                'color' => '#00BCD4',
                'image_url' => 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400',
                'subcategories' => [
                    ['name' => 'Nettoyage', 'name_en' => 'Cleaning'],
                    ['name' => 'Jardinage', 'name_en' => 'Gardening'],
                    ['name' => 'Traitement des nuisibles', 'name_en' => 'Pest control'],
                    ['name' => 'Débouchage canalisations', 'name_en' => 'Drain unblocking'],
                    ['name' => 'Nettoyage façades', 'name_en' => 'Facade cleaning'],
                ],
            ],
            [
                'name' => 'Portes, Fenêtres et Meubles',
                'icon' => 'door_front',
                'color' => '#8D6E63',
                'image_url' => 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
                'subcategories' => [
                    ['name' => 'Menuiserie bois', 'name_en' => 'Woodworking'],
                    ['name' => 'Menuiserie aluminium/PVC', 'name_en' => 'Aluminium & PVC joinery'],
                    ['name' => 'Vitrerie et miroiterie', 'name_en' => 'Glazing and mirrors'],
                    ['name' => 'Montage de meubles', 'name_en' => 'Furniture assembly'],
                ],
            ],
            [
                'name' => 'Automobile',
                'icon' => 'directions_car',
                'color' => '#F44336',
                'image_url' => 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=400',
                'subcategories' => [
                    ['name' => 'Mécanique auto', 'name_en' => 'Auto mechanics'],
                    ['name' => 'Électricité auto', 'name_en' => 'Auto electricity'],
                    ['name' => 'Carrosserie auto', 'name_en' => 'Auto bodywork'],
                    ['name' => 'Pare-brise et vitrage', 'name_en' => 'Windshield repair'],
                    ['name' => 'Lavage auto à domicile', 'name_en' => 'Home car wash'],
                    ['name' => 'Réparation motos/scooters', 'name_en' => 'Motorcycle repair'],
                ],
            ],
        ];

        $this->seedServiceCategories($serviceCategories);
    }

    /**
     * Seed store/product categories with simple subcategories.
     */
    private function seedCategories(array $categories, string $type): void
    {
        foreach ($categories as $index => $cat) {
            $parent = Category::create([
                'type' => $type,
                'name' => $cat['name'],
                'emoji' => $cat['emoji'] ?? null,
                'sort_order' => $index,
                'is_active' => true,
            ]);

            foreach ($cat['subcategories'] as $subIndex => $subName) {
                Category::create([
                    'type' => $type,
                    'parent_id' => $parent->id,
                    'name' => $subName,
                    'sort_order' => $subIndex,
                    'is_active' => true,
                ]);
            }
        }
    }

    /**
     * Seed service categories with more detailed subcategories.
     */
    private function seedServiceCategories(array $categories): void
    {
        foreach ($categories as $index => $cat) {
            $parent = Category::create([
                'type' => 'service',
                'name' => $cat['name'],
                'icon' => $cat['icon'] ?? null,
                'color' => $cat['color'] ?? null,
                'image_url' => $cat['image_url'] ?? null,
                'sort_order' => $index,
                'is_active' => true,
            ]);

            foreach ($cat['subcategories'] as $subIndex => $sub) {
                Category::create([
                    'type' => 'service',
                    'parent_id' => $parent->id,
                    'name' => $sub['name'],
                    'name_en' => $sub['name_en'] ?? null,
                    'sort_order' => $subIndex,
                    'is_active' => true,
                ]);
            }
        }
    }
}
