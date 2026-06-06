import 'store.dart';

class Product {
  final int id;
  final int storeId;
  final String name;
  final String? description;
  final double? price;
  final int? priceUnitId;
  final String? priceUnitSymbol;
  final String? priceUnitName;
  final double? discountPrice;
  final String? image;
  final List<String> images;
  final String type;
  final String? category;
  final int? categoryId;
  final int? subcategoryId;
  final int stock;
  final bool isActive;
  final double averageRating;
  final int reviewsCount;
  final String? thumbnail;
  final Store? store;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.storeId,
    required this.name,
    this.description,
    this.price,
    this.priceUnitId,
    this.priceUnitSymbol,
    this.priceUnitName,
    this.discountPrice,
    this.image,
    this.images = const [],
    this.type = 'product',
    this.category,
    this.categoryId,
    this.subcategoryId,
    this.stock = 0,
    this.isActive = true,
    this.averageRating = 0,
    this.reviewsCount = 0,
    this.thumbnail,
    this.store,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        imagesList = (json['images'] as List).map((e) => e.toString()).toList();
      }
    }

    // Parse unit data from nested object or direct fields
    int? unitId;
    String? unitSymbol;
    String? unitName;
    if (json['unit'] != null) {
      unitId = json['unit']['id'] as int?;
      unitSymbol = json['unit']['symbol'] as String?;
      unitName = json['unit']['name'] as String?;
    } else {
      unitId = json['price_unit_id'] as int?;
      unitSymbol = json['price_unit_symbol'] as String?;
      unitName = json['price_unit_name'] as String?;
    }

    return Product(
      id: json['id'] as int? ?? 0,
      storeId: json['store_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      priceUnitId: unitId,
      priceUnitSymbol: unitSymbol,
      priceUnitName: unitName,
      discountPrice: json['discount_price'] != null ? double.tryParse(json['discount_price'].toString()) : null,
      image: json['image'] as String?,
      images: imagesList,
      type: json['type'] as String? ?? 'product',
      category: json['category'] as String?,
      categoryId: json['category_id'] as int?,
      subcategoryId: json['subcategory_id'] as int?,
      stock: json['stock'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      averageRating: json['average_rating'] != null ? double.tryParse(json['average_rating'].toString()) ?? 0 : 0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      thumbnail: json['thumbnail'] as String?,
      store: json['store'] != null ? Store.fromJson(json['store']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'name': name,
      'description': description,
      'price': price,
      'price_unit_id': priceUnitId,
      'discount_price': discountPrice,
      'image': image,
      'images': images,
      'type': type,
      'category': category,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'stock': stock,
      'is_active': isActive,
    };
  }

  bool get isService => type == 'service';
  bool get isProduct => type == 'product';
  bool get hasDiscount => discountPrice != null && discountPrice! < (price ?? 0);
  bool get inStock => stock > 0;
  bool get hasPriceUnit => priceUnitId != null && priceUnitSymbol != null;
  
  double get effectivePrice => discountPrice ?? price ?? 0;

  /// Calculate discount percentage
  int get discountPercentage {
    if (!hasDiscount || price == null || price == 0) return 0;
    return (((price! - discountPrice!) / price!) * 100).round();
  }

  String get priceFormatted {
    if (price == null) return '';
    return '${price!.toStringAsFixed(2)} DZD';
  }

  /// Price formatted with unit (e.g., "5000.00 DZD/hr")
  String get effectivePriceFormatted {
    final priceStr = '${effectivePrice.toStringAsFixed(2)} DZD';
    if (priceUnitSymbol != null) {
      return '$priceStr/$priceUnitSymbol';
    }
    return priceStr;
  }

  /// Price formatted with full unit name (e.g., "5000.00 DZD per Hour")
  String get effectivePriceFormattedFull {
    final priceStr = '${effectivePrice.toStringAsFixed(2)} DZD';
    if (priceUnitName != null) {
      return '$priceStr per $priceUnitName';
    }
    return priceStr;
  }

  String get thumbnailUrl => thumbnail ?? image ?? (images.isNotEmpty ? images.first : '');
  
  List<String> get allImages {
    final List<String> all = [];
    if (image != null && image!.isNotEmpty) all.add(image!);
    all.addAll(images.where((img) => img != image));
    return all.isNotEmpty ? all : ['https://via.placeholder.com/400x400?text=No+Image'];
  }
}

