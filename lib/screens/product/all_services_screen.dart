import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../product/product_detail_screen.dart';

/// All Services listing page with advanced filtering
class AllServicesScreen extends StatefulWidget {
  const AllServicesScreen({super.key});

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Product> _services = [];
  List<Product> _filteredServices = [];
  bool _isLoading = true;
  bool _isGridView = true;
  String? _error;
  
  // Filters
  String _selectedCategory = 'all';
  String? _selectedServiceCategory; // Selected from AppConstants.serviceCategories (main category)
  String? _selectedServiceType; // Selected sub-service type
  String _sortBy = 'latest'; // 'latest', 'name', 'price_low', 'price_high'
  RangeValues _priceRange = const RangeValues(0, 100000);
  
  List<String> _categories = ['all'];
  double _maxPrice = 100000;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.get('/products/all/list?limit=500&type=service');
      _services = (response as List).map((p) => Product.fromJson(p)).toList();
      
      // Extract unique categories and max price
      final categorySet = <String>{'all'};
      double maxP = 0;
      
      for (var service in _services) {
        if (service.category != null && service.category!.isNotEmpty) {
          categorySet.add(service.category!);
        }
        if (service.price != null && service.price! > maxP) {
          maxP = service.price!;
        }
      }
      
      _categories = categorySet.toList()..sort();
      _maxPrice = maxP > 0 ? maxP : 100000;
      _priceRange = RangeValues(0, _maxPrice);
      
      _applyFilters();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = List<Product>.from(_services);
    
    // Specific sub-service type filter (highest priority)
    if (_selectedServiceType != null) {
      filtered = filtered.where((s) {
        final cat = s.category?.toLowerCase() ?? '';
        final typeName = _selectedServiceType!.toLowerCase();
        return cat.contains(typeName) || typeName.contains(cat) || cat == typeName;
      }).toList();
    }
    // Service category filter (from AppConstants - matches by service type name)
    else if (_selectedServiceCategory != null) {
      // Find all service type names in the selected category
      final category = AppConstants.serviceCategories.firstWhere(
        (c) => c.name == _selectedServiceCategory,
        orElse: () => AppConstants.serviceCategories.first,
      );
      final serviceTypeNames = category.services.map((s) => s.name.toLowerCase()).toList();
      
      filtered = filtered.where((s) {
        final cat = s.category?.toLowerCase() ?? '';
        return serviceTypeNames.any((typeName) => cat.contains(typeName) || typeName.contains(cat));
      }).toList();
    }
    
    // Category filter (from product's own category)
    if (_selectedCategory != 'all') {
      filtered = filtered.where((s) => s.category == _selectedCategory).toList();
    }

    // Price filter
    filtered = filtered.where((s) {
      final price = s.effectivePrice;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    // Search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((s) => 
        s.name.toLowerCase().contains(query) ||
        (s.description?.toLowerCase().contains(query) ?? false) ||
        (s.category?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price_low':
        filtered.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      default: // latest
        filtered.sort((a, b) => b.id.compareTo(a.id));
    }

    setState(() => _filteredServices = filtered);
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
          initialChildSize: 0.65,
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
                          _sortBy = 'latest';
                          _priceRange = RangeValues(0, _maxPrice);
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category
                _buildFilterSection('Service Category', Icons.miscellaneous_services),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return FilterChip(
                      label: Text(cat == 'all' ? 'All Categories' : cat),
                      selected: isSelected,
                      onSelected: (_) => setModalState(() => _selectedCategory = cat),
                      selectedColor: Colors.purple.withOpacity(0.2),
                      checkmarkColor: Colors.purple,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Price Range
                _buildFilterSection('Price Range', Icons.attach_money),
                const SizedBox(height: 12),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: _maxPrice,
                  divisions: 100,
                  activeColor: Colors.purple,
                  labels: RangeLabels(
                    '${_priceRange.start.toInt()} DZD',
                    '${_priceRange.end.toInt()} DZD',
                  ),
                  onChanged: (values) => setModalState(() => _priceRange = values),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${_priceRange.start.toInt()} DZD'),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${_priceRange.end.toInt()} DZD'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sort
                _buildFilterSection('Sort By', Icons.sort),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ('latest', 'Latest', Icons.new_releases),
                    ('name', 'Name', Icons.sort_by_alpha),
                    ('price_low', 'Price ↑', Icons.arrow_upward),
                    ('price_high', 'Price ↓', Icons.arrow_downward),
                  ].map((opt) {
                    final isSelected = _sortBy == opt.$1;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(opt.$3, size: 16, color: isSelected ? Colors.purple : Colors.grey),
                          const SizedBox(width: 6),
                          Text(opt.$2),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (_) => setModalState(() => _sortBy = opt.$1),
                      selectedColor: Colors.purple.withOpacity(0.2),
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
                      backgroundColor: Colors.purple,
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
        Icon(icon, size: 20, color: Colors.purple),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFilters = (_selectedCategory != 'all' ? 1 : 0) + 
                          (_priceRange.start > 0 || _priceRange.end < _maxPrice ? 1 : 0) +
                          (_selectedServiceCategory != null || _selectedServiceType != null ? 1 : 0);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('All Services'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
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
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeFilters',
                      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
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
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: const Icon(Icons.search, color: Colors.purple),
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
                fillColor: Colors.purple.shade50,
              ),
            ),
          ),
          
          // Service Category Filter Chips
          Container(
            height: 110,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: AppConstants.serviceCategories.length + 1, // +1 for "All" option
              itemBuilder: (context, index) {
                if (index == 0) {
                  // "All" option
                  final isSelected = _selectedServiceCategory == null && _selectedServiceType == null;
                  return _buildServiceCategoryChip(
                    name: 'All Services',
                    imageUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=300',
                    color: Colors.purple.value,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedServiceCategory = null;
                        _selectedServiceType = null;
                      });
                      _applyFilters();
                    },
                  );
                }
                final category = AppConstants.serviceCategories[index - 1];
                final isSelected = _selectedServiceCategory == category.name || 
                    (_selectedServiceType != null && 
                     category.services.any((s) => s.name == _selectedServiceType));
                return _buildServiceCategoryChip(
                  name: category.name,
                  imageUrl: category.imageUrl,
                  color: category.color,
                  isSelected: isSelected,
                  onTap: () => _showSubServicesBottomSheet(category),
                );
              },
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
                    if (_selectedServiceType != null)
                      _buildActiveFilterChip('🔧 $_selectedServiceType', () {
                        setState(() {
                          _selectedServiceType = null;
                          _selectedServiceCategory = null;
                        });
                        _applyFilters();
                      }),
                    if (_selectedServiceCategory != null && _selectedServiceType == null)
                      _buildActiveFilterChip('🛠️ $_selectedServiceCategory', () {
                        setState(() => _selectedServiceCategory = null);
                        _applyFilters();
                      }),
                    if (_selectedCategory != 'all')
                      _buildActiveFilterChip('Category: $_selectedCategory', () {
                        setState(() => _selectedCategory = 'all');
                        _applyFilters();
                      }),
                    if (_priceRange.start > 0 || _priceRange.end < _maxPrice)
                      _buildActiveFilterChip(
                        'Price: ${_priceRange.start.toInt()}-${_priceRange.end.toInt()} DZD', 
                        () {
                          setState(() => _priceRange = RangeValues(0, _maxPrice));
                          _applyFilters();
                        }
                      ),
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
                  '${_filteredServices.length} services found',
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

