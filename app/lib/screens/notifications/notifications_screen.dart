import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/app_notification.dart';
import '../../providers/notifications_provider.dart';
import '../demands/demand_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          Consumer<NotificationsProvider>(
            builder: (context, provider, _) {
              if (provider.hasUnread) {
                return TextButton.icon(
                  onPressed: () => provider.markAllAsRead(),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('قراءة الكل'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('حدث خطأ', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => provider.fetchNotifications(refresh: true),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ستظهر هنا إشعارات الطلبات الجديدة',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(refresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _buildNotificationTile(notification, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification notification, NotificationsProvider provider) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => provider.deleteNotification(notification.id),
      child: ListTile(
        leading: _buildNotificationIcon(notification),
        title: Text(
          notification.isNewDemand
              ? notification.demandTitle ?? 'طلب جديد'
              : 'إشعار',
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.demandDescription != null)
              Text(
                notification.demandDescription!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (notification.wilayaName != null) ...[
                  Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 2),
                  Text(
                    notification.wilayaName!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 2),
                Text(
                  notification.timeAgo,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: notification.isRead ? null : AppTheme.primaryColor.withOpacity(0.05),
        onTap: () => _handleNotificationTap(notification, provider),
      ),
    );
  }

  Widget _buildNotificationIcon(AppNotification notification) {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    if (notification.isNewDemand) {
      iconData = Icons.work_outline;
      iconColor = Colors.blue.shade700;
      bgColor = Colors.blue.shade50;
    } else {
      iconData = Icons.notifications_outlined;
      iconColor = Colors.grey.shade700;
      bgColor = Colors.grey.shade100;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor),
    );
  }

  void _handleNotificationTap(AppNotification notification, NotificationsProvider provider) {
    // Mark as read
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    // Navigate based on notification type
    if (notification.isNewDemand && notification.demandId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DemandDetailScreen(demandId: notification.demandId!),
        ),
      );
    }
  }
}
