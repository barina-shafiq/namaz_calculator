import 'package:flutter/material.dart';
import '../models/prayer_record.dart';
import '../utils/theme.dart';

class ProgressCard extends StatelessWidget {
  final List<PrayerRecord> records;

  const ProgressCard({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = records.where((r) => r.status == 'completed').length;
    final totalCount = records.length;
    final double percentage = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress Indicator with status text in center
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: percentage,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  color: AppTheme.primaryColor,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                "${(percentage * 100).toInt()}%",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Progress details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Completion",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$completedCount of $totalCount prayers completed",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 8),
                // Simple motivational sub-text
                Text(
                  percentage == 1.0
                      ? "Excellent! All prayers completed."
                      : percentage > 0.5
                          ? "Good progress, keep it up!"
                          : "Start your daily progress.",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: percentage == 1.0 ? AppTheme.completedColor : Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
