import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../providers/stores_provider.dart';

class StoreAnalyticsScreen extends StatefulWidget {
  const StoreAnalyticsScreen({super.key});

  @override
  State<StoreAnalyticsScreen> createState() => _StoreAnalyticsScreenState();
}

class _StoreAnalyticsScreenState extends State<StoreAnalyticsScreen> {
  String _selectedPeriod = '7days';
  int? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoresProvider>().loadStores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<StoresProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.stores.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.stores.isEmpty) {
            return _buildEmptyState();
          }

          // Auto-select first store if none selected
          _selectedStoreId ??= provider.stores.first.id;
          final selectedStore = provider.stores.firstWhere(
            (s) => s.id == _selectedStoreId,
            orElse: () => provider.stores.first,
          );

          return RefreshIndicator(
            onRefresh: () => provider.loadStores(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with store selector
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sélectionner une boutique',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedStoreId,
                              isExpanded: true,
                              items: provider.stores.map((store) => DropdownMenuItem(
                                value: store.id,
                                child: Text(store.name),
                              )).toList(),
                              onChanged: (v) => setState(() => _selectedStoreId = v),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Period selector
                        Row(
                          children: [
                            _buildPeriodChip('7 jours', '7days'),
                            const SizedBox(width: 8),
                            _buildPeriodChip('30 jours', '30days'),
                            const SizedBox(width: 8),
                            _buildPeriodChip('Cette année', 'year'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Stats cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick stats row
                        Row(
                          children: [
                            Expanded(child: _buildStatCard(
                              icon: Icons.people,
                              label: 'Abonnés',
                              value: '${selectedStore.followerCount}',
                              color: Colors.blue,
                              trend: '+12%',
                              isUp: true,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard(
                              icon: Icons.reviews,
                              label: 'Avis',
                              value: '${selectedStore.reviewCount}',
                              color: Colors.red,
                              trend: '+5%',
                              isUp: true,
                            )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildStatCard(
                              icon: Icons.star,
                              label: 'Note moyenne',
                              value: selectedStore.rating.toStringAsFixed(1),
                              color: Colors.orange,
                              trend: '${selectedStore.reviewCount} avis',
                              isUp: true,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard(
                              icon: Icons.shopping_bag,
                              label: 'Produits',
                              value: '${selectedStore.products.length}',
                              color: Colors.green,
                              trend: 'Total',
                              isUp: true,
                            )),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Views Chart
                        _buildChartSection(
                          title: 'Évolution des vues',
                          chart: _buildViewsChart(),
                        ),

                        const SizedBox(height: 24),

                        // Top Products
                        _buildSection(
                          title: 'Produits populaires',
                          child: _buildTopProductsList(selectedStore),
                        ),

                        const SizedBox(height: 24),

                        // Recent Activity
                        _buildSection(
                          title: 'Activité récente',
                          child: _buildRecentActivity(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_mall_directory, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Aucune boutique trouvée',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez une boutique pour voir les analytics',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? trend,
    bool isUp = true,
  }) {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUp ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      fontSize: 11,
                      color: isUp ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection({required String title, required Widget chart}) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildViewsChart() {
    // Sample data for the chart
    final spots = [
      const FlSpot(0, 20),
      const FlSpot(1, 45),
      const FlSpot(2, 35),
      const FlSpot(3, 60),
      const FlSpot(4, 40),
      const FlSpot(5, 75),
      const FlSpot(6, 55),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                if (value.toInt() < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      days[value.toInt()],
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 35,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
        minY: 0,
        maxY: 100,
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTopProductsList(store) {
    // Sample data - in production, fetch from API
    final products = [
      {'name': 'Produit 1', 'views': 150, 'sales': 25},
      {'name': 'Produit 2', 'views': 120, 'sales': 18},
      {'name': 'Produit 3', 'views': 95, 'sales': 12},
    ];

    return Column(
      children: products.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        return Container(
          margin: EdgeInsets.only(bottom: index < products.length - 1 ? 12 : 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${product['views']} vues',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${product['sales']} ventes',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      {'icon': Icons.star, 'text': 'Nouvel avis 5 étoiles', 'time': 'Il y a 2h', 'color': Colors.orange},
      {'icon': Icons.shopping_bag, 'text': 'Nouvelle commande #1234', 'time': 'Il y a 4h', 'color': Colors.green},
      {'icon': Icons.visibility, 'text': '50 nouvelles vues', 'time': 'Aujourd\'hui', 'color': Colors.blue},
      {'icon': Icons.favorite, 'text': '3 nouveaux favoris', 'time': 'Hier', 'color': Colors.red},
    ];

    return Column(
      children: activities.asMap().entries.map((entry) {
        final index = entry.key;
        final activity = entry.value;
        final color = activity['color'] as Color;
        
        return Container(
          margin: EdgeInsets.only(bottom: index < activities.length - 1 ? 12 : 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(activity['icon'] as IconData, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['text'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      activity['time'] as String,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
