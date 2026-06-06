import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Admin provider for managing dashboard statistics
class AdminProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _stats;
  DateTime? _lastFetched;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get stats => _stats;
  DateTime? get lastFetched => _lastFetched;
  bool get hasData => _stats != null;

  // Basic Stats
  int get totalUsers => _stats?['totalUsers'] ?? 0;
  int get totalStores => _stats?['totalStores'] ?? 0;
  int get totalReviews => _stats?['totalReviews'] ?? 0;
  int get totalMessages => _stats?['totalMessages'] ?? 0;
  int get totalOrders => _stats?['totalOrders'] ?? 0;
  double get avgRating => (_stats?['avgRating'] ?? 0.0).toDouble();

  // Growth Stats
  Map<String, dynamic> get growth => _stats?['growth'] ?? {};
  int get usersThisWeek => growth['usersThisWeek'] ?? 0;
  int get usersThisMonth => growth['usersThisMonth'] ?? 0;
  int get storesThisWeek => growth['storesThisWeek'] ?? 0;
  int get storesThisMonth => growth['storesThisMonth'] ?? 0;
  int get ordersThisMonth => growth['ordersThisMonth'] ?? 0;

  // Distribution Data
  Map<String, dynamic> get usersByRole => _stats?['usersByRole'] ?? {};
  Map<String, dynamic> get storesByCategory => 
      Map<String, dynamic>.from(_stats?['storesByCategory'] ?? {});

  // Recent Activity
  List<dynamic> get recentStores => _stats?['recentStores'] ?? [];
  List<dynamic> get recentUsers => _stats?['recentUsers'] ?? [];
  List<dynamic> get recentReviews => _stats?['recentReviews'] ?? [];

  // Chart Data
  List<dynamic> get dailyGrowth => _stats?['dailyGrowth'] ?? [];

  /// Fetch admin stats from API
  Future<void> fetchStats({bool forceRefresh = false}) async {
    // Don't refetch if we have recent data (less than 5 minutes old)
    if (!forceRefresh && _stats != null && _lastFetched != null) {
      final diff = DateTime.now().difference(_lastFetched!);
      if (diff.inMinutes < 5) return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getAdminStats();
      _stats = response;
      _lastFetched = DateTime.now();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force refresh stats
  Future<void> refresh() => fetchStats(forceRefresh: true);

  /// Format large numbers with K/M suffix
  String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Calculate growth percentage
  String getGrowthPercentage(int current, int previous) {
    if (previous == 0) return current > 0 ? '+100%' : '0%';
    final percentage = ((current - previous) / previous * 100).round();
    return percentage >= 0 ? '+$percentage%' : '$percentage%';
  }
}
