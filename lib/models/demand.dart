import 'user.dart';

/// Helper to parse int from either String or int
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class Demand {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String phone;
  final int? wilayaId;
  final int? communeId;
  final String wilaya;
  final String? commune;
  final double? latitude;
  final double? longitude;
  final List<String> images;
  final String? serviceCategory;
  final String? serviceType;
  final int? serviceCategoryId;
  final String status; // 'open', 'closed', 'expired'
  final bool isAnonymous;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;
  final List<DemandOffer> offers;
  final int offersCount;
  final String? timeAgo;

  Demand({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.phone,
    this.wilayaId,
    this.communeId,
    required this.wilaya,
    this.commune,
    this.latitude,
    this.longitude,
    this.images = const [],
    this.serviceCategory,
    this.serviceType,
    this.serviceCategoryId,
    required this.status,
    this.isAnonymous = false,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.offers = const [],
    this.offersCount = 0,
    this.timeAgo,
  });

  factory Demand.fromJson(Map<String, dynamic> json) {
    return Demand(
      id: _parseInt(json['id']) ?? 0,
      userId: _parseInt(json['user_id']) ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      phone: json['phone'] ?? '',
      wilayaId: _parseInt(json['wilaya_id']),
      communeId: _parseInt(json['commune_id']),
      wilaya: json['wilaya_name'] ?? json['wilaya'] ?? '',
      commune: json['commune_name'] ?? json['commune'],
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      serviceCategory: json['service_category'],
      serviceType: json['service_type'],
      serviceCategoryId: _parseInt(json['service_category_id']),
      status: json['status'] ?? 'open',
      isAnonymous: json['is_anonymous'] ?? false,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      offers: json['offers'] != null
          ? (json['offers'] as List).map((o) => DemandOffer.fromJson(o)).toList()
          : [],
      offersCount: json['offers_count'] ?? 0,
      timeAgo: json['time_ago'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'phone': phone,
      'wilaya_id': wilayaId,
      'commune_id': communeId,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'service_category': serviceCategory,
      'service_type': serviceType,
      'status': status,
      'is_anonymous': isAnonymous,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  String get location => commune != null ? '$commune, $wilaya' : wilaya;

  // Status helpers
  bool get isOpen => status == 'open';
  bool get isInProcess => status == 'in_process';
  bool get isCompleted => status == 'completed';
  bool get isCanceled => status == 'canceled';
  bool get isClosed => status == 'closed';

  String get statusText {
    switch (status) {
      case 'open':
        return 'Ouverte';
      case 'in_process':
        return 'En cours';
      case 'completed':
        return 'Terminée';
      case 'canceled':
        return 'Annulée';
      case 'closed':
        return 'Fermée';
      default:
        return status;
    }
  }

  String get displayName => isAnonymous ? 'Anonyme' : (user?.displayName ?? 'Client');

  String? get displayImage => isAnonymous ? null : user?.profilePic;
}

class DemandOffer {
  final int id;
  final int demandId;
  final int userId;
  final int? storeId;
  final String message;
  final double? proposedPrice;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;
  final dynamic store;
  final Demand? demand;
  final String? timeAgo;

  DemandOffer({
    required this.id,
    required this.demandId,
    required this.userId,
    this.storeId,
    required this.message,
    this.proposedPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.store,
    this.demand,
    this.timeAgo,
  });

  factory DemandOffer.fromJson(Map<String, dynamic> json) {
    return DemandOffer(
      id: _parseInt(json['id']) ?? 0,
      demandId: _parseInt(json['demand_id']) ?? 0,
      userId: _parseInt(json['user_id']) ?? 0,
      storeId: _parseInt(json['store_id']),
      message: json['message'] ?? '',
      proposedPrice: json['proposed_price'] != null 
          ? double.tryParse(json['proposed_price'].toString()) 
          : null,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      store: json['store'],
      demand: json['demand'] != null ? Demand.fromJson(json['demand']) : null,
      timeAgo: json['time_ago'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'demand_id': demandId,
      'message': message,
      'proposed_price': proposedPrice,
      'store_id': storeId,
    };
  }

  String get displayName => store != null ? (store['name'] ?? user?.displayName ?? 'Professional') : (user?.displayName ?? 'Professional');

  String? get displayImage => store != null ? store['profile_image'] : user?.profilePic;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}
