import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prayer_record.dart';
import 'prayer_provider.dart';
import 'settings_provider.dart';

class DayCompletion {
  final DateTime date;
  final int completedCount;
  final String status; // 'full' | 'partial' | 'missed' | 'future'

  DayCompletion({
    required this.date,
    required this.completedCount,
    required this.status,
  });
}

class StatsState {
  final double todayRate;
  final double weekRate;
  final double monthRate;
  final double allTimeRate;
  
  final Map<String, double> perPrayerRates; // Fajr: 0.85, etc.
  
  final List<DayCompletion> currentWeekDays; // Mon-Sun completions
  
  final int monthlyFullyCompletedCount;
  final int monthlyPartiallyCompletedCount;
  final int monthlyMissedCount;

  final int currentStreak;
  final int bestStreak;

  final List<DateTime> loggedDates; // Dates with logs for history screen

  StatsState({
    required this.todayRate,
    required this.weekRate,
    required this.monthRate,
    required this.allTimeRate,
    required this.perPrayerRates,
    required this.currentWeekDays,
    required this.monthlyFullyCompletedCount,
    required this.monthlyPartiallyCompletedCount,
    required this.monthlyMissedCount,
    required this.currentStreak,
    required this.bestStreak,
    required this.loggedDates,
  });
}

