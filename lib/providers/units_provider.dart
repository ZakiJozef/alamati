import 'package:flutter/material.dart';
import '../models/unit.dart';
import '../services/api_service.dart';

/// Provider for managing price units
class UnitsProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Unit> _units = [];
  bool _isLoading = false;
  String? _error;

  List<Unit> get units => _units;
  List<Unit> get activeUnits => _units.where((u) => u.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all units from API
  Future<void> loadUnits({bool forceRefresh = false}) async {
    if (_units.isNotEmpty && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/units?active_only=true');
      if (response is List) {
        _units = response.map((u) => Unit.fromJson(u)).toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get unit by ID
  Unit? getUnitById(int? id) {
    if (id == null) return null;
    try {
      return _units.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a new unit (admin)
  Future<Unit?> createUnit({
    required String name,
    required String symbol,
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    try {
      final response = await _api.post('/admin/units', {
        'name': name,
        'symbol': symbol,
        'is_active': isActive,
        'sort_order': sortOrder,
      });
      final unit = Unit.fromJson(response);
      await loadUnits(forceRefresh: true);
      return unit;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update a unit (admin)
  Future<bool> updateUnit(int id, {
    String? name,
    String? symbol,
    bool? isActive,
    int? sortOrder,
  }) async {
    try {
      await _api.put('/admin/units/$id', {
        if (name != null) 'name': name,
        if (symbol != null) 'symbol': symbol,
        if (isActive != null) 'is_active': isActive,
        if (sortOrder != null) 'sort_order': sortOrder,
      });
      await loadUnits(forceRefresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a unit (admin)
  Future<bool> deleteUnit(int id) async {
    try {
      await _api.delete('/admin/units/$id');
      await loadUnits(forceRefresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