          // Services List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                : _error != null
                    ? _buildErrorState()
                    : _filteredServices.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: Colors.purple,
                            onRefresh: _loadServices,
                            child: _isGridView ? _buildGridView() : _buildListView(),
                          ),
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
        backgroundColor: Colors.purple.withOpacity(0.1),
        deleteIconColor: Colors.purple,
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'name': return 'Name';
      case 'price_low': return 'Price ↑';
      case 'price_high': return 'Price ↓';
      default: return 'Latest';
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Error loading services', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadServices, 
            style: FilledButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.miscellaneous_services_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty ? 'No services found' : 'No services available',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('Try adjusting your filters', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: _filteredServices.length,
      itemBuilder: (context, index) => _buildGridCard(_filteredServices[index]),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredServices.length,
      itemBuilder: (context, index) => _buildListCard(_filteredServices[index]),
    );
  }

  Widget _buildGridCard(Product service) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: service.id, product: service)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with service badge
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: service.thumbnailUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.purple.shade50,
                        child: const Icon(Icons.miscellaneous_services, size: 40, color: Colors.purple),
                      ),
                    ),
                  ),
                  // Service badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.build, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'SERVICE',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (service.category != null)
                      Text(
                        service.category!,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      service.effectivePriceFormatted,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(Product service) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: service.id, product: service)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Image with badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: service.thumbnailUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 90,
                      height: 90,
                      color: Colors.purple.shade50,
                      child: const Icon(Icons.miscellaneous_services, color: Colors.purple),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.build, size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (service.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        service.category!,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade700),
                      ),
                    ),
                  Text(
                    service.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (service.description != null)
                    Text(
                      service.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    service.effectivePriceFormatted,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCategoryChip({
    required String name,
    required String imageUrl,
    required int color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(color) : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Color(color).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Color(color).withValues(alpha: 0.3),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Color(color).withValues(alpha: 0.3),
                  child: Icon(Icons.build, color: Color(color)),
                ),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: isSelected ? 0.8 : 0.6),
                    ],
                  ),
                ),
              ),
              // Selected indicator
              if (isSelected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
              // Category name
              Positioned(
                left: 6,
                right: 6,
                bottom: 8,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    shadows: const [
                      Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black54),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubServicesBottomSheet(ServiceCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: category.imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: Color(category.color).withValues(alpha: 0.2),
                            child: Icon(Icons.build, color: Color(category.color)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${category.services.length} services',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // "All in category" button
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedServiceCategory = category.name;
                            _selectedServiceType = null;
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(category.color),
                          side: BorderSide(color: Color(category.color)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('All', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Service list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: category.services.length,
                    itemBuilder: (context, index) {
                      final service = category.services[index];
                      final isSelected = _selectedServiceType == service.name;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: service.imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey.shade200,
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 56,
                              height: 56,
                              color: Color(category.color).withValues(alpha: 0.2),
                              child: Icon(Icons.build, color: Color(category.color)),
                            ),
                          ),
                        ),
                        title: Text(
                          service.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Color(category.color) : null,
                          ),
                        ),
                        subtitle: Text(
                          service.nameEn,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Color(category.color))
                            : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                        onTap: () {
                          setState(() {
                            _selectedServiceType = service.name;
                            _selectedServiceCategory = category.name;
                          });
                          Navigator.pop(context);
                          _applyFilters();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
