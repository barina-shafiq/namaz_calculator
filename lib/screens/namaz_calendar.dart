import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/prayer_record.dart';
import '../providers/prayer_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/theme.dart';
import '../widgets/prayer_card.dart';

class NamazCalendarScreen extends ConsumerStatefulWidget {
  const NamazCalendarScreen({super.key});

  @override
  ConsumerState<NamazCalendarScreen> createState() => _NamazCalendarScreenState();
}

class _NamazCalendarScreenState extends ConsumerState<NamazCalendarScreen> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageServiceProvider);

    // Fetch and group all records for performance
    final allRecords = storage.getAllPrayerRecords();
    final Map<String, List<PrayerRecord>> groupedRecords = {};
    for (var r in allRecords) {
      final key = _formatDateKey(r.date);
      groupedRecords.putIfAbsent(key, () => []).add(r);
    }

    final year = _focusedMonth.year;
    final month = _focusedMonth.month;

    // Calendar Math
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final totalDays = lastDayOfMonth.day;
    
    // Weekday of 1st day (1 = Monday, 7 = Sunday)
    // Adjust so Monday is 0, Sunday is 6
    final startOffset = firstDayOfMonth.weekday - 1;

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        // Month Navigation Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),

        // Weekday Headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              return SizedBox(
                width: 40,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: startOffset + totalDays,
            itemBuilder: (context, index) {
              if (index < startOffset) {
                return const SizedBox.shrink(); // Empty cells before the 1st
              }

              final dayNum = index - startOffset + 1;
              final cellDate = DateTime(year, month, dayNum);
              final cellDateKey = _formatDateKey(cellDate);

              final dayRecords = groupedRecords[cellDateKey] ?? [];
              final completedCount = dayRecords.where((r) => r.status == 'completed').length;

              final isToday = cellDateKey == _formatDateKey(now);
              final isFuture = cellDate.isAfter(todayMidnight);
              final isPast = cellDate.isBefore(todayMidnight);

              // Determine indicator: ✓, ◐, ✗, ○
              String symbol = '○';
              Color indicatorColor = AppTheme.futureColor;

              if (completedCount == 5) {
                symbol = '✓';
                indicatorColor = AppTheme.completedColor;
              } else if (completedCount > 0) {
                symbol = '◐';
                indicatorColor = AppTheme.pendingColor;
              } else if (isPast) {
                symbol = '✗';
                indicatorColor = AppTheme.missedColor;
              } else {
                symbol = '○';
                indicatorColor = isToday ? AppTheme.primaryColor : AppTheme.futureColor;
              }

              return InkWell(
                onTap: isFuture ? null : () => _showDayDetailSheet(context, cellDate),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isToday 
                        ? AppTheme.primaryColor.withValues(alpha: 0.1) 
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday ? AppTheme.primaryColor : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNum.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isFuture ? Theme.of(context).disabledColor : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        symbol,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: indicatorColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Show detailed bottom sheet for the selected day
  void _showDayDetailSheet(BuildContext context, DateTime date) {
    // Select this date in the provider
    ref.read(prayerProvider.notifier).selectDate(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final prayerState = ref.watch(prayerProvider);
            final settings = ref.watch(settingsProvider);
            final records = prayerState.selectedDateRecords;

            final completedCount = records.where((r) => r.status == 'completed').length;
            final percentage = (completedCount / 5.0) * 100;

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, d MMMM').format(date),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$completedCount of 5 prayers completed (${percentage.toInt()}%)",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return PrayerCard(
                            record: record,
                            timeFormat: settings.timeFormat,
                            onToggle: (completed) {
                              ref.read(prayerProvider.notifier).togglePrayerStatus(record.id, completed);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      // Return focused date back to today or reset
      ref.read(prayerProvider.notifier).selectDate(DateTime.now());
    });
  }
}
