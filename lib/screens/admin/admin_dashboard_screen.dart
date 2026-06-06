import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import 'manage_users_screen.dart';
import 'manage_stores_screen.dart';
import 'store_orders_screen.dart';
import 'manage_featured_screen.dart';
import 'admin_products_list_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_units_screen.dart';
import 'admin_banners_screen.dart';
import 'admin_plans_screen.dart';
import 'manage_featured_stores_screen.dart';
import 'manage_sponsored_stores_screen.dart';
import 'admin_import_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch stats when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () => adminProvider.refresh(),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      user?.displayName ?? 'Admin',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => adminProvider.refresh(),
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Last Updated
                  if (adminProvider.lastFetched != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Last updated: ${DateFormat('MMM d, h:mm a').format(adminProvider.lastFetched!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),

                  // Loading State
                  if (adminProvider.isLoading && !adminProvider.hasData)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (adminProvider.error != null && !adminProvider.hasData)
                    _buildErrorState(adminProvider)
                  else ...[
                    // Stats Cards
                    _buildStatsGrid(adminProvider),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildSectionTitle('Quick Actions'),
                    const SizedBox(height: 12),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),

                    // Charts Row
                    _buildSectionTitle('Analytics'),
                    const SizedBox(height: 12),
                    _buildChartsSection(adminProvider),
                    const SizedBox(height: 24),

                    // Recent Activity
                    _buildSectionTitle('Recent Activity'),
                    const SizedBox(height: 12),
                    _buildRecentActivity(adminProvider),
                    const SizedBox(height: 24),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AdminProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Failed to load stats',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            provider.error ?? 'Unknown error',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildStatsGrid(AdminProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.store_rounded,
          label: 'Total Stores',
          value: provider.formatNumber(provider.totalStores),
          subValue: '+${provider.storesThisWeek} this week',
          color: const Color(0xFF3B82F6),
          gradient: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        ),
        _StatCard(
          icon: Icons.people_rounded,
          label: 'Total Users',
          value: provider.formatNumber(provider.totalUsers),
          subValue: '+${provider.usersThisWeek} this week',
          color: const Color(0xFF10B981),
          gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
        ),
        _StatCard(
          icon: Icons.star_rounded,
          label: 'Reviews',
          value: provider.formatNumber(provider.totalReviews),
          subValue: '${provider.avgRating} avg rating',
          color: const Color(0xFFF59E0B),
          gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        ),
        _StatCard(
          icon: Icons.shopping_bag_rounded,
          label: 'Orders',
          value: provider.formatNumber(provider.totalOrders),
          subValue: '+${provider.ordersThisMonth} this month',
          color: const Color(0xFF8B5CF6),
          gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // General Management Section
        _buildActionSection(
          title: 'General',
          icon: Icons.dashboard_rounded,
          color: const Color(0xFF3B82F6),
          children: [
            _QuickActionCard(
              icon: Icons.people_rounded,
              label: 'Users',
              color: const Color(0xFF10B981),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
              ),
            ),
            _QuickActionCard(
              icon: Icons.store_rounded,
              label: 'Stores',
              color: const Color(0xFF3B82F6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageStoresScreen()),
              ),
            ),
            _QuickActionCard(
              icon: Icons.upload_file,
              label: 'Import',
              color: const Color(0xFF8B5CF6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminImportScreen()),
              ),
            ),
            _QuickActionCard(
              icon: Icons.receipt_long_rounded,
              label: 'Orders',
              color: const Color(0xFF8B5CF6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StoreOrdersScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Promotion & Marketing Section
        _buildActionSection(
          title: 'Promotion',
          icon: Icons.campaign_rounded,
          color: const Color(0xFFF59E0B),
          children: [
            _QuickActionCard(
              icon: Icons.local_fire_department,
              label: 'Featured Products',
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageFeaturedScreen(zone: 'trending_products')),
              ),
            ),
            _QuickActionCard(
              icon: Icons.star_rounded,
              label: 'Featured Services',
              color: Colors.amber,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageFeaturedScreen(zone: 'trending_services')),
              ),
            ),
            _QuickActionCard(
              icon: Icons.storefront_rounded,
              label: 'Featured Stores',
              color: Colors.amber.shade700,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageFeaturedStoresScreen()),
              ),
            ),
            _QuickActionCard(
              icon: Icons.campaign_rounded,
              label: 'Sponsored Stores',
              color: const Color(0xFF8B5CF6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageSponsoredStoresScreen()),
              ),
            ),
            _QuickActionCard(
              icon: Icons.image_rounded,
              label: 'Banners',
              color: const Color(0xFFE11D48),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminBannersScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Catalog Section
        _buildActionSection(
          title: 'Catalog',
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF10B981),
          children: [
            _QuickActionCard(
              icon: Icons.shopping_bag_rounded,
              label: 'Products',
              color: const Color(0xFF06B6D4),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminProductsListScreen(initialType: 'product')),
              ),
            ),
            _QuickActionCard(
              icon: Icons.miscellaneous_services_rounded,
              label: 'Services',
              color: const Color(0xFFEC4899),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminProductsListScreen(initialType: 'service')),
              ),
            ),
            _QuickActionCard(
              icon: Icons.category_rounded,
              label: 'Categories',
              color: const Color(0xFF6366F1),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
              ),
            ),
            _QuickActionCard(
              icon: Icons.straighten_rounded,
              label: 'Units',
              color: const Color(0xFF14B8A6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminUnitsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Settings Section
        _buildActionSection(
          title: 'Subscriptions',
          icon: Icons.card_membership_rounded,
          color: const Color(0xFFD97706),
          children: [
            _QuickActionCard(
              icon: Icons.card_membership_rounded,
              label: 'Plans',
              color: const Color(0xFFD97706),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPlansScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          // Action Cards Grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: children.map((child) => SizedBox(
                width: 72,
                height: 90,
                child: child,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(AdminProvider provider) {
    return Column(
      children: [
        // Growth Chart
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '7-Day Growth',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildGrowthChart(provider),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Distribution Row
        Row(
          children: [
            Expanded(
              child: Container(
                height: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Users by Role',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildRolePieChart(provider),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top Categories',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildCategoryList(provider),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGrowthChart(AdminProvider provider) {
    final dailyGrowth = provider.dailyGrowth;
    if (dailyGrowth.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final spots = dailyGrowth.asMap().entries.map((entry) {
      final users = (entry.value['users'] ?? 0).toDouble();
      return FlSpot(entry.key.toDouble(), users);
    }).toList();

    final storeSpots = dailyGrowth.asMap().entries.map((entry) {
      final stores = (entry.value['stores'] ?? 0).toDouble();
      return FlSpot(entry.key.toDouble(), stores);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < dailyGrowth.length) {
                  final date = DateTime.parse(dailyGrowth[index]['date']);
                  return Text(
                    DateFormat('E').format(date),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF3B82F6),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: storeSpots,
            isCurved: true,
            color: const Color(0xFF10B981),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePieChart(AdminProvider provider) {
    final roles = provider.usersByRole;
    if (roles.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final sections = <PieChartSectionData>[
      PieChartSectionData(
        value: (roles['visitor'] ?? 0).toDouble(),
        color: const Color(0xFF3B82F6),
        title: '${roles['visitor'] ?? 0}',
        radius: 35,
        titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: (roles['store_owner'] ?? 0).toDouble(),
        color: const Color(0xFF10B981),
        title: '${roles['store_owner'] ?? 0}',
        radius: 35,
        titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: (roles['super_admin'] ?? 0).toDouble(),
        color: const Color(0xFFF59E0B),
        title: '${roles['super_admin'] ?? 0}',
        radius: 35,
        titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ];

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 20,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildCategoryList(AdminProvider provider) {
    final categories = provider.storesByCategory.entries.toList();
    if (categories.isEmpty) {
      return const Center(child: Text('No stores'));
    }

    categories.sort((a, b) => (b.value as int).compareTo(a.value as int));
    final top5 = categories.take(5).toList();

    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    return ListView.builder(
      itemCount: top5.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final category = top5[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.key,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${category.value}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(AdminProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Recent Stores
          _buildActivitySection(
            'New Stores',
            Icons.store_rounded,
            const Color(0xFF3B82F6),
            provider.recentStores.map((store) => _ActivityItem(
              title: store['name'] ?? 'Unknown',
              subtitle: store['category'] ?? 'No category',
              time: _formatTime(store['created_at']),
            )).toList(),
          ),
          const Divider(height: 1),
          // Recent Users
          _buildActivitySection(
            'New Users',
            Icons.person_rounded,
            const Color(0xFF10B981),
            provider.recentUsers.map((user) => _ActivityItem(
              title: user['pseudoname'] ?? user['username'] ?? 'Unknown',
              subtitle: user['role'] ?? 'visitor',
              time: _formatTime(user['created_at']),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(
    String title,
    IconData icon,
    Color color,
    List<_ActivityItem> items,
  ) {
    return ExpansionTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${items.length} recent',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      children: items.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ]
          : items.map((item) => ListTile(
                dense: true,
                title: Text(item.title, style: const TextStyle(fontSize: 13)),
                subtitle: Text(item.subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                trailing: Text(item.time, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              )).toList(),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (e) {
      return '';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subValue;
  final Color color;
  final List<Color> gradient;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subValue,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 24),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subValue,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final String time;

  _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
  });
}
