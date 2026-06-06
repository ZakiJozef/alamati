import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../../models/store.dart';
import '../../services/api_service.dart';
import '../../core/theme.dart';
import 'product_editor_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  final Store store;

  const ManageProductsScreen({super.key, required this.store});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String? _error;
  
  // Filters
  String _searchQuery = '';
  String _typeFilter = 'all'; // all, product, service
  String _statusFilter = 'all'; // all, active, draft
  String _sortBy = 'newest'; // newest, oldest, price_low, price_high, name

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.get('/stores/${widget.store.id}/products');
      List data = [];
      
      if (response is Map && response.containsKey('data')) {
        data = response['data'];
      } else if (response is List) {
        data = response;
      }
      
      setState(() {
        _products = data.map<Product>((json) => Product.fromJson(json)).toList();
        _applyFilters();
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
    var filtered = List<Product>.from(_products);
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
               (p.description?.toLowerCase().contains(query) ?? false) ||
               (p.category?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // Type filter
    if (_typeFilter != 'all') {
      filtered = filtered.where((p) => p.type == _typeFilter).toList();
    }
    
    // Status filter
    if (_statusFilter == 'active') {
      filtered = filtered.where((p) => p.isActive).toList();
    } else if (_statusFilter == 'draft') {
      filtered = filtered.where((p) => !p.isActive).toList();
    }
    
    // Sorting
    switch (_sortBy) {
      case 'oldest':
        // Keep original order (oldest first from API)
        break;
      case 'price_low':
        filtered.sort((a, b) => (a.effectivePrice).compareTo(b.effectivePrice));
        break;
      case 'price_high':
        filtered.sort((a, b) => (b.effectivePrice).compareTo(a.effectivePrice));
        break;
      case 'name':
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'newest':
      default:
        // Reverse for newest first
        filtered = filtered.reversed.toList();
        break;
    }
    
    setState(() => _filteredProducts = filtered);
  }

  void _openProductEditor([Product? product]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductEditorScreen(
          store: widget.store,
          product: product,
        ),
      ),
    );
    
    if (result == true) {
      _loadProducts();
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.delete('/products/${product.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted')),
      );
      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        _typeFilter = 'all';
                        _statusFilter = 'all';
                        _sortBy = 'newest';
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Type Filter
              const Text('Type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _typeFilter == 'all',
                    onSelected: (_) => setSheetState(() => _typeFilter = 'all'),
                  ),
                  FilterChip(
                    label: const Text('Products'),
                    selected: _typeFilter == 'product',
                    onSelected: (_) => setSheetState(() => _typeFilter = 'product'),
                    avatar: const Icon(Icons.shopping_bag, size: 16),
                  ),
                  FilterChip(
                    label: const Text('Services'),
                    selected: _typeFilter == 'service',
                    onSelected: (_) => setSheetState(() => _typeFilter = 'service'),
                    avatar: const Icon(Icons.handyman, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Status Filter
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _statusFilter == 'all',
                    onSelected: (_) => setSheetState(() => _statusFilter = 'all'),
                  ),
                  FilterChip(
                    label: const Text('Published'),
                    selected: _statusFilter == 'active',
                    onSelected: (_) => setSheetState(() => _statusFilter = 'active'),
                    avatar: const Icon(Icons.visibility, size: 16),
                  ),
                  FilterChip(
                    label: const Text('Draft'),
                    selected: _statusFilter == 'draft',
                    onSelected: (_) => setSheetState(() => _statusFilter = 'draft'),
                    avatar: const Icon(Icons.visibility_off, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Sort By
              const Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Newest'),
                    selected: _sortBy == 'newest',
                    onSelected: (_) => setSheetState(() => _sortBy = 'newest'),
                  ),
                  ChoiceChip(
                    label: const Text('Oldest'),
                    selected: _sortBy == 'oldest',
                    onSelected: (_) => setSheetState(() => _sortBy = 'oldest'),
                  ),
                  ChoiceChip(
                    label: const Text('Price: Low to High'),
                    selected: _sortBy == 'price_low',
                    onSelected: (_) => setSheetState(() => _sortBy = 'price_low'),
                  ),
                  ChoiceChip(
                    label: const Text('Price: High to Low'),
                    selected: _sortBy == 'price_high',
                    onSelected: (_) => setSheetState(() => _sortBy = 'price_high'),
                  ),
                  ChoiceChip(
                    label: const Text('Name A-Z'),
                    selected: _sortBy == 'name',
                    onSelected: (_) => setSheetState(() => _sortBy = 'name'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Apply Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_typeFilter != 'all') count++;
    if (_statusFilter != 'all') count++;
    if (_sortBy != 'newest') count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Products', style: const TextStyle(fontSize: 18)),
            Text(
              widget.store.name,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openProductEditor(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _applyFilters();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                
                // Quick Stats and Filter Button
                Row(
                  children: [
                    // Stats
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_filteredProducts.length} of ${_products.length} products',
                        style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    
                    // Filter Button
                    OutlinedButton.icon(
                      onPressed: _showFilterSheet,
                      icon: const Icon(Icons.tune, size: 18),
                      label: Row(
                        children: [
                          const Text('Filters'),
                          if (_activeFilterCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$_activeFilterCount',
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _activeFilterCount > 0 ? AppTheme.primaryColor : Colors.grey.shade700,
                        side: BorderSide(color: _activeFilterCount > 0 ? AppTheme.primaryColor : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Products List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            FilledButton(onPressed: _loadProducts, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _products.isEmpty
                        ? _buildEmptyState()
                        : _filteredProducts.isEmpty
                            ? _buildNoResultsState()
                            : RefreshIndicator(
                                onRefresh: _loadProducts,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (context, index) => _buildProductCard(_filteredProducts[index]),
                                ),
                              ),
          ),
        ],
      ),
      floatingActionButton: _products.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _openProductEditor(),
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Product', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No products yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text('Add your first product to get started', style: TextStyle(color: Colors.grey.shade400)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openProductEditor(),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No products found', style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text('Try adjusting your search or filters', style: TextStyle(color: Colors.grey.shade400)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _typeFilter = 'all';
                _statusFilter = 'all';
                _sortBy = 'newest';
              });
              _applyFilters();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openProductEditor(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: product.thumbnailUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name, 
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!product.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Draft', style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.hasDiscount)
                          Row(
                            children: [
                              Text(
                                product.priceFormatted,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('SALE', style: TextStyle(fontSize: 9, color: Colors.red.shade600, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        Text(
                          product.effectivePriceFormatted,
                          style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Details Row
                    Row(
                      children: [
                        Icon(Icons.inventory_2, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('${product.stock}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: product.isService ? Colors.purple.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.isService ? 'SERVICE' : 'PRODUCT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: product.isService ? Colors.purple.shade700 : Colors.blue.shade700,
                            ),
                          ),
                        ),
                        if (product.category != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              product.category!,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openProductEditor(product);
                  } else if (value == 'delete') {
                    _deleteProduct(product);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red.shade700)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
