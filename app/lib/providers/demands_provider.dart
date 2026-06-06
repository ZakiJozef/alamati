import 'package:flutter/foundation.dart';
import '../models/demand.dart';
import '../services/api_service.dart';

class DemandsProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<Demand> _demands = [];
  List<Demand> _myDemands = [];
  List<DemandOffer> _myOffers = [];
  Demand? _currentDemand;
  bool _isLoading = false;
  String? _error;
  String? _selectedCategory;

  // Getters
  List<Demand> get demands => _demands;
  List<Demand> get myDemands => _myDemands;
  List<DemandOffer> get myOffers => _myOffers;
  Demand? get currentDemand => _currentDemand;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategory => _selectedCategory;

  // Set selected category filter
  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
    loadDemands();
  }

  // Load all open demands
  Future<void> loadDemands({String? search, int? wilayaId, String? sort}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = '/demands?';
      if (_selectedCategory != null) {
        url += 'category=$_selectedCategory&';
      }
      if (search != null && search.isNotEmpty) {
        url += 'search=$search&';
      }
      if (wilayaId != null) {
        url += 'wilaya_id=$wilayaId&';
      }
      if (sort != null && sort.isNotEmpty) {
        url += 'sort=$sort&';
      }

      final response = await _api.get(url);
      final data = response['data'] ?? response;
      
      if (data is List) {
        _demands = data.map((d) => Demand.fromJson(d)).toList();
      } else if (data is Map && data.containsKey('data')) {
        _demands = (data['data'] as List).map((d) => Demand.fromJson(d)).toList();
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load demand details
  Future<Demand?> loadDemandDetails(int id) async {
    try {
      final response = await _api.get('/demands/$id');
      _currentDemand = Demand.fromJson(response);
      notifyListeners();
      return _currentDemand;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Create new demand
  Future<Demand?> createDemand({
    required String title,
    required String description,
    required String phone,
    int? wilayaId,
    int? communeId,
    double? latitude,
    double? longitude,
    List<String>? images,
    int? serviceCategoryId,
    bool isAnonymous = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.post('/demands', {
        'title': title,
        'description': description,
        'phone': phone,
        'wilaya_id': wilayaId,
        'commune_id': communeId,
        'latitude': latitude,
        'longitude': longitude,
        'images': images ?? [],
        'service_category_id': serviceCategoryId,
        'is_anonymous': isAnonymous,
      });

      final demand = Demand.fromJson(response);
      _demands.insert(0, demand);
      _isLoading = false;
      notifyListeners();
      return demand;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Load user's own demands
  Future<void> loadMyDemands() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get('/demands/user/my');
      if (response is List) {
        _myDemands = response.map((d) => Demand.fromJson(d)).toList();
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user's submitted offers
  Future<void> loadMyOffers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get('/offers/my');
      if (response is List) {
        _myOffers = response.map((o) => DemandOffer.fromJson(o)).toList();
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Close a demand (only when open)
  Future<bool> closeDemand(int id) async {
    try {
      await _api.put('/demands/$id/close', {});
      await loadMyDemands(); // Refresh to get updated status
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Complete a demand (only when in_process)
  Future<bool> completeDemand(int id) async {
    try {
      await _api.put('/demands/$id/complete', {});
      await loadMyDemands(); // Refresh to get updated status
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Cancel a demand (only when in_process)
  Future<bool> cancelDemand(int id) async {
    try {
      await _api.put('/demands/$id/cancel', {});
      await loadMyDemands(); // Refresh to get updated status
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete a demand
  Future<bool> deleteDemand(int id) async {
    try {
      await _api.delete('/demands/$id');
      _demands.removeWhere((d) => d.id == id);
      _myDemands.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Create offer on demand
  Future<DemandOffer?> createOffer({
    required int demandId,
    required String message,
    double? proposedPrice,
    int? storeId,
  }) async {
    try {
      final response = await _api.post('/demands/$demandId/offers', {
        'message': message,
        'proposed_price': proposedPrice,
        'store_id': storeId,
      });

      final offer = DemandOffer.fromJson(response);
      
      // Update current demand's offers if viewing
      if (_currentDemand?.id == demandId) {
        await loadDemandDetails(demandId);
      }
      
      notifyListeners();
      return offer;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Accept an offer
  Future<bool> acceptOffer(int offerId) async {
    try {
      await _api.put('/offers/$offerId/accept', {});
      await loadMyDemands(); // Refresh my demands
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Reject an offer
  Future<bool> rejectOffer(int offerId) async {
    try {
      await _api.put('/offers/$offerId/reject', {});
      await loadMyDemands(); // Refresh my demands
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update an offer (only when pending)
  Future<bool> updateOffer(int offerId, {String? message, double? proposedPrice}) async {
    try {
      final data = <String, dynamic>{};
      if (message != null) data['message'] = message;
      if (proposedPrice != null) data['proposed_price'] = proposedPrice;
      
      await _api.put('/offers/$offerId', data);
      await loadMyOffers(); // Refresh my offers
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete an offer (only when pending)
  Future<bool> deleteOffer(int offerId) async {
    try {
      await _api.delete('/offers/$offerId');
      _myOffers.removeWhere((o) => o.id == offerId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear user-specific data (call on logout or user change)
  void clearUserData() {
    _myDemands = [];
    _myOffers = [];
    _currentDemand = null;
    _error = null;
    notifyListeners();
  }
}
