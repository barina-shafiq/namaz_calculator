import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/stats_provider.dart';
import '../providers/prayer_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/theme.dart';
import '../widgets/prayer_card.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);

    return Column(
      children: [
        // Tab Header
        TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Theme.of(context).hintColor,
          tabs: const [
            Tab(text: "Overview & Stats"),
            Tab(text: "Full History"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(stats),
              _buildHistoryTab(stats),
            ],
          ),
        ),
      ],
    );
  }

  // --- OVERVIEW TAB ---
  Widget _buildOverviewTab(StatsState stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streaks Card
          _buildStreaksCard(stats),
          const SizedBox(height: 16),
          
          // Completion Rates Grid
          const Text(
            "Completion Rates",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildRatesGrid(stats),
          const SizedBox(height: 20),

          // Weekly Overview Row
          const Text(
            "Weekly Overview",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildWeeklyRow(stats),
          const SizedBox(height: 20),

          // Monthly Breakdown
          const Text(
            "Monthly Breakdown",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildMonthlyBreakdownCard(stats),
          const SizedBox(height: 20),

          // Per Prayer Rates
          const Text(
            "Prayer-Specific Rates",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildPerPrayerRatesCard(stats),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStreaksCard(StatsState stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F9F59), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStreakItem("Current Streak", stats.currentStreak, Icons.local_fire_department),
          Container(width: 1, height: 50, color: Colors.white24),
          _buildStreakItem("Best Streak", stats.bestStreak, Icons.emoji_events),
        ],
      ),
    );
  }

  Widget _buildStreakItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.accentColor, size: 24),
            const SizedBox(width: 6),
            Text(
              "$value ${value == 1 ? 'Day' : 'Days'}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value > 0 ? "Keep going!" : "Start today!",
          style: const TextStyle(
            color: AppTheme.accentColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRatesGrid(StatsState stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildRateCard("Today", stats.todayRate, AppTheme.completedColor),
        _buildRateCard("This Week", stats.weekRate, AppTheme.pendingColor),
        _buildRateCard("This Month", stats.monthRate, AppTheme.primaryColor),
        _buildRateCard("All-Time", stats.allTimeRate, AppTheme.accentColor),
      ],
    );
  }

  Widget _buildRateCard(String title, double rate, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${(rate * 100).toInt()}%",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  value: rate,
                  backgroundColor: color.withValues(alpha: 0.1),
                  color: color,
                  strokeWidth: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyRow(StatsState stats) {
    final weekdaysStr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(stats.currentWeekDays.length, (index) {
          final day = stats.currentWeekDays[index];
          final weekdayLabel = weekdaysStr[index];

          Color symbolColor;
          IconData icon;
          
          if (day.status == 'full') {
            symbolColor = AppTheme.completedColor;
            icon = Icons.check_circle;
          } else if (day.status == 'partial') {
            symbolColor = AppTheme.pendingColor;
            icon = Icons.pause_circle_filled;
          } else if (day.status == 'missed') {
            symbolColor = AppTheme.missedColor;
            icon = Icons.cancel;
          } else {
            symbolColor = AppTheme.futureColor.withValues(alpha: 0.4);
            icon = Icons.radio_button_unchecked;
          }

          return Column(
            children: [
              Text(
                weekdayLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                icon,
                color: symbolColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                "${day.completedCount}/5",
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMonthlyBreakdownCard(StatsState stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBreakdownItem("Fully Done", stats.monthlyFullyCompletedCount, AppTheme.completedColor, '✓'),
          _buildBreakdownItem("Partially Done", stats.monthlyPartiallyCompletedCount, AppTheme.pendingColor, '◐'),
          _buildBreakdownItem("Missed Days", stats.monthlyMissedCount, AppTheme.missedColor, '✗'),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int count, Color color, String symbol) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            symbol,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "$count ${count == 1 ? 'Day' : 'Days'}",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPerPrayerRatesCard(StatsState stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: stats.perPrayerRates.entries.map((entry) {
          final name = entry.key;
          final rate = entry.value;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: rate,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      color: AppTheme.primaryColor,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 36,
                  child: Text(
                    "${(rate * 100).toInt()}%",
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- HISTORY TAB ---
  Widget _buildHistoryTab(StatsState stats) {
    final storage = ref.watch(storageServiceProvider);

    if (stats.loggedDates.isEmpty) {
      return const Center(
        child: Text("No records logged yet. Check off prayers to begin!"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: stats.loggedDates.length,
      itemBuilder: (context, index) {
        final date = stats.loggedDates[index];
        
        final dayRecords = storage.getPrayerRecordsForDate(date);
        final completedCount = dayRecords.where((r) => r.status == 'completed').length;
        final percentage = (completedCount / 5.0) * 100;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            title: Text(
              DateFormat('EEEE, d MMMM yyyy').format(date),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                // Icons representation for the 5 prayers
                Row(
                  children: dayRecords.map((r) {
                    Color iconColor;
                    if (r.status == 'completed') {
                      iconColor = AppTheme.completedColor;
                    } else if (r.status == 'missed') {
                      iconColor = AppTheme.missedColor;
                    } else {
                      iconColor = AppTheme.pendingColor;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Row(
                        children: [
                          Icon(
                            r.status == 'completed' ? Icons.check_circle : Icons.circle,
                            size: 14,
                            color: iconColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            r.prayerName.substring(0, 1),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${percentage.toInt()}%",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: completedCount == 5 
                        ? AppTheme.completedColor 
                        : completedCount > 0 
                            ? AppTheme.pendingColor 
                            : AppTheme.missedColor,
                  ),
                ),
                Text(
                  "$completedCount/5",
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            onTap: () => _showDayDetailSheet(context, date),
          ),
        );
      },
    );
  }

  void _showDayDetailSheet(BuildContext context, DateTime date) {
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
      ref.read(prayerProvider.notifier).selectDate(DateTime.now());
    });
  }
}
