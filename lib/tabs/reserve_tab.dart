import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/parking_slot.dart';
import '../models/reservation.dart';
import '../models/user_model.dart';
import '../providers/parking_provider.dart';
import '../widgets/slot_card.dart';

class ReserveTab extends StatelessWidget {
  const ReserveTab({super.key});

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
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reserve a Slot', style: AppTextStyles.displayMedium)
                          .animate()
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        provider.isParkingFull
                            ? 'All slots are currently full'
                            : 'Pick an available slot below',
                        style: AppTextStyles.bodyMedium,
                      ).animate(delay: 80.ms).fadeIn(duration: 400.ms),
                      const SizedBox(height: AppSpacing.xl),

                      // Live-data error
                      if (provider.error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                                color: AppColors.error.withOpacity(0.35)),
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
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        )),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(provider.error!,
                                        style: AppTextStyles.bodySmall),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: provider.clearError,
                                child: Text('Dismiss',
                                    style: AppTextStyles.labelLarge),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms),

                      // Active reservation card
                      if (provider.reservationParseError != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: AppDecorations.glassCard(
                              borderColor: AppColors.error),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppColors.error),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text('Metadata Error',
                                      style: AppTextStyles.labelLarge
                                          .copyWith(color: AppColors.error)),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(provider.reservationParseError!,
                                  style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms),

                      if (provider.hasActiveReservation)
                        _ActiveReservationCard(provider: provider)
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: -0.1),

                      if (provider.hasActiveReservation)
                        const SizedBox(height: AppSpacing.xl),

                      // Parking full banner
                      if (!provider.hasActiveReservation &&
                          provider.isParkingFull)
                        _ParkingFullBanner()
                            .animate(delay: 150.ms)
                            .fadeIn(duration: 400.ms),

                      if (!provider.hasActiveReservation &&
                          !provider.isParkingFull)
                        Text('Available Slots',
                                style: AppTextStyles.headingMedium)
                            .animate(delay: 150.ms)
                            .fadeIn(duration: 400.ms),
                      if (!provider.hasActiveReservation &&
                          !provider.isParkingFull)
                        const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              // Available slots — empty state, then a two-up grid of slots.
              if (!provider.hasActiveReservation && !provider.isParkingFull)
                if (provider.slots.where((s) => s.isAvailable).isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xxl),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.no_meeting_room_rounded,
                                size: 32, color: AppColors.textMuted),
                            const SizedBox(height: AppSpacing.md),
                            Text('No bays free right now',
                                style: AppTextStyles.headingSmall),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Every bay is reserved or occupied. Try again once a '
                              'driver leaves.',
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 600,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisExtent: 84,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final available = provider.slots
                              .where((s) => s.isAvailable)
                              .toList();
                          return _AvailableSlotTile(slot: available[i])
                              .animate(
                                  delay: Duration(milliseconds: 100 + i * 60))
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.1, end: 0);
                        },
                        childCount:
                            provider.slots.where((s) => s.isAvailable).length,
                      ),
                    ),
                  ),

              // All slots grid (when has active reservation or parking full)
              if (provider.hasActiveReservation || provider.isParkingFull)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('All Slots', style: AppTextStyles.headingMedium),
                        const SizedBox(height: AppSpacing.lg),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 280,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 1.05,
                          ),
                          itemCount: provider.slots.length,
                          itemBuilder: (ctx, i) =>
                              SlotCard(slot: provider.slots[i]),
                        ),
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

// ─── Parking Full Banner ──────────────────────────────────────────────────

