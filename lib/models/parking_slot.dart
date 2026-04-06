enum SlotStatus { available, reserved, occupied }

class ParkingSlot {
  final String id;
  final int slotNumber;
  final SlotStatus status;
  final bool isSensorActive;
  final double? distanceCm;
  final String? userId;
  final String? reservedByName;

  const ParkingSlot({
    required this.id,
    required this.slotNumber,
    this.status = SlotStatus.available,
    this.isSensorActive = false,
    this.distanceCm,
    this.userId,
    this.reservedByName,
  });

  bool get isAvailable => status == SlotStatus.available;
  bool get isReserved => status == SlotStatus.reserved;
  bool get isOccupied => status == SlotStatus.occupied;

  ParkingSlot copyWith({
    String? id,
    int? slotNumber,
    SlotStatus? status,
    bool? isSensorActive,
    double? distanceCm,
    String? userId,
    String? reservedByName,
  }) {
    return ParkingSlot(
      id: id ?? this.id,
      slotNumber: slotNumber ?? this.slotNumber,
      status: status ?? this.status,
      isSensorActive: isSensorActive ?? this.isSensorActive,
      distanceCm: distanceCm ?? this.distanceCm,
      userId: userId ?? this.userId,
      reservedByName: reservedByName ?? this.reservedByName,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'slotNumber': slotNumber,
        'status': status.name,
        'isSensorActive': isSensorActive,
        'distanceCm': distanceCm,
        'userId': userId,
        'reservedByName': reservedByName,
      };

  factory ParkingSlot.fromMap(Map<String, dynamic> map) => ParkingSlot(
        id: map['id'] ?? '',
        slotNumber: map['slotNumber'] ?? 0,
        status: SlotStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => SlotStatus.available,
        ),
        isSensorActive: map['isSensorActive'] ?? false,
        distanceCm: map['distanceCm']?.toDouble(),
        userId: map['userId'],
        reservedByName: map['reservedByName'],
      );
}
