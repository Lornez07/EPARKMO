import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_slot.dart';
import '../models/reservation.dart';
import '../models/parking_log.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/parking_service.dart';
import '../services/otp_service.dart';
import '../constants/app_constants.dart';

class ParkingProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final ParkingService _service = ParkingService();
  final OtpService _otpService = OtpService();

  // ─── State ────────────────────────────────────────────────────────────────
  UserModel? _currentUser;
  List<ParkingSlot> _slots = [];
  List<ParkingLog> _logs = [];
  Reservation? _activeReservation;
  bool _barrierOpen = false;
  bool _isLoading = false;
  String? _error;
  String? _pendingOtp; // OTP waiting to be verified

  StreamSubscription? _slotsSub;
  StreamSubscription? _logsSub;
  StreamSubscription? _resSub;
  Timer? _barrierTimer;
  Timer? _expiryTimer;

  // ─── Getters ──────────────────────────────────────────────────────────────
  UserModel? get currentUser => _currentUser;
  List<ParkingSlot> get slots => _slots;
  List<ParkingLog> get logs => _logs;
  Reservation? get activeReservation => _activeReservation;
  bool get barrierOpen => _barrierOpen;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get pendingOtp => _pendingOtp;
  String? reservationParseError;

  int get availableCount => _slots.where((s) => s.isAvailable).length;
  int get reservedCount => _slots.where((s) => s.isReserved).length;
  int get occupiedCount => _slots.where((s) => s.isOccupied).length;

  /// Reserved + Occupied = effectively unavailable
  int get effectiveOccupiedCount => reservedCount + occupiedCount;
  bool get isParkingFull => effectiveOccupiedCount >= AppStrings.totalSlots;

  bool get hasActiveReservation => _activeReservation != null;

  /// Control Visibility: Show only for Admins OR Users with an active reservation
  bool get canShowBarrier => (_currentUser?.isAdmin ?? false) || hasActiveReservation;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _auth.signIn(email, password);
      _currentUser = user;
      _initFirebaseListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    try {
      final user = await _auth.register(email: email, password: password, name: name);
      _currentUser = user;
      _initFirebaseListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _disposeListeners();
    await _auth.signOut();
    _currentUser = null;
    _slots = [];
    _logs = [];
    _activeReservation = null;
    _pendingOtp = null;
    notifyListeners();
  }

  // ─── Firebase Listeners ───────────────────────────────────────────────────
  void _initFirebaseListeners() {
    _disposeListeners();
    if (_currentUser == null) return;

    // Slots — also watches for reserved→occupied transitions (arrival completion)
    _slotsSub = _service.getSlotsStream().listen((data) {
      final oldSlots = _slots;
      _slots = data;

      // Auto-complete arrival: if user's reserved slot became occupied via sensor
      if (_activeReservation != null) {
        final resSlotId = _activeReservation!.slotId;
        final newSlot = data.where((s) => s.id == resSlotId).firstOrNull;
        final oldSlot = oldSlots.where((s) => s.id == resSlotId).firstOrNull;

        if (newSlot != null &&
            oldSlot != null &&
            oldSlot.isReserved &&
            newSlot.isOccupied) {
          // Sensor confirmed car parked → clean up reservation
          _service.completeArrival(userId: _currentUser!.uid);
        }
      }

      // ─── Passive Expiration/Metadata Cleanup ───────────────────────────
      // If we see a slot that is "available" in Firestore but still has 
      // a userId, it means it wasn't cleaned up properly (e.g., car left).
      for (final slot in data) {
        if (slot.status == SlotStatus.available && slot.userId != null) {
          _service.resetSlot(slot.id);
        }
      }

      notifyListeners();
    });

    // Logs
    _logsSub = _service.getLogsStream().listen((data) {
      _logs = data;
      notifyListeners();
    });

    // Active Reservation for this user
    _resSub = FirebaseFirestore.instance
        .collection('reservations')
        .doc('${_currentUser!.uid}_active')
        .snapshots()
        .listen((doc) {
      debugPrint('🔔 RES LISTENER — exists: ${doc.exists}, data: ${doc.data()}');
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        try {
          final parsed = _parseReservation(doc.id, data);
          if (parsed != null) {
            _activeReservation = parsed;
            reservationParseError = null;
            debugPrint('✅ Parsed OK — remaining: ${_activeReservation!.remaining}');
          }
        } catch (e) {
          debugPrint('❌ PARSE ERROR: $e');
          reservationParseError = e.toString();
          _activeReservation = null;
        }

        // ─── Lazy Cleanup ──────────────────────────────────────────────────
        if (_activeReservation != null && _activeReservation!.remaining == Duration.zero) {
          debugPrint('⏰ Expired immediately — cleaning up');
           _service.expireReservation(
            slotId: _activeReservation!.slotId,
            slotNumber: _activeReservation!.slotNumber,
            user: _currentUser!,
          ).catchError((e) {
            reservationParseError = 'Cleanup Error: $e';
            notifyListeners();
          });
          _activeReservation = null;
        } else if (_activeReservation != null) {
          debugPrint('✅ ACTIVE — card should show now');
          _startExpiryTimer();
        }
      } else {
        debugPrint('📭 No reservation doc — clearing');
        _activeReservation = null;
        reservationParseError = null;
        _expiryTimer?.cancel();
      }
      debugPrint('🔁 hasActiveReservation = $hasActiveReservation');
      notifyListeners();
    }, onError: (e) {
      debugPrint('🔥 RES STREAM ERROR: $e');
      reservationParseError = 'Stream error: $e';
      notifyListeners();
    });
  }

  /// Parse a Firestore reservation document into a Reservation model.
  /// Returns null if data is invalid (caller should handle).
  Reservation? _parseReservation(String docId, Map<String, dynamic> data) {
    DateTime parseDate(dynamic value, {required DateTime fallback}) {
      if (value == null) return fallback;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? fallback;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return fallback;
    }

    return Reservation(
      id: docId,
      slotId: data['slotId'] ?? '',
      slotNumber: data['slotNumber'] ?? 0,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'User',
      startTime: parseDate(data['startTime'], fallback: DateTime.now()),
      expiresAt: parseDate(data['expiresAt'], fallback: DateTime.now().add(const Duration(minutes: 15))),
      status: ReservationStatus.active,
      otp: data['otp']?.toString(),
    );
  }

  /// Tick every second to update countdown display and check expiry
  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeReservation == null || _currentUser == null) {
        _expiryTimer?.cancel();
        return;
      }
      if (_activeReservation!.remaining == Duration.zero) {
        _service.expireReservation(
          slotId: _activeReservation!.slotId,
          slotNumber: _activeReservation!.slotNumber,
          user: _currentUser!,
        );
        _activeReservation = null;
        _expiryTimer?.cancel();
      }
      notifyListeners(); // Always rebuild so countdown ticks
    });
  }

  Future<void> _disposeListeners() async {
    await _slotsSub?.cancel();
    await _logsSub?.cancel();
    await _resSub?.cancel();
    _barrierTimer?.cancel();
    _expiryTimer?.cancel();
  }

  // ─── OTP Flow ─────────────────────────────────────────────────────────────

  /// Step 1: Request an OTP before reservation
  Future<String> requestOtp() async {
    if (_currentUser == null) throw Exception('Not logged in.');
    final email = _currentUser!.email;
    if (email == null || email.isEmpty) {
      throw Exception('User email not found. Please update your profile.');
    }
    
    final otp = await _otpService.createAndStoreOtp(_currentUser!.uid, email);
    _pendingOtp = otp;
    notifyListeners();
    return otp;
  }

  /// Step 2: Verify OTP and create reservation if valid
  Future<String?> verifyOtpAndReserve(ParkingSlot slot, String enteredOtp) async {
    if (_currentUser == null) return 'Not logged in.';
    if (hasActiveReservation) return 'You already have an active reservation.';

    _setLoading(true);
    try {
      // Verify OTP
      final valid = await _otpService.verifyOtp(_currentUser!.uid, enteredOtp);
      if (!valid) {
        return 'Invalid or expired OTP. Please try again.';
      }

      // OTP verified → create reservation
      await _service.reserve(slot: slot, user: _currentUser!, otp: enteredOtp);
      _pendingOtp = null;

      // ─── DIRECT UI UPDATE ─────────────────────────────────────────────
      // Don't rely solely on the Firestore listener — set reservation now
      // so the Active Reservation Card appears immediately.
      final now = DateTime.now();
      _activeReservation = Reservation(
        id: '${_currentUser!.uid}_active',
        slotId: slot.id,
        slotNumber: slot.slotNumber,
        userId: _currentUser!.uid,
        userName: _currentUser!.name,
        startTime: now,
        expiresAt: now.add(const Duration(minutes: AppStrings.reservationMinutes)),
        status: ReservationStatus.active,
        otp: enteredOtp,
      );
      _startExpiryTimer();
      debugPrint('✅ DIRECT SET — activeReservation for slot ${slot.slotNumber}');
      // ─────────────────────────────────────────────────────────────────

      return null; // success
    } catch (e, stack) {
      debugPrint('RESERVE_ERROR: $e\n$stack');
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel pending OTP (user dismissed dialog)
  void cancelOtp() {
    if (_currentUser != null) {
      _otpService.clearPendingOtp(_currentUser!.uid);
    }
    _pendingOtp = null;
    notifyListeners();
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> cancelReservation() async {
    if (_activeReservation == null || _currentUser == null) return;
    _setLoading(true);
    try {
      await _service.cancel(
        slotId: _activeReservation!.slotId,
        slotNumber: _activeReservation!.slotNumber,
        user: _currentUser!,
      );
      _activeReservation = null;
      _expiryTimer?.cancel();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> confirmArrival() async {
    if (_activeReservation == null || _currentUser == null) return;
    _setLoading(true);
    try {
      await _service.confirmArrival(
        slotId: _activeReservation!.slotId,
        slotNumber: _activeReservation!.slotNumber,
        user: _currentUser!,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void openBarrier() async {
    if (_currentUser == null) return;
    _barrierOpen = true;
    notifyListeners();

    await _service.openBarrier(_currentUser!);

    _barrierTimer?.cancel();
    _barrierTimer = Timer(const Duration(seconds: AppStrings.barrierAutoCloseSeconds), () {
      _barrierOpen = false;
      notifyListeners();
    });
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposeListeners();
    super.dispose();
  }
}
