import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../product/product_detail_screen.dart';

/// All Products listing page with advanced filtering
class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _isGridView = true;
  String? _error;
  
  // Filters
  String _selectedCategory = 'all';
  String _sortBy = 'latest'; // 'latest', 'name', 'price_low', 'price_high', 'discount'
  RangeValues _priceRange = const RangeValues(0, 100000);
  bool _showDiscountedOnly = false;
  
  List<String> _categories = ['all'];
  double _maxPrice = 100000;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.get('/products/all/list?limit=500&type=product');
      _products = (response as List).map((p) => Product.fromJson(p)).toList();
      
      // Extract unique categories and max price
      final categorySet = <String>{'all'};
      double maxP = 0;
      
      for (var product in _products) {
        if (product.category != null && product.category!.isNotEmpty) {
          categorySet.add(product.category!);
        }
        if (product.price != null && product.price! > maxP) {
          maxP = product.price!;
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
    var filtered = List<Product>.from(_products);
    
    // Category filter
    if (_selectedCategory != 'all') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    // Price filter
    filtered = filtered.where((p) {
      final price = p.effectivePrice;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    // Discount filter
    if (_showDiscountedOnly) {
      filtered = filtered.where((p) => p.hasDiscount).toList();
    }

    // Search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((p) => 
        p.name.toLowerCase().contains(query) ||
        (p.description?.toLowerCase().contains(query) ?? false) ||
        (p.category?.toLowerCase().contains(query) ?? false)
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
      case 'discount':
        filtered.sort((a, b) {
          final discountA = a.hasDiscount ? ((1 - a.discountPrice! / a.price!) * 100) : 0;
          final discountB = b.hasDiscount ? ((1 - b.discountPrice! / b.price!) * 100) : 0;
          return discountB.compareTo(discountA);
        });
        break;
      default: // latest
        filtered.sort((a, b) => b.id.compareTo(a.id));
    }

    setState(() => _filteredProducts = filtered);
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
                          _sortBy = 'latest';
                          _priceRange = RangeValues(0, _maxPrice);
                          _showDiscountedOnly = false;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category
                _buildFilterSection('Category', Icons.category),
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
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryColor,
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
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${_priceRange.start.toInt()} DZD'),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${_priceRange.end.toInt()} DZD'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Discount Only
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_offer, color: Colors.red.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Discounted Items Only',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Show only products with discounts',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _showDiscountedOnly,
                        onChanged: (v) => setModalState(() => _showDiscountedOnly = v),
                        activeColor: Colors.red,
                      ),
                    ],
                  ),
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
                    ('discount', 'Best Deals', Icons.local_offer),
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

  @override
  Widget build(BuildContext context) {
    final activeFilters = (_selectedCategory != 'all' ? 1 : 0) + 
                          (_showDiscountedOnly ? 1 : 0) +
                          (_priceRange.start > 0 || _priceRange.end < _maxPrice ? 1 : 0);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('All Products'),
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
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search products...',
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
                    if (_showDiscountedOnly)
                      _buildActiveFilterChip('Discounts Only', () {
                        setState(() => _showDiscountedOnly = false);
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
                  '${_filteredProducts.length} products found',
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

          // Products List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _filteredProducts.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadProducts,
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
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        deleteIconColor: AppTheme.primaryColor,
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'name': return 'Name';
      case 'price_low': return 'Price ↑';
      case 'price_high': return 'Price ↓';
      case 'discount': return 'Best Deals';
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
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty ? 'No products found' : 'No products available',
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
        childAspectRatio: 0.65,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) => _buildGridCard(_filteredProducts[index]),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) => _buildListCard(_filteredProducts[index]),
    );
  }

  Widget _buildGridCard(Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id, product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${((1 - product.discountPrice! / product.price!) * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (product.category != null)
                      Text(
                        product.category!,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    const SizedBox(height: 4),
                    if (product.hasDiscount)
                      Text(
                        product.priceFormatted,
                        style: TextStyle(
                          fontSize: 11,
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id, product: product)),
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
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: product.thumbnailUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image),
                    ),
                  ),
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${((1 - product.discountPrice! / product.price!) * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
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
                  if (product.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.category!,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                      ),
                    ),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (product.hasDiscount) ...[
                        Text(
                          product.priceFormatted,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        product.effectivePriceFormatted,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
