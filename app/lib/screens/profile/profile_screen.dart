import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../auth/login_screen.dart';
import '../saved/saved_screen.dart';
import 'edit_profile_screen.dart';
import '../chat/conversations_screen.dart';
import 'my_reviews_screen.dart';
import 'my_orders_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/manage_users_screen.dart';
import '../admin/manage_stores_screen.dart';
import '../admin/manage_employees_screen.dart';
import '../admin/store_orders_screen.dart';
import 'store_analytics_screen.dart';
import '../subscription/my_subscription_screen.dart';
import '../subscription/subscription_plans_screen.dart';
import '../admin/admin_subscriptions_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('Not logged in'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                ),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Picture
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor, width: 3),
                ),
                child: ClipOval(
                  child: user.profilePic != null
                      ? CachedNetworkImage(
                          imageUrl: user.profilePic!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              user.displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getRoleLabel(user.role),
                style: TextStyle(
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Menu Items
            _ProfileMenuItem(
              icon: Icons.person_outline,
              iconColor: const Color(0xFF3B82F6),
              title: 'Edit Profile',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              ),
            ),
            _ProfileMenuItem(
              icon: Icons.bookmark_outline,
              iconColor: const Color(0xFFF59E0B),
              title: 'Saved Stores',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavedScreen()),
              ),
            ),
            _ProfileMenuItem(
              icon: Icons.chat_outlined,
              iconColor: const Color(0xFF10B981),
              title: 'Messages',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConversationsScreen()),
              ),
            ),
            _ProfileMenuItem(
              icon: Icons.star_outline,
              iconColor: const Color(0xFFF97316),
              title: 'My Reviews',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyReviewsScreen()),
              ),
            ),
            _ProfileMenuItem(
              icon: Icons.shopping_bag_outlined,
              iconColor: const Color(0xFF8B5CF6),
              title: 'My Orders',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
              ),
            ),

            // Subscription for store owners
            if (user.isStoreOwner) ...[
              _ProfileMenuItem(
                icon: Icons.card_membership,
                iconColor: const Color(0xFFFFD700),
                title: 'My Subscription',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MySubscriptionScreen()),
                ),
              ),
            ],

            // Become Store Owner option for visitors
            if (user.isVisitor) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor.withValues(alpha: 0.1), Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.storefront, size: 40, color: AppTheme.primaryColor),
                    const SizedBox(height: 12),
                    const Text(
                      'Want to sell on 3alamati?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Become a store owner and start your business',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SubscriptionPlansScreen(showUpgradeFlow: true)),
                        ),
                        child: const Text('Become Store Owner'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Store Owner options
            if (user.isStoreOwner) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Store Management',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
              _ProfileMenuItem(
                icon: Icons.store_outlined,
                iconColor: const Color(0xFF06B6D4),
                title: 'My Stores',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageStoresScreen()),
                ),
              ),
              _ProfileMenuItem(
                icon: Icons.analytics_outlined,
                iconColor: const Color(0xFF6366F1),
                title: 'Analytics',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StoreAnalyticsScreen()),
                ),
              ),
              _ProfileMenuItem(
                icon: Icons.people_alt_outlined,
                iconColor: const Color(0xFFEC4899),
                title: 'Manage Employees',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageEmployeesScreen()),
                ),
              ),
              _ProfileMenuItem(
                icon: Icons.receipt_long_outlined,
                iconColor: const Color(0xFFF43F5E),
                title: 'Store Orders',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StoreOrdersScreen()),
                ),
              ),
            ],
            
            // Admin options
            if (user.isSuperAdmin) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Admin Panel',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
              _ProfileMenuItem(
                icon: Icons.dashboard,
                iconColor: const Color(0xFFEF4444),
                title: 'Dashboard',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                ),
              ),
              _ProfileMenuItem(
                icon: Icons.people,
                iconColor: const Color(0xFF14B8A6),
                title: 'Manage Users',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageUsersScreen()),
                ),
              ),
              _ProfileMenuItem(
                icon: Icons.storefront,
                iconColor: const Color(0xFFA855F7),
                title: 'Manage Stores',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManageStoresScreen()),
                ),
              ),
              _ProfileMenuItem(
                icon: Icons.card_membership,
                iconColor: const Color(0xFFFFD700),
                title: 'Manage Subscriptions',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminSubscriptionsScreen()),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.red;
      case 'store_owner':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'store_owner':
        return 'Store Owner';
      default:
        return 'Customer';
    }
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    this.iconColor = Colors.grey,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
