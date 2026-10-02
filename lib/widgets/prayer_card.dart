import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/prayer_record.dart';
import '../utils/theme.dart';

class PrayerCard extends StatelessWidget {
  final PrayerRecord record;
  final String timeFormat;
  final ValueChanged<bool> onToggle;

  const PrayerCard({
    super.key,
    required this.record,
    required this.timeFormat,
    required this.onToggle,
  });

  Color _getStatusColor() {
    switch (record.status) {
      case 'completed':
        return AppTheme.completedColor;
      case 'missed':
        return AppTheme.missedColor;
      case 'pending':
      default:
        return AppTheme.pendingColor;
    }
  }

  IconData _getStatusIcon() {
    switch (record.status) {
      case 'completed':
        return Icons.check_circle;
      case 'missed':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat(timeFormat == '24h' ? 'HH:mm' : 'h:mm a').format(record.prayerTime);
    final isCompleted = record.status == 'completed';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted 
              ? AppTheme.completedColor.withValues(alpha: 0.2) 
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            onToggle(!isCompleted);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Checkbox / State indicator
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 28,
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onToggle(!isCompleted);
                  },
                ),
                const SizedBox(width: 16),
                // Prayer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.prayerName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