final statsProvider = Provider<StatsState>((ref) {
  // Recompute stats when prayer state changes
  ref.watch(prayerProvider); 
  final storage = ref.watch(storageServiceProvider);

  final allRecords = storage.getAllPrayerRecords();
  if (allRecords.isEmpty) {
    return StatsState(
      todayRate: 0.0,
      weekRate: 0.0,
      monthRate: 0.0,
      allTimeRate: 0.0,
      perPrayerRates: {
        'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0
      },
      currentWeekDays: [],
      monthlyFullyCompletedCount: 0,
      monthlyPartiallyCompletedCount: 0,
      monthlyMissedCount: 0,
      currentStreak: 0,
      bestStreak: 0,
      loggedDates: [],
    );
  }

  final now = DateTime.now();
  final todayMidnight = DateTime(now.year, now.month, now.day);

  // Group records by Date key
  final Map<String, List<PrayerRecord>> grouped = {};
  for (var r in allRecords) {
    final key = _formatDateKey(r.date);
    grouped.putIfAbsent(key, () => []).add(r);
  }

  // List of all logged dates in chronological order
  final sortedDates = grouped.keys.map((k) => DateTime.parse(k)).toList()
    ..sort((a, b) => a.compareTo(b));

  // --- Streaks Calculation ---
  int currentStreak = 0;
  int bestStreak = 0;
  int runningStreak = 0;

  if (sortedDates.isNotEmpty) {
    final oldestDate = sortedDates.first;
    // Walk from oldest date to today
    DateTime currentWalk = DateTime(oldestDate.year, oldestDate.month, oldestDate.day);
    
    while (!currentWalk.isAfter(todayMidnight)) {
      final key = _formatDateKey(currentWalk);
      final dayRecs = grouped[key] ?? [];
      final completed = dayRecs.where((r) => r.status == 'completed').length;
      
      final isWalkToday = key == _formatDateKey(now);
      
      if (completed == 5) {
        runningStreak++;
        if (runningStreak > bestStreak) {
          bestStreak = runningStreak;
        }
      } else {
        if (isWalkToday) {
          // If it's today and not yet complete, don't break the streak yet, 
          // let the streak remain what it was up to yesterday.
          if (runningStreak > bestStreak) {
            bestStreak = runningStreak;
          }
        } else {
          // It's a past day and not completed, so streak is broken
          if (runningStreak > bestStreak) {
            bestStreak = runningStreak;
          }
          runningStreak = 0;
        }
      }
      currentWalk = currentWalk.add(const Duration(days: 1));
    }
    
    currentStreak = runningStreak;
  }

  // --- Today Rate ---
  final todayKey = _formatDateKey(now);
  final todayRecs = grouped[todayKey] ?? [];
  final todayCompleted = todayRecs.where((r) => r.status == 'completed').length;
  final double todayRate = todayRecs.isNotEmpty ? todayCompleted / todayRecs.length : 0.0;

  // --- Weekly Overview & Rate ---
  // Find start of current week (Monday)
  final weekday = now.weekday; // 1 = Mon, 7 = Sun
  final startOfWeek = todayMidnight.subtract(Duration(days: weekday - 1));
  
  List<DayCompletion> currentWeekDays = [];
  int weeklyCompletedCount = 0;
  int weeklyTotalCount = 0;

  for (int i = 0; i < 7; i++) {
    final day = startOfWeek.add(Duration(days: i));
    final key = _formatDateKey(day);
    final dayRecs = grouped[key] ?? [];
    final completed = dayRecs.where((r) => r.status == 'completed').length;
    
    weeklyCompletedCount += completed;
    weeklyTotalCount += dayRecs.isNotEmpty ? dayRecs.length : 5; // assume 5 if not generated yet

    String status = 'future';
    if (day.isBefore(todayMidnight)) {
      status = completed == 5 ? 'full' : completed > 0 ? 'partial' : 'missed';
    } else if (_formatDateKey(day) == todayKey) {
      status = completed == 5 ? 'full' : completed > 0 ? 'partial' : 'missed';
    }

    currentWeekDays.add(
      DayCompletion(
        date: day,
        completedCount: completed,
        status: status,
      ),
    );
  }
  final double weekRate = weeklyTotalCount > 0 ? weeklyCompletedCount / weeklyTotalCount : 0.0;

  // --- Monthly Breakdown & Rate ---
  int monthlyFullyCompletedCount = 0;
  int monthlyPartiallyCompletedCount = 0;
  int monthlyMissedCount = 0;
  int monthlyCompletedPrayers = 0;
  int monthlyTotalPrayers = 0;

  // Walk all days in the current month up to today
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  for (int d = 1; d <= daysInMonth; d++) {
    final day = DateTime(now.year, now.month, d);
    if (day.isAfter(todayMidnight)) continue;

    final key = _formatDateKey(day);
    final dayRecs = grouped[key] ?? [];
    final completed = dayRecs.where((r) => r.status == 'completed').length;

    monthlyCompletedPrayers += completed;
    monthlyTotalPrayers += dayRecs.isNotEmpty ? dayRecs.length : 5;

    if (completed == 5) {
      monthlyFullyCompletedCount++;
    } else if (completed > 0) {
      monthlyPartiallyCompletedCount++;
    } else {
      monthlyMissedCount++;
    }
  }
  final double monthRate = monthlyTotalPrayers > 0 ? monthlyCompletedPrayers / monthlyTotalPrayers : 0.0;

  // --- All Time Rate ---
  final int totalPrayersCount = allRecords.length;
  final int completedPrayersCount = allRecords.where((r) => r.status == 'completed').length;
  final double allTimeRate = totalPrayersCount > 0 ? completedPrayersCount / totalPrayersCount : 0.0;

  // --- Per-prayer Rates ---
  final Map<String, int> prayerTotals = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};
  final Map<String, int> prayerCompletions = {'Fajr': 0, 'Dhuhr': 0, 'Asr': 0, 'Maghrib': 0, 'Isha': 0};

  for (var r in allRecords) {
    if (prayerTotals.containsKey(r.prayerName)) {
      prayerTotals[r.prayerName] = prayerTotals[r.prayerName]! + 1;
      if (r.status == 'completed') {
        prayerCompletions[r.prayerName] = prayerCompletions[r.prayerName]! + 1;
      }
    }
  }

  final Map<String, double> perPrayerRates = {};
  prayerTotals.forEach((name, total) {
    perPrayerRates[name] = total > 0 ? prayerCompletions[name]! / total : 0.0;
  });

  // Logged dates in descending order (newest first) for history screen
  final loggedDates = sortedDates.reversed.toList();

  return StatsState(
    todayRate: todayRate,
    weekRate: weekRate,
    monthRate: monthRate,
    allTimeRate: allTimeRate,
    perPrayerRates: perPrayerRates,
    currentWeekDays: currentWeekDays,
    monthlyFullyCompletedCount: monthlyFullyCompletedCount,
    monthlyPartiallyCompletedCount: monthlyPartiallyCompletedCount,
    monthlyMissedCount: monthlyMissedCount,
    currentStreak: currentStreak,
    bestStreak: bestStreak,
    loggedDates: loggedDates,
  );
});

String _formatDateKey(DateTime date) {
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}
