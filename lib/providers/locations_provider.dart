import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/location.dart';

class LocationsProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Wilaya> _wilayas = [];
  final Map<int, List<Commune>> _communesCache = {};
  
  bool _isLoading = false;
  String? _error;

  List<Wilaya> get wilayas => _wilayas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWilayas() async {
    if (_wilayas.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/wilayas');
      _wilayas = (response as List).map((json) => Wilaya.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load wilayas: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading wilayas: $e');
    }
  }

  Future<List<Commune>> getCommunes(int wilayaId) async {
    if (_communesCache.containsKey(wilayaId)) {
      return _communesCache[wilayaId]!;
    }

    try {
      // Find the wilaya to make sure it exists
      final wilaya = _wilayas.firstWhere((w) => w.id == wilayaId, orElse: () => throw Exception('Wilaya not found'));
      
      final response = await _api.get('/wilayas/${wilaya.id}/communes');
      final communes = (response as List).map((json) => Commune.fromJson(json)).toList();
      
      _communesCache[wilayaId] = communes;
      notifyListeners();
      return communes;
    } catch (e) {
      debugPrint('Error loading communes for wilaya $wilayaId: $e');
      rethrow;
    }
  }
  
  /// Get communes for a wilaya by name (synchronous - returns cached data)
  List<Commune> getCommunesByWilayaName(String wilayaName) {
    final wilaya = getWilayaByName(wilayaName);
    if (wilaya == null) return [];
    return _communesCache[wilaya.id] ?? [];
  }
  
  /// Load communes for a wilaya by name (async)
  Future<void> loadCommunesByWilayaName(String wilayaName) async {
    final wilaya = getWilayaByName(wilayaName);
    if (wilaya == null) return;
    await getCommunes(wilaya.id);
  }
  
  Wilaya? getWilayaByName(String name) {
    try {
      return _wilayas.firstWhere((w) => w.name == name);
    } catch (e) {
      return null;
    }
  }
  
  Wilaya? getWilayaById(int id) {
    try {
      return _wilayas.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Commune? getCommuneById(int id) {
    for (final communes in _communesCache.values) {
      try {
        return communes.firstWhere((c) => c.id == id);
      } catch (e) {
        // Continue searching in other cached wilayas
      }
    }
    return null;
  }
}

