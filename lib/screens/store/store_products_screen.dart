import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../models/store.dart';
import '../../models/store_section.dart';
import '../../services/api_service.dart';
import '../../widgets/store_section_widgets.dart';
import '../../providers/auth_provider.dart';
import '../product/product_detail_screen.dart';
import '../chat/chat_room_screen.dart';

/// Store Products List page with search, filters, and sorting
class StoreProductsScreen extends StatefulWidget {
  final int storeId;
  final Store? store;
  final String? storeSlug;

  const StoreProductsScreen({
    super.key,
    required this.storeId,
    this.store,
    this.storeSlug,
  });

  @override
  State<StoreProductsScreen> createState() => _StoreProductsScreenState();
}

class _StoreProductsScreenState extends State<StoreProductsScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Store? _store;
  List<StoreSection> _sections = [];
  List<Product> _products = [];
  List<String> _categories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isGridView = true;
  String? _error;

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  // Filters
  String _selectedCategory = 'all';
  String _sortBy = 'latest';
  RangeValues _priceRange = const RangeValues(0, 100000);
  bool _showDiscountedOnly = false;
  double _minPrice = 0;
  double _maxPrice = 100000;

  @override
  void initState() {
    super.initState();
    _store = widget.store;
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _lastPage) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load store if not provided
      if (_store == null) {
        final storeResponse = await _api.get('/stores/${widget.storeId}');
        _store = Store.fromJson(storeResponse);
      }

      // Load store sections
      try {
        final sectionsResponse = await _api.get('/stores/${widget.storeId}/sections');
        _sections = (sectionsResponse as List)
            .map((s) => StoreSection.fromJson(s))
            .where((s) => s.isActive)
            .toList();
      } catch (_) {
        _sections = [];
      }

      // Load products with filters
      try {
        await _loadProducts(reset: true);
      } catch (productError) {
        debugPrint('Error loading products: $productError');
        rethrow;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('StoreProductsScreen error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      _products = [];
    }

    final queryParams = <String, String>{
      'page': _currentPage.toString(),
      'per_page': '20',
      'sort': _sortBy,
    };

    if (_searchController.text.isNotEmpty) {
      queryParams['search'] = _searchController.text;
    }
    if (_selectedCategory != 'all') {
      queryParams['category'] = _selectedCategory;
    }
    if (_priceRange.start > _minPrice) {
      queryParams['min_price'] = _priceRange.start.toInt().toString();
    }
    if (_priceRange.end < _maxPrice) {
      queryParams['max_price'] = _priceRange.end.toInt().toString();
    }
    if (_showDiscountedOnly) {
      queryParams['discounted'] = 'true';
    }

    final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await _api.get('/stores/${widget.storeId}/products?$queryString');

    final data = response['data'] as List;
    final meta = response['meta'] as Map<String, dynamic>;
    final filters = response['filters'] as Map<String, dynamic>;

    final newProducts = data.map((p) => Product.fromJson(p)).toList();

    setState(() {
      if (reset) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }
      _currentPage = meta['current_page'];
      _lastPage = meta['last_page'];
      _total = meta['total'];

      // Update filter options from API
      _categories = ['all', ...(filters['categories'] as List).cast<String>()];
      // Handle price values that may come as strings or numbers
      final minP = filters['min_price'];
      final maxP = filters['max_price'];
      _minPrice = minP is String ? double.tryParse(minP) ?? 0 : (minP ?? 0).toDouble();
      _maxPrice = maxP is String ? double.tryParse(maxP) ?? 100000 : (maxP ?? 100000).toDouble();
      
      // Reset price range if it's the initial load
      if (reset && _priceRange == const RangeValues(0, 100000)) {
        _priceRange = RangeValues(_minPrice, _maxPrice);
      }
    });
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _loadProducts();
    setState(() => _isLoadingMore = false);
  }

  void _applyFilters() {
    _loadProducts(reset: true);
  }

  void _shareStore() {
    final slug = _store?.slug ?? widget.storeSlug ?? widget.storeId.toString();
    Share.share(
      '${_store?.name ?? 'Store'} Products\n\nCheck out all products here:\nhttps://3alamati.com/store/$slug/products',
      subject: '${_store?.name ?? 'Store'} Products',
    );
  }

  void _copyLink() {
    final slug = _store?.slug ?? widget.storeSlug ?? widget.storeId.toString();
    Clipboard.setData(ClipboardData(text: 'https://3alamati.com/store/$slug/products'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard!'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to chat')),
      );
      return;
    }
    if (_store?.ownerId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          otherUserId: _store!.ownerId!,
          otherUsername: _store!.name,
          storeId: _store!.id,
          storeName: _store!.name,
        ),
      ),
    );
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
                          _priceRange = RangeValues(_minPrice, _maxPrice);
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
                      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
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
                  min: _minPrice,
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
                      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
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
                      setState(() {}); // Update main state
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
        (_priceRange.start > _minPrice || _priceRange.end < _maxPrice ? 1 : 0);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // App Bar with Store Info
                    SliverAppBar(
                      expandedHeight: 200,
                      pinned: true,
                      backgroundColor: AppTheme.primaryColor,
                      flexibleSpace: FlexibleSpaceBar(
                        background: _buildStoreHeader(),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: _shareStore,
                        ),
                        IconButton(
                          icon: const Icon(Icons.link, color: Colors.white),
                          onPressed: _copyLink,
                        ),
                      ],
                    ),

                    // Quick Actions (Call, Chat, Email, GPS, Share)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _QuickActionButton(
                              icon: Icons.call,
                              label: 'Call',
                              color: const Color(0xFF25D366),
                              onTap: _store?.phone != null ? () => _launchUrl('tel:${_store!.phone}') : null,
                            ),
                            const SizedBox(width: 16),
                            _QuickActionButton(
                              icon: Icons.chat,
                              label: 'Chat',
                              color: AppTheme.primaryColor,
                              onTap: _store?.ownerId != null ? _openChat : null,
                            ),
                            const SizedBox(width: 16),
                            _QuickActionButton(
                              icon: Icons.email,
                              label: 'Email',
                              color: const Color(0xFFEA4335),
                              onTap: _store?.email != null ? () => _launchUrl('mailto:${_store!.email}') : null,
                            ),
                            const SizedBox(width: 16),
                            _QuickActionButton(
                              icon: Icons.location_on,
                              label: 'GPS',
                              color: const Color(0xFFFF5722),
                              onTap: _store?.mapUrl != null ? () => _launchUrl(_store!.mapUrl!) : null,
                            ),
                            const SizedBox(width: 16),
                            _QuickActionButton(
                              icon: Icons.share,
                              label: 'Share',
                              color: const Color(0xFF9C27B0),
                              onTap: _shareStore,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Search Bar at top (right after quick actions)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) {
                            if (_searchController.text.isEmpty || _searchController.text.length >= 2) {
                              _applyFilters();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _applyFilters();
                                    },
                                  ),
                                // Filter button with badge
                                Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.tune),
                                      onPressed: _showFilterSheet,
                                    ),
                                    if (activeFilters > 0)
                                      Positioned(
                                        right: 6,
                                        top: 6,
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                      ),
                    ),

                    // Store Sections (if any)
                    if (_sections.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: _sections.map((section) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: StoreSectionWidget(section: section),
                            )).toList(),
                          ),
                        ),
                      ),

                    // Results count
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          '$_total products found',
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),

                    // Active filter chips
                    if (activeFilters > 0)
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                                if (_priceRange.start > _minPrice || _priceRange.end < _maxPrice)
                                  _buildActiveFilterChip(
                                    'Price: ${_priceRange.start.toInt()}-${_priceRange.end.toInt()} DZD',
                                    () {
                                      setState(() => _priceRange = RangeValues(_minPrice, _maxPrice));
                                      _applyFilters();
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Products Grid (2 per row)
                    _products.isEmpty
                        ? SliverFillRemaining(child: _buildEmptyState())
                        : SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.65,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildGridCard(_products[index]),
                                childCount: _products.length,
                              ),
                            ),
                          ),

                    // Loading more indicator
                    if (_isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),

                    // Bottom padding
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
    );
  }

  Widget _buildStoreHeader() {
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover Image (full height)
          _store?.coverImage != null
              ? CachedNetworkImage(
                  imageUrl: _store!.coverImage!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade800,
                          Colors.blue.shade600,
                        ],
                      ),
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade800,
                        Colors.blue.shade600,
                      ],
                    ),
                  ),
                ),
          // Gradient overlay (black at bottom, transparent at top)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),
          // Store Info at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipOval(
                    child: _store?.profileImage != null
                        ? CachedNetworkImage(
                            imageUrl: _store!.profileImage!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.store, size: 28),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.store, size: 28),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Store Name + Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _store?.name ?? 'Store',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_total Products & Services',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        deleteIconColor: AppTheme.primaryColor,
      ),
    );
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
          FilledButton(onPressed: _loadData, child: const Text('Retry')),
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
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

/// Quick action button for store contact shortcuts
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final buttonColor = color ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isEnabled
                  ? buttonColor.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isEnabled ? buttonColor : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isEnabled ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

