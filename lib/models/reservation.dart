enum ReservationStatus { active, completed, cancelled, expired }

class Reservation {
  final String id;
  final String slotId;
  final int slotNumber;
  final String userId;
  final String userName;
  final DateTime startTime;
  final DateTime expiresAt;
  final ReservationStatus status;
  final DateTime? arrivalTime;
  final String? cancelReason;
  final String? otp;

  const Reservation({
    required this.id,
    required this.slotId,
    required this.slotNumber,
    required this.userId,
    required this.userName,
    required this.startTime,
    required this.expiresAt,
    this.status = ReservationStatus.active,
    this.arrivalTime,
    this.cancelReason,
    this.otp,
  });

  bool get isActive => status == ReservationStatus.active;

  Duration get remaining {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  int get remainingSeconds => remaining.inSeconds;

  Reservation copyWith({
    String? id,
    String? slotId,
    int? slotNumber,
    String? userId,
    String? userName,
    DateTime? startTime,
    DateTime? expiresAt,
    ReservationStatus? status,
    DateTime? arrivalTime,
    String? cancelReason,
    String? otp,
  }) {
    return Reservation(
      id: id ?? this.id,
      slotId: slotId ?? this.slotId,
      slotNumber: slotNumber ?? this.slotNumber,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      startTime: startTime ?? this.startTime,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      cancelReason: cancelReason ?? this.cancelReason,
      otp: otp ?? this.otp,
    );
  }
}
