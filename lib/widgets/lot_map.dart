import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import '../models/parking_slot.dart';
import '../models/reservation.dart';

/// Top-down plan of the lot: painted bays with a top-view car in any bay that
/// is taken or held.
///
/// Read-only. All state comes from [ParkingProvider] — this widget never
/// writes to Firestore.
class LotMap extends StatelessWidget {
  final List<ParkingSlot> slots;
  final Reservation? myReservation;
  final int totalSlots;

  const LotMap({
    super.key,
    required this.slots,
    this.myReservation,
    this.totalSlots = AppStrings.totalSlots,
  });

  /// Bays per row: six across on desktop, three per row on phones.
  static int baysPerRow(double width) => width < 560 ? 3 : 6;

  @override
  Widget build(BuildContext context) {
    final sorted = [...slots]
      ..sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
    final bays = <ParkingSlot?>[
      for (var i = 0; i < totalSlots; i++) i < sorted.length ? sorted[i] : null,
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.glassBorder),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, c) {
          final perRow = baysPerRow(c.maxWidth);
          final rows = <List<ParkingSlot?>>[];
          for (var i = 0; i < bays.length; i += perRow) {
            rows.add(bays.sublist(i, (i + perRow).clamp(0, bays.length)));
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < rows.length; r++) ...[
                if (r > 0) const SizedBox(height: AppSpacing.md),
                _StallRow(bays: rows[r], myReservation: myReservation),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ─── Painted stall row ────────────────────────────────────────────────────────

class _StallRow extends StatelessWidget {
  final List<ParkingSlot?> bays;
  final Reservation? myReservation;

  const _StallRow({required this.bays, this.myReservation});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0x33FFFFFF)),
          bottom: BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < bays.length; i++)
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: i == bays.length - 1
                      ? null
                      : const Border(
                          right: BorderSide(color: Color(0x22FFFFFF)),
                        ),
                ),
                child: _Stall(slot: bays[i], myReservation: myReservation),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stall extends StatelessWidget {
  final ParkingSlot? slot;
  final Reservation? myReservation;

  const _Stall({required this.slot, this.myReservation});

  Color get _color {
    switch (slot?.status) {
      case SlotStatus.occupied:
        return AppColors.occupied;
      case SlotStatus.reserved:
        return AppColors.reserved;
      case SlotStatus.available:
      case null:
        return AppColors.available;
    }
  }

  String get _label {
    switch (slot?.status) {
      case SlotStatus.occupied:
        return 'Occupied';
      case SlotStatus.reserved:
        return 'Reserved';
      case SlotStatus.available:
        return 'Available';
      case null:
        return 'No data';
    }
  }

  /// Plate for a taken bay; the signed-in user's own countdown when they hold it.
  String? get _detail {
    if (slot == null) return null;
    if (myReservation != null &&
        myReservation!.slotId == slot!.id &&
        slot!.isReserved) {
      return _formatRemaining(myReservation!.remaining);
    }
    return slot!.reservedByPlate;
  }

  String _formatRemaining(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s left';
  }

  @override
  Widget build(BuildContext context) {
    final empty = slot == null;

    return Semantics(
      label: empty
          ? 'Bay, waiting for data'
          : 'Bay ${slot!.slotNumber}, ${_label.toLowerCase()}',
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.md),
        child: Column(
          children: [
            Text(
              empty ? '—' : 'P${slot!.slotNumber}',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.45),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  if (slot == null) return const SizedBox.shrink();
                  if (slot!.isAvailable) {
                    // Bare stall: only the painted "P" on the floor.
                    return Center(
                      child: Text(
                        'P',
                        style: AppTextStyles.displayLarge.copyWith(
                          color: Colors.white.withOpacity(0.08),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }
                  final h = (c.maxHeight * 0.94).clamp(0.0, 160.0);
                  final w = h / 2.1;
                  return Center(
                    child: CustomPaint(
                      size: Size(w, h),
                      painter: _CarPainter(color: _color),
                    ),
                  );
                },
              ),
            ),
            Text(
              _label,
              style: AppTextStyles.bodySmall.copyWith(
                color: empty ? AppColors.textMuted : _color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_detail != null)
              Text(
                _detail!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Top-view car ─────────────────────────────────────────────────────────────

class _CarPainter extends CustomPainter {
  final Color color;

  _CarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final body = Path()
      ..moveTo(w * 0.28, 0)
      ..quadraticBezierTo(w * 0.12, h * 0.02, w * 0.06, h * 0.16)
      ..lineTo(w * 0.02, h * 0.34)
      ..lineTo(w * 0.02, h * 0.76)
      ..quadraticBezierTo(w * 0.04, h * 0.96, w * 0.18, h)
      ..lineTo(w * 0.82, h)
      ..quadraticBezierTo(w * 0.96, h * 0.96, w * 0.98, h * 0.76)
      ..lineTo(w * 0.98, h * 0.34)
      ..lineTo(w * 0.94, h * 0.16)
      ..quadraticBezierTo(w * 0.88, h * 0.02, w * 0.72, 0)
      ..close();

    canvas.drawPath(body, Paint()..color = color.withOpacity(0.9));

    // Cabin, inset from the flanks, with glass cut out of it.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.24, w * 0.68, h * 0.46),
        Radius.circular(w * 0.18),
      ),
      Paint()..color = color.withOpacity(0.55),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.20, h * 0.27, w * 0.60, h * 0.10),
        Radius.circular(w * 0.05),
      ),
      Paint()..color = AppColors.bgDark.withOpacity(0.85),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.20, h * 0.58, w * 0.60, h * 0.08),
        Radius.circular(w * 0.04),
      ),
      Paint()..color = AppColors.bgDark.withOpacity(0.85),
    );

    // Wheels notch into the silhouette at all four corners.
    final wheel = Paint()..color = AppColors.bgDark;
    for (final y in [h * 0.14, h * 0.70]) {
      for (final x in [0.0, w * 0.90]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w * 0.10, h * 0.13),
            Radius.circular(w * 0.03),
          ),
          wheel,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CarPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

/// Placeholder shown until the first slot snapshot arrives. Same footprint as
/// [LotMap] so the layout does not jump.
class LotMapSkeleton extends StatelessWidget {
  const LotMapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading parking lot',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.glassBorder),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, c) {
            final perRow = LotMap.baysPerRow(c.maxWidth);
            final rows = (AppStrings.totalSlots / perRow).ceil();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < rows; r++) ...[
                  if (r > 0) const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        for (var i = 0; i < perRow; i++)
                          Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: i == perRow - 1
                                    ? null
                                    : const Border(
                                        right: BorderSide(
                                            color: Color(0x22FFFFFF)),
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .fade(begin: 0.35, end: 1, duration: 1100.ms),
    );
  }
}
