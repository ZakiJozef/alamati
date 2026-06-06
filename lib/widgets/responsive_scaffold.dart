import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/theme.dart';

/// A responsive layout wrapper that provides:
/// - NavigationRail (sidebar) on web
/// - BottomNavigationBar on mobile
/// - Centered content with max width on web
class ResponsiveScaffold extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;
  final Widget body;
  final List<NavDestination> destinations;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  
  const ResponsiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.body,
    required this.destinations,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  static const double webMaxWidth = 1200.0;
  static const double webContentWidthRatio = 0.85;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = kIsWeb && screenWidth > 800;

    if (isWideScreen) {
      return _buildWebLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  Widget _buildWebLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail (Sidebar)
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            selectedIconTheme: IconThemeData(color: AppTheme.primaryColor),
            selectedLabelTextStyle: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
            unselectedIconTheme: IconThemeData(color: Colors.grey.shade500),
            unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade500),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '3alamati',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            destinations: [
              NavigationRailDestination(
                icon: Icon(destinations[0].icon),
                selectedIcon: Icon(destinations[0].selectedIcon ?? destinations[0].icon),
                label: Text(destinations[0].label),
              ),
              NavigationRailDestination(
                icon: Icon(destinations[1].icon),
                selectedIcon: Icon(destinations[1].selectedIcon ?? destinations[1].icon),
                label: Text(destinations[1].label),
              ),
              // Index 2 - Nearby (Restored)
              NavigationRailDestination(
                icon: Icon(destinations[2].icon),
                selectedIcon: Icon(destinations[2].selectedIcon ?? destinations[2].icon),
                label: Text(destinations[2].label),
              ),
              NavigationRailDestination(
                icon: Icon(destinations[3].icon),
                selectedIcon: Icon(destinations[3].selectedIcon ?? destinations[3].icon),
                label: Text(destinations[3].label),
              ),
              NavigationRailDestination(
                icon: Icon(destinations[4].icon),
                selectedIcon: Icon(destinations[4].selectedIcon ?? destinations[4].icon),
                label: Text(destinations[4].label),
              ),
            ],
          ),
          // Divider
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content Area
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: destinations[0].icon,
                label: destinations[0].label,
                isSelected: currentIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _NavItem(
                icon: destinations[1].icon,
                label: destinations[1].label,
                isSelected: currentIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
              // QR Scanner FAB
              GestureDetector(
                onTap: () => onDestinationSelected(2),
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      destinations[2].icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: destinations[3].icon,
                label: destinations[3].label,
                isSelected: currentIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
              _NavItem(
                icon: destinations[4].icon,
                label: destinations[4].label,
                isSelected: currentIndex == 4,
                onTap: () => onDestinationSelected(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.primaryColor : Colors.grey.shade400;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigation destination definition
class NavDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const NavDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}
