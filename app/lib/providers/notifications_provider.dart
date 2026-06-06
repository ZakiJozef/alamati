import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/app_notification.dart';
import '../services/api_service.dart';

class NotificationsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnread => _unreadCount > 0;

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/notifications');
      
      if (response != null && response['data'] != null) {
        _notifications = (response['data'] as List)
            .map((json) => AppNotification.fromJson(json))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await _apiService.get('/notifications/unread-count');
      
      if (response != null && response['count'] != null) {
        _unreadCount = response['count'] as int;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      await _apiService.post('/notifications/$notificationId/read', {});
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final notification = _notifications[index];
        _notifications[index] = AppNotification(
          id: notification.id,
          type: notification.type,
          data: notification.data,
          readAt: DateTime.now(),
          createdAt: notification.createdAt,
        );
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _apiService.post('/notifications/read-all', {});
      
      // Update local state
      _notifications = _notifications.map((n) => AppNotification(
        id: n.id,
        type: n.type,
        data: n.data,
        readAt: n.readAt ?? DateTime.now(),
        createdAt: n.createdAt,
      )).toList();
      _unreadCount = 0;
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _apiService.delete('/notifications/$notificationId');
      
      // Update local state
      final notification = _notifications.firstWhere((n) => n.id == notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      if (!notification.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
      }
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  void clearNotifications() {
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }
}
