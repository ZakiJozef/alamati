import 'package:flutter/material.dart';
import '../models/subscription_plan.dart';
import '../services/api_service.dart';

/// Provider for managing subscription plans (admin)
class SubscriptionPlansProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = false;
  String? _error;

  List<SubscriptionPlan> get plans => _plans;
  List<SubscriptionPlan> get activePlans => _plans.where((p) => p.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all plans from API (admin view - includes inactive)
  Future<void> loadPlans({bool forceRefresh = false}) async {
    if (_plans.isNotEmpty && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/admin/plans');
      if (response is List) {
        _plans = response.map((p) => SubscriptionPlan.fromJson(p)).toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new plan (admin)
  Future<SubscriptionPlan?> createPlan({
    required String name,
    String? slug,
    String? description,
    required double price,
    required int durationDays,
    required int maxStores,
    required int maxProducts,
    required int maxPortfolio,
    int maxSections = 5,
    bool canUseSponsoredZones = false,
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    try {
      final response = await _api.post('/admin/plans', {
        'name': name,
        if (slug != null) 'slug': slug,
        if (description != null) 'description': description,
        'price': price,
        'duration_days': durationDays,
        'max_stores': maxStores,
        'max_products': maxProducts,
        'max_portfolio': maxPortfolio,
        'max_sections': maxSections,
        'can_use_sponsored_zones': canUseSponsoredZones,
        'is_active': isActive,
        'sort_order': sortOrder,
      });
      final plan = SubscriptionPlan.fromJson(response);
      await loadPlans(forceRefresh: true);
      return plan;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update a plan (admin)
  Future<bool> updatePlan(int id, {
    String? name,
    String? slug,
    String? description,
    double? price,
    int? durationDays,
    int? maxStores,
    int? maxProducts,
    int? maxPortfolio,
    int? maxSections,
    bool? canUseSponsoredZones,
    bool? isActive,
    int? sortOrder,
  }) async {
    try {
      await _api.put('/admin/plans/$id', {
        if (name != null) 'name': name,
        if (slug != null) 'slug': slug,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (durationDays != null) 'duration_days': durationDays,
        if (maxStores != null) 'max_stores': maxStores,
        if (maxProducts != null) 'max_products': maxProducts,
        if (maxPortfolio != null) 'max_portfolio': maxPortfolio,
        if (maxSections != null) 'max_sections': maxSections,
        if (canUseSponsoredZones != null) 'can_use_sponsored_zones': canUseSponsoredZones,
        if (isActive != null) 'is_active': isActive,
        if (sortOrder != null) 'sort_order': sortOrder,
      });
      await loadPlans(forceRefresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a plan (admin)
  Future<bool> deletePlan(int id) async {
    try {
      await _api.delete('/admin/plans/$id');
      await loadPlans(forceRefresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Toggle plan active status
  Future<bool> toggleActive(int id) async {
    try {
      await _api.post('/admin/plans/$id/toggle-active', {});
      await loadPlans(forceRefresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
