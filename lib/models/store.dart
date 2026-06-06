import 'product.dart';
import 'portfolio_item.dart';
import 'review.dart';

class Store {
  final int id;
  final int ownerId;
  final String name;
  final String? slug;
  final String? description;
  final String? coverImage;
  final String? profileImage;
  final String? address;
  final String? city;
  final String? state;
  final int? wilayaId;
  final int? communeId;
  final String? category;
  final int? categoryId;
  final List<int> categoryIds;
  final int? subcategoryId;
  final List<int> subcategoryIds;
  final bool providesServices;
  final List<int> serviceCategoryIds;
  final String? phone;
  final List<String> phones;
  final String? email;
  final String? website;
  final double? lat;
  final double? lng;
  final String? mapUrl;
  final double rating;
  final int reviewCount;
  final int followerCount;
  final bool isOpen;
  final bool isFeatured;
  final bool isSponsored;
  final Map<String, String> socialLinks;
  final DateTime? createdAt;
  
  // Related data
  final String? ownerName;
  final String? ownerPic;
  final bool isSaved;
  final bool isFollowing;
  final List<Product> products;
  final List<PortfolioItem> portfolio;
  final List<Review> reviews;
  final Map<String, dynamic> businessHours;

  Store({
    required this.id,
    required this.ownerId,
    required this.name,
    this.slug,
    this.description,
    this.coverImage,
    this.profileImage,
    this.address,
    this.city,
    this.state,
    this.wilayaId,
    this.communeId,
    this.category,
    this.categoryId,
    this.categoryIds = const [],
    this.subcategoryId,
    this.subcategoryIds = const [],
    this.providesServices = false,
    this.serviceCategoryIds = const [],
    this.phone,
    this.phones = const [],
    this.email,
    this.website,
    this.lat,
    this.lng,
    this.mapUrl,
    this.rating = 0,
    this.reviewCount = 0,
    this.followerCount = 0,
    this.isOpen = true,
    this.isFeatured = false,
    this.isSponsored = false,
    this.socialLinks = const {},
    this.createdAt,
    this.ownerName,
    this.ownerPic,
    this.isSaved = false,
    this.isFollowing = false,
    this.products = const [],
    this.portfolio = const [],
    this.reviews = const [],
    this.businessHours = const {},
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    // Parse phones
    List<String> phonesList = [];
    if (json['phones'] != null) {
      if (json['phones'] is List) {
        phonesList = List<String>.from(json['phones']);
      }
    }

    // Parse social links
    Map<String, String> socialMap = {};
    if (json['social_links'] != null) {
      if (json['social_links'] is Map) {
        socialMap = Map<String, String>.from(json['social_links']);
      }
    }

    return Store(
      id: json['id'] as int? ?? 0,
      ownerId: json['owner_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      coverImage: json['cover_image'] as String?,
      profileImage: json['profile_image'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      wilayaId: json['wilaya_id'] as int?,
      communeId: json['commune_id'] as int?,
      category: json['category'] as String?,
      categoryId: json['category_id'] as int?,
      categoryIds: json['category_ids'] != null
          ? List<int>.from(json['category_ids'])
          : [],
      subcategoryId: json['subcategory_id'] as int?,
      subcategoryIds: json['subcategory_ids'] != null
          ? List<int>.from(json['subcategory_ids'])
          : [],
      providesServices: json['provides_services'] == 1 || json['provides_services'] == true,
      serviceCategoryIds: json['service_category_ids'] != null
          ? List<int>.from(json['service_category_ids'])
          : [],
      phone: json['phone'] as String?,
      phones: phonesList,
      email: json['email'] as String?,
      website: json['website'] as String?,
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
      mapUrl: json['map_url'] as String?,
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      followerCount: json['follower_count'] as int? ?? 0,
      isOpen: json['is_open'] == 1 || json['is_open'] == true,
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
      isSponsored: json['is_sponsored'] == 1 || json['is_sponsored'] == true,
      socialLinks: socialMap,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      ownerName: json['owner_name'] as String?,
      ownerPic: json['owner_pic'] as String?,
      isSaved: json['is_saved'] == 1 || json['is_saved'] == true,
      isFollowing: json['is_following'] == 1 || json['is_following'] == true,
      products: json['products'] != null
          ? (json['products'] as List).map((p) => Product.fromJson(p)).toList()
          : [],
      portfolio: _parsePortfolio(json),
      reviews: json['reviews'] != null
          ? (json['reviews'] as List).map((r) => Review.fromJson(r)).toList()
          : [],
      businessHours: json['business_hours'] != null && json['business_hours'] is Map
          ? Map<String, dynamic>.from(json['business_hours'])
          : {},
    );
  }

  /// Helper to parse portfolio items (checks both 'portfolio' and 'portfolio_items' keys)
  static List<PortfolioItem> _parsePortfolio(Map<String, dynamic> json) {
    // Try 'portfolio_items' first (Laravel snake_case from portfolioItems relationship)
    if (json['portfolio_items'] != null && json['portfolio_items'] is List) {
      return (json['portfolio_items'] as List)
          .map((p) => PortfolioItem.fromJson(p))
          .toList();
    }
    // Fallback to 'portfolio'
    if (json['portfolio'] != null && json['portfolio'] is List) {
      return (json['portfolio'] as List)
          .map((p) => PortfolioItem.fromJson(p))
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'slug': slug,
      'description': description,
      'cover_image': coverImage,
      'profile_image': profileImage,
      'address': address,
      'city': city,
      'state': state,
      'wilaya_id': wilayaId,
      'commune_id': communeId,
      'category': category,
      'category_id': categoryId,
      'category_ids': categoryIds,
      'subcategory_id': subcategoryId,
      'subcategory_ids': subcategoryIds,
      'provides_services': providesServices,
      'service_category_ids': serviceCategoryIds,
      'phone': phone,
      'phones': phones,
      'email': email,
      'website': website,
      'lat': lat,
      'lng': lng,
      'map_url': mapUrl,
      'rating': rating,
      'review_count': reviewCount,
      'follower_count': followerCount,
      'is_open': isOpen,
      'is_featured': isFeatured,
      'is_sponsored': isSponsored,
      'social_links': socialLinks,
      'business_hours': businessHours,
    };
  }

  String get location {
    if (city != null && state != null) {
      return '$city, $state';
    }
    return city ?? state ?? '';
  }

  String get fullAddress {
    final parts = [address, city, state].where((p) => p != null && p.isNotEmpty);
    return parts.join(', ');
  }

  bool get hasLocation => lat != null && lng != null;

  Store copyWith({
    bool? isSaved,
    bool? isFollowing,
    int? followerCount,
    List<Product>? products,
    List<PortfolioItem>? portfolio,
    List<Review>? reviews,
    List<int>? categoryIds,
    List<int>? subcategoryIds,
    bool? providesServices,
    List<int>? serviceCategoryIds,
    Map<String, dynamic>? businessHours,
  }) {
    return Store(
      id: id,
      ownerId: ownerId,
      name: name,
      slug: slug,
      description: description,
      coverImage: coverImage,
      profileImage: profileImage,
      address: address,
      city: city,
      state: state,
      wilayaId: wilayaId,
      communeId: communeId,
      category: category,
      categoryId: categoryId,
      categoryIds: categoryIds ?? this.categoryIds,
      subcategoryId: subcategoryId,
      subcategoryIds: subcategoryIds ?? this.subcategoryIds,
      providesServices: providesServices ?? this.providesServices,
      serviceCategoryIds: serviceCategoryIds ?? this.serviceCategoryIds,
      phone: phone,
      phones: phones,
      email: email,
      website: website,
      lat: lat,
      lng: lng,
      mapUrl: mapUrl,
      rating: rating,
      reviewCount: reviewCount,
      followerCount: followerCount ?? this.followerCount,
      isOpen: isOpen,
      isFeatured: isFeatured,
      isSponsored: isSponsored,
      socialLinks: socialLinks,
      createdAt: createdAt,
      ownerName: ownerName,
      ownerPic: ownerPic,
      isSaved: isSaved ?? this.isSaved,
      isFollowing: isFollowing ?? this.isFollowing,
      products: products ?? this.products,
      portfolio: portfolio ?? this.portfolio,
      reviews: reviews ?? this.reviews,
      businessHours: businessHours ?? this.businessHours,
    );
  }

}
