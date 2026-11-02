import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/parking_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/log_entry.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ParkingProvider>(
      builder: (ctx, provider, _) {
        if (!(provider.currentUser?.isAdmin ?? false)) {
          return const Center(
            child: Text('Admin access required',
                style: TextStyle(color: AppColors.textMuted)),
          );
        }
        if (provider.logStreamError != null) {
          return Center(
            child: Text('Error: ${provider.logStreamError}',
                style: const TextStyle(color: Colors.redAccent)),
          );
        }

        return SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Admin Dashboard',
                                    style: AppTextStyles.displayMedium),
                                Text('Parking system overview',
                                    style: AppTextStyles.bodyMedium),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration:
                                AppDecorations.glassCard(borderRadius: 14),
                            child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: AppColors.primary,
                                size: 22),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: AppSpacing.xl),
                      // Summary stats
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
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: StatCard(
                              label: 'Reserved',
                              value: provider.reservedCount.toString(),
                              icon: Icons.bookmark_rounded,
                              color: AppColors.reserved,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: StatCard(
                              label: 'Occupied',
                              value: provider.occupiedCount.toString(),
                              icon: Icons.directions_car_rounded,
                              color: AppColors.occupied,
                            ),
                          ),
                        ],
                      ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
                      const SizedBox(height: AppSpacing.page),

                      // Log count card
                      _buildLogCountCard(provider)
                          .animate(delay: 200.ms)
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: AppSpacing.xl),

                      Row(
                        children: [
                          Text('Audit Log', style: AppTextStyles.headingMedium),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh,
                                color: Colors.white54, size: 20),
                            onPressed: () {
                              provider.fetchLogs();
                            },
                          ),
                          Text('${provider.logs.length} entries',
                              style: AppTextStyles.bodyMedium),
                        ],
                      ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              // Log entries
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx2, i) {
                      if (provider.logs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text('No logs yet.',
                                style: TextStyle(color: AppColors.textMuted)),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LogEntry(log: provider.logs[i])
                            .animate(
                                delay: Duration(milliseconds: 100 + i * 40))
                            .fadeIn(duration: 350.ms)
                            .slideX(begin: 0.1, end: 0),
                      );
                    },
                    childCount:
                        provider.logs.isEmpty ? 1 : provider.logs.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogCountCard(ParkingProvider provider) {
    final totalLogs = provider.logs.length;
    final reservations =
        provider.logs.where((l) => l.type.name == 'reservation').length;
    final cancellations =
        provider.logs.where((l) => l.type.name == 'cancellation').length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: AppDecorations.glassCard(borderRadius: 20),
          child: Row(
            children: [
              _miniStat('Total Logs', totalLogs.toString(), AppColors.primary),
              _divider(),
              _miniStat(
                  'Reservations', reservations.toString(), AppColors.available),
              _divider(),
              _miniStat('Cancellations', cancellations.toString(),
                  AppColors.occupied),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.displayMedium.copyWith(color: color)),
          Text(label,
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 36, color: AppColors.glassBorder);
  }
}
