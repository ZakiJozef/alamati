import 'subscription_plan.dart';

class Subscription {
  final int id;
  final int userId;
  final String? userName;
  final int planId;
  final SubscriptionPlan? plan;
  final String status;
  final String paymentMethod;
  final String? paymentProof;
  final bool paymentVerified;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final String? adminNotes;
  final int? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.userId,
    this.userName,
    required this.planId,
    this.plan,
    required this.status,
    required this.paymentMethod,
    this.paymentProof,
    this.paymentVerified = false,
    this.startsAt,
    this.expiresAt,
    this.adminNotes,
    this.verifiedBy,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    // verified_by can be an int or a full User object
    int? verifiedById;
    if (json['verified_by'] != null) {
      if (json['verified_by'] is int) {
        verifiedById = json['verified_by'] as int;
      } else if (json['verified_by'] is Map) {
        verifiedById = (json['verified_by'] as Map)['id'] as int?;
      }
    }

    // Extract username from user object
    String? userName;
    if (json['user'] != null && json['user'] is Map) {
      userName = json['user']['username'] as String? ?? json['user']['pseudoname'] as String?;
    }

    return Subscription(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      userName: userName,
      planId: json['plan_id'] as int,
      plan: json['plan'] != null
          ? SubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String,
      paymentProof: json['payment_proof'] as String?,
      paymentVerified: json['payment_verified'] as bool? ?? false,
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      adminNotes: json['admin_notes'] as String?,
      verifiedBy: verifiedById,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'plan': plan?.toJson(),
      'status': status,
      'payment_method': paymentMethod,
      'payment_verified': paymentVerified,
      'starts_at': startsAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'admin_notes': adminNotes,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if subscription is active
  bool get isActive {
    return status == 'active' &&
        expiresAt != null &&
        expiresAt!.isAfter(DateTime.now());
  }

  /// Check if subscription is pending
  bool get isPending => status == 'pending';

  /// Check if subscription is expired
  bool get isExpired {
    return status == 'expired' ||
        (expiresAt != null && expiresAt!.isBefore(DateTime.now()));
  }

  /// Get days remaining
  int get daysRemaining {
    if (expiresAt == null || expiresAt!.isBefore(DateTime.now())) {
      return 0;
    }
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  /// Get status display text
  String get statusText {
    switch (status) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending Approval';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Get status color
  int get statusColor {
    switch (status) {
      case 'active':
        return 0xFF10B981; // Green
      case 'pending':
        return 0xFFF59E0B; // Amber
      case 'expired':
        return 0xFFEF4444; // Red
      case 'cancelled':
        return 0xFF6B7280; // Gray
      default:
        return 0xFF6B7280;
    }
  }

  /// Get payment method label
  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'free':
        return 'Free Trial';
      case 'ccp':
        return 'CCP';
      case 'baridimob':
        return 'BaridiMob';
      case 'cash':
        return 'Cash';
      default:
        return paymentMethod;
    }
  }
}
