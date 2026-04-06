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
      if (doc.exists) {
        final data = doc.data()!;
        _activeReservation = Reservation(
          id: doc.id,
          slotId: data['slotId'],
          slotNumber: data['slotNumber'],
          userId: data['userId'],
          userName: data['userName'],
          startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          expiresAt: DateTime.parse(data['expiresAt']),
          status: ReservationStatus.active,
          otp: data['otp'],
        );
        _startExpiryTimer();
      } else {
        _activeReservation = null;
        _expiryTimer?.cancel();
      }
      notifyListeners();
    });
  }

  /// Periodically check if the active reservation has expired
  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
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
        _expiryTimer?.cancel();
      }
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
      return null; // success
    } catch (e) {
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
