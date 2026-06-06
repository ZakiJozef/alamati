import 'product.dart';

/// Section types for store customization
enum StoreSectionType {
  slider,
  sponsoredSlider,
  featuredTrending,
  sponsoredZone,
  countdown,
  productGrid,
}

/// Extension to get string values and labels for section types
extension StoreSectionTypeExtension on StoreSectionType {
  String get value {
    switch (this) {
      case StoreSectionType.slider:
        return 'slider';
      case StoreSectionType.sponsoredSlider:
        return 'sponsored_slider';
      case StoreSectionType.featuredTrending:
        return 'featured_trending';
      case StoreSectionType.sponsoredZone:
        return 'sponsored_zone';
      case StoreSectionType.countdown:
        return 'countdown';
      case StoreSectionType.productGrid:
        return 'product_grid';
    }
  }

  String get label {
    switch (this) {
      case StoreSectionType.slider:
        return 'Product Slider';
      case StoreSectionType.sponsoredSlider:
        return 'Sponsored Slider';
      case StoreSectionType.featuredTrending:
        return 'Featured / Trending / Top Rated';
      case StoreSectionType.sponsoredZone:
        return 'Sponsored Zone';
      case StoreSectionType.countdown:
        return 'Countdown Sale';
      case StoreSectionType.productGrid:
        return 'Product Grid';
    }
  }

  String get icon {
    switch (this) {
      case StoreSectionType.slider:
        return 'view_carousel';
      case StoreSectionType.sponsoredSlider:
        return 'star';
      case StoreSectionType.featuredTrending:
        return 'trending_up';
      case StoreSectionType.sponsoredZone:
        return 'workspace_premium';
      case StoreSectionType.countdown:
        return 'timer';
      case StoreSectionType.productGrid:
        return 'grid_view';
    }
  }

  bool get isSponsored {
    return this == StoreSectionType.sponsoredSlider || 
           this == StoreSectionType.sponsoredZone;
  }

  static StoreSectionType fromString(String value) {
    switch (value) {
      case 'slider':
        return StoreSectionType.slider;
      case 'sponsored_slider':
        return StoreSectionType.sponsoredSlider;
      case 'featured_trending':
        return StoreSectionType.featuredTrending;
      case 'sponsored_zone':
        return StoreSectionType.sponsoredZone;
      case 'countdown':
        return StoreSectionType.countdown;
      case 'product_grid':
        return StoreSectionType.productGrid;
      default:
        return StoreSectionType.slider;
    }
  }
}

/// Store Section model for customizable product display sections
class StoreSection {
  final int id;
  final int storeId;
  final StoreSectionType type;
  final String? title;
  final int sortOrder;
  final bool isActive;
  final Map<String, dynamic>? config;
  final List<Product> products;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StoreSection({
    required this.id,
    required this.storeId,
    required this.type,
    this.title,
    this.sortOrder = 0,
    this.isActive = true,
    this.config,
    this.products = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Parse from JSON response
  factory StoreSection.fromJson(Map<String, dynamic> json) {
    return StoreSection(
      id: json['id'] as int,
      storeId: json['store_id'] as int,
      type: StoreSectionTypeExtension.fromString(json['type'] as String),
      title: json['title'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      config: json['config'] as Map<String, dynamic>?,
      products: json['products'] != null
          ? (json['products'] as List).map((p) => Product.fromJson(p)).toList()
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'title': title,
      'sort_order': sortOrder,
      'is_active': isActive,
      'config': config,
      'product_ids': products.map((p) => p.id).toList(),
    };
  }

  /// Get countdown end time from config
  DateTime? get countdownEnd {
    if (type != StoreSectionType.countdown || config == null) {
      return null;
    }
    final endTime = config!['end_time'];
    if (endTime == null) return null;
    return DateTime.tryParse(endTime.toString());
  }

  /// Check if countdown is still active
  bool get isCountdownActive {
    final end = countdownEnd;
    return end != null && end.isAfter(DateTime.now());
  }

  /// Get remaining countdown duration
  Duration? get countdownRemaining {
    final end = countdownEnd;
    if (end == null) return null;
    final remaining = end.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Copy with updated fields
  StoreSection copyWith({
    int? id,
    int? storeId,
    StoreSectionType? type,
    String? title,
    int? sortOrder,
    bool? isActive,
    Map<String, dynamic>? config,
    List<Product>? products,
  }) {
    return StoreSection(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      type: type ?? this.type,
      title: title ?? this.title,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      config: config ?? this.config,
      products: products ?? this.products,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Section type info returned from API
class SectionTypeInfo {
  final StoreSectionType type;
  final String label;
  final bool isSponsored;
  final bool available;

  SectionTypeInfo({
    required this.type,
    required this.label,
    required this.isSponsored,
    required this.available,
  });

  factory SectionTypeInfo.fromJson(Map<String, dynamic> json) {
    return SectionTypeInfo(
      type: StoreSectionTypeExtension.fromString(json['type'] as String),
      label: json['label'] as String,
      isSponsored: json['is_sponsored'] as bool? ?? false,
      available: json['available'] as bool? ?? true,
    );
  }
}
