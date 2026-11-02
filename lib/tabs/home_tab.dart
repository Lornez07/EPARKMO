import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/parking_provider.dart';
import '../widgets/lot_map.dart';
import '../widgets/stat_card.dart';

class HomeTab extends StatelessWidget {
  /// The desktop rail already carries the brand, so the inline logo is hidden.
  final bool showBrand;

  const HomeTab({super.key, this.showBrand = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<ParkingProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${provider.currentUser?.name.split(' ').first ?? 'User'}',
                                  style: AppTextStyles.headingSmall,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text('Parking Overview',
                                    style: AppTextStyles.displayMedium),
                              ],
                            ),
                          ),
                          // The rail already carries the brand on desktop.
                          if (showBrand)
                            Container(
                              width: 50,
                              height: 50,
                              padding: const EdgeInsets.all(
                                  2), // Subtle padding for a professional frame
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                color: AppColors
                                    .primary, // Solid brand color for perfect blending
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                child: Image.asset(
                                  'assets/images/app_logo.png',
                                  fit: BoxFit
                                      .cover, // Fill the container seamlessly
                                ),
                              ),
                            ),
                        ],
                      ).animate().fadeIn(duration: 500.ms),
                      const SizedBox(height: AppSpacing.xl),

                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Available',
                              value: provider.slots.isEmpty
                                  ? '–'
                                  : provider.availableCount.toString(),
                              icon: Icons.check_circle_outline_rounded,
                              color: AppColors.available,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: StatCard(
                              label: 'Reserved',
                              value: provider.slots.isEmpty
                                  ? '–'
                                  : provider.reservedCount.toString(),
                              icon: Icons.bookmark_rounded,
                              color: AppColors.reserved,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: StatCard(
                              label: 'Occupied',
                              value: provider.slots.isEmpty
                                  ? '–'
                                  : provider.occupiedCount.toString(),
                              icon: Icons.directions_car_rounded,
                              color: AppColors.occupied,
                            ),
                          ),
                        ],
                      ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
                      const SizedBox(height: AppSpacing.xl),
                      Text('Parking Lot', style: AppTextStyles.headingMedium)
                          .animate(delay: 200.ms)
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        provider.slots.isEmpty
                            ? 'Waiting for sensor data'
                            : '${provider.availableCount} of ${AppStrings.totalSlots} bays free',
                        style: AppTextStyles.bodySmall,
                      ).animate(delay: 220.ms).fadeIn(duration: 400.ms),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              // Lot plan — skeleton until the first snapshot, error banner on
              // failure, live plan once slots arrive.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0,
                      AppSpacing.page, AppLayout.bottomNavInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (provider.error != null) ...[
                        _ErrorBanner(
                          message: provider.error!,
                          onDismiss: provider.clearError,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (provider.slots.isEmpty && provider.error == null)
                        const LotMapSkeleton()
                      else if (provider.slots.isEmpty)
                        const _NoDataPanel()
                      else
                        LotMap(
                          slots: provider.slots,
                          myReservation: provider.activeReservation,
                        ).animate(delay: 260.ms).fadeIn(duration: 400.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── States ───────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.error.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 20, color: AppColors.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Live data unavailable',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: onDismiss,
            child: Text('Dismiss', style: AppTextStyles.labelLarge),
          ),
        ],
      ),
    );
  }
}

class _NoDataPanel extends StatelessWidget {
  const _NoDataPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.sensors_off_rounded,
              size: 32, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text('No bays are reporting', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'The lot sensors have not sent any data. Reopen this screen once '
            'they are back online.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
