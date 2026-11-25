import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// Persistent fixed Bottom Navigation Bar matching Doctorac's exact pill design:
/// الرئيسية | الخريطة | مواعيدي | طلباتي | حسابي
class MainShellScaffold extends StatelessWidget {
  const MainShellScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTabTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: AppColors.bottomBarShadow,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  label: 'الرئيسية',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  isActive: currentIndex == 0,
                  onTap: () => _onTabTap(0),
                ),
                _NavItem(
                  label: 'الخريطة',
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map_rounded,
                  isActive: currentIndex == 1,
                  onTap: () => _onTabTap(1),
                ),
                _NavItem(
                  label: 'مواعيدي',
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                  isActive: currentIndex == 2,
                  onTap: () => _onTabTap(2),
                ),
                _NavItem(
                  label: 'طلباتي',
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag_rounded,
                  isActive: currentIndex == 3,
                  onTap: () => _onTabTap(3),
                ),
                _NavItem(
                  label: 'حسابي',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  isActive: currentIndex == 4,
                  onTap: () => _onTabTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 13 : 9,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.mintChipActive : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
