import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/parking_slot.dart';
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
                      Text('Reserve a Slot',
                              style: AppTextStyles.displayMedium)
                          .animate()
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 6),
                      Text(
                        provider.isParkingFull
                            ? 'All slots are currently full'
                            : 'Pick an available slot below',
                        style: AppTextStyles.bodyMedium,
                      ).animate(delay: 80.ms).fadeIn(duration: 400.ms),
                      const SizedBox(height: 24),

                      // Active reservation card
                      if (provider.reservationParseError != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: AppDecorations.glassCard(borderColor: AppColors.error),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.error),
                                  const SizedBox(width: 8),
                                  Text('Metadata Error', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(provider.reservationParseError!, style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms),

                      if (provider.hasActiveReservation)
                        _ActiveReservationCard(provider: provider)
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: -0.1),

                      if (provider.hasActiveReservation)
                        const SizedBox(height: 24),

                      // Parking full banner
                      if (!provider.hasActiveReservation && provider.isParkingFull)
                        _ParkingFullBanner()
                            .animate(delay: 150.ms)
                            .fadeIn(duration: 400.ms),

                      if (!provider.hasActiveReservation && !provider.isParkingFull)
                        Text('Available Slots',
                                style: AppTextStyles.headingMedium)
                            .animate(delay: 150.ms)
                            .fadeIn(duration: 400.ms),
                      if (!provider.hasActiveReservation && !provider.isParkingFull)
                        const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              // Available slots list (only when no active reservation and not full)
              if (!provider.hasActiveReservation && !provider.isParkingFull)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final available = provider.slots
                            .where((s) => s.isAvailable)
                            .toList();
                        if (available.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.no_meeting_room_rounded,
                                      size: 52,
                                      color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text('No slots available',
                                      style: AppTextStyles.headingSmall),
                                  Text('All slots are occupied or reserved.',
                                      style: AppTextStyles.bodyMedium),
                                ],
                              ),
                            ),
                          );
                        }
                        final slot = available[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AvailableSlotTile(slot: slot)
                              .animate(
                                  delay: Duration(
                                      milliseconds: 100 + i * 60))
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: 0.1, end: 0),
                        );
                      },
                      childCount: provider.slots
                              .where((s) => s.isAvailable)
                              .isEmpty
                          ? 1
                          : provider.slots
                              .where((s) => s.isAvailable)
                              .length,
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
                        Text('All Slots',
                            style: AppTextStyles.headingMedium),
                        const SizedBox(height: 14),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.occupied.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.block_rounded, size: 48, color: AppColors.occupied),
          const SizedBox(height: 12),
          Text('Parking Full', style: AppTextStyles.headingMedium.copyWith(color: AppColors.occupied)),
          const SizedBox(height: 4),
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
    final progress = remaining.inSeconds /
        (AppStrings.reservationMinutes * 60);

    final urgentColor = remaining.inMinutes < 5
        ? AppColors.occupied
        : remaining.inMinutes < 10
            ? AppColors.reserved
            : AppColors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
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
            borderRadius: BorderRadius.circular(24),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.bookmark_rounded,
                        color: urgentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: urgentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDuration(remaining),
                      style: AppTextStyles.displayMedium
                          .copyWith(color: urgentColor, fontSize: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: AppColors.glassBase,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(urgentColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text('${remaining.inMinutes} min remaining',
                  style: AppTextStyles.bodySmall),


              const SizedBox(height: 18),
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
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading
                          ? null
                          : provider.confirmArrival,
<<<<<<< HEAD
                      icon: const Icon(Icons.location_on_rounded,
                          size: 16),
                      label: const Text("I Have Arrived"),
=======
                      icon: const Icon(Icons.sensor_door_rounded,
                          size: 16),
                      label: const Text("Open Barrier"),
>>>>>>> 9ede775032aa32cf38300adae5899ef150f0ecce
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.available,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
          if (provider.hasActiveReservation) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: const Text('You already have an active reservation.'),
                backgroundColor: AppColors.bgCard,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          _showOtpReservationFlow(ctx, provider);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.available.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: AppColors.available.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.available.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'P${slot.slotNumber}',
                        style: AppTextStyles.headingMedium
                            .copyWith(color: AppColors.available),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Slot ${slot.slotNumber}',
                            style: AppTextStyles.headingSmall),
                        Text('Available — Tap to reserve',
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.available)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
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

    final err = await widget.provider.verifyOtpAndReserve(widget.slot, entered);

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
          content: Text('Slot ${widget.slot.slotNumber} reserved successfully!'),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _otpSent ? Icons.lock_rounded : Icons.bookmark_add_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
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
      content: _otpSent ? _buildOtpEntry(maskedEmail) : _buildConfirmation(),
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
          onPressed: _loading
              ? null
              : (_otpSent ? _verifyAndReserve : _requestOtp),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You will have ${AppStrings.reservationMinutes} minutes to arrive. '
          'An OTP will be sent to verify your identity.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
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
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Check your Inbox',
            style: AppTextStyles.headingSmall,
          ),
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 24),

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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 16),
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
          const SizedBox(height: 8),
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
