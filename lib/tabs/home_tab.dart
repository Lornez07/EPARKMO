
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
}
