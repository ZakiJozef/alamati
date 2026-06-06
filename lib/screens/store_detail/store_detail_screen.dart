import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stores_provider.dart';
import '../../providers/categories_provider.dart';
import '../../models/store.dart';
import '../../models/portfolio_item.dart';
import '../../models/review.dart';
import '../../models/store_section.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/store_section_widgets.dart';
import '../../services/api_service.dart';
import '../store/edit_store_screen.dart';
import '../store/manage_portfolio_screen.dart';
import '../chat/chat_room_screen.dart';
import '../auth/login_screen.dart';
import '../product/product_detail_screen.dart';
import '../store/store_products_screen.dart';
import '../store/store_inbox_screen.dart';

class StoreDetailScreen extends StatefulWidget {
  final dynamic slugOrId;

  const StoreDetailScreen({super.key, required this.slugOrId});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Store? _store;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFollowing = false;
  
  // Reviews
  final ApiService _api = ApiService();
  List<Review> _reviews = [];
  bool _isLoadingReviews = false;
  bool _isSubmittingReview = false;
  int _userRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  
  // Store Sections
  List<StoreSection> _storeSections = [];
  bool _isLoadingSections = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStore();
  }

  Future<void> _loadStore() async {
    final store = await context.read<StoresProvider>().loadStoreDetails(widget.slugOrId);
    setState(() {
      _store = store;
      _isLoading = false;
    });
    if (store != null) {
      _loadReviews();
      _loadSections();
    }
  }

  Future<void> _loadReviews() async {
    if (_store == null) return;
    setState(() => _isLoadingReviews = true);
    try {
      final response = await _api.get('/stores/${_store!.id}/reviews');
      final List<dynamic> reviewsJson = response is List ? response : (response['data'] ?? []);
      setState(() {
        _reviews = reviewsJson.map((json) => Review.fromJson(json)).toList();
      });
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    } finally {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _loadSections() async {
    if (_store == null) return;
    setState(() => _isLoadingSections = true);
    try {
      final response = await _api.get('/stores/${_store!.id}/sections');
      final List<dynamic> sectionsJson = response is List ? response : (response['data'] ?? []);
      setState(() {
        _storeSections = sectionsJson
            .map((json) => StoreSection.fromJson(json))
            .where((s) => s.isActive)
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading sections: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSections = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_store == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Store not found')),
      );
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Stack(
            children: [
              NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    // Cover Image & Profile - collapses when scrolling
                    SliverToBoxAdapter(child: _buildHeader()),
                    
                    // Tab Bar - stays pinned
                    SliverOverlapAbsorber(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                      sliver: SliverPersistentHeader(
                        pinned: true,
                        delegate: _TabBarDelegate(
                          tabController: _tabController,
                          tabs: const ['Overview', 'Portfolio', 'Products', 'Reviews'],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent(_buildOverviewTabContent()),
                    _buildTabContent(_buildPortfolioTabContent()),
                    _buildTabContent(_buildProductsTabContent()),
                    _buildTabContent(_buildReviewsTabContent()),
                  ],
                ),
              ),
              
              // Sticky Download Button
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingActionButton.extended(
                  onPressed: _downloadVCard,
                  backgroundColor: AppTheme.primaryColor,
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text(
                    'Save vCard',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Wraps tab content with proper scroll handling for NestedScrollView
  Widget _buildTabContent(Widget content) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(child: content),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Cover Image
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 220,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: _store!.coverImage ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey.shade200),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.store, size: 60),
                ),
              ),
            ),
            // Back Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
            // Save and Follow Buttons
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: Row(
                children: [
                  // Edit Button (for owner/admin only)
                  if (_canEditStore())
                    GestureDetector(
                      onTap: _navigateToEditStore,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                    ),
                  // Follow Button
                  GestureDetector(
                    onTap: _isFollowing ? null : _handleFollowStore,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: _isFollowing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _store!.isFollowing ? Icons.person_remove : Icons.person_add,
                              color: _store!.isFollowing ? Colors.red.shade300 : Colors.white,
                            ),
                    ),
                  ),
                  // Save Button
                  GestureDetector(
                    onTap: _isSaving ? null : _handleSaveStore,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _store!.isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: _store!.isSaved ? AppTheme.primaryColor : Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            // Profile Picture
            Positioned(
              bottom: -50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _store!.profileImage ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey.shade200),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.primaryColor,
                        child: const Icon(Icons.store, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 60),
        // Store Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                _store!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Rating and Followers stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rating
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          _store!.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' (${_store!.reviewCount})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Followers
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, color: AppTheme.primaryColor, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${_store!.followerCount}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' followers',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Category display from IDs
              Consumer<CategoriesProvider>(
                builder: (context, categories, _) {
                  String? categoryName;
                  String? subcategoryName;
                  
                  // Look up category name from ID
                  if (_store!.categoryId != null) {
                    final category = categories.getCategoryById(_store!.categoryId!);
                    categoryName = category?.name;
                    
                    // Look up subcategory name from ID
                    if (_store!.subcategoryId != null && category != null) {
                      final subcategory = category.children?.firstWhere(
                        (c) => c.id == _store!.subcategoryId,
                        orElse: () => category,
                      );
                      if (subcategory != null && subcategory.id != category.id) {
                        subcategoryName = subcategory.name;
                      }
                    }
                  }
                  
                  // Fallback to old string category field
                  final displayCategory = categoryName ?? _store!.category ?? 'Other';
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CategoryBadge(category: displayCategory, isLarge: true),
                      if (subcategoryName != null) ...[
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          subcategoryName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    _store!.location,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_store!.description != null)
                Text(
                  _store!.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _QuickActionButton(
          icon: Icons.call,
          label: 'Call',
          color: const Color(0xFF25D366), // WhatsApp green
          onTap: _hasAnyPhone() ? _handleCallButton : null,
        ),
        const SizedBox(width: 12),
        _QuickActionButton(
          icon: Icons.chat,
          label: 'Chat',
          color: AppTheme.primaryColor,
          onTap: _store!.ownerId != null ? _openChat : null,
        ),
        const SizedBox(width: 12),
        // Store Inbox button (for owner only)
        if (_canEditStore())
          _QuickActionButton(
            icon: Icons.inbox,
            label: 'Inbox',
            color: const Color(0xFF2196F3), // Blue
            onTap: _openStoreInbox,
          ),
        if (_canEditStore())
          const SizedBox(width: 12),
        _QuickActionButton(
          icon: Icons.email,
          label: 'Email',
          color: const Color(0xFFEA4335), // Gmail red
          onTap: _store!.email != null ? () => _launchUrl('mailto:${_store!.email}') : null,
        ),
        const SizedBox(width: 12),
        _QuickActionButton(
          icon: Icons.location_on,
          label: 'GPS',
          color: const Color(0xFFFF5722), // Deep orange
          onTap: _openMaps,
        ),
        const SizedBox(width: 12),
        _QuickActionButton(
          icon: Icons.share,
          label: 'Share',
          color: const Color(0xFF9C27B0), // Purple
          onTap: _shareStore,
        ),
      ],
    );
  }

  Widget _buildOverviewTabContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Social Links
          if (_store!.socialLinks.isNotEmpty) ...[
            _buildSectionHeader('Connect Socially', Icons.share),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _store!.socialLinks.entries.map((entry) {
                return _buildSocialButton(entry.key, entry.value);
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Contact Details Section
          _buildSectionHeader('Contact Information', Icons.contact_phone),
          const SizedBox(height: 12),
          _buildContactCard(),
          const SizedBox(height: 24),
          
          // Map
          if (_store!.mapUrl != null && _store!.mapUrl!.isNotEmpty) ...[
            _buildSectionHeader('Location', Icons.location_on),
            const SizedBox(height: 12),
            _buildGoogleMapsEmbed(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.place, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _store!.fullAddress,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Open in Google Maps button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openMaps,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in Google Maps'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // QR Code
          _buildSectionHeader('Scan QR Code', Icons.qr_code),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: QrImageView(
                data: 'https://3alamati.com/store/${_store!.slug ?? _store!.id}',
                version: QrVersions.auto,
                size: 180,
              ),
            ),
          ),
          
          // Business Hours Section
          if (_store!.businessHours.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Business Hours', Icons.access_time),
            const SizedBox(height: 12),
            _buildBusinessHoursCard(),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBusinessHoursCard() {
    const weekDays = ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
    const dayLabels = {
      'sunday': 'Sun',
      'monday': 'Mon',
      'tuesday': 'Tue',
      'wednesday': 'Wed',
      'thursday': 'Thu',
      'friday': 'Fri',
      'saturday': 'Sat',
    };
    
    // Get current day to highlight
    // Dart weekday: Monday=1, Tuesday=2, ..., Saturday=6, Sunday=7
    // Our order: saturday(0), sunday(1), monday(2), tuesday(3), wednesday(4), thursday(5), friday(6)
    final now = DateTime.now();
    final dartWeekday = now.weekday; // 1-7 (Mon-Sun)
    // Convert Dart weekday to our index: Sat=6->0, Sun=7->1, Mon=1->2, etc.
    final dayIndexMap = {6: 0, 7: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 6};
    final currentDayIndex = dayIndexMap[dartWeekday] ?? 0;
    final currentDay = weekDays[currentDayIndex];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: weekDays.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          final schedule = _store!.businessHours[day];
          final isOpen = schedule?['is_open'] == true;
          final isToday = day == currentDay;
          
          return Container(
            decoration: BoxDecoration(
              color: isToday ? AppTheme.primaryColor.withValues(alpha: 0.05) : null,
              border: Border(
                bottom: index < 6 
                    ? BorderSide(color: Colors.grey.shade200)
                    : BorderSide.none,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Day label
                SizedBox(
                  width: 45,
                  child: Text(
                    dayLabels[day]!,
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday ? AppTheme.primaryColor : Colors.grey.shade700,
                    ),
                  ),
                ),
                
                // Today badge
                if (isToday) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                const Spacer(),
                
                // Hours or Closed
                if (isOpen && schedule != null) ...[
                  // Morning
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wb_sunny, size: 14, color: Colors.orange.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '${schedule['morning_start'] ?? '08:00'}-${schedule['morning_end'] ?? '12:00'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Afternoon
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wb_twilight, size: 14, color: Colors.blue.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '${schedule['afternoon_start'] ?? '13:00'}-${schedule['afternoon_end'] ?? '16:30'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    'Closed',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_store!.phone != null && _store!.phone!.isNotEmpty)
            _buildContactRow(Icons.phone, 'Phone', _store!.phone!, () => _launchUrl('tel:${_store!.phone}')),
          if (_store!.email != null && _store!.email!.isNotEmpty)
            _buildContactRow(Icons.email, 'Email', _store!.email!, () => _launchUrl('mailto:${_store!.email}')),
          if (_store!.website != null && _store!.website!.isNotEmpty)
            _buildContactRow(Icons.language, 'Website', _store!.website!, () => _launchUrl(_store!.website!)),
          if (_store!.fullAddress.isNotEmpty)
            _buildContactRow(Icons.location_on, 'Address', _store!.fullAddress, null),
          _buildContactRow(
            _store!.isOpen ? Icons.check_circle : Icons.cancel,
            'Status',
            _store!.isOpen ? 'Open Now' : 'Closed',
            null,
            iconColor: _store!.isOpen ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value, VoidCallback? onTap, {Color? iconColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.primaryColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor ?? AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: onTap != null ? AppTheme.primaryColor : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioTabContent() {
    final canEdit = _canEditStore();
    
    if (_store!.portfolio.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.collections, size: 50, color: Colors.purple.shade300),
              ),
              const SizedBox(height: 16),
              const Text(
                'No portfolio works yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              if (canEdit) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _navigateToManagePortfolio(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Portfolio Work'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Manage Portfolio button for owner
          if (canEdit)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton.icon(
                onPressed: () => _navigateToManagePortfolio(),
                icon: const Icon(Icons.edit),
                label: const Text('Manage Portfolio'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          
          // Portfolio works as cards with carousels
          ..._store!.portfolio.map((item) => _buildPortfolioWorkCard(item)),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPortfolioWorkCard(PortfolioItem item) {
    final images = item.displayImages;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and description header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.description != null && item.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                // Image count badge
                if (images.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library, size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '${images.length}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Image carousel - clean, no overlay
          if (images.isEmpty)
            _buildEmptyPortfolioImage()
          else if (images.length == 1)
            _buildSinglePortfolioImage(images.first)
          else
            CarouselSlider.builder(
              itemCount: images.length,
              itemBuilder: (ctx, idx, realIdx) => _buildPortfolioCarouselImage(images[idx]),
              options: CarouselOptions(
                height: 200,
                viewportFraction: 0.92,
                enlargeCenterPage: true,
                enlargeFactor: 0.12,
                enableInfiniteScroll: images.length > 2,
                autoPlay: images.length > 1,
                autoPlayInterval: const Duration(seconds: 4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyPortfolioImage() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade200,
      ),
      child: const Center(
        child: Icon(Icons.image, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildSinglePortfolioImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (ctx, url) => Container(
          height: 200,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (ctx, url, err) => Container(
          height: 200,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPortfolioCarouselImage(String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (ctx, url) => Container(
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (ctx, url, err) => Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  void _navigateToManagePortfolio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManagePortfolioScreen(store: _store!),
      ),
    ).then((_) => _loadStore());
  }

  Widget _buildProductsTabContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Sections (sliders, featured, countdown, etc.)
          if (_isLoadingSections)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_storeSections.isNotEmpty) ...[
            ..._storeSections.map((section) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: StoreSectionWidget(section: section),
            )),
            const SizedBox(height: 8),
          ],
          
          // Section header for all products with See All button
          if (_store!.products.isNotEmpty) ...[
            Row(
              children: [
                Expanded(child: _buildSectionHeader('All Products', Icons.shopping_bag)),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoreProductsScreen(
                        storeId: _store!.id,
                        store: _store,
                        storeSlug: _store!.slug,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('See All'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // Grid of products - 2 per row
          if (_store!.products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: Text('No products or services')),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _store!.products.map((product) {
              final cardWidth = (MediaQuery.of(context).size.width - 44) / 2;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      productId: product.id,
                      product: product,
                    ),
                  ),
                ),
                child: Container(
                  width: cardWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: CachedNetworkImage(
                              imageUrl: product.thumbnailUrl,
                              width: cardWidth,
                              height: cardWidth * 0.85,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: cardWidth,
                                height: cardWidth * 0.85,
                                color: Colors.grey.shade200,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: cardWidth,
                                height: cardWidth * 0.85,
                                color: Colors.grey.shade200,
                                child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey.shade400),
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
                                color: product.isService
                                    ? Colors.purple.withValues(alpha: 0.9)
                                    : AppTheme.primaryColor.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                product.isService ? 'SERVICE' : 'PRODUCT',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Discount badge
                          if (product.hasDiscount)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'SALE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Product Info
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Rating
                            if (product.reviewsCount > 0)
                              Row(
                                children: [
                                  ...List.generate(5, (i) => Icon(
                                    i < product.averageRating ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 12,
                                  )),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${product.reviewsCount})',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            // Price
                            if (product.price != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product.hasDiscount)
                                    Text(
                                      product.priceFormatted,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  Text(
                                    product.effectivePriceFormatted,
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildReviewsTabContent() {
    final authProvider = context.read<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;
    final currentUser = authProvider.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Summary Card
          _buildRatingSummaryCard(),
          const SizedBox(height: 24),

          // Write Review Section
          _buildSectionHeader('Write a Review', Icons.rate_review),
          const SizedBox(height: 16),
          if (isAuthenticated)
            _buildWriteReviewCard()
          else
            _buildLoginPromptCard(),
          const SizedBox(height: 32),

          // All Reviews Section
          Row(
            children: [
              _buildSectionHeader('Customer Reviews', Icons.reviews),
              const Spacer(),
              Text(
                '${_reviews.length} reviews',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_reviews.isEmpty)
            _buildEmptyReviewsCard()
          else
            ..._reviews.map((review) => _buildReviewCard(review)),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildRatingSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            Colors.amber.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Big Rating Number
          Column(
            children: [
              Text(
                _store!.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              _buildStarRating(_store!.rating, size: 20),
              const SizedBox(height: 4),
              Text(
                '${_store!.reviewCount} reviews',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          // Rating Distribution Bars
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final starCount = 5 - index;
                final percentage = _store!.reviewCount > 0
                    ? (_reviews.where((r) => r.rating == starCount).length / _store!.reviewCount * 100)
                    : 0.0;
                return _buildRatingBar(starCount, percentage);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$stars',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 35,
            child: Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteReviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Interactive Star Rating
          const Text(
            'Your Rating',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _userRating = star),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    star <= _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 40,
                    color: star <= _userRating ? Colors.amber : Colors.grey.shade300,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getRatingLabel(_userRating),
              style: TextStyle(
                color: _userRating > 0 ? Colors.amber.shade700 : Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Comment Text Field
          TextField(
            controller: _reviewController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share your experience with this store...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _userRating > 0 && !_isSubmittingReview ? _submitReview : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSubmittingReview
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded),
                        SizedBox(width: 8),
                        Text(
                          'Submit Review',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor 😞';
      case 2:
        return 'Fair 😐';
      case 3:
        return 'Good 🙂';
      case 4:
        return 'Very Good 😊';
      case 5:
        return 'Excellent! 🤩';
      default:
        return 'Tap to rate';
    }
  }

  Widget _buildLoginPromptCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.login_rounded, size: 48, color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          const Text(
            'Login to Write a Review',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your experience with other customers',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Login Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReviewsCard() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_outline_rounded, size: 48, color: Colors.amber),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Reviews Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your experience!',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    final dateStr = review.createdAt != null
        ? DateFormat('MMM d, yyyy').format(review.createdAt!)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Date, Stars
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                backgroundImage: review.profilePic != null && review.profilePic!.isNotEmpty
                    ? CachedNetworkImageProvider(review.profilePic!)
                    : null,
                child: review.profilePic == null || review.profilePic!.isEmpty
                    ? Text(
                        review.displayName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Star Rating Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStarRating(review.rating.toDouble(), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${review.rating}.0',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Comment
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                review.comment!,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star_rounded, color: Colors.amber, size: size);
        } else if (index < rating) {
          return Icon(Icons.star_half_rounded, color: Colors.amber, size: size);
        } else {
          return Icon(Icons.star_outline_rounded, color: Colors.amber.shade200, size: size);
        }
      }),
    );
  }

  Future<void> _submitReview() async {
    if (_userRating == 0 || _store == null) return;

    setState(() => _isSubmittingReview = true);

    try {
      await _api.post('/stores/${_store!.id}/reviews', {
        'rating': _userRating,
        'comment': _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
      });

      // Refresh reviews
      await _loadReviews();
      
      // Clear form
      setState(() {
        _userRating = 0;
        _reviewController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Review submitted successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  Widget _buildSocialButton(String platform, String handle) {
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
    };

    final brandColor = colors[platform] ?? AppTheme.primaryColor;
    // For snapchat, use dark icon on yellow background
    final iconColor = platform == 'snapchat' ? Colors.black : brandColor;

    return GestureDetector(
      onTap: () => _openSocialLink(platform, handle),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: brandColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icons[platform] ?? FontAwesomeIcons.link,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }

  /// Builds a native Flutter map using flutter_map with OpenStreetMap tiles
  Widget _buildGoogleMapsEmbed() {
    // Extract coordinates from the URL
    final coords = _extractCoordsFromGoogleMapsUrl(_store!.mapUrl!);
    
    // If we have coordinates, show the interactive map
    if (coords != null) {
      final lat = coords['lat']!;
      final lng = coords['lng']!;
      
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Native Flutter Map with OpenStreetMap tiles
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.alamati.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Overlay button to open in Google Maps
              Positioned(
                bottom: 8,
                right: 8,
                child: Material(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => _launchUrl(_store!.mapUrl!),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text('Directions', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Fallback: show placeholder if no coordinates could be extracted
    return _buildMapPlaceholder();
  }
  
  /// Builds a placeholder for when coordinates can't be extracted
  Widget _buildMapPlaceholder() {
    return GestureDetector(
      onTap: () => _launchUrl(_store!.mapUrl!),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          color: Colors.grey.shade100,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text('Tap to view map', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  /// Extracts latitude and longitude from various Google Maps URL formats
  Map<String, double>? _extractCoordsFromGoogleMapsUrl(String url) {
    try {
      // Pattern 1: @lat,lng in URL (e.g., /place/Name/@36.565545,3.5918028,...)
      final atPattern = RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)');
      final atMatch = atPattern.firstMatch(url);
      if (atMatch != null) {
        return {
          'lat': double.parse(atMatch.group(1)!),
          'lng': double.parse(atMatch.group(2)!),
        };
      }
      
      // Pattern 2: !3d lat !4d lng in URL (e.g., !3d36.565545!4d3.5918028)
      final dataPattern = RegExp(r'!3d(-?\d+\.?\d*)!4d(-?\d+\.?\d*)');
      final dataMatch = dataPattern.firstMatch(url);
      if (dataMatch != null) {
        return {
          'lat': double.parse(dataMatch.group(1)!),
          'lng': double.parse(dataMatch.group(2)!),
        };
      }
      
      // Pattern 3: q=lat,lng query parameter
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final q = uri.queryParameters['q'];
        if (q != null) {
          final qPattern = RegExp(r'^(-?\d+\.?\d*),(-?\d+\.?\d*)$');
          final qMatch = qPattern.firstMatch(q);
          if (qMatch != null) {
            return {
              'lat': double.parse(qMatch.group(1)!),
              'lng': double.parse(qMatch.group(2)!),
            };
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  void _launchUrl(String url) async {
    if (!url.startsWith('http') && !url.startsWith('tel') && !url.startsWith('mailto')) {
      url = 'https://$url';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Check if store has any phone number
  bool _hasAnyPhone() {
    return (_store!.phone != null && _store!.phone!.isNotEmpty) || _store!.phones.isNotEmpty;
  }

  /// Get all available phone numbers
  List<String> _getAllPhones() {
    final phones = <String>[];
    if (_store!.phone != null && _store!.phone!.isNotEmpty) {
      phones.add(_store!.phone!);
    }
    phones.addAll(_store!.phones.where((p) => p.isNotEmpty));
    return phones;
  }

  /// Handle call button - show dialog if multiple phones
  void _handleCallButton() {
    final phones = _getAllPhones();
    
    if (phones.isEmpty) return;
    
    // If only one phone, call directly
    if (phones.length == 1) {
      _launchUrl('tel:${phones.first}');
      return;
    }
    
    // Multiple phones - show selection dialog
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.call, color: Color(0xFF25D366)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Select a number to call',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...phones.asMap().entries.map((entry) {
              final index = entry.key;
              final phone = entry.value;
              final label = index == 0 ? 'Primary' : 'Phone ${index + 1}';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  phone,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                trailing: const Icon(Icons.call, color: Color(0xFF25D366)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _launchUrl('tel:$phone');
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openSocialLink(String platform, String handle) async {
    // If handle is already a full URL, use it directly
    if (handle.startsWith('http://') || handle.startsWith('https://')) {
      _launchUrl(handle);
      return;
    }

    // Clean handle - remove @ symbol if present
    final cleanHandle = handle.replaceAll('@', '').trim();
    final numericHandle = handle.replaceAll(RegExp(r'[^0-9+]'), '');

    // Define App Schemes (Try these first)
    final appSchemes = <String, String>{
      'facebook': 'fb://facewebmodal/f?href=https://www.facebook.com/$cleanHandle',
      'instagram': 'instagram://user?username=$cleanHandle',
      'whatsapp': 'whatsapp://send?phone=$numericHandle',
      'viber': 'viber://chat?number=$numericHandle',
      'twitter': 'twitter://user?screen_name=$cleanHandle',
      'youtube': 'youtube://$cleanHandle', // Often requires channel ID, but worth a try
      'telegram': 'tg://resolve?domain=$cleanHandle',
      'snapchat': 'snapchat://add/$cleanHandle',
      'tiktok': 'snssdk1128://user/profile/$cleanHandle', // Varies by region, risky
    };

    // Define Web Fallbacks (Use if app not installed)
    final webUrls = <String, String>{
      'facebook': 'https://facebook.com/$cleanHandle',
      'instagram': 'https://instagram.com/$cleanHandle',
      'whatsapp': 'https://wa.me/$numericHandle',
      'viber': 'https://viber.click/$numericHandle',
      'tiktok': 'https://tiktok.com/@$cleanHandle',
      'snapchat': 'https://snapchat.com/add/$cleanHandle',
      'linkedin': handle.contains('/') 
          ? 'https://linkedin.com/$cleanHandle' 
          : 'https://linkedin.com/in/$cleanHandle',
      'youtube': cleanHandle.startsWith('UC') 
          ? 'https://youtube.com/channel/$cleanHandle' 
          : 'https://youtube.com/@$cleanHandle',
      'twitter': 'https://twitter.com/$cleanHandle',
      'telegram': cleanHandle.startsWith('t.me') 
          ? 'https://$cleanHandle' 
          : 'https://t.me/$cleanHandle',
    };

    // 1. Try App Scheme
    if (!kIsWeb && appSchemes.containsKey(platform)) {
      final appUrl = appSchemes[platform]!;
      final uri = Uri.parse(appUrl);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        debugPrint('Could not launch app scheme for $platform: $e');
      }
    }

    // 2. Fallback to Web URL
    final webUrl = webUrls[platform] ?? handle;
    _launchUrl(webUrl);
  }

  void _openMaps() async {
    Uri mapsUri;
    
    // Use direct map URL if available (e.g., https://maps.app.goo.gl/...)
    if (_store!.mapUrl != null && _store!.mapUrl!.isNotEmpty) {
      mapsUri = Uri.parse(_store!.mapUrl!);
    }
    // Use coordinates if available
    else if (_store!.lat != null && _store!.lng != null) {
      mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${_store!.lat},${_store!.lng}'
      );
    } else {
      // Search by store name + city for better results
      final String query = '${_store!.name}, ${_store!.city ?? _store!.state ?? 'Algeria'}';
      mapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}'
      );
    }
    
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareStore() {
    Share.share(
      '${_store!.name} sur 3alamati!\nhttps://3alamati.com/store/${_store!.slug ?? _store!.id}',
    );
  }

  void _downloadVCard() {
    // TODO: Generate and download vCard file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('vCard saved!')),
    );
  }

  Future<void> _handleSaveStore() async {
    final authProvider = context.read<AuthProvider>();
    
    if (!authProvider.isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final isSaved = await context.read<StoresProvider>().toggleSaveStore(_store!.id);
      if (mounted) {
        setState(() {
          _store = _store!.copyWith(isSaved: isSaved);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save store. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleFollowStore() async {
    final authProvider = context.read<AuthProvider>();
    
    if (!authProvider.isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }
    
    setState(() => _isFollowing = true);
    
    try {
      final isFollowing = await context.read<StoresProvider>().toggleFollowStore(_store!.id);
      if (mounted) {
        final provider = context.read<StoresProvider>();
        final store = provider.selectedStore;
        if (store != null) {
          setState(() {
            _store = store;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_store!.isFollowing ? 'Failed to unfollow store.' : 'Failed to follow store.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFollowing = false);
      }
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.bookmark, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Login Required'),
          ],
        ),
        content: const Text(
          'You need to be logged in to save stores. Would you like to log in now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen - adjust route as needed
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Log In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  bool _canEditStore() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated || _store == null) return false;
    
    final user = authProvider.user;
    if (user == null) return false;
    
    // Allow if super admin or store owner
    return user.isSuperAdmin || _store!.ownerId == user.id;
  }

  Future<void> _navigateToEditStore() async {
    if (_store == null) return;
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditStoreScreen(store: _store!),
      ),
    );
    
    // Reload store if it was updated
    if (result == true) {
      _loadStore();
    }
  }

  void _openStoreInbox() {
    if (_store == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreInboxScreen(
          storeId: _store!.id,
          storeName: _store!.name,
        ),
      ),
    );
  }

  void _openChat() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    if (_store == null || _store!.ownerId == null) return;

    // Don't allow chatting with yourself
    if (authProvider.user?.id == _store!.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is your own store')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          otherUserId: _store!.ownerId!,
          otherUsername: _store!.ownerName ?? 'Store Owner',
          storeId: _store!.id,
          storeName: _store!.name,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reviewController.dispose();
    super.dispose();
  }
}

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

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<String> tabs;

  _TabBarDelegate({
    required this.tabController,
    required this.tabs,
  });

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey.shade500,
        indicatorColor: AppTheme.primaryColor,
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
