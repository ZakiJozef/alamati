class Order {
  final int id;
  final int? userId;
  final int storeId;
  final String orderNumber;
  final String status;
  final String fullName;
  final String phone;
  final String deliveryType; // 'home' or 'desk'
  final String wilaya;
  final String commune;
  final String? address;
  final String? notes;
  final double subtotal;
  final double shippingFee;
  final double total;
  final String paymentMethod;
  final DateTime? createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    this.userId,
    required this.storeId,
    required this.orderNumber,
    required this.status,
    required this.fullName,
    required this.phone,
    this.deliveryType = 'home',
    required this.wilaya,
    required this.commune,
    this.address,
    this.notes,
    required this.subtotal,
    this.shippingFee = 0,
    required this.total,
    this.paymentMethod = 'cod',
    this.createdAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int?,
      storeId: json['store_id'] as int? ?? 0,
      orderNumber: json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      deliveryType: json['delivery_type'] as String? ?? 'home',
      wilaya: json['wilaya'] as String? ?? '',
      commune: json['commune'] as String? ?? '',
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
      shippingFee: double.tryParse(json['shipping_fee'].toString()) ?? 0,
      total: double.tryParse(json['total'].toString()) ?? 0,
      paymentMethod: json['payment_method'] as String? ?? 'cod',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      items: json['items'] != null
          ? (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList()
          : [],
    );
  }

  /// Get formatted delivery type for display
  String get deliveryTypeFormatted {
    return deliveryType == 'desk' ? 'Pickup at Desk' : 'Home Delivery';
  }

  /// Check if this is a pickup order
  bool get isPickup => deliveryType == 'desk';

  String get statusFormatted {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'processing': return 'Processing';
      case 'shipped': return 'Shipped';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  String get statusColor {
    switch (status) {
      case 'pending': return 'orange';
      case 'confirmed': return 'blue';
      case 'processing': return 'purple';
      case 'shipped': return 'cyan';
      case 'delivered': return 'green';
      case 'cancelled': return 'red';
      default: return 'gray';
    }
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int? ?? 0,
      orderId: json['order_id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      productName: json['product_name'] as String? ?? '',
      productImage: json['product_image'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0,
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0,
    );
  }
}
