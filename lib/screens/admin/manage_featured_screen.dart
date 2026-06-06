import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';

/// Admin screen to manage featured/trending products or services
class ManageFeaturedScreen extends StatefulWidget {
  final String zone; // 'trending_products' or 'trending_services'

  const ManageFeaturedScreen({super.key, required this.zone});

  @override
  State<ManageFeaturedScreen> createState() => _ManageFeaturedScreenState();
}

class _ManageFeaturedScreenState extends State<ManageFeaturedScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  
  List<dynamic> _featuredItems = [];
  List<Product> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadFeaturedItems();
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    super.dispose();
  }

  String get _title => widget.zone == 'trending_products' 
      ? 'Featured Products' 
      : 'Featured Services';

  IconData get _icon => widget.zone == 'trending_products'
      ? Icons.local_fire_department
      : Icons.star;

  Color get _color => widget.zone == 'trending_products'
      ? Colors.orange
      : Colors.amber;

  Future<void> _loadFeaturedItems() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/admin/featured?zone=${widget.zone}');
      setState(() {
        _featuredItems = response as List;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading featured items: $e')),
        );
      }
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      _removeOverlay();
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final type = widget.zone == 'trending_products' ? 'product' : 'service';
      final response = await _api.get('/products/all/list?limit=20&type=$type&search=$query');
      setState(() {
        _searchResults = (response as List).map((p) => Product.fromJson(p)).toList();
        _isSearching = false;
      });
      _showOverlay();
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _showOverlay() {
    _removeOverlay();
    if (_searchResults.isEmpty) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final product = _searchResults[index];
                  final isAlreadyFeatured = _featuredItems.any(
                    (item) => item['product_id'] == product.id,
                  );
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: product.thumbnailUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image),
                        ),
                      ),
                    ),
                    title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(product.effectivePriceFormatted),
                    trailing: isAlreadyFeatured
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Added', style: TextStyle(fontSize: 12)),
                          )
                        : IconButton(
                            icon: Icon(Icons.add_circle, color: _color, size: 28),
                            onPressed: () => _addToFeatured(product),
                          ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _addToFeatured(Product product) async {
    try {
      await _api.post('/admin/featured', {
        'product_id': product.id,
        'zone': widget.zone,
        'display_order': _featuredItems.length,
      });
      _searchController.clear();
      _removeOverlay();
      setState(() => _searchResults = []);
      await _loadFeaturedItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "${product.name}" to featured')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeFromFeatured(int featuredItemId) async {
    try {
      await _api.delete('/admin/featured/$featuredItemId');
      await _loadFeaturedItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from featured')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _removeOverlay();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Row(
            children: [
              Icon(_icon, color: _color),
              const SizedBox(width: 8),
              Text(_title),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadFeaturedItems,
            ),
          ],
        ),
        body: Column(
          children: [
            // Search section - fixed at top
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add New Featured Item',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  CompositedTransformTarget(
                    link: _layerLink,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: widget.zone == 'trending_products' 
                            ? 'Search products to add...' 
                            : 'Search services to add...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearching 
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _removeOverlay();
                                      setState(() => _searchResults = []);
                                    },
                                  )
                                : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) => _searchProducts(value),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(_icon, color: _color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Current Featured Items (${_featuredItems.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),

            // Featured items list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _featuredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_icon, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'No featured items yet',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.zone == 'trending_products' 
                                    ? 'Search above to add products'
                                    : 'Search above to add services',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _featuredItems.length,
                          onReorder: (oldIndex, newIndex) async {
                            if (newIndex > oldIndex) newIndex--;
                            final item = _featuredItems.removeAt(oldIndex);
                            _featuredItems.insert(newIndex, item);
                            setState(() {});
                            
                            // Update order on server
                            final items = _featuredItems.asMap().entries.map((e) => {
                              'id': e.value['id'],
                              'display_order': e.key,
                            }).toList();
                            try {
                              await _api.put('/admin/featured/order', {'items': items});
                            } catch (e) {
                              debugPrint('Error updating order: $e');
                            }
                          },
                          itemBuilder: (context, index) {
                            final item = _featuredItems[index];
                            final product = item['product'];
                            return Card(
                              key: ValueKey(item['id']),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Icon(Icons.drag_handle, color: Colors.grey),
                                    ),
                                    const SizedBox(width: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: product?['image'] != null
                                          ? CachedNetworkImage(
                                              imageUrl: product['image'],
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.image),
                                            ),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  product?['name'] ?? 'Unknown Product',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      'Order: ${index + 1}',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                    if (item['is_active'] == true) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _showDeleteConfirmation(item['id']),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int featuredItemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Featured?'),
        content: const Text('This will remove the product from the featured carousel.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFromFeatured(featuredItemId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
