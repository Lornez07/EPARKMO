import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/parking_provider.dart';
import '../screens/login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ParkingProvider>(
      builder: (ctx, provider, _) {
        final user = provider.currentUser;
        if (user == null) return const SizedBox.shrink();

        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            child: Column(
              children: [
                // Avatar card
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 32, horizontal: 24),
                      decoration: AppDecorations.primaryGlassCard(
                          borderRadius: 28),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.primaryGlow,
                                    blurRadius: 16)
                              ],
                            ),
                            child: Center(
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: AppTextStyles.displayLarge,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(user.name,
                              style: AppTextStyles.headingMedium),
                          const SizedBox(height: 4),
                          Text(user.email,
                              style: AppTextStyles.bodyMedium),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: user.isAdmin
                                  ? AppColors.primary.withOpacity(0.2)
                                  : AppColors.available.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: user.isAdmin
                                    ? AppColors.primary.withOpacity(0.5)
                                    : AppColors.available.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              user.isAdmin ? '⚡ Admin' : '🙍 Guest',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: user.isAdmin
                                    ? AppColors.primary
                                    : AppColors.available,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),

                const SizedBox(height: 24),

                // Menu items
                _MenuCard(
                  items: [
                    _MenuItem(
                      icon: Icons.info_outline_rounded,
                      label: 'About E-Park Mo',
                      onTap: () => _showAbout(context),
                    ),
                    _MenuItem(
                      icon: Icons.local_parking_rounded,
                      label: 'Total Slots',
                      trailing: '${AppStrings.totalSlots}',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.timer_outlined,
                      label: 'Reservation Timeout',
                      trailing: '${AppStrings.reservationMinutes} min',
                      onTap: () {},
                    ),
                  ],
                ).animate(delay: 150.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 16),

                // Sign out
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.logout_rounded,
                          color: AppColors.error),
                      title: Text('Sign Out',
                          style: AppTextStyles.bodyLarge
                              .copyWith(color: AppColors.error)),
                      onTap: () async {
                        await provider.signOut();
                        if (ctx.mounted) {
                          Navigator.of(ctx).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (_) => false,
                          );
                        }
                      },
                    ),
                  ),
                ).animate(delay: 250.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 24),
                Text('${AppStrings.appName} v1.0.0',
                    style: AppTextStyles.bodySmall),
                Text(AppStrings.college, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_parking_rounded,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text('E-Park Mo', style: AppTextStyles.headingMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Parking System Prototype',
                style: AppTextStyles.bodyLarge),
            const SizedBox(height: 12),
            Text('Thesis Project 2026 — ${AppStrings.college}',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            Text('Developers:', style: AppTextStyles.labelLarge),
            Text('John Cedrick Pasco', style: AppTextStyles.bodyMedium),
            Text('Lorenz Estrella', style: AppTextStyles.bodyMedium),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: AppDecorations.glassCard(borderRadius: 20),
        child: Column(
          children: List.generate(items.length, (i) {
            final item = items[i];
            return Column(
              children: [
                ListTile(
                  leading: Icon(item.icon, color: AppColors.primary, size: 20),
                  title: Text(item.label, style: AppTextStyles.bodyLarge),
                  trailing: item.trailing != null
                      ? Text(item.trailing!,
                          style: AppTextStyles.bodyMedium)
                      : const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.textMuted),
                  onTap: item.onTap,
                ),
                if (i < items.length - 1)
                  const Divider(
                      height: 1, indent: 16, endIndent: 16,
                      color: AppColors.glassBorder),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });
}
