import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stores_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/store_card.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/store.dart';
import '../../models/product.dart';
import '../../models/sponsored_banner.dart';
import '../store_detail/store_detail_screen.dart';
import '../product/product_detail_screen.dart';
import '../store/all_stores_screen.dart';
import '../product/all_products_screen.dart';
import '../product/all_services_screen.dart';
import '../cart/cart_screen.dart';
import '../../providers/locations_provider.dart';
import '../../models/location.dart';
import '../main_shell.dart'; // For QRScannerSheet

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Use addPostFrameCallback to ensure data loads after widget tree is built
    // and auth token is fully propagated (fixes post-login loading issue)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _loadNearbyStores();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User returned to the app (possibly from Settings), re-check location
      _loadNearbyStores();
    }
  }

  Future<void> _loadData() async {
    final storesProvider = context.read<StoresProvider>();
    await Future.wait([
      storesProvider.loadStores(limit: 40),
      storesProvider.loadFeaturedStores(),
      storesProvider.loadSponsoredStores(),
      storesProvider.loadProducts(limit: 12),
      storesProvider.loadServices(limit: 12),
      storesProvider.loadTrendingProducts(),
      storesProvider.loadTrendingServices(),
      storesProvider.loadTrendingServices(),
      storesProvider.loadSponsoredBanners(),
    ]);
    // Load nearby stores separately as it might fail or take longer
    await _loadNearbyStores();
  }

  Future<void> _loadNearbyStores() async {
    try {
      final storesProvider = context.read<StoresProvider>();
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      storesProvider.setLocationServiceEnabled(serviceEnabled);
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          storesProvider.setLocationServiceEnabled(false); // Treat denied permission as disabled for UI purposes
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        storesProvider.setLocationServiceEnabled(false); // Treat denied permission as disabled for UI purposes
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      
      // If we got here, location is enabled!
      storesProvider.setLocationServiceEnabled(true);

      if (mounted) {
        storesProvider.loadNearbyStoresForHome(
          lat: position.latitude,
          lng: position.longitude,
        );
      }
    } catch (e) {
      debugPrint('Error loading nearby stores for home: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final storesProvider = context.watch<StoresProvider>();
    
    // Responsive breakpoint - use phone layout for narrow screens
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 800;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.isAuthenticated ? 'Welcome back,' : 'Discover Stores',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          authProvider.user?.displayName ?? 'Welcome to 3alamati!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                      ),
                      child: ClipOval(
                        child: authProvider.user?.profilePic != null
                            ? CachedNetworkImage(
                                imageUrl: authProvider.user!.profilePic!,
                                fit: BoxFit.cover,
                              )
                            : Icon(Icons.person, color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Cart icon with badge
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, child) {
                        return Stack(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CartScreen()),
                                  );
                                },
                                icon: Icon(
                                  Icons.shopping_cart_outlined,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            if (cartProvider.itemCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    cartProvider.itemCount > 9 ? '9+' : '${cartProvider.itemCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Search Bar with Suggestions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: SearchWithSuggestions(
                  controller: _searchController,
                  onChanged: (value) => storesProvider.setSearchQuery(value),
                  onSubmitted: () => storesProvider.loadStores(),
                  onFilterTap: () => _showFilterSheet(context),
                  onQRTap: () => _showQRScanner(context),
                  onStoreTap: (store) => _navigateToDetail(store.id),
                ),
              ),

              // Tab Bar
              TabBar(
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: AppTheme.primaryColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store, size: 18),
                        SizedBox(width: 6),
                        Text('Stores'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag, size: 18),
                        SizedBox(width: 6),
                        Text('Products'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.handyman, size: 18),
                        SizedBox(width: 6),
                        Text('Services'),
                      ],
                    ),
                  ),
                ],
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  children: [
                    // TAB 1: Stores only
                    RefreshIndicator(
                      onRefresh: _loadData,
                      child: _buildStoresTab(storesProvider, isWideScreen),
                    ),
                    // TAB 2: Products only
                    RefreshIndicator(
                      onRefresh: _loadData,
                      child: _buildProductsTab(storesProvider, isWideScreen),
                    ),
                    // TAB 3: Services
                    RefreshIndicator(
                      onRefresh: _loadData,
                      child: _buildServicesTab(storesProvider, isWideScreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// TAB 1: Stores only content
  Widget _buildStoresTab(StoresProvider storesProvider, bool isWideScreen) {
    return CustomScrollView(
      slivers: [
        // Featured Stores Carousel
        if (storesProvider.featuredStores.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Featured Stores',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                CarouselSlider.builder(
                  itemCount: storesProvider.featuredStores.length,
                  itemBuilder: (context, index, realIndex) {
                    final store = storesProvider.featuredStores[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12), // Space for shadow
                      child: _buildCarouselCard(store),
                    );
                  },
                  options: CarouselOptions(
                    height: (isWideScreen ? 220 : 180) + 12, // Add height for shadow padding
                    viewportFraction: isWideScreen ? 0.24 : 0.85,
                    enlargeCenterPage: !isWideScreen,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 5),
                    clipBehavior: Clip.none,
                  ),
                ),
              ],
            ),
          ),

        // Sponsored Stores Section - Premium Design
        if (storesProvider.sponsoredStores.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade50,
                    Colors.orange.shade50.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.star, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sponsored Stores',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Premium partner stores',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'PREMIUM',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: storesProvider.sponsoredStores.length,
                      itemBuilder: (context, index) {
                        final store = storesProvider.sponsoredStores[index];
                        return _buildSponsoredCard(store);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),


        // All Stores Header with Show All
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.store, color: AppTheme.primaryColor, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'All Stores',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AllStoresScreen()));
                      },
                      child: Text(
                        'Show All',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        storesProvider.setSortOrder(
                          storesProvider.sortOrder == 'newest' ? 'oldest' : 'newest'
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              storesProvider.sortOrder == 'newest' 
                                ? Icons.arrow_downward 
                                : Icons.arrow_upward,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              storesProvider.sortOrder == 'newest' ? 'Newest' : 'Oldest',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Stores Grid - LIMITED TO 12
        if (storesProvider.isLoading)
          const SliverToBoxAdapter(
            child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
          )
        else if (storesProvider.stores.isEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: Center(
                child: Text('No stores found', style: TextStyle(color: Colors.grey.shade500)),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWideScreen ? 5 : 2,
                mainAxisSpacing: isWideScreen ? 20 : 16,
                crossAxisSpacing: isWideScreen ? 20 : 16,
                childAspectRatio: isWideScreen ? 0.85 : 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final store = storesProvider.stores[index];
                  return StoreCard(
                    store: store,
                    viewType: CardViewType.grid,
                    onTap: () => _navigateToDetail(store.id),
                    onSave: () => _handleSaveStore(store.id),
                    isSaving: storesProvider.isSavingStore(store.id),
                  );
                },
                childCount: storesProvider.stores.length > 12 ? 12 : storesProvider.stores.length,
              ),
            ),
          ),

        // 📢 SPONSORED BANNERS SECTION
        if (storesProvider.sponsoredBanners.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                  child: Row(
                    children: [
                      Icon(Icons.campaign, color: AppTheme.primaryColor, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Sponsored',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: storesProvider.sponsoredBanners.length,
                    itemBuilder: (context, index) {
                      final banner = storesProvider.sponsoredBanners[index];
                      return _buildSponsoredBannerCard(banner);
                    },
                  ),
                ),
              ],
            ),
          ),

        // 📍 NEARBY STORES SECTION
        if (storesProvider.nearbyStoresForHome.isNotEmpty || !storesProvider.isLocationServiceEnabled)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red.shade400, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Nearby Stores',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (storesProvider.isLocationServiceEnabled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NEAR YOU',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Nearby Stores Grid or Nudge Card
        if (!storesProvider.isLocationServiceEnabled)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.location_off, color: Colors.red.shade400, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Find stores near you',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enable location services to see stores in your area.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                              await Geolocator.openLocationSettings();
                              // Retry loading after returning from settings
                              _loadNearbyStores(); 
                            },
                            child: Text(
                              'Enable Location',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (storesProvider.nearbyStoresForHome.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWideScreen ? 5 : 2,
                mainAxisSpacing: isWideScreen ? 20 : 16,
                crossAxisSpacing: isWideScreen ? 20 : 16,
                childAspectRatio: isWideScreen ? 0.85 : 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final store = storesProvider.nearbyStoresForHome[index];
                  return StoreCard(
                    store: store,
                    viewType: CardViewType.grid,
                    onTap: () => _navigateToDetail(store.id),
                    onSave: () => _handleSaveStore(store.id),
                    isSaving: storesProvider.isSavingStore(store.id),
                  );
                },
                childCount: storesProvider.nearbyStoresForHome.length > 12 ? 12 : storesProvider.nearbyStoresForHome.length,
              ),
            ),
          ),

        // Bottom padding if no nearby stores
        if (storesProvider.nearbyStoresForHome.isEmpty)
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
      ],
    );
  }

  /// TAB 2: Products only content
  Widget _buildProductsTab(StoresProvider storesProvider, bool isWideScreen) {
    return CustomScrollView(
      slivers: [
        // 🔥 TRENDING PRODUCTS CAROUSEL (Featured)
        if (storesProvider.trendingProducts.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Trending Products',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllProductsScreen())),
                        child: Text(
                          'See All',
                          style: TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('FEATURED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                      ),
                    ],
                  ),
                ),
                CarouselSlider.builder(
                  itemCount: storesProvider.trendingProducts.length,
                  itemBuilder: (context, index, realIndex) {
                    final product = storesProvider.trendingProducts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildProductCarouselCard(product, isService: false),
                    );
                  },
                  options: CarouselOptions(
                    height: 200 + 12,
                    viewportFraction: isWideScreen ? 0.2 : 0.7,
                    enlargeCenterPage: !isWideScreen,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 4),
                    clipBehavior: Clip.none,
                  ),
                ),
              ],
            ),
          ),


        // Sponsored Products Section
        if (storesProvider.trendingProducts.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sponsored',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'AD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: storesProvider.trendingProducts.length > 6 ? 6 : storesProvider.trendingProducts.length,
                    itemBuilder: (context, index) {
                      final product = storesProvider.trendingProducts[index];
                      return _buildSponsoredProductCard(product);
                    },
                  ),
                ),
              ],
            ),
          ),

        // Products Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_bag, color: AppTheme.primaryColor, size: 22),
                    const SizedBox(width: 8),
                    const Text('All Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AllProductsScreen()));
                  },
                  child: Text('Show All', style: TextStyle(fontSize: 14, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),

        // Products Grid (limit 12)
        if (storesProvider.products.isEmpty)
          SliverToBoxAdapter(
            child: SizedBox(height: 100, child: Center(child: Text('No products yet', style: TextStyle(color: Colors.grey.shade500)))),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWideScreen ? 6 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWideScreen ? 0.75 : 0.7,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProductCard(storesProvider.products[index]),
                childCount: storesProvider.products.length > 12 ? 12 : storesProvider.products.length,
              ),
            ),
          ),
      ],
    );
  }

  /// TAB 3: Services content
  Widget _buildServicesTab(StoresProvider storesProvider, bool isWideScreen) {
    return CustomScrollView(
      slivers: [
        // ⭐ TRENDING SERVICES CAROUSEL (Paid Zone)
        if (storesProvider.trendingServices.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 22),
                      const SizedBox(width: 8),
                      const Text('Trending Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllServicesScreen())),
                        child: Text(
                          'See All',
                          style: TextStyle(fontSize: 13, color: Colors.purple, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text('SPONSORED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                      ),
                    ],
                  ),
                ),
                CarouselSlider.builder(
                  itemCount: storesProvider.trendingServices.length,
                  itemBuilder: (context, index, realIndex) {
                    final service = storesProvider.trendingServices[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildProductCarouselCard(service, isService: true),
                    );
                  },
                  options: CarouselOptions(
                    height: 200 + 12,
                    viewportFraction: isWideScreen ? 0.2 : 0.7,
                    enlargeCenterPage: !isWideScreen,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 5),
                    clipBehavior: Clip.none,
                  ),
                ),
              ],
            ),
          ),


        // Sponsored Services Section (horizontal list like Sponsored stores)
        if (storesProvider.trendingServices.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sponsored',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'AD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: storesProvider.trendingServices.length > 6 ? 6 : storesProvider.trendingServices.length,
                    itemBuilder: (context, index) {
                      final service = storesProvider.trendingServices[index];
                      return _buildSponsoredServiceCard(service);
                    },
                  ),
                ),
              ],
            ),
          ),

        // Services Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.handyman, color: Colors.purple, size: 22),
                    const SizedBox(width: 8),
                    const Text('All Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AllServicesScreen()));
                  },
                  child: Text('Show All', style: TextStyle(fontSize: 14, color: Colors.purple, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),

        // Services Grid (limit 12)
        if (storesProvider.services.isEmpty)
          SliverToBoxAdapter(
            child: SizedBox(height: 100, child: Center(child: Text('No services yet', style: TextStyle(color: Colors.grey.shade500)))),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWideScreen ? 6 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWideScreen ? 0.75 : 0.7,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildProductCard(storesProvider.services[index]),
                childCount: storesProvider.services.length > 12 ? 12 : storesProvider.services.length,
              ),
            ),
          ),
      ],
    );
  }

  /// Build a product/service card for home page
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: product.id, product: product)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: product.thumbnailUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 40),
                  ),
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (product.hasDiscount)
                      Text(
                        product.priceFormatted,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough),
                      ),
                    Text(
                      product.effectivePriceFormatted,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
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

  /// Build a product/service carousel card matching the Featured stores style
  Widget _buildProductCarouselCard(Product product, {bool isService = false}) {
    final Color accentColor = isService ? Colors.amber : Colors.orange;
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: product.id, product: product)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade300,
          image: DecorationImage(
            image: CachedNetworkImageProvider(product.thumbnailUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.category ?? (isService ? 'Service' : 'Product'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // Price and discount
              Row(
                children: [
                  Text(
                    product.effectivePriceFormatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (product.hasDiscount) ...[
                    const SizedBox(width: 8),
                    Text(
                      product.priceFormatted,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 6),
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
      ),
    );
  }

  Widget _buildCarouselCard(Store store) {
    return GestureDetector(
      onTap: () => _navigateToDetail(store.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade300,
          image: (store.coverImage != null && store.coverImage!.isNotEmpty)
            ? DecorationImage(
                image: CachedNetworkImageProvider(store.coverImage!),
                fit: BoxFit.cover,
              )
            : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryBadge(category: store.category ?? 'Other'),
              const SizedBox(height: 8),
              Text(
                store.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    store.location,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    store.rating.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSponsoredCard(Store store) {
    return GestureDetector(
      onTap: () => _navigateToDetail(store.id),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with gradient overlay
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: (store.profileImage != null && store.profileImage!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: store.profileImage!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: Colors.amber.shade50,
                              child: const Icon(Icons.store, color: Colors.amber, size: 32),
                            ),
                          )
                        : Container(
                            color: Colors.amber.shade50,
                            child: const Center(
                              child: Icon(Icons.store, color: Colors.amber, size: 32),
                            ),
                          ),
                  ),
                  // Rating badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            store.rating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store.category ?? 'Store',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsoredBannerCard(SponsoredBanner banner) {
    return GestureDetector(
      onTap: () async {
        if (banner.linkUrl != null && banner.linkUrl!.isNotEmpty) {
          final uri = Uri.tryParse(banner.linkUrl!);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 280,
                height: 140,
                child: CachedNetworkImage(
                  imageUrl: banner.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
            // Gradient overlay for text
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Text(
                  banner.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Sponsored badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.campaign, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'AD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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

  Widget _buildSponsoredServiceCard(Product service) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: service.id, product: service)),
      ),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.shade100),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: service.thumbnailUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.purple.shade50,
                  child: Icon(Icons.handyman, color: Colors.purple.shade300),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.category ?? 'Service',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.shade600,
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

  Widget _buildSponsoredProductCard(Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: product.id, product: product)),
      ),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: product.thumbnailUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.orange.shade50,
                  child: Icon(Icons.shopping_bag, color: Colors.orange.shade300),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category ?? 'Product',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
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

  void _navigateToDetail(int storeId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StoreDetailScreen(slugOrId: storeId)),
    );
  }

  void _callStore(String phone) async {
    // Implement phone call functionality
  }

  void _handleSaveStore(int storeId) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }
    
    final storesProvider = context.read<StoresProvider>();
    try {
      await storesProvider.toggleSaveStore(storeId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save store: $e')),
        );
      }
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to save stores to your favorites.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  void _showLocationPicker(BuildContext context) {
    // Implement location picker
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final storesProvider = context.read<StoresProvider>();
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: storesProvider.selectedCategory == null,
                    onSelected: (_) {
                      storesProvider.setCategory(null);
                      Navigator.pop(context);
                    },
                  ),
                  ...AppConstants.storeCategories.map((category) => FilterChip(
                    label: Text('${category.emoji} ${category.name}'),
                    selected: storesProvider.selectedCategory == category.name,
                    onSelected: (_) {
                      storesProvider.setCategory(category.name);
                      Navigator.pop(context);
                    },
                  )),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQRScanner(BuildContext context) {
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


}

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedWilaya;
  int? _selectedWilayaId;
  String? _selectedCategory;
  String? _selectedSubcategory;
  double _minRating = 0;
  bool _onlyOpen = false;
  String _sortOrder = 'newest';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationsProvider>().loadWilayas();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final storesProvider = context.read<StoresProvider>();
    _selectedWilaya = storesProvider.selectedCity;
    _selectedWilayaId = storesProvider.selectedWilayaId;
    _selectedCategory = storesProvider.selectedCategory;
    _selectedSubcategory = storesProvider.selectedSubcategory;
    _minRating = storesProvider.minRating;
    _onlyOpen = storesProvider.openNowOnly;
    _sortOrder = storesProvider.sortOrder;
  }
  
  /// Get subcategories for the selected category
  List<String> get _availableSubcategories {
    if (_selectedCategory == null) return [];
    return AppConstants.getStoreSubcategories(_selectedCategory!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ... header ...
          // Drag handle
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
                  onPressed: _clearAllFilters,
                  child: Text('Clear All', style: TextStyle(color: AppTheme.primaryColor)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Filter content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location filters
                  const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Consumer<LocationsProvider>(
                    builder: (context, locations, _) {
                      final selectedWilayaObj = locations.getWilayaByName(_selectedWilaya ?? '');
                      
                      return DropdownSearch<Wilaya>(
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search wilaya...',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        items: (filter, props) => locations.wilayas,
                        itemAsString: (w) => '${w.code} - ${w.name}',
                        selectedItem: selectedWilayaObj,
                        compareFn: (i, s) => i.id == s.id,
                        decoratorProps: DropDownDecoratorProps(
                          decoration: InputDecoration(
                            labelText: 'Wilaya',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedWilaya = value?.name;
                            _selectedWilayaId = value?.id;
                          });
                        },
                      );
                    }
                  ),
                  const SizedBox(height: 24),

                  // Category Dropdown
                  const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  DropdownSearch<StoreCategory>(
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: const TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search category...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      itemBuilder: (context, category, isSelected, isHovered) {
                        return ListTile(
                          leading: Text(category.emoji, style: const TextStyle(fontSize: 24)),
                          title: Text(category.name),
                          selected: isSelected,
                          selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
                        );
                      },
                    ),
                    items: (filter, props) => AppConstants.storeCategories,
                    itemAsString: (category) => '${category.emoji} ${category.name}',
                    selectedItem: _selectedCategory != null 
                        ? AppConstants.storeCategories.firstWhere(
                            (c) => c.name == _selectedCategory,
                            orElse: () => AppConstants.storeCategories.first,
                          )
                        : null,
                    compareFn: (i, s) => i.name == s.name,
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: 'Select Category',
                        hintText: 'All Categories',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: _selectedCategory != null 
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _selectedCategory = null;
                                    _selectedSubcategory = null;
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value?.name;
                        _selectedSubcategory = null; // Reset subcategory when category changes
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Subcategory Dropdown (only shown when category is selected)
                  if (_selectedCategory != null && _availableSubcategories.isNotEmpty) ...[
                    const Text('Subcategory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    DropdownSearch<String>(
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search subcategory...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      items: (filter, props) => _availableSubcategories,
                      selectedItem: _selectedSubcategory,
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: 'Select Subcategory',
                          hintText: 'All Subcategories',
                          prefixIcon: const Icon(Icons.subdirectory_arrow_right),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: _selectedSubcategory != null 
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _selectedSubcategory = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubcategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 24),

                  // Rating
                  const Text('Minimum Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: _minRating.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _minRating = value;
                      });
                    },
                  ),
                  Text('Min: ${_minRating.toStringAsFixed(1)} ⭐'),
                  const SizedBox(height: 24),

                  // Quick filters
                  const Text('Quick Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Open Now'),
                    subtitle: const Text('Show only currently open stores'),
                    value: _onlyOpen,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => setState(() => _onlyOpen = value),
                  ),
                  const SizedBox(height: 24),

                  // Sort By
                  const Text('Sort By', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.arrow_downward, size: 16),
                            SizedBox(width: 4),
                            Text('Newest First'),
                          ],
                        ),
                        selected: _sortOrder == 'newest',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _sortOrder = 'newest');
                          }
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      ),
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.arrow_upward, size: 16),
                            SizedBox(width: 4),
                            Text('Oldest First'),
                          ],
                        ),
                        selected: _sortOrder == 'oldest',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _sortOrder = 'oldest');
                          }
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Apply button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply Filters', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedWilaya = null;
      _selectedWilayaId = null;
      _selectedCategory = null;
      _selectedSubcategory = null;
      _minRating = 0;
      _onlyOpen = false;
      _sortOrder = 'newest';
    });
  }

  void _applyFilters() {
    final storesProvider = context.read<StoresProvider>();
    storesProvider.setCategory(_selectedCategory);
    storesProvider.setSubcategory(_selectedSubcategory);
    storesProvider.setWilayaId(_selectedWilayaId);
    storesProvider.setMinRating(_minRating);
    storesProvider.setOpenNowOnly(_onlyOpen);
    storesProvider.setSortOrder(_sortOrder);
    Navigator.pop(context);
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickySearchBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 70;

  @override
  double get minExtent => 70;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
