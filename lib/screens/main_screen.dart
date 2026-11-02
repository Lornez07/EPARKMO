import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
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

class _NavEntry {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavEntry({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ParkingProvider>(
      builder: (context, provider, _) {
        final isAdmin = provider.currentUser?.isAdmin ?? false;

        final entries = <_NavEntry>[
          const _NavEntry(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          _NavEntry(
            icon: isAdmin
                ? Icons.dashboard_outlined
                : Icons.bookmark_border_rounded,
            activeIcon:
                isAdmin ? Icons.dashboard_rounded : Icons.bookmark_rounded,
            label: isAdmin ? 'Dashboard' : 'Reserve',
          ),
          const _NavEntry(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ];

        final background =
            BoxDecoration(gradient: AppDecorations.backgroundGradient);

        return LayoutBuilder(
          builder: (context, constraints) {
            final useRail = constraints.maxWidth >= AppLayout.railBreakpoint;

            final tabs = <Widget>[
              HomeTab(showBrand: !useRail),
              isAdmin ? const AdminDashboard() : const ReserveTab(),
              const ProfileTab(),
            ];
            // Clamp index if tabs changed
            final index = _currentIndex.clamp(0, tabs.length - 1);
            final content = IndexedStack(index: index, children: tabs);

            if (!useRail) {
              return Scaffold(
                extendBody: true,
                body: Container(decoration: background, child: content),
                bottomNavigationBar: _GlassNavBar(
                  currentIndex: index,
                  entries: entries,
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
              );
            }

            return Scaffold(
              body: Container(
                decoration: background,
                child: Row(
                  children: [
                    _SideRail(
                      currentIndex: index,
                      entries: entries,
                      onTap: (i) => setState(() => _currentIndex = i),
                      user: provider.currentUser,
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, inner) {
                          final slack =
                              inner.maxWidth - AppLayout.contentMaxWidth;
                          final gutter = slack > 0 ? slack / 2 : 0.0;
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: gutter),
                            child: content,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Desktop Rail ─────────────────────────────────────────────────────────────

class _SideRail extends StatelessWidget {
  final int currentIndex;
  final List<_NavEntry> entries;
  final ValueChanged<int> onTap;
  final UserModel? user;

  const _SideRail({
    required this.currentIndex,
    required this.entries,
    required this.onTap,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: AppLayout.railWidth,
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          border: Border(right: BorderSide(color: AppColors.glassBorder)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _RailBrand(),
            const SizedBox(height: AppSpacing.xxl),
            for (var i = 0; i < entries.length; i++) ...[
              _railItem(i),
              const SizedBox(height: AppSpacing.xs),
            ],
            const Spacer(),
            const Divider(height: 1, color: AppColors.glassBorder),
            const SizedBox(height: AppSpacing.lg),
            _UserChip(user: user),
          ],
        ),
      ),
    );
  }

  Widget _railItem(int i) {
    final isActive = i == currentIndex;
    final entry = entries[i];
    return GestureDetector(
      onTap: () => onTap(i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? entry.activeIcon : entry.icon,
              size: 20,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              entry.label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailBrand extends StatelessWidget {
  const _RailBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.appName,
                style: AppTextStyles.headingSmall,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                AppStrings.tagline,
                style: AppTextStyles.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserChip extends StatelessWidget {
  final UserModel? user;

  const _UserChip({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Guest';
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final role = (user?.isAdmin ?? false) ? 'Admin' : 'Guest';

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.16),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            initial,
            style:
                AppTextStyles.headingSmall.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(role, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Mobile Glass Nav ─────────────────────────────────────────────────────────

class _GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavEntry> entries;
  final ValueChanged<int> onTap;

  const _GlassNavBar({
    required this.currentIndex,
    required this.entries,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard.withOpacity(0.85),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.glassBorder, width: 1),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(entries.length, (i) {
                final item = entries[i];
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
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: IconTheme(
                              data: IconThemeData(
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                size: 22,
                              ),
                              child:
                                  Icon(isActive ? item.activeIcon : item.icon),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.label,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w400,
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
