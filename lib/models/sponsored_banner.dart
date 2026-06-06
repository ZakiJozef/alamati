class SponsoredBanner {
  final int id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final bool isActive;
  final int displayOrder;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SponsoredBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    this.isActive = true,
    this.displayOrder = 0,
    this.startsAt,
    this.endsAt,
    this.createdAt,
    this.updatedAt,
  });

  factory SponsoredBanner.fromJson(Map<String, dynamic> json) {
    return SponsoredBanner(
      id: json['id'] as int,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String,
      linkUrl: json['link_url'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      displayOrder: json['display_order'] as int? ?? 0,
      startsAt: json['starts_at'] != null ? DateTime.tryParse(json['starts_at']) : null,
      endsAt: json['ends_at'] != null ? DateTime.tryParse(json['ends_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'is_active': isActive,
      'display_order': displayOrder,
      'starts_at': startsAt?.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
    };
  }
}
