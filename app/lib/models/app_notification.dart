class AppNotification {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.data,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  // Notification type helpers
  bool get isNewDemand => type.contains('NewDemandNotification');

  // Data accessors for demand notifications
  int? get demandId => data['demand_id'] as int?;
  String? get demandTitle => data['title'] as String?;
  String? get demandDescription => data['description'] as String?;
  String? get serviceCategory => data['service_category'] as String?;
  int? get serviceCategoryId => data['service_category_id'] as int?;
  int? get wilayaId => data['wilaya_id'] as int?;
  String? get wilayaName => data['wilaya_name'] as String?;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      data: json['data'] is String 
          ? {} 
          : json['data'] as Map<String, dynamic>? ?? {},
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays > 0) {
      return 'منذ ${diff.inDays} يوم';
    } else if (diff.inHours > 0) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inMinutes > 0) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}
