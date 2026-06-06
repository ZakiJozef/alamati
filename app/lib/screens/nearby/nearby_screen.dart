import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/stores_provider.dart';
import '../../providers/locations_provider.dart';
import '../../providers/categories_provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/store.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../models/location.dart';
import '../../core/theme.dart';
import '../store_detail/store_detail_screen.dart';
import '../product/product_detail_screen.dart';
import '../main_shell.dart'; // For QRScannerSheet
import '../../widgets/common_widgets.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final MapController _mapController = MapController();
  final PageController _pageController = PageController(viewportFraction: 0.85);
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  
  // Default location: Algiers, Algeria
  double _currentLat = 36.726065;
  double _currentLng = 3.183034;
  double _radius = 10.0;
  double _currentZoom = 12.0;

  // Filters
  Category? _selectedCategory;
  Category? _selectedSubcategory;
  String? _selectedWilaya;
  String? _selectedCommune;
  double _minRating = 0;
  bool _openOnly = false;
  
  int _selectedStoreIndex = 0;
  bool _isMapReady = false;
  
  // Draggable sheet state
  bool _isSheetExpanded = false;
  List<Product> _selectedStoreProducts = [];
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Load categories and wilayas for filters
    context.read<CategoriesProvider>().loadCategories();
    context.read<LocationsProvider>().loadWilayas();
    
    // Get current GPS location
    await _getCurrentLocation();
    
    // Load nearby stores
    _loadNearbyStores();
  }

  Future<void> _getCurrentLocation({bool showMessages = false}) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showMessages && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('GPS is disabled. Please enable location services.'),
              action: SnackBarAction(
                label: 'Open Settings',
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (showMessages && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (showMessages && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission permanently denied.'),
              action: SnackBarAction(
                label: 'Open Settings',
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _currentLat = position.latitude;
          _currentLng = position.longitude;
        });
        
        // Move map to current location
        if (_isMapReady) {
          _mapController.move(LatLng(_currentLat, _currentLng), 14);
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (showMessages && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Future<void> _loadNearbyStores() async {
    await context.read<StoresProvider>().loadNearbyStores(
      lat: _currentLat,
      lng: _currentLng,
      radius: _radius,
      categoryId: _selectedCategory?.id,
      subcategoryId: _selectedSubcategory?.id,
      wilaya: _selectedWilaya,
      commune: _selectedCommune,
      minRating: _minRating > 0 ? _minRating : null,
      isOpen: _openOnly ? true : null,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );
    
    // After loading, focus on first result
    if (mounted) {
      final stores = context.read<StoresProvider>().nearbyStores;
      if (stores.isNotEmpty) {
        setState(() => _selectedStoreIndex = 0);
        
        // Reset page controller to first item
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
        
        // Focus map on first store
        final firstStore = stores.first;
        if (firstStore.lat != null && firstStore.lng != null && _isMapReady) {
          _mapController.move(LatLng(firstStore.lat!, firstStore.lng!), 12);
        }
      }
    }
  }

  void _onStoreCardChanged(int index) {
    setState(() => _selectedStoreIndex = index);
    
    final stores = context.read<StoresProvider>().nearbyStores;
    if (stores.isNotEmpty && index < stores.length) {
      final store = stores[index];
      if (store.lat != null && store.lng != null) {
        _mapController.move(LatLng(store.lat!, store.lng!), 14);
      }
    }
  }

  void _onMarkerTapped(Store store, int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedStoreProducts() async {
    final stores = context.read<StoresProvider>().nearbyStores;
    if (stores.isEmpty || _selectedStoreIndex >= stores.length) return;
    
    final store = stores[_selectedStoreIndex];
    
    setState(() {
      _isLoadingProducts = true;
    });
    
    try {
      // Load products for the selected store
      await context.read<StoresProvider>().loadStoreProducts(store.id.toString());
      final products = context.read<StoresProvider>().storeProducts;
      
      if (mounted) {
        setState(() {
          _selectedStoreProducts = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedStoreProducts = [];
          _isLoadingProducts = false;
        });
      }
    }
  }

  void _showAllStoresSheet() {
    final stores = context.read<StoresProvider>().nearbyStores;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Nearby Stores (${stores.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List of stores
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    return ListTile(
                      leading: ClipOval(
                        child: store.profileImage != null
                            ? CachedNetworkImage(
                                imageUrl: store.profileImage!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.store),
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.store),
                              ),
                      ),
                      title: Text(store.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        store.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(store.rating.toStringAsFixed(1)),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoreDetailScreen(slugOrId: store.slug ?? store.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<StoresProvider>(
        builder: (context, storesProvider, _) {
          final stores = storesProvider.nearbyStores;
          final storesWithLocation = stores.where((s) => s.hasLocation).toList();
          
          return Stack(
            children: [
              // Map View
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(_currentLat, _currentLng),
                  initialZoom: 12,
                  onMapReady: () => setState(() => _isMapReady = true),
                  onPositionChanged: (position, hasGesture) {
                    if (position.zoom != null && (position.zoom! - _currentZoom).abs() > 0.1) {
                      setState(() => _currentZoom = position.zoom!);
                    }
                  },
                ),
                children: [
                  // OpenStreetMap Tiles
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.3alamati.app',
                  ),
                  // Store Markers
                  MarkerLayer(
                    markers: storesWithLocation.asMap().entries.map((entry) {
                      final index = entry.key;
                      final store = entry.value;
                      final isSelected = index == _selectedStoreIndex;
                      
                      // Dynamic scaling logic
                      // Base scale factor: zoom 12 = 1.0
                      double zoomScale = (_currentZoom / 14.0).clamp(0.4, 1.2);
                      
                      // Base sizes
                      double baseSize = isSelected ? 56.0 : 44.0;
                      
                      // Apply scale
                      double markerSize = baseSize * zoomScale;
                      
                      return Marker(
                        point: LatLng(store.lat!, store.lng!),
                        width: markerSize,
                        height: markerSize + (10 * zoomScale), // Scale the extra space too
                        child: GestureDetector(
                          onTap: () => _onMarkerTapped(store, index),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                width: markerSize,
                                height: markerSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                                    width: (isSelected ? 4 : 3) * zoomScale, // Scale border
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8 * zoomScale, // Scale shadow
                                      offset: Offset(0, 3 * zoomScale),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: store.profileImage != null && store.profileImage!.isNotEmpty
                                      ? Image.network(
                                          store.profileImage!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: AppTheme.primaryColor,
                                            child: Icon(
                                              Icons.store,
                                              color: Colors.white,
                                              size: markerSize * 0.5,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: AppTheme.primaryColor,
                                          child: Icon(
                                            Icons.store,
                                            color: Colors.white,
                                            size: markerSize * 0.5,
                                          ),
                                        ),
                                ),
                              ),
                              // Small pointer triangle
                              if (isSelected)
                                Transform.scale(
                                  scale: zoomScale,
                                  child: CustomPaint(
                                    size: const Size(12, 8),
                                    painter: _TrianglePainter(color: AppTheme.primaryColor),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // User's Current Location Marker
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_currentLat, _currentLng),
                        width: 50,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2), // Blue tint
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.my_location,
                                color: AppTheme.primaryColor, // Blue icon
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Top Bar with Search and Filter
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: _buildSearchBar(),
              ),
              
              // User Location Button
              Positioned(
                right: 16,
                bottom: 280,
                child: FloatingActionButton.small(
                  heroTag: 'location',
                  onPressed: () async {
                    // Re-fetch current GPS location and move map
                    await _getCurrentLocation(showMessages: true);
                  },
                  backgroundColor: Colors.white,
                  child: Icon(Icons.my_location, color: AppTheme.primaryColor),
                ),
              ),
              
              // Bottom Card Slider (Draggable)
              Positioned.fill(
                child: _buildBottomSection(storesProvider, storesWithLocation),
              ),
              
              // Loading Overlay
              if (storesProvider.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.1),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return SearchWithSuggestions(
      controller: _searchController,
      onChanged: (value) {
        // Trigger search suggestions via provider
      },
      onSubmitted: () => _loadNearbyStores(),
      onFilterTap: _showFilterSheet,
      onQRTap: _showQRScanner,
      onStoreTap: (store) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreDetailScreen(slugOrId: store.slug ?? store.id),
          ),
        );
      },
    );
  }

  void _showQRScanner() {
    if (kIsWeb) {
      // Show web not supported message
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                Text(
                  'QR Scanner is only available on mobile devices',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Use the full-featured QR scanner from main_shell
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const QRScannerSheet(),
      );
    }
  }

  Widget _buildBottomSection(StoresProvider provider, List<Store> stores) {
    final selectedStore = stores.isNotEmpty && _selectedStoreIndex < stores.length
        ? stores[_selectedStoreIndex]
        : null;
    
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        final isExpanded = notification.extent > 0.5;
        if (isExpanded != _isSheetExpanded) {
          setState(() {
            _isSheetExpanded = isExpanded;
          });
          // Load products when expanded
          if (isExpanded && selectedStore != null) {
            _loadSelectedStoreProducts();
          }
          // When collapsing, make sure PageView is at the selected store
          if (!isExpanded && _pageController.hasClients) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients && _pageController.page?.round() != _selectedStoreIndex) {
                _pageController.jumpToPage(_selectedStoreIndex);
              }
            });
          }
        }
        return true;
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: 0.32,
        minChildSize: 0.15,
        maxChildSize: 0.85,
        snap: true,
        snapSizes: const [0.32, 0.85],
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(_isSheetExpanded ? 0.95 : 0.75),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    // Header with View All
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isSheetExpanded && selectedStore != null
                                    ? selectedStore.name
                                    : 'Suggested Near You',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _isSheetExpanded && selectedStore != null
                                    ? selectedStore.category ?? ''
                                    : '${stores.length} stores found',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          if (!_isSheetExpanded)
                            TextButton(
                              onPressed: _showAllStoresSheet,
                              child: Text('View all', style: TextStyle(color: AppTheme.primaryColor)),
                            )
                          else if (selectedStore != null)
                            Row(
                              children: [
                                // Close button to collapse
                                IconButton(
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  onPressed: () {
                                    _sheetController.animateTo(
                                      0.32,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                ),
                                // Navigate to full store detail
                                IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StoreDetailScreen(
                                          slugOrId: selectedStore.slug ?? selectedStore.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    
                    // Store Cards (collapsed view)
                    if (!_isSheetExpanded) ...[
                      SizedBox(
                        height: 150,
                        child: stores.isEmpty
                            ? Center(
                                child: Text(
                                  'No stores found nearby',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              )
                            : Builder(
                                builder: (context) {
                                  // Ensure PageController is at the correct page
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (_pageController.hasClients && 
                                        _pageController.page?.round() != _selectedStoreIndex) {
                                      _pageController.jumpToPage(_selectedStoreIndex);
                                    }
                                  });
                                  return PageView.builder(
                                    controller: _pageController,
                                    onPageChanged: _onStoreCardChanged,
                                    itemCount: stores.length,
                                    itemBuilder: (context, index) {
                                  return _buildStoreCard(stores[index], index == _selectedStoreIndex);
                                    },
                                  );
                                },
                              ),
                      ),
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                    ],
                    
                    // Expanded View - Store Details + Products
                    if (_isSheetExpanded && selectedStore != null) ...[
                      // Store info card
                      _buildExpandedStoreInfo(selectedStore),
                      
                      const SizedBox(height: 16),
                      
                      // Action buttons row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildActionChip(
                                icon: Icons.directions,
                                label: 'Directions',
                                color: AppTheme.primaryColor,
                                onTap: () => _openMaps(selectedStore),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionChip(
                                icon: Icons.phone,
                                label: 'Call',
                                color: Colors.green,
                                onTap: selectedStore.phone != null
                                    ? () => _callStore(selectedStore)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionChip(
                                icon: Icons.bookmark_border,
                                label: 'Save',
                                color: Colors.orange,
                                onTap: () => context.read<StoresProvider>().toggleSaveStore(selectedStore.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Social Media & Website Links
                      if (selectedStore.socialLinks.isNotEmpty || selectedStore.website != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ...selectedStore.socialLinks.entries.map((entry) {
                                return _buildSocialButton(entry.key, entry.value);
                              }),
                              if (selectedStore.website != null)
                                _buildSocialButton('website', selectedStore.website!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Products Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Products & Services',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if (_selectedStoreProducts.isNotEmpty)
                              Text(
                                '${_selectedStoreProducts.length} items',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Products Grid or Loading
                      if (_isLoadingProducts)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_selectedStoreProducts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  'No products yet',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        _buildProductsGrid(),
                      
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandedStoreInfo(Store store) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Profile Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: store.profileImage != null
                ? CachedNetworkImage(
                    imageUrl: store.profileImage!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.store, size: 32),
                    ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.store, size: 32),
                  ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating + Open Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            store.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: store.isOpen ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        store.isOpen ? 'Open' : 'Closed',
                        style: TextStyle(
                          color: store.isOpen ? Colors.green : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        store.location,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Followers
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatFollowerCount(store.followerCount)} followers',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isEnabled ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isEnabled ? color : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? color : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(String platform, String url) {
    final icons = {
      'facebook': FontAwesomeIcons.facebook,
      'instagram': FontAwesomeIcons.instagram,
      'whatsapp': FontAwesomeIcons.whatsapp,
      'viber': FontAwesomeIcons.viber,
      'tiktok': FontAwesomeIcons.tiktok,
      'snapchat': FontAwesomeIcons.snapchat,
      'linkedin': FontAwesomeIcons.linkedin,
      'youtube': FontAwesomeIcons.youtube,
      'twitter': FontAwesomeIcons.xTwitter,
      'telegram': FontAwesomeIcons.telegram,
      'website': FontAwesomeIcons.globe,
    };

    final colors = {
      'facebook': const Color(0xFF1877F2),
      'instagram': const Color(0xFFE4405F),
      'whatsapp': const Color(0xFF25D366),
      'viber': const Color(0xFF7360F2),
      'tiktok': const Color(0xFF000000),
      'snapchat': const Color(0xFFFFFC00),
      'linkedin': const Color(0xFF0A66C2),
      'youtube': const Color(0xFFFF0000),
      'twitter': const Color(0xFF000000),
      'telegram': const Color(0xFF0088CC),
      'website': AppTheme.primaryColor,
    };

    final brandColor = colors[platform] ?? AppTheme.primaryColor;
    final iconColor = platform == 'snapchat' ? Colors.black : brandColor;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: brandColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icons[platform] ?? FontAwesomeIcons.link,
            color: iconColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _selectedStoreProducts.length > 6 ? 6 : _selectedStoreProducts.length,
        itemBuilder: (context, index) {
          final product = _selectedStoreProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: product.id,
              product: product,
            ),
          ),
        );
      },
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
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.thumbnailUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image),
                      ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.price != null ? '${product.price!.toStringAsFixed(2)} DA' : '',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(Store store, bool isSelected) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreDetailScreen(slugOrId: store.slug ?? store.id),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.15 : 0.05),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image with overlays
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              child: SizedBox(
                width: 120,
                height: double.infinity,
                child: Stack(
                  children: [
                    // Image
                    Positioned.fill(
                      child: store.profileImage != null
                          ? CachedNetworkImage(
                              imageUrl: store.profileImage!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: Icon(Icons.store, color: Colors.grey.shade400, size: 40),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: Icon(Icons.store, color: Colors.grey.shade400, size: 40),
                            ),
                    ),
                    // Rating badge (top-left)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              store.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Save button (top-right)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => context.read<StoresProvider>().toggleSaveStore(store.id),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            store.isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: store.isSaved ? AppTheme.primaryColor : Colors.grey.shade600,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top section: Category, Name, Location
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category badge + Followers
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.getCategoryColor(store.category).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                store.category?.toUpperCase() ?? 'OTHER',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getCategoryColor(store.category),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.people, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 2),
                            Text(
                              _formatFollowerCount(store.followerCount),
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Name
                        Text(
                          store.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Location
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                store.location.isNotEmpty ? store.location : 'No address',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Bottom section: Action buttons
                    Row(
                      children: [
                        // GPS Button
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.location_on,
                            color: AppTheme.primaryColor,
                            onTap: () => _openMaps(store),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Call Button
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.phone,
                            color: Colors.green,
                            onTap: store.phone != null ? () => _callStore(store) : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Open/Closed indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: store.isOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            store.isOpen ? 'Open' : 'Closed',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: store.isOpen ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: onTap != null ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: onTap != null ? color : Colors.grey.shade400,
          size: 16,
        ),
      ),
    );
  }

  String _formatFollowerCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
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

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          _selectedCategory = null;
                          _selectedSubcategory = null;
                          _selectedWilaya = null;
                          _selectedCommune = null;
                          _minRating = 0;
                          _openOnly = false;
                          _radius = 20;
                        });
                      },
                      child: Text('Clear All', style: TextStyle(color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Filters
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Radius
                      const Text('Search Radius', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _radius.clamp(1, 2000),
                              min: 1,
                              max: 2000,
                              divisions: 1999,
                              label: '${_radius.toInt()} km',
                              activeColor: AppTheme.primaryColor,
                              onChanged: (value) => setSheetState(() => _radius = value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              initialValue: _radius.toInt().toString(),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                suffixText: 'km',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (value) {
                                final parsed = double.tryParse(value);
                                if (parsed != null && parsed >= 1 && parsed <= 5000) {
                                  setSheetState(() => _radius = parsed);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Category & Subcategory - Side by Side
                      const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Consumer<CategoriesProvider>(
                        builder: (context, cats, _) {
                          final categories = cats.storeCategories;
                          final subcategories = _selectedCategory?.children ?? [];
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category Dropdown
                              DropdownSearch<Category>(
                                popupProps: const PopupProps.menu(
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    decoration: InputDecoration(
                                      hintText: 'Search category...',
                                      prefixIcon: Icon(Icons.search, size: 20),
                                    ),
                                  ),
                                ),
                                items: (filter, props) => categories,
                                itemAsString: (cat) => cat.displayName,
                                selectedItem: _selectedCategory,
                                compareFn: (i, s) => i.id == s.id,
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    hintText: 'All Categories',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                
                                onChanged: (value) {
                                  setSheetState(() {
                                    _selectedCategory = value;
                                    _selectedSubcategory = null; // Reset subcategory
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              // Subcategory Dropdown
                              DropdownSearch<Category>(
                                enabled: subcategories.isNotEmpty,
                                popupProps: const PopupProps.menu(
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    decoration: InputDecoration(
                                      hintText: 'Search subcategory...',
                                      prefixIcon: Icon(Icons.search, size: 20),
                                    ),
                                  ),
                                ),
                                items: (filter, props) => subcategories,
                                itemAsString: (cat) => cat.displayName,
                                selectedItem: _selectedSubcategory,
                                compareFn: (i, s) => i.id == s.id,
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    hintText: subcategories.isEmpty ? 'category first' : 'All Subcategories',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                
                                onChanged: (value) {
                                  setSheetState(() {
                                    _selectedSubcategory = value;
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Wilaya & Commune - Side by Side
                      const Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Consumer<LocationsProvider>(
                        builder: (context, locations, _) {
                          final wilayas = locations.wilayas;
                          final communes = _selectedWilaya != null
                              ? locations.getCommunesByWilayaName(_selectedWilaya!)
                              : <Commune>[];
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Wilaya Dropdown
                              DropdownSearch<Wilaya>(
                                popupProps: const PopupProps.menu(
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    decoration: InputDecoration(
                                      hintText: 'Search wilaya...',
                                      prefixIcon: Icon(Icons.search, size: 20),
                                    ),
                                  ),
                                ),
                                items: (filter, props) => wilayas,
                                itemAsString: (w) => '${w.code ?? ""} - ${w.name}',
                                selectedItem: _selectedWilaya != null 
                                    ? locations.getWilayaByName(_selectedWilaya!)
                                    : null,
                                compareFn: (i, s) => i.id == s.id,
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    hintText: 'All Wilayas',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                
                                onChanged: (value) {
                                  setSheetState(() {
                                    _selectedWilaya = value?.name;
                                    _selectedCommune = null; // Reset commune
                                  });
                                  // Load communes for selected wilaya
                                  if (value != null) {
                                    locations.loadCommunesByWilayaName(value.name).then((_) {
                                      setSheetState(() {}); // Refresh to show communes
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              // Commune Dropdown
                              DropdownSearch<Commune>(
                                enabled: communes.isNotEmpty,
                                popupProps: const PopupProps.menu(
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    decoration: InputDecoration(
                                      hintText: 'Search commune...',
                                      prefixIcon: Icon(Icons.search, size: 20),
                                    ),
                                  ),
                                ),
                                items: (filter, props) => communes,
                                itemAsString: (c) => c.name,
                                selectedItem: _selectedCommune != null && communes.isNotEmpty
                                    ? communes.cast<Commune?>().firstWhere((c) => c?.name == _selectedCommune, orElse: () => null)
                                    : null,
                                compareFn: (i, s) => i.id == s.id,
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    hintText: communes.isEmpty ? 'Wilaya first' : 'All Communes',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                
                                onChanged: (value) {
                                  setSheetState(() {
                                    _selectedCommune = value?.name;
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Rating
                      const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.w600)),
                      Slider(
                        value: _minRating,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        label: _minRating > 0 ? '${_minRating.toStringAsFixed(1)}+' : 'Any',
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) => setSheetState(() => _minRating = value),
                      ),
                      Text(_minRating > 0 ? '${_minRating.toStringAsFixed(1)}+ stars' : 'Any rating'),
                      const SizedBox(height: 20),
                      
                      // Open Now
                      SwitchListTile(
                        title: const Text('Open Now Only'),
                        value: _openOnly,
                        onChanged: (value) => setSheetState(() => _openOnly = value),
                        activeColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              // Apply Button
              Container(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {}); // Update parent state
                      _loadNearbyStores();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for drawing a small triangle pointer below selected markers
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
