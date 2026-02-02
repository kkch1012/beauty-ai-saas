import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../../core/constants/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Side Navigation (tablet)
          if (MediaQuery.of(context).size.width >= 768)
            _SideNavigation(),

          // Main Content
          Expanded(child: child),
        ],
      ),
      // Bottom Navigation (mobile/small tablet)
      bottomNavigationBar: MediaQuery.of(context).size.width < 768
          ? _BottomNavigation()
          : null,
    );
  }
}

class _SideNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    FeatherIcons.eye,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Beauty AI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavItem(
                  icon: FeatherIcons.camera,
                  label: '촬영 & 시뮬레이션',
                  path: '/',
                  isSelected: currentPath == '/',
                ),
                _NavItem(
                  icon: FeatherIcons.grid,
                  label: '디자인 라이브러리',
                  path: '/designs',
                  isSelected: currentPath == '/designs',
                ),
                _NavItem(
                  icon: FeatherIcons.users,
                  label: '고객 관리',
                  path: '/customers',
                  isSelected: currentPath.startsWith('/customers'),
                ),
                _NavItem(
                  icon: FeatherIcons.calendar,
                  label: '예약 관리',
                  path: '/bookings',
                  isSelected: currentPath == '/bookings',
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(),
                ),

                _NavItem(
                  icon: FeatherIcons.settings,
                  label: '설정',
                  path: '/settings',
                  isSelected: currentPath == '/settings',
                ),
              ],
            ),
          ),

          // User Info / Subscription Status
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      FeatherIcons.user,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Free Plan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '5/10 시뮬레이션',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool isSelected;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => context.go(path),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    int currentIndex = 0;
    if (currentPath == '/designs') currentIndex = 1;
    if (currentPath.startsWith('/customers')) currentIndex = 2;
    if (currentPath == '/bookings') currentIndex = 3;
    if (currentPath == '/settings') currentIndex = 4;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/designs');
            break;
          case 2:
            context.go('/customers');
            break;
          case 3:
            context.go('/bookings');
            break;
          case 4:
            context.go('/settings');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(FeatherIcons.camera),
          label: '촬영',
        ),
        BottomNavigationBarItem(
          icon: Icon(FeatherIcons.grid),
          label: '디자인',
        ),
        BottomNavigationBarItem(
          icon: Icon(FeatherIcons.users),
          label: '고객',
        ),
        BottomNavigationBarItem(
          icon: Icon(FeatherIcons.calendar),
          label: '예약',
        ),
        BottomNavigationBarItem(
          icon: Icon(FeatherIcons.settings),
          label: '설정',
        ),
      ],
    );
  }
}
