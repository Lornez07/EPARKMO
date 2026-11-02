import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/parking_provider.dart';
import '../screens/login_screen.dart';
import '../models/user_model.dart';

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
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 32, horizontal: 24),
                      decoration:
                          AppDecorations.primaryGlassCard(borderRadius: 28),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 80,
                            decoration: const BoxDecoration(
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
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name,
                                    style: AppTextStyles.headingMedium),
                                const SizedBox(height: AppSpacing.xs),
                                Text(user.email,
                                    style: AppTextStyles.bodyMedium),
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: user.isAdmin
                                        ? AppColors.primary.withOpacity(0.2)
                                        : AppColors.available.withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                    border: Border.all(
                                      color: user.isAdmin
                                          ? AppColors.primary.withOpacity(0.5)
                                          : AppColors.available
                                              .withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        user.isAdmin
                                            ? Icons.verified_user_outlined
                                            : Icons.person_outline_rounded,
                                        size: 14,
                                        color: user.isAdmin
                                            ? AppColors.primary
                                            : AppColors.available,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        user.isAdmin ? 'Admin' : 'Guest',
                                        style:
                                            AppTextStyles.labelLarge.copyWith(
                                          color: user.isAdmin
                                              ? AppColors.primary
                                              : AppColors.available,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1),

                const SizedBox(height: AppSpacing.xl),

                // Section 1: Account Settings
                const _SectionHeader(label: 'Account Settings'),
                _MenuCard(
                  items: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      onTap: () => _showProfile(ctx, provider),
                    ),
                    _MenuItem(
                      icon: Icons.local_parking_rounded,
                      label: 'Parking Information',
                      onTap: () => _showParkingInfo(ctx, provider),
                    ),
                  ],
                ).animate(delay: 150.ms).fadeIn(duration: 500.ms),

                const SizedBox(height: AppSpacing.xl),

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

                const SizedBox(height: AppSpacing.xl),

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

                const SizedBox(height: AppSpacing.xxl),

                // Sign out
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border:
                          Border.all(color: AppColors.error.withOpacity(0.3)),
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

                const SizedBox(height: AppSpacing.xl),
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

  void _showProfile(BuildContext context, ParkingProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ProfileModal(provider: provider),
    );
  }

  void _showParkingInfo(BuildContext context, ParkingProvider provider) {
    _showModal(context, 'Parking Information', Icons.local_parking_rounded, [
      _buildInfoRow('Total Capacity', '${AppStrings.totalSlots} Slots'),
      _buildInfoRow(
          'Reservation Time', '${AppStrings.reservationMinutes} Minutes'),
      _buildInfoRow(
          'Auto-Close Guard', '${AppStrings.barrierAutoCloseSeconds} Seconds'),
    ]);
  }

  void _showSystemStatus(BuildContext context, ParkingProvider provider) {
    _showModal(context, 'System Status', Icons.monitor_heart_outlined, [
      _buildStatusRow('Cloud Database', 'Connected', true),
      _buildStatusRow(
          'Hardware Gateway',
          provider.slots.isNotEmpty ? 'Online' : 'Connecting...',
          provider.slots.isNotEmpty),
      _buildStatusRow('OTP Service', 'Active', true),
      _buildStatusRow('System Version', 'v1.0.0 (Thesis)', true),
    ]);
  }

  void _showHelp(BuildContext context) {
    _showModal(context, 'Help & FAQ', Icons.help_outline_rounded, [
      _buildFaqItem('How do I reserve?',
          'Select an "Available" slot and tap "Reserve". You have 15 minutes to arrive.'),
      _buildFaqItem('How to open the gate?',
          'Once you arrive at your slot and confirm, use the "Open Barrier" button.'),
      _buildFaqItem('What if my time expires?',
          'The reservation will automatically cancel and the slot becomes available again.'),
    ]);
  }

  void _showFeedback(BuildContext context) {
    _showModal(context, 'Feedback', Icons.feedback_outlined, [
      const Text('We value your feedback for our thesis project.',
          style: TextStyle(color: Colors.white70)),
      const SizedBox(height: AppSpacing.lg),
      _buildTextField(label: 'Feedback / Issue Description', maxLines: 4),
      const SizedBox(height: AppSpacing.lg),
      ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Submit Feedback')),
    ]);
  }

  void _showTerms(BuildContext context) {
    _showModal(context, 'Terms & Conditions', Icons.gavel_rounded, [
      const Text(
          'By using E-Park Mo, you agree to follow the campus parking regulations of ${AppStrings.college}...',
          style: TextStyle(color: Colors.white70)),
    ]);
  }

  void _showPrivacy(BuildContext context) {
    _showModal(context, 'Privacy Policy', Icons.privacy_tip_outlined, [
      const Text(
          'We only collect minimal data (Name, Email) to facilitate the parking reservation system...',
          style: TextStyle(color: Colors.white70)),
    ]);
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
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
              const Divider(height: AppSpacing.xl),
              _buildAboutRow(
                  'Developers', 'John Cedrick Pasco\nLorenz Estrella'),
              _buildAboutRow('Institution', AppStrings.college),
              _buildAboutRow('Stakeholder', 'Micronet Solutions Inc.'),
              const Divider(height: AppSpacing.xl),
              _buildAboutRow('Technologies',
                  'Flutter, Firebase, ESP32,\nUltrasonic Sensors'),
              _buildAboutRow('Version', '1.0'),
              _buildAboutRow('Year', '2026'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Close', style: TextStyle(color: AppColors.primary)),
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
          Text(label,
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // --- Helpers ---
  void _showModal(BuildContext context, String title, IconData icon,
      List<Widget> children) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _BaseModalSheet(
        title: title,
        icon: icon,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
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
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
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
              color: (success ? AppColors.available : AppColors.error)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(status,
                style: TextStyle(
                    color: success ? AppColors.available : AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
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
          Text(q,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          Text(a,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary)),
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
        child: Text(label.toUpperCase(),
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.textMuted, letterSpacing: 1.2)),
      ),
    );
  }
}

class _BaseModalSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _BaseModalSheet(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgDark.withOpacity(0.9),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(AppRadius.xs))),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Text(title, style: AppTextStyles.headingSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            child,
            const SizedBox(height: AppSpacing.xl),
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
      borderRadius: BorderRadius.circular(AppRadius.lg),
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
                      ? Text(item.trailing!, style: AppTextStyles.bodyMedium)
                      : const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.textMuted),
                  onTap: item.onTap,
                ),
                if (i < items.length - 1)
                  const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
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

