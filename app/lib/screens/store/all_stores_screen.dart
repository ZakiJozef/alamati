import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../widgets/store_card.dart';
import '../../providers/stores_provider.dart';
import '../../core/theme.dart';
import '../../models/store.dart';
import '../../services/api_service.dart';
import '../store_detail/store_detail_screen.dart';

/// All Stores listing page with advanced filtering
class AllStoresScreen extends StatefulWidget {
  const AllStoresScreen({super.key});

  @override
  State<AllStoresScreen> createState() => _AllStoresScreenState();
}

class _AllStoresScreenState extends State<AllStoresScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  
  List<Store> _stores = [];
  List<Store> _filteredStores = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMorePages = true;
  int _currentPage = 1;
  int _totalStores = 0;
  bool _isGridView = true;
  String? _error;
  
  // Filters
  String _selectedCategory = 'all';
  int? _selectedWilayaId;
  int? _selectedCommuneId;
  String _sortBy = 'name'; // 'name', 'rating', 'followers'
  double _minRating = 0;
  
  List<String> _categories = ['all'];
  List<Map<String, dynamic>> _wilayas = [];
  List<Map<String, dynamic>> _communes = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFilters();
    _loadStores();
  }

  Future<void> _loadFilters() async {
    try {
      final catResponse = await _api.get('/stores/categories');
      if (catResponse != null && catResponse is List) {
        setState(() {
          _categories = ['all', ...catResponse.map((e) => e.toString())];
        });
      }

      final wiloyaResponse = await _api.get('/wilayas');
      if (wiloyaResponse != null && wiloyaResponse is List) {
        setState(() {
          _wilayas = List<Map<String, dynamic>>.from(wiloyaResponse);
        });
      }
    } catch (e) {
      debugPrint('Error loading filters: $e');
    }
  }

  Future<void> _loadCommunes(int wilayaId) async {
    try {
      final response = await _api.get('/wilayas/$wilayaId/communes');
      if (response != null && response is List) {
        setState(() {
          _communes = List<Map<String, dynamic>>.from(response);
          _selectedCommuneId = null; // Reset commune when wilaya changes
        });
      }
    } catch (e) {
      debugPrint('Error loading communes: $e');
    }
  }

  void _applyFilters() {
    _loadStores(refresh: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreStores();
    }
  }

  @override
  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStores({bool refresh = true}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _hasMorePages = true;
        _stores = [];
        _filteredStores = [];
      });
    }

    try {
      String queryString = 'page=$_currentPage&per_page=20';
      
      // Add filters
      if (_searchController.text.isNotEmpty) {
        queryString += '&search=${Uri.encodeComponent(_searchController.text)}';
      }
      if (_selectedCategory != 'all') {
        queryString += '&category=${Uri.encodeComponent(_selectedCategory)}';
      }
      if (_selectedWilayaId != null) {
        queryString += '&wilaya_id=$_selectedWilayaId';
      }
      if (_selectedCommuneId != null) {
        queryString += '&commune_id=$_selectedCommuneId';
      }
      if (_minRating > 0) {
        queryString += '&min_rating=$_minRating';
      }
      
      // Add sort
      queryString += '&sort=$_sortBy';

      final response = await _api.get('/stores?$queryString');
      
      // Handle paginated Laravel response
      List<dynamic> data;
      if (response is Map) {
        data = response['data'] ?? [];
        _totalStores = response['total'] ?? 0;
        _currentPage = response['current_page'] ?? 1;
        _hasMorePages = response['current_page'] < response['last_page'];
      } else {
        data = response as List;
        _totalStores = data.length;
        _hasMorePages = false;
      }
      
      final newStores = data.map((s) => Store.fromJson(s)).toList();
      
      if (refresh) {
        _stores = newStores;
      } else {
        _stores.addAll(newStores);
      }
      
      _filteredStores = _stores;
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreStores() async {
    if (_isLoadingMore || !_hasMorePages || _isLoading) return;
    
    setState(() => _isLoadingMore = true);
    _currentPage++;
    
    try {
      String queryString = 'page=$_currentPage&per_page=20';
      
      // Add filters
      if (_searchController.text.isNotEmpty) {
        queryString += '&search=${Uri.encodeComponent(_searchController.text)}';
      }
      if (_selectedCategory != 'all') {
        queryString += '&category=${Uri.encodeComponent(_selectedCategory)}';
      }
      if (_selectedWilayaId != null) {
        queryString += '&wilaya_id=$_selectedWilayaId';
      }
      if (_selectedCommuneId != null) {
        queryString += '&commune_id=$_selectedCommuneId';
      }
      if (_minRating > 0) {
        queryString += '&min_rating=$_minRating';
      }
      
      // Add sort
      queryString += '&sort=$_sortBy';

      final response = await _api.get('/stores?$queryString');
      
      List<dynamic> data;
      if (response is Map) {
        data = response['data'] ?? [];
        _hasMorePages = response['current_page'] < response['last_page'];
      } else {
        data = response as List;
        _hasMorePages = false;
      }
      
      final newStores = data.map((s) => Store.fromJson(s)).toList();
      _stores.addAll(newStores);
      _filteredStores = _stores;
      
      setState(() => _isLoadingMore = false);
    } catch (e) {
      _currentPage--; // Revert page on error
      setState(() => _isLoadingMore = false);
    }
  }




  Future<void> _callStore(Store store) async {
    if (store.phone != null && store.phone!.isNotEmpty) {
      final Uri phoneUri = Uri(scheme: 'tel', path: store.phone);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    }
  }

  Future<void> _openMaps(Store store) async {
    Uri mapsUri;
    if (store.mapUrl != null && store.mapUrl!.isNotEmpty) {
      mapsUri = Uri.parse(store.mapUrl!);
    } else if (store.lat != null && store.lng != null) {
      mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${store.lat},${store.lng}');
    } else {
      final String query = '${store.name}, ${store.city ?? store.state ?? 'Algeria'}';
      mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    }
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedCategory = 'all';
                          _selectedWilayaId = null;
                          _selectedCommuneId = null;
                          _communes = []; // Clear communes
                          _sortBy = 'name';
                          _minRating = 0;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category Dropdown
                _buildFilterSection('Category', Icons.category),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat == 'all' ? 'All Categories' : cat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => _selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Location (Wilaya & Commune)
                _buildFilterSection('Location', Icons.location_on),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: _selectedWilayaId,
                  decoration: InputDecoration(
                    labelText: 'Wilaya',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Wilayas'),
                    ),
                    ..._wilayas.map((w) {
                      return DropdownMenuItem<int?>(
                        value: w['id'] as int,
                        child: Text(w['name'] ?? ''),
                      );
                    }),
                  ],
                  onChanged: (val) async {
                    setModalState(() {
                      _selectedWilayaId = val;
                      _selectedCommuneId = null;
                      _communes = [];
                    });
                    if (val != null) {
                      // Fetch communes for this wilaya
                      try {
                        final response = await _api.get('/wilayas/$val/communes');
                        if (response != null && response is List) {
                          setModalState(() {
                            _communes = List<Map<String, dynamic>>.from(response);
                          });
                        }
                      } catch (e) {
                        debugPrint('Error loading communes in modal: $e');
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: _selectedCommuneId,
                  decoration: InputDecoration(
                    labelText: 'Commune',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ..._communes.map((c) {
                      return DropdownMenuItem<int?>(
                        value: c['id'] as int,
                        child: Text(c['name'] ?? ''),
                      );
                    }),
                  ],
                  onChanged: _selectedWilayaId == null ? null : (val) {
                    setModalState(() => _selectedCommuneId = val);
                  },
                  // Disable if no wilaya selected
                  disabledHint: const Text('Select Wilaya first'),
                ),
                const SizedBox(height: 24),

                // Rating
                _buildFilterSection('Minimum Rating', Icons.star),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _minRating,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        label: _minRating.toStringAsFixed(1),
                        onChanged: (v) => setModalState(() => _minRating = v),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            _minRating.toStringAsFixed(1),
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sort
                _buildFilterSection('Sort By', Icons.sort),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ('name', 'Name (A-Z)', Icons.sort_by_alpha),
                    ('name_desc', 'Name (Z-A)', Icons.sort_by_alpha),
                    ('rating', 'Rating', Icons.star),
                    ('followers', 'Followers', Icons.people),
                    ('newest', 'Newest', Icons.new_releases),
                    ('oldest', 'Oldest', Icons.history),
                  ].map((opt) {
                    final isSelected = _sortBy == opt.$1;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(opt.$3, size: 16, color: isSelected ? AppTheme.primaryColor : Colors.grey),
                          const SizedBox(width: 6),
                          Text(opt.$2),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (_) => setModalState(() => _sortBy = opt.$1),
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyFilters();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply Filters', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  String _getWilayaName(int id) {
    if (_wilayas.isEmpty) return 'ID: $id';
    try {
      final w = _wilayas.firstWhere((w) => w['id'] == id);
      return w['name'] ?? 'ID: $id';
    } catch (_) {
      return 'ID: $id';
    }
  }

  String _getCommuneName(int id) {
    if (_communes.isEmpty) return 'ID: $id';
    try {
      final c = _communes.firstWhere((c) => c['id'] == id);
      return c['name'] ?? 'ID: $id';
    } catch (_) {
      return 'ID: $id';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFilters = (_selectedCategory != 'all' ? 1 : 0) + 
                          (_selectedWilayaId != null ? 1 : 0) + 
                          (_selectedCommuneId != null ? 1 : 0) +
                          (_minRating > 0 ? 1 : 0);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('All Stores'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterSheet,
              ),
              if (activeFilters > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeFilters',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search stores...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // Active Filters
          if (activeFilters > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedCategory != 'all')
                      _buildActiveFilterChip('Category: $_selectedCategory', () {
                        setState(() => _selectedCategory = 'all');
                        _applyFilters();
                      }),
                    if (_selectedWilayaId != null)
                      _buildActiveFilterChip(
                        'Wilaya: ${_getWilayaName(_selectedWilayaId!)}', 
                        () {
                          setState(() {
                            _selectedWilayaId = null;
                            _selectedCommuneId = null;
                            _communes = []; // Reset communes
                          });
                          _applyFilters();
                        }
                      ),
                    if (_selectedCommuneId != null)
                      _buildActiveFilterChip(
                        'Commune: ${_getCommuneName(_selectedCommuneId!)}', 
                        () {
                          setState(() => _selectedCommuneId = null);
                          _applyFilters();
                        }
                      ),
                    if (_minRating > 0)
                      _buildActiveFilterChip('Rating: ≥${_minRating.toStringAsFixed(1)}', () {
                        setState(() => _minRating = 0);
                        _applyFilters();
                      }),
                  ],
                ),
              ),
            ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredStores.length} stores found',
                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  'Sort: ${_getSortLabel()}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),

          // Store List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _filteredStores.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadStores,
                            child: _isGridView ? _buildGridView() : _buildListView(),
                          ),
          ),
          
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        deleteIconColor: AppTheme.primaryColor,
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'name_desc': return 'Name (Z-A)';
      case 'rating': return 'Rating';
      case 'followers': return 'Followers';
      case 'newest': return 'Newest';
      case 'oldest': return 'Oldest';
      default: return 'Name (A-Z)';
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Error loading stores', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadStores, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty ? 'No stores found' : 'No stores available',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('Try adjusting your filters', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (width > 1200) {
      crossAxisCount = 6;
    } else if (width > 900) {
      crossAxisCount = 4;
    } else if (width > 600) {
      crossAxisCount = 3;
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredStores.length,
      itemBuilder: (context, index) => _buildGridCard(_filteredStores[index]),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStores.length,
      itemBuilder: (context, index) => _buildListCard(_filteredStores[index]),
    );
  }

  // Track which stores are currently being saved/unsaved
  final Set<int> _savingStoreIds = {};

  Widget _buildGridCard(Store store) {
    return StoreCard(
      store: store,
      viewType: CardViewType.grid,
      isSaving: _savingStoreIds.contains(store.id),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StoreDetailScreen(slugOrId: store.slug ?? store.id)),
      ),
      onSave: () async {
        if (_savingStoreIds.contains(store.id)) return;

        setState(() {
          _savingStoreIds.add(store.id);
        });

        try {
          // Toggle save in provider
          await context.read<StoresProvider>().toggleSaveStore(store.id);
          
          // Update local state to reflect change
          if (mounted) {
            setState(() {
              _savingStoreIds.remove(store.id);
              
              // Find the store in both lists and update isSaved status
              final index = _stores.indexWhere((s) => s.id == store.id);
              if (index != -1) {
                _stores[index] = _stores[index].copyWith(isSaved: !store.isSaved);
              }
              
              final filteredIndex = _filteredStores.indexWhere((s) => s.id == store.id);
              if (filteredIndex != -1) {
                _filteredStores[filteredIndex] = _filteredStores[filteredIndex].copyWith(isSaved: !store.isSaved);
              }
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _savingStoreIds.remove(store.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update save status')),
            );
          }
        }
      },
      // StoreCard handles GPS/Call internally for grid view
    );
  }

  Widget _buildListCard(Store store) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StoreDetailScreen(slugOrId: store.slug ?? store.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: store.coverImage ?? '',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(Icons.store, color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (store.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        store.category!,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ),
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          store.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        store.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${store.followerCount} followers',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action Buttons
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () => _openMaps(store),
                    child: Icon(Icons.location_on, size: 20, color: AppTheme.primaryColor),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () => _callStore(store),
                    child: const Icon(Icons.phone, size: 20, color: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
