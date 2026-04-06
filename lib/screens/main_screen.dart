import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/parking_provider.dart';
import '../tabs/home_tab.dart';
import '../tabs/reserve_tab.dart';
import '../tabs/admin_dashboard.dart';
import '../tabs/profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ParkingProvider>(
      builder: (context, provider, _) {
        final isAdmin = provider.currentUser?.isAdmin ?? false;

        final tabs = <Widget>[
          const HomeTab(),
          isAdmin ? const AdminDashboard() : const ReserveTab(),
          const ProfileTab(),
        ];

        final navItems = <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(isAdmin
                ? Icons.dashboard_outlined
                : Icons.bookmark_border_rounded),
            activeIcon: Icon(isAdmin
                ? Icons.dashboard_rounded
                : Icons.bookmark_rounded),
            label: isAdmin ? 'Dashboard' : 'Reserve',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ];

        // Clamp index if tabs changed
        final clampedIndex = _currentIndex.clamp(0, tabs.length - 1);

        return Scaffold(
          extendBody: true,
          body: Container(
            decoration:
                BoxDecoration(gradient: AppDecorations.backgroundGradient),
            child: IndexedStack(
              index: clampedIndex,
              children: tabs,
            ),
          ),
          bottomNavigationBar: _GlassNavBar(
            currentIndex: clampedIndex,
            items: navItems,
            onTap: (i) => setState(() => _currentIndex = i),
          ),
        );
      },
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int> onTap;

  const _GlassNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard.withOpacity(0.85),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.glassBorder, width: 1),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final item = items[i];
                final isActive = i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconTheme(
                              data: IconThemeData(
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                size: 22,
                              ),
                              child: isActive ? item.activeIcon! : item.icon,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label ?? '',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
