class PortfolioItem {
  final int id;
  final int storeId;
  final String title;
  final String? description;
  final String? image;
  final List<String> images;
  final List<String> allImages;
  final DateTime? createdAt;

  PortfolioItem({
    required this.id,
    required this.storeId,
    required this.title,
    this.description,
    this.image,
    this.images = const [],
    this.allImages = const [],
    this.createdAt,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    // Parse images array
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List).map((e) => e.toString()).toList();
    }
    
    // Parse all_images (combined from backend)
    List<String> allImagesList = [];
    if (json['all_images'] != null && json['all_images'] is List) {
      allImagesList = (json['all_images'] as List).map((e) => e.toString()).toList();
    }
    
    return PortfolioItem(
      id: json['id'] as int? ?? 0,
      storeId: json['store_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      image: json['image'] as String?,
      images: imagesList,
      allImages: allImagesList,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'title': title,
      'description': description,
      'image': image,
      'images': images,
    };
  }
  
  /// Get display images - prefer allImages from backend, fallback to local images
  List<String> get displayImages {
    if (allImages.isNotEmpty) return allImages;
    if (images.isNotEmpty) return images;
    if (image != null && image!.isNotEmpty) return [image!];
    return [];
  }
}

