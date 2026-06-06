import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import '../models/category.dart' as models;
import '../services/api_service.dart';

/// Provider for managing categories from the API.
/// Caches categories and provides methods for CRUD operations.
class CategoriesProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // Cached categories by type
  List<models.Category> _storeCategories = [];
  List<models.Category> _productCategories = [];
  List<models.Category> _serviceCategories = [];

  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  List<models.Category> get storeCategories => _storeCategories;
  List<models.Category> get productCategories => _productCategories;
  List<models.Category> get serviceCategories => _serviceCategories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  /// Get flat list of store category names (for dropdowns).
  List<String> get storeCategoryNames =>
      _storeCategories.map((c) => c.name).toList();

  /// Get flat list of product category names (for dropdowns).
  List<String> get productCategoryNames =>
      _productCategories.map((c) => c.name).toList();

  /// Get flat list of service category names (for dropdowns).
  List<String> get serviceCategoryNames =>
      _serviceCategories.map((c) => c.name).toList();

  /// Load all categories from API.
  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _api.get('/categories');

      if (response is Map<String, dynamic>) {
        _storeCategories = _parseCategories(response['store']);
        _productCategories = _parseCategories(response['product']);
        _serviceCategories = _parseCategories(response['service']);
      }

      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load categories by type.
  Future<List<models.Category>> loadCategoriesByType(String type) async {
    try {
      final response = await _api.get('/categories/$type');
      return _parseCategories(response);
    } catch (e) {
      debugPrint('Error loading $type categories: $e');
      return [];
    }
  }

  /// Parse categories from API response.
  List<models.Category> _parseCategories(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((c) => models.Category.fromJson(c as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Get subcategories for a given parent category name.
  List<String> getStoreSubcategories(String categoryName) {
    final category = _storeCategories.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => models.Category(id: 0, type: 'store', name: ''),
    );
    return category.subcategoryNames;
  }

  /// Get subcategories for a given product category name.
  List<String> getProductSubcategories(String categoryName) {
    final category = _productCategories.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => models.Category(id: 0, type: 'product', name: ''),
    );
    return category.subcategoryNames;
  }

  /// Get service category by name.
  models.Category? getServiceCategoryByName(String name) {
    try {
      return _serviceCategories.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Get category by ID (searches all category types).
  models.Category? getCategoryById(int id) {
    // Search store categories
    for (final category in _storeCategories) {
      if (category.id == id) return category;
      if (category.children != null) {
        for (final child in category.children!) {
          if (child.id == id) return child;
        }
      }
    }
    // Search product categories
    for (final category in _productCategories) {
      if (category.id == id) return category;
      if (category.children != null) {
        for (final child in category.children!) {
          if (child.id == id) return child;
        }
      }
    }
    // Search service categories
    for (final category in _serviceCategories) {
      if (category.id == id) return category;
      if (category.children != null) {
        for (final child in category.children!) {
          if (child.id == id) return child;
        }
      }
    }
    return null;
  }

  // ========== ADMIN CRUD OPERATIONS ==========

  /// Create a new category.
  Future<models.Category?> createCategory({
    required String type,
    required String name,
    String? nameEn,
    int? parentId,
    String? emoji,
    String? icon,
    String? color,
    String? imageUrl,
    int? sortOrder,
  }) async {
    try {
      final response = await _api.post('/admin/categories', {
        'type': type,
        'name': name,
        'name_en': nameEn,
        'parent_id': parentId,
        'emoji': emoji,
        'icon': icon,
        'color': color,
        'image_url': imageUrl,
        'sort_order': sortOrder ?? 0,
      });

      final category = models.Category.fromJson(response);

      // Refresh categories
      await loadCategories(forceRefresh: true);

      return category;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating category: $e');
      notifyListeners();
      return null;
    }
  }

  /// Update an existing category.
  Future<bool> updateCategory(int categoryId, Map<String, dynamic> data) async {
    try {
      await _api.put('/admin/categories/$categoryId', data);

      // Refresh categories
      await loadCategories(forceRefresh: true);

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating category: $e');
      notifyListeners();
      return false;
    }
  }

  /// Delete a category.
  Future<bool> deleteCategory(int categoryId) async {
    try {
      await _api.delete('/admin/categories/$categoryId');

      // Refresh categories
      await loadCategories(forceRefresh: true);

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting category: $e');
      notifyListeners();
      return false;
    }
  }

  /// Reorder categories.
  Future<bool> reorderCategories(List<Map<String, dynamic>> categoryOrders) async {
    try {
      await _api.post('/admin/categories/reorder', {
        'categories': categoryOrders,
      });

      // Refresh categories
      await loadCategories(forceRefresh: true);

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error reordering categories: $e');
      notifyListeners();
      return false;
    }
  }

  /// Clear error state.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
