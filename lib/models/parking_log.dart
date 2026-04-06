import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingLog {
  final String id;
  final String action;
  final String slotId;
  final int slotNumber;
  final String userId;
  final String userName;
  final DateTime timestamp;
  final LogType type;

  const ParkingLog({
    required this.id,
    required this.action,
    required this.slotId,
    required this.slotNumber,
    required this.userId,
    required this.userName,
    required this.timestamp,
    this.type = LogType.info,
  });

  IconData get icon {
    switch (type) {
      case LogType.reservation:
        return Icons.bookmark_added_rounded;
      case LogType.cancellation:
        return Icons.cancel_rounded;
      case LogType.arrival:
        return Icons.directions_car_rounded;
      case LogType.departure:
        return Icons.logout_rounded;
      case LogType.barrier:
        return Icons.sensor_door_rounded;
      case LogType.info:
        return Icons.info_rounded;
    }
  }

  Color get color {
    switch (type) {
      case LogType.reservation:
        return const Color(0xFF0FB9B1);
      case LogType.cancellation:
        return const Color(0xFFE74C3C);
      case LogType.arrival:
        return const Color(0xFF2ECC71);
      case LogType.departure:
        return const Color(0xFFF1C40F);
      case LogType.barrier:
        return const Color(0xFF9B59B6);
      case LogType.info:
        return const Color(0xFF8BA5BE);
    }
  }
  Map<String, dynamic> toMap() => {
        'id': id,
        'action': action,
        'slotId': slotId,
        'slotNumber': slotNumber,
        'userId': userId,
        'userName': userName,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
      };

  factory ParkingLog.fromMap(Map<String, dynamic> map) => ParkingLog(
        id: map['id'] ?? '',
        action: map['action'] ?? '',
        slotId: map['slotId'] ?? '',
        slotNumber: map['slotNumber'] ?? 0,
        userId: map['userId'] ?? '',
        userName: map['userName'] ?? '',
        timestamp: (map['timestamp'] is Timestamp)
            ? (map['timestamp'] as Timestamp).toDate()
            : DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
        type: LogType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => LogType.info,
        ),
      );
}

enum LogType { reservation, cancellation, arrival, departure, barrier, info }
