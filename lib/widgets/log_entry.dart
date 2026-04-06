import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../models/parking_log.dart';

class LogEntry extends StatelessWidget {
  final ParkingLog log;

  const LogEntry({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(log.timestamp);
    final dateStr = DateFormat('MMM d').format(log.timestamp);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppDecorations.glassCard(
          opacity: 0.07, borderRadius: 14),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: log.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(log.icon, color: log.color, size: 18),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.action,
                    style: AppTextStyles.bodyLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(log.userName, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Timestamp
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timeStr,
                  style: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w600)),
              Text(dateStr, style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
