import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  Cart? _cart;
  bool _isLoading = false;
  String? _error;

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Get cart item count for badge
  int get itemCount => _cart?.itemCount ?? 0;
  
  /// Check if cart is empty
  bool get isEmpty => _cart?.isEmpty ?? true;
  
  /// Get cart subtotal
  double get subtotal => _cart?.subtotal ?? 0;

  /// Load cart from API
  Future<void> loadCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/cart');
      if (response['id'] != null) {
        _cart = Cart.fromJson(response);
      } else {
        _cart = null;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add item to cart
  Future<bool> addToCart(int productId, {int quantity = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/cart/items', {
        'product_id': productId,
        'quantity': quantity,
      });
      
      if (response['cart'] != null) {
        _cart = Cart.fromJson(response['cart']);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding to cart: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// Update item quantity
  Future<bool> updateQuantity(int itemId, int quantity) async {
    if (quantity < 1) {
      return removeItem(itemId);
    }

    try {
      final response = await _api.put('/cart/items/$itemId', {
        'quantity': quantity,
      });
      
      if (response['cart'] != null) {
        _cart = Cart.fromJson(response['cart']);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating cart item: $e');
      notifyListeners();
      return false;
    }
  }

  /// Remove item from cart
  Future<bool> removeItem(int itemId) async {
    try {
      final response = await _api.delete('/cart/items/$itemId');
      
      if (response['cart'] != null) {
        _cart = Cart.fromJson(response['cart']);
      } else {
        _cart = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error removing cart item: $e');
      notifyListeners();
      return false;
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      await _api.delete('/cart');
      _cart = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error clearing cart: $e');
    }
  }

  /// Checkout - create order from cart
  Future<Map<String, dynamic>?> checkout({
    required String fullName,
    required String phone,
    String deliveryType = 'home',
    String? wilaya,
    String? commune,
    String? address,
    String? notes,
  }) async {
    if (_cart == null || _cart!.isEmpty) {
      _error = 'Cart is empty';
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/orders', {
        'cart_id': _cart!.id,
        'full_name': fullName,
        'phone': phone,
        'delivery_type': deliveryType,
        'wilaya': wilaya,
        'commune': commune,
        'address': address,
        'notes': notes,
      });
      
      // Cart is cleared after successful checkout
      _cart = null;
      notifyListeners();
      
      return response;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error during checkout: $e');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
    }
  }

  /// Reset cart state (e.g., on logout)
  void reset() {
    _cart = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
