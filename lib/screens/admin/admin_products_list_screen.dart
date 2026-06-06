import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../product/product_detail_screen.dart';

/// Admin screen to view and manage all products and services
class AdminProductsListScreen extends StatefulWidget {
  final String? initialType; // 'product', 'service', or null for all

  const AdminProductsListScreen({super.key, this.initialType});

  @override
  State<AdminProductsListScreen> createState() => _AdminProductsListScreenState();
}

class _AdminProductsListScreenState extends State<AdminProductsListScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _isGridView = true;
  String? _error;
  
  // Filters
  String _selectedType = 'all'; // 'all', 'product', 'service'
  String _selectedStatus = 'all'; // 'all', 'active', 'inactive'
  String _selectedCategory = 'all';
  String _sortBy = 'latest'; // 'latest', 'name', 'price_low', 'price_high'
  RangeValues _priceRange = const RangeValues(0, 100000);
  
  List<String> _categories = ['all'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialType == 'product') {
      _tabController.index = 1;
      _selectedType = 'product';
    } else if (widget.initialType == 'service') {
      _tabController.index = 2;
      _selectedType = 'service';
    }
    _tabController.addListener(_onTabChanged);
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedType = ['all', 'product', 'service'][_tabController.index];
      });
      _applyFilters();
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load products
      final productsResponse = await _api.get('/products/all/list?limit=500&type=product');
      final servicesResponse = await _api.get('/products/all/list?limit=500&type=service');
      
      final products = (productsResponse as List).map((p) => Product.fromJson(p)).toList();
      final services = (servicesResponse as List).map((p) => Product.fromJson(p)).toList();
      
      _allProducts = [...products, ...services];
      
      // Extract unique categories
      final categorySet = <String>{'all'};
      for (var p in _allProducts) {
        if (p.category != null && p.category!.isNotEmpty) {
          categorySet.add(p.category!);
        }
      }
      _categories = categorySet.toList();
      
      _applyFilters();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = List<Product>.from(_allProducts);
    
    // Type filter
    if (_selectedType != 'all') {
      filtered = filtered.where((p) => p.type == _selectedType).toList();
    }

    // Status filter
    if (_selectedStatus != 'all') {
      final isActive = _selectedStatus == 'active';
      filtered = filtered.where((p) => p.isActive == isActive).toList();
    }

    // Category filter
    if (_selectedCategory != 'all') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    // Price filter
    filtered = filtered.where((p) {
      final price = p.effectivePrice;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    // Search filter
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((p) => 
        p.name.toLowerCase().contains(searchQuery) ||
        (p.description?.toLowerCase().contains(searchQuery) ?? false) ||
        (p.category?.toLowerCase().contains(searchQuery) ?? false)
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
      default: // latest - by id desc
        filtered.sort((a, b) => b.id.compareTo(a.id));
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _showFilterBottomSheet() {
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedStatus = 'all';
                            _selectedCategory = 'all';
                            _sortBy = 'latest';
                            _priceRange = const RangeValues(0, 100000);
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Status Filter
                  const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ['all', 'active', 'inactive'].map((status) {
                      final isSelected = _selectedStatus == status;
                      return FilterChip(
                        label: Text(status == 'all' ? 'All' : status[0].toUpperCase() + status.substring(1)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() => _selectedStatus = status);
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryColor,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Category Filter
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return FilterChip(
                        label: Text(category == 'all' ? 'All Categories' : category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() => _selectedCategory = category);
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryColor,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Price Range
                  const Text('Price Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 100000,
                    divisions: 100,
                    labels: RangeLabels(
                      '${_priceRange.start.toInt()} DZD',
                      '${_priceRange.end.toInt()} DZD',
                    ),
                    onChanged: (values) {
                      setModalState(() => _priceRange = values);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_priceRange.start.toInt()} DZD'),
                      Text('${_priceRange.end.toInt()} DZD'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sort By
                  const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ('latest', 'Latest'),
                      ('name', 'Name'),
                      ('price_low', 'Price: Low to High'),
                      ('price_high', 'Price: High to Low'),
                    ].map((option) {
                      final isSelected = _sortBy == option.$1;
                      return ChoiceChip(
                        label: Text(option.$2),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() => _sortBy = option.$1);
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),

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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productCount = _allProducts.where((p) => p.type == 'product').length;
    final serviceCount = _allProducts.where((p) => p.type == 'service').length;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Products & Services'),
        actions: [
          // View toggle
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          // Filter button
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterBottomSheet,
              ),
              if (_selectedStatus != 'all' || _selectedCategory != 'all' || _sortBy != 'latest')
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(text: 'All (${_allProducts.length})'),
            Tab(text: 'Products ($productCount)'),
            Tab(text: 'Services ($serviceCount)'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products and services...',
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
              onChanged: (_) => _applyFilters(),
            ),
          ),

          // Active filters chips
          if (_selectedStatus != 'all' || _selectedCategory != 'all')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedStatus != 'all')
                    Chip(
                      label: Text('Status: ${_selectedStatus[0].toUpperCase()}${_selectedStatus.substring(1)}'),
                      onDeleted: () {
                        setState(() => _selectedStatus = 'all');
                        _applyFilters();
                      },
                      deleteIconColor: Colors.grey,
                    ),
                  if (_selectedCategory != 'all')
                    Chip(
                      label: Text('Category: $_selectedCategory'),
                      onDeleted: () {
                        setState(() => _selectedCategory = 'all');
                        _applyFilters();
                      },
                      deleteIconColor: Colors.grey,
                    ),
                ],
              ),
            ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredProducts.length} items found',
                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  'Sort: ${_getSortLabel(_sortBy)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),

          // Products list/grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _filteredProducts.isEmpty
                        ? _buildEmptyState()
                        : _isGridView
                            ? _buildGridView()
                            : _buildListView(),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'name':
        return 'Name';
      case 'price_low':
        return 'Price ↑';
      case 'price_high':
        return 'Price ↓';
      default:
        return 'Latest';
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Error loading products', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadProducts, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No results found'
                : 'No products or services',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) => _buildGridCard(_filteredProducts[index]),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) => _buildListCard(_filteredProducts[index]),
    );
  }

  Widget _buildGridCard(Product product) {
    return GestureDetector(
      onTap: () => _navigateToDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: product.thumbnailUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, size: 40),
                      ),
                    ),
                  ),
                  // Type badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.type == 'service' ? Colors.purple : Colors.blue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.type == 'service' ? 'SERVICE' : 'PRODUCT',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Status indicator
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: product.isActive ? Colors.green : Colors.red,
                        border: Border.all(color: Colors.white, width: 2),
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
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (product.category != null)
                      Text(
                        product.category!,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    const SizedBox(height: 2),
                    if (product.hasDiscount)
                      Text(
                        product.priceFormatted,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      product.effectivePriceFormatted,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
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

  Widget _buildListCard(Product product) {
    return GestureDetector(
      onTap: () => _navigateToDetail(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: product.thumbnailUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.type == 'service' ? Colors.purple.shade100 : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.type == 'service' ? 'Service' : 'Product',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: product.type == 'service' ? Colors.purple : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: product.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          color: product.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  if (product.category != null)
                    Text(
                      product.category!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        product.effectivePriceFormatted,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          product.priceFormatted,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${((1 - product.discountPrice! / product.price!) * 100).toInt()}%',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(productId: product.id, product: product),
      ),
    );
  }
}
