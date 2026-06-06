import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/store.dart';
import '../models/product.dart';
import '../models/store_section.dart';
import '../models/sponsored_banner.dart';
import '../services/api_service.dart';
import '../widgets/store_card.dart';

class StoresProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  // Debounce timer for search
  Timer? _searchDebounceTimer;
  
  List<Store> _stores = [];
  List<Store> _featuredStores = [];
  List<Store> _sponsoredStores = [];
  List<Store> _savedStores = [];
  List<Store> _myStores = [];  // Stores owned by the current user
  int _myStoresTotal = 0;
  List<Store> _nearbyStores = [];  // Nearby stores for map view
  Store? _selectedStore;
  
  // Products and Services for home page
  List<Product> _products = [];
  List<Product> _services = [];
  List<Product> _trendingProducts = [];
  List<Product> _trendingServices = [];
  List<Product> _storeProducts = [];  // Products for a specific store
  
  // Sponsored Banners for home page
  List<SponsoredBanner> _sponsoredBanners = [];
  
  // Nearby stores for home page (separate from map view nearby stores)
  List<Store> _nearbyStoresForHome = [];
  
  bool _isLoading = false;
  String? _error;
  bool _isLocationServiceEnabled = true; // Default to true, updated on check
  
  // Track which stores are currently being saved
  final Set<int> _savingStoreIds = {};
  
  // Track which stores are currently being followed
  final Set<int> _followingStoreIds = {};
  
  // Followed stores list
  List<Store> _followedStores = [];
  
  // Search suggestions
  List<Store> _searchSuggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _suggestionsDebounceTimer;
  
  // Filters
  String? _selectedCategory;
  String? _selectedSubcategory;
  String? _selectedCity;
  String _searchQuery = '';
  CardViewType _viewType = CardViewType.grid;
  double _minRating = 0;
  bool _openNowOnly = false;
  String _sortOrder = 'newest'; // 'newest' or 'oldest'
  int? _selectedWilayaId;

  // Filtered stores (client-side filtering for rating and open status)
  List<Store> get stores {
    List<Store> filtered = _stores;
    
    // Apply minimum rating filter
    if (_minRating > 0) {
      filtered = filtered.where((s) => s.rating >= _minRating).toList();
    }
    
    // Apply open now filter
    if (_openNowOnly) {
      filtered = filtered.where((s) => s.isOpen).toList();
    }
    
    return filtered;
  }
  
  List<Store> get featuredStores => _featuredStores;
  List<Store> get sponsoredStores => _sponsoredStores;
  List<Store> get savedStores => _savedStores;
  List<Store> get myStores => _myStores;
  int get myStoresTotal => _myStoresTotal;
  List<Store> get nearbyStores => _nearbyStores;
  List<Store> get followedStores => _followedStores;
  Store? get selectedStore => _selectedStore;
  
  // Search suggestions getters
  List<Store> get searchSuggestions => _searchSuggestions;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  
  // Products and Services getters
  List<Product> get products => _products;
  List<Product> get services => _services;
  List<Product> get trendingProducts => _trendingProducts;
  List<Product> get trendingServices => _trendingServices;
  List<Product> get storeProducts => _storeProducts;
  
  // Sponsored Banners getter
  List<SponsoredBanner> get sponsoredBanners => _sponsoredBanners;
  
  // Nearby stores for home getter
  List<Store> get nearbyStoresForHome => _nearbyStoresForHome;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  
  void setLocationServiceEnabled(bool enabled) {
    if (_isLocationServiceEnabled != enabled) {
      _isLocationServiceEnabled = enabled;
      notifyListeners();
    }
  }

  String? get selectedCategory => _selectedCategory;
  String? get selectedSubcategory => _selectedSubcategory;
  String? get selectedCity => _selectedCity;
  String get searchQuery => _searchQuery;
  CardViewType get viewType => _viewType;
  double get minRating => _minRating;
  bool get openNowOnly => _openNowOnly;
  String get sortOrder => _sortOrder;
  int? get selectedWilayaId => _selectedWilayaId;
  // Backwards compatibility
  bool get isGridView => _viewType == CardViewType.grid;
  
  // Check if a specific store is being saved
  bool isSavingStore(int storeId) => _savingStoreIds.contains(storeId);
  
  // Check if a specific store is being followed/unfollowed
  bool isFollowingStoreInProgress(int storeId) => _followingStoreIds.contains(storeId);

  void toggleViewMode() {
    // Cycle through: grid -> list -> detailed -> grid
    switch (_viewType) {
      case CardViewType.grid:
        _viewType = CardViewType.list;
        break;
      case CardViewType.list:
        _viewType = CardViewType.detailed;
        break;
      case CardViewType.detailed:
        _viewType = CardViewType.grid;
        break;
    }
    notifyListeners();
  }

  void setViewType(CardViewType type) {
    _viewType = type;
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    // Clear subcategory when category changes
    _selectedSubcategory = null;
    notifyListeners();
    loadStores();
  }

  void setSubcategory(String? subcategory) {
    _selectedSubcategory = subcategory;
    notifyListeners();
    loadStores();
  }

  void setCity(String? city) {
    _selectedCity = city;
    notifyListeners();
    loadStores();
  }

  void setWilayaId(int? wilayaId) {
    _selectedWilayaId = wilayaId;
    notifyListeners();
    loadStores();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    
    // Cancel previous debounce timer if exists
    _searchDebounceTimer?.cancel();
    
    // Debounce the search - wait 300ms after user stops typing
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      loadStores();
    });
  }

  /// Fetch search suggestions with debouncing (for autocomplete dropdown)
  void searchForSuggestions(String query) {
    // Cancel previous debounce timer if exists
    _suggestionsDebounceTimer?.cancel();
    
    // Clear suggestions if query is too short
    if (query.length < 2) {
      _searchSuggestions = [];
      _isLoadingSuggestions = false;
      notifyListeners();
      return;
    }
    
    _isLoadingSuggestions = true;
    notifyListeners();
    
    // Debounce the search - wait 200ms after user stops typing
    _suggestionsDebounceTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        final response = await _api.get('/stores?search=${Uri.encodeComponent(query)}&limit=10');
        final List storeList = response is Map ? (response['data'] ?? []) : response;
        _searchSuggestions = storeList.map((s) => Store.fromJson(s)).toList();
      } catch (e) {
        debugPrint('Error loading search suggestions: $e');
        _searchSuggestions = [];
      } finally {
        _isLoadingSuggestions = false;
        notifyListeners();
      }
    });
  }
  
  /// Clear search suggestions (hide the dropdown)
  void clearSuggestions() {
    _suggestionsDebounceTimer?.cancel();
    _searchSuggestions = [];
    _isLoadingSuggestions = false;
    notifyListeners();
  }

  void setMinRating(double rating) {
    _minRating = rating;
    notifyListeners();
  }

  void setOpenNowOnly(bool value) {
    _openNowOnly = value;
    notifyListeners();
  }

  void setSortOrder(String order) {
    _sortOrder = order;
    notifyListeners();
    loadStores();
  }

  Future<void> loadStores({int limit = 40}) async {
    try {
      _isLoading = true;
      notifyListeners();

      String endpoint = '/stores?limit=$limit&';
      if (_selectedCategory != null) {
        endpoint += 'category=${Uri.encodeComponent(_selectedCategory!)}&';
      }
      if (_selectedSubcategory != null) {
        endpoint += 'subcategory=${Uri.encodeComponent(_selectedSubcategory!)}&';
      }
      if (_selectedCity != null) {
        endpoint += 'city=${Uri.encodeComponent(_selectedCity!)}&';
      }
      if (_selectedWilayaId != null) {
        endpoint += 'wilaya_id=$_selectedWilayaId&';
      }
      if (_searchQuery.isNotEmpty) {
        endpoint += 'search=${Uri.encodeComponent(_searchQuery)}&';
      }
      // Add sort order parameter
      endpoint += 'sort=${_sortOrder == 'oldest' ? 'oldest' : 'newest'}&';

      final response = await _api.get(endpoint);
      debugPrint('API Response received: ${response.runtimeType}');
      // Laravel returns paginated response with 'data' key
      final List storeList = response is Map ? (response['data'] ?? []) : response;
      debugPrint('Store list length: ${storeList.length}');
      
      _stores = [];
      for (int i = 0; i < storeList.length; i++) {
        try {
          final store = Store.fromJson(storeList[i]);
          _stores.add(store);
        } catch (e, stackTrace) {
          debugPrint('Error parsing store at index $i: $e');
          debugPrint('Store data: ${storeList[i]}');
          debugPrint('Stack trace: $stackTrace');
        }
      }
      debugPrint('Successfully parsed ${_stores.length} stores');
      _error = null;
    } catch (e, stackTrace) {
      _error = e.toString();
      debugPrint('Error loading stores: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFeaturedStores() async {
    try {
      final response = await _api.get('/stores/featured');
      _featuredStores = (response as List).map((s) => Store.fromJson(s)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading featured stores: $e');
    }
  }

  Future<void> loadSponsoredStores() async {
    try {
      final response = await _api.get('/stores/sponsored');
      _sponsoredStores = (response as List).map((s) => Store.fromJson(s)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading sponsored stores: $e');
    }
  }

  /// Load nearby stores based on coordinates
  Future<void> loadNearbyStores({
    required double lat,
    required double lng,
    double radius = 20,
    int? categoryId,
    int? subcategoryId,
    String? wilaya,
    String? commune,
    double? minRating,
    bool? isOpen,
    String? search,
    int? limit, // Nullable to allow "no limit"
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      String endpoint = '/stores/nearby?lat=$lat&lng=$lng&radius=$radius';
      
      if (limit != null) {
        endpoint += '&limit=$limit';
      }
      
      if (categoryId != null) {
        endpoint += '&category_id=$categoryId';
      }
      if (subcategoryId != null) {
        endpoint += '&subcategory_id=$subcategoryId';
      }
      if (wilaya != null) {
        endpoint += '&wilaya=${Uri.encodeComponent(wilaya)}';
      }
      if (commune != null) {
        endpoint += '&commune=${Uri.encodeComponent(commune)}';
      }
      if (minRating != null && minRating > 0) {
        endpoint += '&min_rating=$minRating';
      }
      if (isOpen != null) {
        endpoint += '&is_open=${isOpen ? 1 : 0}';
      }
      if (search != null && search.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(search)}';
      }

      final response = await _api.get(endpoint);
      _nearbyStores = (response as List).map((s) => Store.fromJson(s)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading nearby stores: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear nearby stores
  void clearNearbyStores() {
    _nearbyStores = [];
    notifyListeners();
  }

  Future<void> loadSavedStores() async {
    try {
      final response = await _api.get('/users/saved/stores');
      _savedStores = (response as List).map((s) => Store.fromJson(s)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved stores: $e');
    }
  }

  /// Load stores owned by the current user
  /// Load stores owned by the current user
  Future<void> loadMyStores({
    int page = 1,
    int limit = 10,
    String? search,
    String? category,
    String? wilaya,
    String? city,
    String? status,
    double? minRating,
    String? sort,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      String endpoint = '/my-stores?page=$page&limit=$limit';
      if (search != null && search.isNotEmpty) endpoint += '&search=${Uri.encodeComponent(search)}';
      if (category != null) endpoint += '&category=${Uri.encodeComponent(category)}';
      if (wilaya != null) endpoint += '&state=${Uri.encodeComponent(wilaya)}';
      if (city != null) endpoint += '&city=${Uri.encodeComponent(city)}';
      if (status != null) endpoint += '&status=$status';
      if (minRating != null && minRating > 0) endpoint += '&min_rating=$minRating';
      if (sort != null) endpoint += '&sort=$sort';
      
      final response = await _api.get(endpoint);
      
      if (response is Map<String, dynamic> && response.containsKey('data')) {
        final List storeList = response['data'] ?? [];
        _myStores = storeList.map((s) => Store.fromJson(s)).toList();
        _myStoresTotal = response['total'] is int ? response['total'] : 0;
      } else {
         // Fallback for non-paginated or unexpected structure
         final List storeList = response as List;
         _myStores = storeList.map((s) => Store.fromJson(s)).toList();
         _myStoresTotal = _myStores.length;
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading my stores: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load products for home page (limit 12)
  Future<void> loadProducts({int limit = 12}) async {
    try {
      final response = await _api.get('/products/all/list?limit=$limit');
      _products = (response as List).map((p) => Product.fromJson(p)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  /// Load services for home page (limit 12)
  Future<void> loadServices({int limit = 12}) async {
    try {
      final response = await _api.get('/services/all/list?limit=$limit');
      _services = (response as List).map((p) => Product.fromJson(p)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading services: $e');
    }
  }

  /// Load trending products for carousel (paid zone)
  Future<void> loadTrendingProducts() async {
    try {
      final response = await _api.get('/products/trending/list');
      _trendingProducts = (response as List).map((p) => Product.fromJson(p)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading trending products: $e');
    }
  }

  /// Load trending services for carousel (paid zone)
  Future<void> loadTrendingServices() async {
    try {
      final response = await _api.get('/services/trending/list');
      _trendingServices = (response as List).map((p) => Product.fromJson(p)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading trending services: $e');
    }
  }

  /// Load sponsored banners for home page
  Future<void> loadSponsoredBanners() async {
    try {
      final response = await _api.get('/banners');
      _sponsoredBanners = (response as List).map((b) => SponsoredBanner.fromJson(b)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading sponsored banners: $e');
    }
  }

  /// Load nearby stores for home page display (limited to 12)
  Future<void> loadNearbyStoresForHome({
    required double lat,
    required double lng,
    double radius = 50,
  }) async {
    try {
      final response = await _api.get('/stores/nearby?lat=$lat&lng=$lng&radius=$radius&limit=12');
      _nearbyStoresForHome = (response as List).map((s) => Store.fromJson(s)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading nearby stores for home: $e');
    }
  }

  /// Load products for a specific store
  Future<void> loadStoreProducts(String storeId) async {
    try {
      _storeProducts = [];
      notifyListeners();
      
      final response = await _api.get('/stores/$storeId/products');
      final List productList = response is Map ? (response['data'] ?? []) : response;
      _storeProducts = productList.map((p) => Product.fromJson(p)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading store products: $e');
      _storeProducts = [];
      notifyListeners();
    }
  }

  Future<Store?> loadStoreDetails(dynamic identifier) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _api.get('/stores/$identifier');
      _selectedStore = Store.fromJson(response);
      _error = null;
      notifyListeners();
      return _selectedStore;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleSaveStore(int storeId) async {
    // Mark as saving
    _savingStoreIds.add(storeId);
    notifyListeners();
    
    try {
      final response = await _api.post('/users/save-store/$storeId', {});
      final isSaved = response['saved'] == true;
      
      // Update local state
      if (_selectedStore?.id == storeId) {
        _selectedStore = _selectedStore!.copyWith(isSaved: isSaved);
      }
      
      // Update in lists
      _updateStoreInLists(storeId, isSaved);
      
      if (!isSaved) {
        _savedStores.removeWhere((s) => s.id == storeId);
      }
      
      return isSaved;
    } catch (e) {
      debugPrint('Error toggling save: $e');
      rethrow;
    } finally {
      // Remove from saving set
      _savingStoreIds.remove(storeId);
      notifyListeners();
    }
  }

  void _updateStoreInLists(int storeId, bool isSaved) {
    for (int i = 0; i < _stores.length; i++) {
      if (_stores[i].id == storeId) {
        _stores[i] = _stores[i].copyWith(isSaved: isSaved);
        break;
      }
    }
    for (int i = 0; i < _featuredStores.length; i++) {
      if (_featuredStores[i].id == storeId) {
        _featuredStores[i] = _featuredStores[i].copyWith(isSaved: isSaved);
        break;
      }
    }
  }

  /// Toggle follow/unfollow for a store
  Future<bool> toggleFollowStore(int storeId) async {
    // Mark as following in progress
    _followingStoreIds.add(storeId);
    notifyListeners();
    
    try {
      final response = await _api.post('/stores/$storeId/follow', {});
      final isFollowing = response['following'] == true;
      final followerCount = response['follower_count'] as int? ?? 0;
      
      // Update local state
      if (_selectedStore?.id == storeId) {
        _selectedStore = _selectedStore!.copyWith(
          isFollowing: isFollowing,
          followerCount: followerCount,
        );
      }
      
      // Update in lists
      _updateStoreFollowInLists(storeId, isFollowing, followerCount);
      
      // Update followed stores list
      if (!isFollowing) {
        _followedStores.removeWhere((s) => s.id == storeId);
      }
      
      return isFollowing;
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      rethrow;
    } finally {
      // Remove from following set
      _followingStoreIds.remove(storeId);
      notifyListeners();
    }
  }

  void _updateStoreFollowInLists(int storeId, bool isFollowing, int followerCount) {
    for (int i = 0; i < _stores.length; i++) {
      if (_stores[i].id == storeId) {
        _stores[i] = _stores[i].copyWith(
          isFollowing: isFollowing,
          followerCount: followerCount,
        );
        break;
      }
    }
    for (int i = 0; i < _featuredStores.length; i++) {
      if (_featuredStores[i].id == storeId) {
        _featuredStores[i] = _featuredStores[i].copyWith(
          isFollowing: isFollowing,
          followerCount: followerCount,
        );
        break;
      }
    }
  }

  Future<void> loadFollowedStores() async {
    try {
      final response = await _api.get('/users/followed/stores');
      _followedStores = (response as List).map((s) => Store.fromJson(s)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading followed stores: $e');
    }
  }

  Future<bool> createStore(Map<String, dynamic> data) async {
    try {
      await _api.post('/stores', data);
      await loadMyStores();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStore(int storeId, Map<String, dynamic> data) async {
    try {
      await _api.put('/stores/$storeId', data);
      await loadStoreDetails(storeId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStore(int storeId) async {
    try {
      await _api.delete('/stores/$storeId');
      _stores.removeWhere((s) => s.id == storeId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearSelectedStore() {
    _selectedStore = null;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _selectedSubcategory = null;
    _selectedCity = null;
    _selectedWilayaId = null;
    _searchQuery = '';
    _sortOrder = 'newest';
    notifyListeners();
    loadStores();
  }

  // ========== STORE SECTIONS ==========
  
  List<StoreSection> _storeSections = [];
  List<SectionTypeInfo> _sectionTypes = [];
  bool _canUseSponsoredZones = false;
  int _maxSections = 5;
  int _currentSectionCount = 0;
  
  List<StoreSection> get storeSections => _storeSections;
  List<SectionTypeInfo> get sectionTypes => _sectionTypes;
  bool get canUseSponsoredZones => _canUseSponsoredZones;
  int get maxSections => _maxSections;
  int get currentSectionCount => _currentSectionCount;
  bool get canAddMoreSections => _maxSections == -1 || _currentSectionCount < _maxSections;
  
  /// Load sections for a store
  Future<List<StoreSection>> loadStoreSections(int storeId) async {
    try {
      final response = await _api.get('/stores/$storeId/sections');
      if (response is List) {
        _storeSections = response.map((s) => StoreSection.fromJson(s)).toList();
        notifyListeners();
      }
      return _storeSections;
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }
  
  /// Load section types and subscription info for a store
  Future<void> loadSectionTypes(int storeId) async {
    try {
      final response = await _api.get('/stores/$storeId/sections/types');
      if (response is Map<String, dynamic>) {
        if (response['types'] is List) {
          _sectionTypes = (response['types'] as List)
              .map((t) => SectionTypeInfo.fromJson(t))
              .toList();
        }
        _canUseSponsoredZones = response['can_use_sponsored_zones'] ?? false;
        _maxSections = response['max_sections'] ?? 5;
        _currentSectionCount = response['current_count'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }
  
  /// Create a new section
  Future<StoreSection?> createSection(int storeId, {
    required String type,
    String? title,
    int sortOrder = 0,
    bool isActive = true,
    Map<String, dynamic>? config,
    List<int>? productIds,
  }) async {
    try {
      final response = await _api.post('/stores/$storeId/sections', {
        'type': type,
        'title': title,
        'sort_order': sortOrder,
        'is_active': isActive,
        'config': config,
        'product_ids': productIds ?? [],
      });
      
      if (response is Map<String, dynamic>) {
        final section = StoreSection.fromJson(response);
        _storeSections.add(section);
        _currentSectionCount++;
        notifyListeners();
        return section;
      }
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }
  
  /// Update an existing section
  Future<StoreSection?> updateSection(int storeId, int sectionId, {
    String? type,
    String? title,
    int? sortOrder,
    bool? isActive,
    Map<String, dynamic>? config,
    List<int>? productIds,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (type != null) data['type'] = type;
      if (title != null) data['title'] = title;
      if (sortOrder != null) data['sort_order'] = sortOrder;
      if (isActive != null) data['is_active'] = isActive;
      if (config != null) data['config'] = config;
      if (productIds != null) data['product_ids'] = productIds;
      
      final response = await _api.put('/stores/$storeId/sections/$sectionId', data);
      
      if (response is Map<String, dynamic>) {
        final updated = StoreSection.fromJson(response);
        final index = _storeSections.indexWhere((s) => s.id == sectionId);
        if (index != -1) {
          _storeSections[index] = updated;
          notifyListeners();
        }
        return updated;
      }
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }
  
  /// Delete a section
  Future<bool> deleteSection(int storeId, int sectionId) async {
    try {
      await _api.delete('/stores/$storeId/sections/$sectionId');
      _storeSections.removeWhere((s) => s.id == sectionId);
      _currentSectionCount--;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
  
  /// Reorder sections
  Future<bool> reorderSections(int storeId, List<int> sectionIds) async {
    try {
      await _api.post('/stores/$storeId/sections/reorder', {
        'section_ids': sectionIds,
      });
      
      // Update local order
      final orderedSections = <StoreSection>[];
      for (final id in sectionIds) {
        final section = _storeSections.firstWhere((s) => s.id == id);
        orderedSections.add(section);
      }
      _storeSections = orderedSections;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
  
  void clearStoreSections() {
    _storeSections = [];
    _sectionTypes = [];
    notifyListeners();
  }
}

