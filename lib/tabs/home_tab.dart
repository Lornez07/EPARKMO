
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/parking_provider.dart';
import '../widgets/slot_card.dart';
import '../widgets/stat_card.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

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
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                                  'Hello, ${provider.currentUser?.name.split(' ').first ?? 'User'} 👋',
                                  style: AppTextStyles.headingSmall,
                                ),
                                const SizedBox(height: 2),
                                Text('Parking Overview',
                                    style: AppTextStyles.displayMedium),
                              ],
                            ),
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            padding: const EdgeInsets.all(2), // Subtle padding for a professional frame
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: AppColors.primary, // Solid brand color for perfect blending
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                fit: BoxFit.cover, // Fill the container seamlessly
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms),
                      const SizedBox(height: 24),

                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Available',
                              value: provider.availableCount.toString(),
                              icon: Icons.check_circle_outline_rounded,
                              color: AppColors.available,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              label: 'Reserved',
                              value: provider.reservedCount.toString(),
                              icon: Icons.bookmark_rounded,
                              color: AppColors.reserved,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              label: 'Occupied',
                              value: provider.occupiedCount.toString(),
                              icon: Icons.directions_car_rounded,
                              color: AppColors.occupied,
                            ),
                          ),
                        ],
                      ).animate(delay: 100.ms).fadeIn(duration: 500.ms),
                      const SizedBox(height: 24),

<<<<<<< HEAD


=======
                      // Gate status card (only for those with permission)
                      if (provider.canShowBarrier) ...[
                        _buildGateCard(provider, isEntrance: true)
                            .animate(delay: 200.ms)
                            .fadeIn(duration: 500.ms),
                        const SizedBox(height: 12),
                        _buildGateCard(provider, isEntrance: false)
                            .animate(delay: 300.ms)
                            .fadeIn(duration: 500.ms),
                        const SizedBox(height: 24),
                      ],
>>>>>>> 9ede775032aa32cf38300adae5899ef150f0ecce

                      Text('Parking Slots',
                          style: AppTextStyles.headingMedium)
                          .animate(delay: 200.ms).fadeIn(duration: 400.ms),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              // Slots grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final slot = provider.slots[i];
                      return SlotCard(slot: slot)
                          .animate(delay: Duration(milliseconds: 100 + i * 60))
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.2, end: 0);
                    },
                    childCount: provider.slots.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.05,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
<<<<<<< HEAD
=======

  Widget _buildGateCard(ParkingProvider provider, {required bool isEntrance}) {
    final bool isOpen = isEntrance ? provider.barrierOpen : provider.exitBarrierOpen;
    final String label = isEntrance ? 'Entrance Barrier' : 'Exit Barrier';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: isOpen
              ? AppDecorations.primaryGlassCard(borderRadius: 20)
              : AppDecorations.glassCard(borderRadius: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isOpen
                          ? AppColors.available
                          : AppColors.textMuted)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isEntrance ? Icons.sensor_door_rounded : Icons.door_back_door_rounded,
                  color: isOpen
                      ? AppColors.available
                      : AppColors.textMuted,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTextStyles.headingSmall),
                    Text(
                      isOpen ? 'OPENING' : 'CLOSED',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isOpen
                            ? AppColors.available
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isOpen && isEntrance)
                      Text('Auto-closes when clear',
                          style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (provider.currentUser?.isAdmin ?? false)
                ElevatedButton(
                  onPressed: isOpen
                      ? null
                      : () => provider.openBarrier(), // Admin override
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Open',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
>>>>>>> 9ede775032aa32cf38300adae5899ef150f0ecce
}
