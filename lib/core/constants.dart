import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  // API Configuration
  // API Configuration
  // For Android emulator use 10.0.2.2 (special alias to host machine)
  // For physical device use your computer's local IP (e.g., 192.168.0.51)
  
  // Production URL for Web
  static const String _prodUrl = 'https://api.3alamati.com';
  
  static const String _pcIp = '192.168.0.51'; // Your PC's IP on local network
  
  // Use Production URL
  static String get apiBaseUrl => '$_prodUrl/api';
  
  // Laravel Reverb WebSocket Configuration
  static String get reverbHost => 'api.3alamati.com';
  static const int reverbPort = 6001; // Note: On production, this might need to be 80/443 if proxied
  static const String reverbKey = '3alamati-key';
  
  // For local development, use ws (non-secure)
  static String get reverbWsUrl => 
      'ws://$reverbHost:$reverbPort/app/$reverbKey?protocol=7&client=flutter&version=1.0';
  
  // Google Maps API Key
  static const String googleMapsApiKey = 'AIzaSyAgDAOe2QhEcyV6ixVtJx6Hwztu2VvukTc';

  // User Roles
  static const String roleSuperAdmin = 'super_admin';
  static const String roleStoreOwner = 'store_owner';
  static const String roleVisitor = 'visitor';

  // Social Media Platforms
  static const List<SocialPlatform> socialPlatforms = [
    SocialPlatform(key: 'facebook', name: 'Facebook', icon: 'facebook', color: 0xFF1877F2),
    SocialPlatform(key: 'instagram', name: 'Instagram', icon: 'instagram', color: 0xFFE4405F),
    SocialPlatform(key: 'whatsapp', name: 'WhatsApp', icon: 'whatsapp', color: 0xFF25D366),
    SocialPlatform(key: 'viber', name: 'Viber', icon: 'viber', color: 0xFF7360F2),
    SocialPlatform(key: 'tiktok', name: 'TikTok', icon: 'tiktok', color: 0xFF000000),
    SocialPlatform(key: 'snapchat', name: 'Snapchat', icon: 'snapchat', color: 0xFFFFFC00),
    SocialPlatform(key: 'linkedin', name: 'LinkedIn', icon: 'linkedin', color: 0xFF0A66C2),
    SocialPlatform(key: 'youtube', name: 'YouTube', icon: 'youtube', color: 0xFFFF0000),
  ];

  // Store Categories (Hierarchical - 2 levels)
  static const List<StoreCategory> storeCategories = [
    StoreCategory(emoji: '🍽️', name: 'Alimentation & Boissons', subcategories: [
      'Épicerie', 'Supérette', 'Boulangerie / Pâtisserie', 'Boucherie / Poissonnerie',
      'Cafétéria / Salon de thé', 'Restaurant', 'Fast-food', 'Glacier',
    ]),
    StoreCategory(emoji: '👗', name: 'Mode & Accessoires', subcategories: [
      'Vêtements', 'Chaussures', 'Bijouterie', 'Maroquinerie',
      'Accessoires de mode', 'Tenues traditionnelles',
    ]),
    StoreCategory(emoji: '💄', name: 'Beauté & Bien-être', subcategories: [
      'Cosmétique', 'Parfumerie', 'Salon de coiffure', 'Institut de beauté',
      'Spa / Hammam', 'Produits naturels',
    ]),
    StoreCategory(emoji: '📱', name: 'Électronique & Technologie', subcategories: [
      'Téléphonie', 'Informatique', 'Accessoires électroniques', 'Gaming', 'Audio & Vidéo',
    ]),
    StoreCategory(emoji: '🏠', name: 'Maison & Déco', subcategories: [
      'Meubles', 'Décoration', 'Articles de cuisine', 'Luminaires', 'Literie',
    ]),
    StoreCategory(emoji: '🛠️', name: 'Bricolage & Services techniques', subcategories: [
      'Bricolage', 'Plomberie', 'Électricité', 'Peinture', 'Climatisation',
    ]),
    StoreCategory(emoji: '🚗', name: 'Auto & Moto', subcategories: [
      'Garage automobile', 'Pièces auto', 'Accessoires auto', 'Lavage auto', 'Location de véhicules',
    ]),
    StoreCategory(emoji: '🧑‍💼', name: 'Services Professionnels', subcategories: [
      'Services informatiques', 'Design & création', 'Marketing & communication',
      'Comptabilité', 'Services juridiques',
    ]),
    StoreCategory(emoji: '🏠', name: 'Services à Domicile', subcategories: [
      'Nettoyage', 'Réparation', 'Déménagement', 'Jardinage', 'Maintenance générale',
    ]),
    StoreCategory(emoji: '🎓', name: 'Éducation & Culture', subcategories: [
      'Librairie', 'Papeterie', 'Centre de formation', 'Cours particuliers',
    ]),
    StoreCategory(emoji: '🏥', name: 'Santé & Médical', subcategories: [
      'Pharmacie', 'Parapharmacie', 'Cabinet médical', 'Opticien', 'Matériel médical',
    ]),
    StoreCategory(emoji: '👶', name: 'Bébé & Enfant', subcategories: [
      'Articles bébé', 'Jouets', 'Vêtements enfant', 'Crèche / Garderie',
    ]),
    StoreCategory(emoji: '🐾', name: 'Animaux', subcategories: [
      'Animalerie', 'Produits pour animaux', 'Clinique vétérinaire',
    ]),
    StoreCategory(emoji: '🏋️', name: 'Sport & Loisirs', subcategories: [
      'Salle de sport', 'Articles de sport', 'Club sportif',
    ]),
    StoreCategory(emoji: '🎮', name: 'Divertissement & Loisirs', subcategories: [
      'Jeux vidéo', 'Loisirs & hobbies', 'Événementiel',
    ]),
    StoreCategory(emoji: '✈️', name: 'Voyage & Services', subcategories: [
      'Agence de voyage', 'Hébergement', 'Transport touristique',
    ]),
    StoreCategory(emoji: '🏢', name: 'Immobilier', subcategories: [
      'Agence immobilière', 'Promotion immobilière',
    ]),
    StoreCategory(emoji: '🏭', name: 'Industrie & B2B', subcategories: [
      'Fournitures industrielles', 'Équipements professionnels',
    ]),
    StoreCategory(emoji: '🛍️', name: 'Autres', subcategories: [
      'Boutique spécialisée', 'Produits artisanaux', 'Cadeaux & souvenirs', 'Multi-services',
    ]),
  ];

  /// Get flat list of store category names (for simple dropdowns)
  static List<String> get storeCategoryNames => 
      storeCategories.map((c) => c.name).toList();

  /// Get subcategories for a given store category
  static List<String> getStoreSubcategories(String categoryName) {
    final category = storeCategories.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => const StoreCategory(emoji: '', name: '', subcategories: []),
    );
    return category.subcategories;
  }

  // Legacy categories list (for backward compatibility)
  static List<String> get categories => storeCategoryNames;

  // Product Categories (Hierarchical - 2 levels)
  static const List<ProductCategory> productCategories = [
    ProductCategory(emoji: '🏪', name: 'Alimentation & Boissons', subcategories: [
      'Épiceries & Supérettes', 'Boulangeries & Pâtisseries', 'Fruits & Légumes',
      'Boucheries & Poissonneries', 'Produits laitiers', 'Produits bio & naturels',
      'Boissons & Jus', 'Cafés, Thés & Chocolats', 'Produits importés',
    ]),
    ProductCategory(emoji: '👗', name: 'Mode & Habillement', subcategories: [
      'Vêtements Homme', 'Vêtements Femme', 'Vêtements Enfant', 'Chaussures',
      'Sacs & Maroquinerie', 'Sous-vêtements', 'Tenues traditionnelles', 'Accessoires de mode',
    ]),
    ProductCategory(emoji: '💄', name: 'Beauté & Bien-être', subcategories: [
      'Parfums', 'Cosmétiques & maquillage', 'Produits capillaires',
      'Soins visage & corps', 'Instituts de beauté', 'Salons de coiffure',
      'Spas & Hammams', 'Produits naturels',
    ]),
    ProductCategory(emoji: '📱', name: 'Électronique & High-Tech', subcategories: [
      'Téléphones & Smartphones', 'Accessoires mobiles', 'Ordinateurs & Tablettes',
      'Périphériques & accessoires', 'TV & Audio', 'Caméras & Sécurité',
      'Gaming & Consoles', 'Réseaux & Internet',
    ]),
    ProductCategory(emoji: '🏠', name: 'Maison & Déco', subcategories: [
      'Meubles', 'Décoration intérieure', 'Luminaires', 'Rideaux & Tapis',
      'Literie', 'Articles de cuisine', 'Rangement & Organisation', 'Jardin & Extérieur',
    ]),
    ProductCategory(emoji: '🔧', name: 'Bricolage & Construction', subcategories: [
      'Outils & Matériel', 'Électricité', 'Plomberie', 'Peinture & Revêtements',
      'Menuiserie', 'Matériaux de construction', 'Serrurerie', 'Services de réparation',
    ]),
    ProductCategory(emoji: '🚗', name: 'Auto & Moto', subcategories: [
      'Véhicules (vente)', 'Pièces détachées', 'Accessoires auto', 'Pneus & Batteries',
      'Lavage auto', 'Mécanique & Diagnostic', 'Location de véhicules', 'Moto & Scooters',
    ]),
    ProductCategory(emoji: '🧑‍💻', name: 'Services Professionnels', subcategories: [
      'Développement web & mobile', 'Design graphique', 'Marketing digital',
      'Comptabilité & Finance', 'Services juridiques', 'Ressources humaines',
      'Conseil & Business', 'Traduction & rédaction',
    ]),
    ProductCategory(emoji: '🛠️', name: 'Services à Domicile', subcategories: [
      'Plomberie', 'Électricité', 'Peinture', 'Nettoyage', 'Déménagement',
      'Climatisation & chauffage', 'Réparation électroménager', 'Jardinage',
    ]),
    ProductCategory(emoji: '🎓', name: 'Éducation & Formation', subcategories: [
      'Cours particuliers', 'Langues', 'Informatique', 'Formation professionnelle',
      'Coaching', 'Soutien scolaire', 'Centres de formation', 'Préparation examens',
    ]),
    ProductCategory(emoji: '🏥', name: 'Santé & Médical', subcategories: [
      'Pharmacies', 'Parapharmacie', 'Cliniques & cabinets', 'Analyses médicales',
      'Opticiens', 'Matériel médical', 'Soins à domicile', 'Bien-être & thérapies',
    ]),
    ProductCategory(emoji: '👶', name: 'Bébé & Enfant', subcategories: [
      'Vêtements bébé', 'Jouets', 'Poussettes & accessoires', 'Produits d\'hygiène',
      'Meubles bébé', 'Éducation & loisirs', 'Garde d\'enfants',
    ]),
    ProductCategory(emoji: '🐾', name: 'Animaux', subcategories: [
      'Nourriture animaux', 'Accessoires animaux', 'Vétérinaires',
      'Toilettage', 'Dressage', 'Animaux domestiques',
    ]),
    ProductCategory(emoji: '🏋️', name: 'Sport & Loisirs', subcategories: [
      'Fitness & Musculation', 'Sports collectifs', 'Sports individuels',
      'Vêtements sport', 'Équipements sportifs', 'Clubs & salles de sport', 'Loisirs & hobbies',
    ]),
    ProductCategory(emoji: '🎮', name: 'Jeux, Culture & Divertissement', subcategories: [
      'Jeux vidéo', 'Consoles', 'Jeux de société', 'Livres & librairies',
      'Musique & instruments', 'Cinéma & événements', 'Arts & artisanat',
    ]),
    ProductCategory(emoji: '✈️', name: 'Voyage & Services Touristiques', subcategories: [
      'Agences de voyage', 'Hôtels & hébergement', 'Location vacances',
      'Transport touristique', 'Guides & excursions', 'Billetterie',
    ]),
    ProductCategory(emoji: '🏢', name: 'Immobilier', subcategories: [
      'Vente immobilière', 'Location immobilière', 'Agences immobilières',
      'Gestion de biens', 'Promotion immobilière',
    ]),
    ProductCategory(emoji: '🛍️', name: 'Boutiques & Magasins Spécialisés', subcategories: [
      'Produits artisanaux', 'Produits locaux', 'Import-export',
      'Cadeaux & souvenirs', 'Articles personnalisés',
    ]),
    ProductCategory(emoji: '⚙️', name: 'Industrie & B2B', subcategories: [
      'Machines & équipements', 'Fournitures industrielles', 'Sécurité & protection',
      'Logistique & transport', 'Services industriels',
    ]),
  ];

  /// Get flat list of product category names (for simple dropdowns)
  static List<String> get productCategoryNames => 
      productCategories.map((c) => c.name).toList();

  /// Get subcategories for a given product category
  static List<String> getProductSubcategories(String categoryName) {
    final category = productCategories.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => const ProductCategory(emoji: '', name: '', subcategories: []),
    );
    return category.subcategories;
  }

  // Service Categories with subcategories
  static const List<ServiceCategory> serviceCategories = [
    ServiceCategory(
      name: 'Construction',
      icon: 'construction',
      color: 0xFF795548,
      imageUrl: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400',
      services: [
        ServiceType(name: 'Maçonnerie', nameEn: 'Masonry', imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=300'),
        ServiceType(name: 'Gros œuvre', nameEn: 'Main structural work', imageUrl: 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?w=300'),
        ServiceType(name: 'Charpente bois et tuile', nameEn: 'Wooden framework and tiling', imageUrl: 'https://images.unsplash.com/photo-1632759145351-1d592919f522?w=300'),
        ServiceType(name: 'Démolition', nameEn: 'Demolition', imageUrl: 'https://images.unsplash.com/photo-1590274853856-f8f0f545f6e3?w=300'),
        ServiceType(name: 'Terrassement', nameEn: 'Earthworks/Excavation', imageUrl: 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?w=300'),
        ServiceType(name: 'Construction de piscine', nameEn: 'Pool construction', imageUrl: 'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?w=300'),
        ServiceType(name: 'Couvre-joint de dilatation', nameEn: 'Expansion joint covers', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
        ServiceType(name: 'Carottage', nameEn: 'Core drilling', imageUrl: 'https://images.unsplash.com/photo-1572981779307-38b8cabb2407?w=300'),
      ],
    ),
    ServiceCategory(
      name: 'Plomberie et Froid',
      icon: 'plumbing',
      color: 0xFF2196F3,
      imageUrl: 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400',
      services: [
        ServiceType(name: 'Plomberie', nameEn: 'Plumbing', imageUrl: 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=300'),
        ServiceType(name: 'Réparation chauffage', nameEn: 'Heating repair', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
        ServiceType(name: 'Réparation frigo', nameEn: 'Fridge repair', imageUrl: 'https://images.unsplash.com/photo-1571175443880-49e1d25b2bc5?w=300'),
        ServiceType(name: 'Réparation machine à laver', nameEn: 'Washing machine repair', imageUrl: 'https://images.unsplash.com/photo-1626806787461-102c1bfaaea1?w=300'),
        ServiceType(name: 'Réparation lave vaisselle', nameEn: 'Dishwasher repair', imageUrl: 'https://images.unsplash.com/photo-1585659722983-3a680e3e5c12?w=300'),
        ServiceType(name: 'Climatisation', nameEn: 'AC repair & installation', imageUrl: 'https://images.unsplash.com/photo-1631545806609-95dce28c7ef8?w=300'),
        ServiceType(name: 'Réparation four/cuisinière', nameEn: 'Oven and stove repair', imageUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=300'),
        ServiceType(name: 'Réparation robots ménagers', nameEn: 'Food processor repair', imageUrl: 'https://images.unsplash.com/photo-1570222094114-d054a817e56b?w=300'),
        ServiceType(name: 'Réparation machine à café', nameEn: 'Coffee machine repair', imageUrl: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=300'),
        ServiceType(name: 'Chambres froides', nameEn: 'Cold room maintenance', imageUrl: 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=300'),
      ],
    ),
    ServiceCategory(
      name: 'Sécurité et Électricité',
      icon: 'electrical_services',
      color: 0xFFFFC107,
      imageUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400',
      services: [
        ServiceType(name: 'Électricité', nameEn: 'Electricity', imageUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=300'),
        ServiceType(name: 'Caméras de surveillance', nameEn: 'CCTV installation', imageUrl: 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?w=300'),
        ServiceType(name: 'Alarmes anti-intrusion', nameEn: 'Intruder alarms', imageUrl: 'https://images.unsplash.com/photo-1558002038-1055907df827?w=300'),
        ServiceType(name: 'Systèmes anti-incendie', nameEn: 'Fire safety systems', imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca49df?w=300'),
        ServiceType(name: 'Portail électrique', nameEn: 'Electric gates', imageUrl: 'https://images.unsplash.com/photo-1548247416-ec66f4900b2e?w=300'),
        ServiceType(name: 'Interphone/Visiophone', nameEn: 'Intercom and video entry', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
        ServiceType(name: 'Domotique', nameEn: 'Smart Home', imageUrl: 'https://images.unsplash.com/photo-1558002038-c6dd27b77c32?w=300'),
        ServiceType(name: 'Parabole', nameEn: 'Satellite dish', imageUrl: 'https://images.unsplash.com/photo-1614064641938-3bbee52942c7?w=300'),
      ],
    ),
    ServiceCategory(
      name: 'Informatique et Réseaux',
      icon: 'computer',
      color: 0xFF9C27B0,
      imageUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=400',
      services: [
        ServiceType(name: 'Programmation web', nameEn: 'Web programming', imageUrl: 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=300'),
        ServiceType(name: 'Programmation mobile', nameEn: 'Mobile programming', imageUrl: 'https://images.unsplash.com/photo-1526498460520-4c246339dccb?w=300'),
        ServiceType(name: 'Réseaux informatiques', nameEn: 'Computer networks', imageUrl: 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=300'),
        ServiceType(name: 'Cybersécurité', nameEn: 'Cybersecurity', imageUrl: 'https://images.unsplash.com/photo-1614064641938-3bbee52942c7?w=300'),
        ServiceType(name: 'Réparation ordinateurs', nameEn: 'Computer repair', imageUrl: 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=300'),
        ServiceType(name: 'Réparation téléphone', nameEn: 'Phone repair', imageUrl: 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=300'),
        ServiceType(name: 'Réparation TV', nameEn: 'TV repair', imageUrl: 'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=300'),
        ServiceType(name: 'Rédaction web', nameEn: 'Web content writing', imageUrl: 'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=300'),
      ],
    ),
    ServiceCategory(
      name: 'Image et Marketing',
      icon: 'campaign',
      color: 0xFFE91E63,
      imageUrl: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400',
      services: [
        ServiceType(name: 'Impression numérique', nameEn: 'Digital printing', imageUrl: 'https://images.unsplash.com/photo-1562408590-e32931084e23?w=300'),
        ServiceType(name: 'Photographie', nameEn: 'Photography', imageUrl: 'https://images.unsplash.com/photo-1542038784456-1ea8e935640e?w=300'),
        ServiceType(name: 'Vidéographie', nameEn: 'Videography', imageUrl: 'https://images.unsplash.com/photo-1579566346927-c68383817a62?w=300'),
        ServiceType(name: 'Impression textile', nameEn: 'Textile printing', imageUrl: 'https://images.unsplash.com/photo-1558171813-4c088753af8f?w=300'),
        ServiceType(name: 'Découpe CNC', nameEn: 'CNC cutting', imageUrl: 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=300'),
        ServiceType(name: 'Community Management', nameEn: 'Community Management', imageUrl: 'https://images.unsplash.com/photo-1611162617474-5b21e879e113?w=300'),
        ServiceType(name: 'Infographie', nameEn: 'Graphic design', imageUrl: 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=300'),
        ServiceType(name: 'Montage vidéo', nameEn: 'Video editing', imageUrl: 'https://images.unsplash.com/photo-1574717024653-61fd2cf4d44d?w=300'),
        ServiceType(name: 'Voix off', nameEn: 'Voiceover', imageUrl: 'https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=300'),
        ServiceType(name: 'Publicité digitale', nameEn: 'Digital ads', imageUrl: 'https://images.unsplash.com/photo-1432888622747-4eb9a8efeb07?w=300'),
        ServiceType(name: 'Traduction', nameEn: 'Translation', imageUrl: 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=300'),
      ],
    ),
    ServiceCategory(
      name: 'Événements et Mariages',
      icon: 'celebration',
      color: 0xFFFF5722,
      imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=400',
      services: [
        ServiceType(name: 'Habilleuse de mariées', nameEn: 'Bridal dresser (Machta)', imageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=300'),
        ServiceType(name: 'Gâteaux sur commande', nameEn: 'Custom cakes', imageUrl: 'https://images.unsplash.com/photo-1535254973040-607b474cb50d?w=300'),
        ServiceType(name: 'Cuisinier', nameEn: 'Chef/Cook', imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=300'),
        ServiceType(name: 'Maquillage et coiffure', nameEn: 'Makeup and hair', imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=300'),
        ServiceType(name: 'Couture sur mesure', nameEn: 'Custom tailoring', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
        ServiceType(name: 'Cake design', nameEn: 'Cake design', imageUrl: 'https://images.unsplash.com/photo-1562440499-64c9a111f713?w=300'),
        ServiceType(name: 'Décoration des fêtes', nameEn: 'Party decoration', imageUrl: 'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=300'),
        ServiceType(name: 'Clown/Animation', nameEn: 'Clown/Entertainment', imageUrl: 'https://images.unsplash.com/photo-1527529482837-4698179dc6ce?w=300'),
      ],
    ),
    ServiceCategory(
      name: 'Étude et Ingénierie',
      icon: 'architecture',
      color: 0xFF607D8B,
      imageUrl: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=400',
      services: [
        ServiceType(name: 'Architecture', nameEn: 'Architecture', imageUrl: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=300'),
        ServiceType(name: 'Génie civil', nameEn: 'Civil engineering', imageUrl: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=300'),
        ServiceType(name: 'Étude de sol', nameEn: 'Soil analysis', imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=300'),
        ServiceType(name: 'Topographie', nameEn: 'Topography', imageUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=300'),
        ServiceType(name: 'Panneaux solaires', nameEn: 'Solar panels', imageUrl: 'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=300'),
        ServiceType(name: 'Travaux publics', nameEn: 'Public works', imageUrl: 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?w=300'),
      ],
    ),
    ServiceCategory(
      name: 'Santé',
      icon: 'medical_services',
      color: 0xFF4CAF50,
      imageUrl: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=400',
      services: [
        ServiceType(name: 'Soins infirmiers', nameEn: 'Home nursing care', imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=300'),
        ServiceType(name: 'Garde malade', nameEn: 'Caregiver', imageUrl: 'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?w=300'),
        ServiceType(name: 'Médecin à domicile', nameEn: 'Home doctor visits', imageUrl: 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=300'),
        ServiceType(name: 'Transport sanitaire', nameEn: 'Medical transport', imageUrl: 'https://images.unsplash.com/photo-1587745416684-47953f16f02f?w=300'),
        ServiceType(name: 'Hijama', nameEn: 'Cupping therapy', imageUrl: 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=300'),
        ServiceType(name: 'Psychologue en ligne', nameEn: 'Online psychologist', imageUrl: 'https://images.unsplash.com/photo-1573497620053-ea5300f94f21?w=300'),
        ServiceType(name: 'Médecine alternative', nameEn: 'Alternative medicine', imageUrl: 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=300'),
        ServiceType(name: 'Kinésithérapie', nameEn: 'Home physiotherapy', imageUrl: 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=300'),
      ],
    ),
    ServiceCategory(
      name: 'Conseil et Consultation',
      icon: 'support_agent',
      color: 0xFF3F51B5,
      imageUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=400',
      services: [
        ServiceType(name: 'Conseil juridique', nameEn: 'Legal advice', imageUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=300'),
        ServiceType(name: 'Comptabilité', nameEn: 'Accounting', imageUrl: 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=300'),
      ],
    ),
    ServiceCategory(
      name: 'Métallerie',
      icon: 'hardware',
      color: 0xFF757575,
      imageUrl: 'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=400',
      services: [
        ServiceType(name: 'Soudure', nameEn: 'Welding', imageUrl: 'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=300'),
        ServiceType(name: 'Ferronnerie', nameEn: 'Ironwork', imageUrl: 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=300'),
        ServiceType(name: 'Serrurerie', nameEn: 'Locksmithing', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
        ServiceType(name: 'Charpente métallique', nameEn: 'Metal framework', imageUrl: 'https://images.unsplash.com/photo-1565008447742-97f6f38c985c?w=300'),
      ],
    ),
    ServiceCategory(
      name: 'Entretien et Nettoyage',
      icon: 'cleaning_services',
      color: 0xFF00BCD4,
      imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400',
      services: [
        ServiceType(name: 'Nettoyage', nameEn: 'Cleaning', imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300'),
        ServiceType(name: 'Jardinage', nameEn: 'Gardening', imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=300'),
        ServiceType(name: 'Traitement des nuisibles', nameEn: 'Pest control', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
        ServiceType(name: 'Débouchage canalisations', nameEn: 'Drain unblocking', imageUrl: 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=300'),
        ServiceType(name: 'Nettoyage façades', nameEn: 'Facade cleaning', imageUrl: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=300'),
      ],
    ),
    ServiceCategory(
      name: 'Portes, Fenêtres et Meubles',
      icon: 'door_front',
      color: 0xFF8D6E63,
      imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400',
      services: [
        ServiceType(name: 'Menuiserie bois', nameEn: 'Woodworking', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
        ServiceType(name: 'Menuiserie aluminium/PVC', nameEn: 'Aluminium & PVC joinery', imageUrl: 'https://images.unsplash.com/photo-1565940566776-d73a13ca71c0?w=300'),
        ServiceType(name: 'Vitrerie et miroiterie', nameEn: 'Glazing and mirrors', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
        ServiceType(name: 'Montage de meubles', nameEn: 'Furniture assembly', imageUrl: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=300'),
      ],
    ),
    ServiceCategory(
      name: 'Automobile',
      icon: 'directions_car',
      color: 0xFFF44336,
      imageUrl: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=400',
      services: [
        ServiceType(name: 'Mécanique auto', nameEn: 'Auto mechanics', imageUrl: 'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=300'),
        ServiceType(name: 'Électricité auto', nameEn: 'Auto electricity', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
        ServiceType(name: 'Carrosserie auto', nameEn: 'Auto bodywork', imageUrl: 'https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2?w=300'),
        ServiceType(name: 'Pare-brise et vitrage', nameEn: 'Windshield repair', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
        ServiceType(name: 'Lavage auto à domicile', nameEn: 'Home car wash', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
        ServiceType(name: 'Réparation motos/scooters', nameEn: 'Motorcycle repair', imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300'),
      ],
    ),
  ];

  // Default Images
  // Using DiceBear for CORS-friendly avatars
  static const String defaultProfileImage = 'https://api.dicebear.com/7.x/initials/svg?seed=User&backgroundColor=137fec';
  static const String defaultCoverImage = 'https://images.unsplash.com/photo-1557683316-973673baf926?w=800';


}

class SocialPlatform {
  final String key;
  final String name;
  final String icon;
  final int color;

  const SocialPlatform({
    required this.key,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class ServiceCategory {
  final String name;
  final String icon;
  final int color;
  final String imageUrl;
  final List<ServiceType> services;

  const ServiceCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.imageUrl,
    required this.services,
  });
}

class ServiceType {
  final String name;
  final String nameEn;
  final String imageUrl;

  const ServiceType({
    required this.name,
    required this.nameEn,
    required this.imageUrl,
  });
}

/// Store Category with subcategories (2-level hierarchy)
class StoreCategory {
  final String emoji;
  final String name;
  final List<String> subcategories;

  const StoreCategory({
    required this.emoji,
    required this.name,
    required this.subcategories,
  });
  
  /// Display name with emoji
  String get displayName => '$emoji $name';
}

/// Product Category with subcategories (2-level hierarchy)
class ProductCategory {
  final String emoji;
  final String name;
  final List<String> subcategories;

  const ProductCategory({
    required this.emoji,
    required this.name,
    required this.subcategories,
  });
  
  /// Display name with emoji
  String get displayName => '$emoji $name';
}
