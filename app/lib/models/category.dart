/// Category model for dynamic category management.
/// Supports hierarchical structure with parent/child relationships.
class Category {
  final int id;
  final String type; // 'store', 'product', 'service'
  final int? parentId;
  final String name;
  final String? nameEn;
  final String? emoji;
  final String? icon;
  final String? color;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final List<Category> children;

  Category({
    required this.id,
    required this.type,
    this.parentId,
    required this.name,
    this.nameEn,
    this.emoji,
    this.icon,
    this.color,
    this.imageUrl,
    this.sortOrder = 0,
    this.isActive = true,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      type: json['type'] as String,
      parentId: json['parent_id'] as int?,
      name: json['name'] as String,
      nameEn: json['name_en'] as String?,
      emoji: json['emoji'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      imageUrl: json['image_url'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      children: (json['children'] as List<dynamic>?)
              ?.map((c) => Category.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'parent_id': parentId,
      'name': name,
      'name_en': nameEn,
      'emoji': emoji,
      'icon': icon,
      'color': color,
      'image_url': imageUrl,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  /// Get display name with emoji if available.
  String get displayName {
    if (emoji != null && emoji!.isNotEmpty) {
      return '$emoji $name';
    }
    return name;
  }

  /// Check if this is a root/parent category.
  bool get isRoot => parentId == null;

  /// Check if this category has subcategories.
  bool get hasChildren => children.isNotEmpty;

  /// Get color as Flutter Color (parses hex string).
  int? get colorValue {
    if (color == null || color!.isEmpty) return null;
    String hex = color!.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add alpha channel
    }
    return int.tryParse(hex, radix: 16);
  }

  /// Get all subcategory names as a flat list.
  List<String> get subcategoryNames => children.map((c) => c.name).toList();

  @override
  String toString() => 'Category(id: $id, name: $name, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
