/// Price unit model for services (e.g., per hour, per meter)
class Unit {
  final int id;
  final String name;
  final String symbol;
  final bool isActive;
  final int sortOrder;

  Unit({
    required this.id,
    required this.name,
    required this.symbol,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  @override
  String toString() => name;

  /// Display format for dropdowns (e.g., "Hour (hr)")
  String get displayName => '$name ($symbol)';
}
