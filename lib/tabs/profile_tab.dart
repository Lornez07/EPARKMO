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

                // Section 1: Account Settings
                const _SectionHeader(label: 'Account Settings'),
                _MenuCard(
                  items: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Edit Profile',
                      onTap: () => _showEditProfile(ctx, provider),
                    ),
                    _MenuItem(
                      icon: Icons.local_parking_rounded,
                      label: 'Parking Information',
                      onTap: () => _showParkingInfo(ctx, provider),
                    ),
                  ],
                ).animate(delay: 150.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 24),

                // Section 2: Support & Operations
                const _SectionHeader(label: 'Support & Operations'),
                _MenuCard(
                  items: [
                    _MenuItem(
                      icon: Icons.monitor_heart_outlined,
                      label: 'System Status',
                      onTap: () => _showSystemStatus(ctx, provider),
                    ),
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Help / FAQ',
                      onTap: () => _showHelp(ctx),
                    ),
                    _MenuItem(
                      icon: Icons.feedback_outlined,
                      label: 'Feedback / Report Issue',
                      onTap: () => _showFeedback(ctx),
                    ),
                  ],
                ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 24),

                // Section 3: Legal & Meta
                const _SectionHeader(label: 'Legal & Info'),
                _MenuCard(
                  items: [
                    _MenuItem(
                      icon: Icons.gavel_rounded,
                      label: 'Terms and Conditions',
                      onTap: () => _showTerms(ctx),
                    ),
                    _MenuItem(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      onTap: () => _showPrivacy(ctx),
                    ),
                    _MenuItem(
                      icon: Icons.info_outline_rounded,
                      label: 'About App',
                      onTap: () => _showAbout(ctx),
                    ),
                  ],
                ).animate(delay: 250.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: 32),

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
                ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

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

  void _showEditProfile(BuildContext context, ParkingProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _BaseModalSheet(
        title: 'Edit Profile',
        icon: Icons.person_outline_rounded,
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildTextField(label: 'Full Name', initialValue: provider.currentUser?.name ?? ''),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showParkingInfo(BuildContext context, ParkingProvider provider) {
    _showModal(context, 'Parking Information', Icons.local_parking_rounded, [
      _buildInfoRow('Total Capacity', '${AppStrings.totalSlots} Slots'),
      _buildInfoRow('Reservation Time', '${AppStrings.reservationMinutes} Minutes'),
      _buildInfoRow('Auto-Close Guard', '${AppStrings.barrierAutoCloseSeconds} Seconds'),
    ]);
  }

  void _showSystemStatus(BuildContext context, ParkingProvider provider) {
    _showModal(context, 'System Status', Icons.monitor_heart_outlined, [
      _buildStatusRow('Cloud Database', 'Connected', true),
      _buildStatusRow('Hardware Gateway', provider.slots.isNotEmpty ? 'Online' : 'Connecting...', provider.slots.isNotEmpty),
      _buildStatusRow('OTP Service', 'Active', true),
      _buildStatusRow('System Version', 'v1.0.0 (Thesis)', true),
    ]);
  }

  void _showHelp(BuildContext context) {
    _showModal(context, 'Help & FAQ', Icons.help_outline_rounded, [
      _buildFaqItem('How do I reserve?', 'Select an "Available" slot and tap "Reserve". You have 15 minutes to arrive.'),
      _buildFaqItem('How to open the gate?', 'Once you arrive at your slot and confirm, use the "Open Barrier" button.'),
      _buildFaqItem('What if my time expires?', 'The reservation will automatically cancel and the slot becomes available again.'),
    ]);
  }

  void _showFeedback(BuildContext context) {
    _showModal(context, 'Feedback', Icons.feedback_outlined, [
      const Text('We value your feedback for our thesis project.', style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 16),
      _buildTextField(label: 'Feedback / Issue Description', maxLines: 4),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Submit Feedback')),
    ]);
  }

  void _showTerms(BuildContext context) {
    _showModal(context, 'Terms & Conditions', Icons.gavel_rounded, [
      Text('By using E-Park Mo, you agree to follow the campus parking regulations of ${AppStrings.college}...', style: const TextStyle(color: Colors.white70)),
    ]);
  }

  void _showPrivacy(BuildContext context) {
    _showModal(context, 'Privacy Policy', Icons.privacy_tip_outlined, [
      const Text('We only collect minimal data (Name, Email) to facilitate the parking reservation system...', style: TextStyle(color: Colors.white70)),
    ]);
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text('About App', style: AppTextStyles.headingMedium),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAboutRow('App Name', AppStrings.appName),
              _buildAboutRow('Description', 'Smart Parking System prototype'),
              const Divider(height: 24),
              _buildAboutRow('Developers', 'John Cedrick Pasco\nLorenz Estrella'),
              _buildAboutRow('Institution', AppStrings.college),
              _buildAboutRow('Stakeholder', 'Micronet Solutions Inc.'),
              const Divider(height: 24),
              _buildAboutRow('Technologies', 'Flutter, Firebase, ESP32,\nUltrasonic Sensors'),
              _buildAboutRow('Version', '1.0'),
              _buildAboutRow('Year', '2026'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // --- Helpers ---
  void _showModal(BuildContext context, String title, IconData icon, List<Widget> children) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _BaseModalSheet(
        title: title,
        icon: icon,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, bool success) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (success ? AppColors.available : AppColors.error).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status, style: TextStyle(color: success ? AppColors.available : AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(a, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, int maxLines = 1, dynamic initialValue}) {
    return TextField(
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label.toUpperCase(), style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMuted, letterSpacing: 1.2)),
      ),
    );
  }
}

class _BaseModalSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _BaseModalSheet({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgDark.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(title, style: AppTextStyles.headingSmall),
              ],
            ),
            const SizedBox(height: 24),
            child,
            const SizedBox(height: 24),
          ],
        ),
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
