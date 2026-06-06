import 'store.dart';
import 'product.dart';

class Cart {
  final int? id;
  final int? userId;
  final int storeId;
  final Store? store;
  final List<CartItem> items;
  final double subtotal;
  final int itemCount;

  Cart({
    this.id,
    this.userId,
    required this.storeId,
    this.store,
    this.items = const [],
    this.subtotal = 0,
    this.itemCount = 0,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      storeId: json['store_id'] as int? ?? 0,
      store: json['store'] != null ? Store.fromJson(json['store']) : null,
      items: json['items'] != null
          ? (json['items'] as List).map((e) => CartItem.fromJson(e)).toList()
          : [],
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0,
      itemCount: json['item_count'] as int? ?? 0,
    );
  }

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => items.isNotEmpty;

  /// Get store name if available
  String get storeName => store?.name ?? 'Unknown Store';
}

class CartItem {
  final int id;
  final int cartId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Product? product;

  CartItem({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.quantity,
    this.unitPrice = 0,
    this.totalPrice = 0,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int? ?? 0,
      cartId: json['cart_id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0,
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }

  /// Get product name
  String get productName => product?.name ?? 'Unknown Product';

  /// Get product thumbnail URL
  String get productImage => product?.thumbnailUrl ?? '';

  /// Get formatted unit price
  String get unitPriceFormatted => '${unitPrice.toStringAsFixed(2)} DZD';

  /// Get formatted total price
  String get totalPriceFormatted => '${totalPrice.toStringAsFixed(2)} DZD';
}
