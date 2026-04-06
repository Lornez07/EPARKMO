import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/parking_slot.dart';

class SlotCard extends StatelessWidget {
  final ParkingSlot slot;

  const SlotCard({super.key, required this.slot});

  Color get _statusColor {
    switch (slot.status) {
      case SlotStatus.available:
        return AppColors.available;
      case SlotStatus.reserved:
        return AppColors.reserved;
      case SlotStatus.occupied:
        return AppColors.occupied;
    }
  }

  Color get _glowColor {
    switch (slot.status) {
      case SlotStatus.available:
        return AppColors.availableGlow;
      case SlotStatus.reserved:
        return AppColors.reservedGlow;
      case SlotStatus.occupied:
        return AppColors.occupiedGlow;
    }
  }

  IconData get _statusIcon {
    switch (slot.status) {
      case SlotStatus.available:
        return Icons.check_circle_rounded;
      case SlotStatus.reserved:
        return Icons.bookmark_rounded;
      case SlotStatus.occupied:
        return Icons.directions_car_rounded;
    }
  }

  String get _statusLabel {
    switch (slot.status) {
      case SlotStatus.available:
        return 'Available';
      case SlotStatus.reserved:
        return 'Reserved';
      case SlotStatus.occupied:
        return 'Occupied';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _statusColor.withOpacity(0.12),
                _statusColor.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _statusColor.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: _glowColor,
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'P${slot.slotNumber}',
                    style: AppTextStyles.displayMedium
                        .copyWith(color: _statusColor),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_statusIcon,
                        color: _statusColor, size: 18),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (slot.reservedByName != null) ...[
                const SizedBox(height: 4),
                Text(
                  slot.reservedByName!,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (slot.isSensorActive && slot.distanceCm != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${slot.distanceCm!.toStringAsFixed(1)} cm',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
