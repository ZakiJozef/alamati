class SubscriptionPlan {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final int durationDays;
  final int maxStores;
  final int maxProducts;
  final int maxPortfolio;
  final bool canUseSponsoredZones;
  final int maxSections;
  final bool isActive;
  final int sortOrder;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    required this.durationDays,
    required this.maxStores,
    required this.maxProducts,
    required this.maxPortfolio,
    this.canUseSponsoredZones = false,
    this.maxSections = 5,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      price: (json['price'] is String)
          ? double.parse(json['price'])
          : (json['price'] as num).toDouble(),
      durationDays: json['duration_days'] as int,
      maxStores: json['max_stores'] as int,
      maxProducts: json['max_products'] as int,
      maxPortfolio: json['max_portfolio'] as int,
      canUseSponsoredZones: json['can_use_sponsored_zones'] as bool? ?? false,
      maxSections: json['max_sections'] as int? ?? 5,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'price': price,
      'duration_days': durationDays,
      'max_stores': maxStores,
      'max_products': maxProducts,
      'max_portfolio': maxPortfolio,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  /// Check if this is the free trial plan
  bool get isFreeTrial => slug == 'free';

  /// Check if products are unlimited
  bool get hasUnlimitedProducts => maxProducts == -1;

  /// Get formatted price
  String get formattedPrice {
    if (price == 0) return 'Free';
    return '${price.toInt()} DA';
  }

  /// Get duration text
  String get durationText {
    if (durationDays <= 30) {
      return '$durationDays days';
    }
    final months = durationDays ~/ 30;
    if (months >= 12) {
      final years = months ~/ 12;
      return '$years year${years > 1 ? 's' : ''}';
    }
    return '$months months';
  }

  /// Get badge color based on plan
  int get badgeColor {
    switch (slug) {
      case 'gold':
        return 0xFFFFD700; // Gold
      case 'silver':
        return 0xFFC0C0C0; // Silver
      default:
        return 0xFF10B981; // Green for free
    }
  }
}