class _ParkingFullBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.occupied.withOpacity(0.18),
            AppColors.occupied.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.occupied.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.block_rounded, size: 48, color: AppColors.occupied),
          const SizedBox(height: AppSpacing.md),
          Text('Parking Full',
              style: AppTextStyles.headingMedium
                  .copyWith(color: AppColors.occupied)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'All slots are currently occupied or reserved.\nPlease try again later.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Active Reservation Card ──────────────────────────────────────────────

class _ActiveReservationCard extends StatefulWidget {
  final ParkingProvider provider;
  const _ActiveReservationCard({required this.provider});

  @override
  State<_ActiveReservationCard> createState() => _ActiveReservationCardState();
}

class _ActiveReservationCardState extends State<_ActiveReservationCard> {
  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final res = provider.activeReservation!;
    final remaining = res.remaining;
    final progress = remaining.inSeconds / (AppStrings.reservationMinutes * 60);

    final urgentColor = remaining.inMinutes < 5
        ? AppColors.occupied
        : remaining.inMinutes < 10
            ? AppColors.reserved
            : AppColors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                urgentColor.withOpacity(0.18),
                urgentColor.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: urgentColor.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: urgentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.bookmark_rounded,
                        color: urgentColor, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Active Reservation',
                            style: AppTextStyles.headingSmall),
                        Text('Slot ${res.slotNumber}',
                            style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                  // Countdown
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: urgentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      _formatDuration(remaining),
                      style: AppTextStyles.displayMedium
                          .copyWith(color: urgentColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: AppColors.glassBase,
                  valueColor: AlwaysStoppedAnimation<Color>(urgentColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('${remaining.inMinutes} min remaining',
                  style: AppTextStyles.bodySmall),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: provider.isLoading
                          ? null
                          : provider.cancelReservation,
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancel Booking'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.occupied,
                        side: BorderSide(
                            color: AppColors.occupied.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading
                          ? null
                          : () async {
                              await provider.confirmArrival();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Barrier opened! Please proceed to your slot. The sensor is waiting to locate your vehicle.'),
                                    backgroundColor: AppColors.available,
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.location_on_rounded, size: 16),
                      label: const Text("Open Barrier"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.available,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Available Slot Tile ──────────────────────────────────────────────────

class _AvailableSlotTile extends StatelessWidget {
  final ParkingSlot slot;

  const _AvailableSlotTile({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Consumer<ParkingProvider>(
      builder: (ctx, provider, _) => GestureDetector(
        onTap: () async {
          if (provider.isUserCurrentlyOccupyingOrReserved) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text(
                    'You already have an active reservation or are occupying a slot.',
                    style: TextStyle(color: Colors.white)),
                backgroundColor: AppColors.bgCard,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          _showOtpReservationFlow(ctx, provider);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.available.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.available.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.available.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Center(
                      child: Text(
                        'P${slot.slotNumber}',
                        style: AppTextStyles.headingMedium
                            .copyWith(color: AppColors.available),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Slot ${slot.slotNumber}',
                            style: AppTextStyles.headingSmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// OTP-based reservation flow:
  /// 1. Show confirm dialog → request OTP
  /// 2. Show OTP entry dialog → verify + reserve
  void _showOtpReservationFlow(BuildContext context, ParkingProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OtpReservationDialog(slot: slot, provider: provider),
    );
  }
}

// ─── OTP Reservation Dialog ───────────────────────────────────────────────

class _OtpReservationDialog extends StatefulWidget {
  final ParkingSlot slot;
  final ParkingProvider provider;

  const _OtpReservationDialog({
    required this.slot,
    required this.provider,
  });

  @override
  State<_OtpReservationDialog> createState() => _OtpReservationDialogState();
}

class _OtpReservationDialogState extends State<_OtpReservationDialog> {
  final _otpController = TextEditingController();
  String? _generatedOtp;
  String? _errorText;
  bool _loading = false;
  bool _otpSent = false;
  CarModel? _selectedCar;

  @override
  void initState() {
    super.initState();
    final user = widget.provider.currentUser;
    if (user != null && user.cars.isNotEmpty) {
      _selectedCar = user.cars.first;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() => _loading = true);
    try {
      final otp = await widget.provider.requestOtp();
      setState(() {
        _generatedOtp = otp;
        _otpSent = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorText = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _verifyAndReserve() async {
    final entered = _otpController.text.trim();
    if (entered.isEmpty) {
      setState(() => _errorText = 'Please enter the OTP.');
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final err = await widget.provider
        .verifyOtpAndReserve(widget.slot, entered, _selectedCar);

    if (!mounted) return;

    if (err != null) {
      setState(() {
        _errorText = err;
        _loading = false;
      });
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Slot ${widget.slot.slotNumber} reserved successfully!'),
          backgroundColor: AppColors.available,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = widget.provider.currentUser?.email ?? '';
    // Mask email: show first 3 chars + *** + @domain
    final maskedEmail = userEmail.length > 5
        ? '${userEmail.substring(0, 3)}***${userEmail.substring(userEmail.indexOf('@'))}'
        : userEmail;

    return AlertDialog(
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
            child: Icon(
              _otpSent ? Icons.lock_rounded : Icons.bookmark_add_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              _otpSent
                  ? 'Enter OTP'
                  : 'Reserve Slot ${widget.slot.slotNumber}?',
              style: AppTextStyles.headingMedium,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: _otpSent ? _buildOtpEntry(maskedEmail) : _buildConfirmation(),
      ),
      actions: [
        TextButton(
          onPressed: _loading
              ? null
              : () {
                  widget.provider.cancelOtp();
                  Navigator.pop(context);
                },
          child: Text('Cancel',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed:
              _loading ? null : (_otpSent ? _verifyAndReserve : _requestOtp),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_otpSent ? 'Verify & Reserve' : 'Send OTP'),
        ),
      ],
    );
  }

  Widget _buildConfirmation() {
    final user = widget.provider.currentUser;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user != null && user.cars.isNotEmpty) ...[
          Text('Select Vehicle', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.glassBase,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CarModel>(
                value: _selectedCar,
                isExpanded: true,
                dropdownColor: AppColors.bgCard,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary),
                items: user.cars.map((car) {
                  return DropdownMenuItem<CarModel>(
                    value: car,
                    child: Text(
                      '${car.color} ${car.model} (${car.plateNumber})',
                      style: AppTextStyles.bodyMedium,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedCar = val);
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          'You will have ${AppStrings.reservationMinutes} minutes to arrive. '
          'An OTP will be sent to verify your identity.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'OTP verification required for security',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpEntry(String maskedEmail) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Icon(Icons.mark_email_read_outlined,
              size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            'Check your Inbox',
            style: AppTextStyles.headingSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'We have sent a 6-digit confirmation code to:',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        Center(
          child: Text(
            maskedEmail,
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // OTP input field
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: AppStrings.otpLength,
          textAlign: TextAlign.center,
          style: AppTextStyles.headingMedium.copyWith(
            letterSpacing: 6,
          ),
          decoration: InputDecoration(
            hintText: '• ' * AppStrings.otpLength,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            hintStyle: AppTextStyles.headingMedium.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 6,
            ),
            counterText: '',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: AppSpacing.xs),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton(
            onPressed: _loading ? null : _requestOtp,
            child: Text(
              _otpSent ? "Didn't receive it? Resend" : "Send Code",
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),

        if (_errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              _errorText!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
