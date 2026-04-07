import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/parking_slot.dart';
import '../models/parking_log.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class ParkingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── Collection references ────────────────────────────────────────────────
  // NOTE: firmware uses these same collection/doc names
  CollectionReference get _slotsRef       => _db.collection('slots');
  CollectionReference get _logsRef        => _db.collection('parkingLogs');
  CollectionReference get _reservationsRef => _db.collection('reservations');
  DocumentReference   get _barrierRef     => _db.collection('barrier').doc('gate');

  // ─── Streams ──────────────────────────────────────────────────────────────

  Stream<List<ParkingSlot>> getSlotsStream() {
    return _slotsRef.orderBy('slotNumber').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => ParkingSlot.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
          .toList(),
    );
  }

  Stream<List<ParkingLog>> getLogsStream() {
    return _logsRef
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ParkingLog.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id}))
              .toList(),
        );
  }

  // Barrier stream — app UI listens to this to show barrier state
  Stream<bool> getBarrierStream() {
    return _barrierRef.snapshots().map((doc) {
      if (!doc.exists) return false;
      return (doc.data() as Map<String, dynamic>?)?['isOpen'] ?? false;
    });
  }

  // Active reservation stream for a specific user
  Stream<DocumentSnapshot?> getActiveReservationStream(String userId) {
    return _reservationsRef
        .doc('${userId}_active')
        .snapshots()
        .map((doc) => doc.exists ? doc : null);
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  /// Reserve a slot — uses a transaction to atomically prevent double bookings
  Future<void> reserve({
    required ParkingSlot slot,
    required UserModel user,
    required String otp,
  }) async {
    await _db.runTransaction((txn) async {
      // 1. Check user doesn't already have an active reservation
      final existingRes = await txn.get(_reservationsRef.doc('${user.uid}_active'));
      if (existingRes.exists) {
        throw Exception('You already have an active reservation.');
      }

      // 2. Check slot is still available
      final slotDoc = await txn.get(_slotsRef.doc(slot.id));
      final slotData = slotDoc.data() as Map<String, dynamic>?;
      if (slotData?['status'] != 'available') {
        throw Exception('Slot ${slot.slotNumber} is no longer available.');
      }

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: AppStrings.reservationMinutes));

      // 3. Update slot status → "reserved"
      // ESP32 reads this and sets slotStatus[i] = 2 → LED yellow
      txn.update(_slotsRef.doc(slot.id), {
        'status': SlotStatus.reserved.name,
        'userId': user.uid,
        'reservedByName': user.name,
      });

      // 4. Create active reservation doc (with OTP for QR/verification)
      txn.set(_reservationsRef.doc('${user.uid}_active'), {
        'slotId': slot.id,
        'slotNumber': slot.slotNumber,
        'userId': user.uid,
        'userName': user.name,
        'startTime': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt.toIso8601String(),
        'status': 'active',
        'otp': otp,
      });

      // 5. Log it
      txn.set(_logsRef.doc(_uuid.v4()), {
        'action': 'Slot ${slot.slotNumber} reserved by ${user.name}',
        'slotId': slot.id,
        'slotNumber': slot.slotNumber,
        'userId': user.uid,
        'userName': user.name,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'reservation',
      });
    });
  }

  Future<void> cancel({
    required String slotId,
    required int slotNumber,
    required UserModel user,
  }) async {
    final batch = _db.batch();

    // 1. Reset slot → "available"
    // ESP32 reads this and sets slotStatus[i] = 0 → LED green
    batch.update(_slotsRef.doc(slotId), {
      'status': SlotStatus.available.name,
      'userId': null,
      'reservedByName': null,
    });

    // 2. Delete active reservation
    batch.delete(_reservationsRef.doc('${user.uid}_active'));

    // 3. Log it
    batch.set(_logsRef.doc(_uuid.v4()), {
      'action': 'Slot $slotNumber reservation cancelled by ${user.name}',
      'slotId': slotId,
      'slotNumber': slotNumber,
      'userId': user.uid,
      'userName': user.name,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'cancellation',
    });

    await batch.commit();
  }

  /// Confirm arrival — opens entrance barrier, keeps slot as "reserved"
  /// so ESP32 can detect via hasReservedSlot() and open the gate.
  /// The ESP32 sensor will transition the slot to "occupied" when car parks.
  Future<void> confirmArrival({
    required String slotId,
    required int slotNumber,
    required UserModel user,
  }) async {
    // 1. Open the entrance barrier FIRST
    // ESP32 polls barrier/gate → sees isOpen: true → sets reservationTrigger
    // ESP32 handleGate checks reservationTrigger → opens entrance servo
    await openBarrier(user);

    // 2. Mark reservation as "arrived" (don't delete yet — ESP32 needs it)
    await _reservationsRef.doc('${user.uid}_active').update({
      'status': 'arrived',
    });

    // 3. Log it
    await _logsRef.doc(_uuid.v4()).set({
      'action': 'Slot $slotNumber: ${user.name} arrived — barrier opening',
      'slotId': slotId,
      'slotNumber': slotNumber,
      'userId': user.uid,
      'userName': user.name,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'arrival',
    });
  }

  /// Clean up reservation after sensor confirms car is parked
  /// Called by provider when slot changes from reserved → occupied
  Future<void> completeArrival({
    required String userId,
  }) async {
    await _reservationsRef.doc('${userId}_active').delete();
  }

  /// Auto-expire a reservation that has passed its expiry time
  Future<void> expireReservation({
    required String slotId,
    required int slotNumber,
    required UserModel user,
  }) async {
    final batch = _db.batch();

    batch.update(_slotsRef.doc(slotId), {
      'status': SlotStatus.available.name,
      'userId': null,
      'reservedByName': null,
    });

    batch.delete(_reservationsRef.doc('${user.uid}_active'));

    batch.set(_logsRef.doc(_uuid.v4()), {
      'action': 'Slot $slotNumber reservation expired for ${user.name}',
      'slotId': slotId,
      'slotNumber': slotNumber,
      'userId': user.uid,
      'userName': user.name,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'cancellation',
    });

    await batch.commit();
  }

  /// Explicitly reset a slot back to a completely fresh available state
  Future<void> resetSlot(String slotId) async {
    final batch = _db.batch();

    batch.update(_slotsRef.doc(slotId), {
      'status': SlotStatus.available.name,
      'userId': null,
      'reservedByName': null,
    });

    // Note: Since this is a passive cleanup (e.g. car left), we don't always 
    // have the userId/Name easily without fetching. We'll log it as a general reset.
    batch.set(_logsRef.doc(_uuid.v4()), {
      'action': 'Slot reset to available (passive cleanup)',
      'slotId': slotId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'system',
    });

    await batch.commit();
  }

  // ─── Barrier ──────────────────────────────────────────────────────────────

  /// Open the entrance barrier.
  /// ESP32 polls barrier/gate every ~1.5s (nominal). The ESP32 resets isOpen
  /// to false after reading it, so we do NOT auto-close from the app side.
  /// The increased timeout (30s) is a safety fallback only.
  Future<void> openBarrier(UserModel user) async {
    await _barrierRef.set({'isOpen': true}, SetOptions(merge: true));
    await logBarrier(user, true);

    // Safety fallback — ESP32 normally resets this much sooner
    Future.delayed(
      const Duration(seconds: AppStrings.barrierAutoCloseSeconds),
      () async {
        await _barrierRef.set({'isOpen': false}, SetOptions(merge: true));
      },
    );
  }

  Future<void> logBarrier(UserModel user, bool opened) async {
    await _logsRef.add({
      'action': 'Barrier ${opened ? "opened" : "closed"} by ${user.name}',
      'slotId': '',
      'slotNumber': 0,
      'userId': user.uid,
      'userName': user.name,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'barrier',
    });
  }

  // ─── Seed (run once) ──────────────────────────────────────────────────────

  Future<void> seedInitialData() async {
    for (int i = 1; i <= 6; i++) {
      await _slotsRef.doc('slot-$i').set({
        'slotNumber': i,
        'status': 'available',
        'isSensorActive': false,
        'distanceCm': null,
        'userId': null,
        'reservedByName': null,
      });
    }

    await _barrierRef.set({'isOpen': false}, SetOptions(merge: true));
  }
}