class _ProfileModal extends StatefulWidget {
  final ParkingProvider provider;
  const _ProfileModal({required this.provider});

  @override
  State<_ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<_ProfileModal> {
  bool _isEditing = false;
  late TextEditingController _nameCtrl;
  List<CarModel> _cars = [];

  @override
  void initState() {
    super.initState();
    final user = widget.provider.currentUser;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    if (user != null) {
      _cars = List.from(user.cars);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addCar() {
    setState(() {
      _cars.add(CarModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        plateNumber: '',
        model: '',
        color: '',
      ));
    });
  }

  void _removeCar(int index) {
    setState(() {
      _cars.removeAt(index);
    });
  }

  void _updateCar(int index, CarModel updatedCar) {
    setState(() {
      _cars[index] = updatedCar;
    });
  }

  Future<void> _saveProfile() async {
    final ok =
        await widget.provider.updateProfile(_nameCtrl.text.trim(), _cars);
    if (ok && mounted) {
      setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.provider.currentUser;
    if (user == null) return const SizedBox.shrink();

    return _BaseModalSheet(
      title: 'Profile Information',
      icon: Icons.person_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isEditing) ...[
            _buildViewRow('Full Name', user.name),
            _buildViewRow('Email', user.email),
            const SizedBox(height: AppSpacing.lg),
            const Text('Registered Vehicles',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            if (user.cars.isEmpty)
              const Text('No vehicles registered.',
                  style: TextStyle(color: Colors.white70))
            else
              ...user.cars.map((c) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.plateNumber.toUpperCase(),
                            style: AppTextStyles.headingSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text('${c.color} ${c.model}',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  )),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit Profile'),
              ),
            ),
          ] else ...[
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: const TextStyle(color: Colors.white60),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.1))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.primary)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('Vehicles',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            ...List.generate(_cars.length, (index) {
              final c = _cars[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: c.plateNumber,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                                labelText: 'Plate Number',
                                labelStyle: TextStyle(color: Colors.white60)),
                            onChanged: (v) => _updateCar(index,
                                c.copyWith(plateNumber: v.toUpperCase())),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                          onPressed: () => _removeCar(index),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: c.model,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                                labelText: 'Car Model',
                                labelStyle: TextStyle(color: Colors.white60)),
                            onChanged: (v) =>
                                _updateCar(index, c.copyWith(model: v)),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            initialValue: c.color,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                                labelText: 'Color',
                                labelStyle: TextStyle(color: Colors.white60)),
                            onChanged: (v) =>
                                _updateCar(index, c.copyWith(color: v)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addCar,
              icon: const Icon(Icons.add, color: AppColors.primary),
              label: const Text('Add Another Vehicle',
                  style: TextStyle(color: AppColors.primary)),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _nameCtrl.text = user.name;
                        _cars = List.from(user.cars);
                      });
                    },
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: widget.provider.isLoading ? null : _saveProfile,
                    child: widget.provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        ],
      ),
    );
  }
}
