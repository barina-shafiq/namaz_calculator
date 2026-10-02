import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prayer_record.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/prayer_time_service.dart';
import 'settings_provider.dart';

class PrayerState {
  final DateTime selectedDate;
  final List<PrayerRecord> selectedDateRecords;
  final List<PrayerRecord> todayRecords;
  final PrayerRecord? nextPrayer;
  final Duration? timeToNextPrayer;

  PrayerState({
    required this.selectedDate,
    required this.selectedDateRecords,
    required this.todayRecords,
    this.nextPrayer,
    this.timeToNextPrayer,
  });

  PrayerState copyWith({
    DateTime? selectedDate,
    List<PrayerRecord>? selectedDateRecords,
    List<PrayerRecord>? todayRecords,
    PrayerRecord? nextPrayer,
    Duration? timeToNextPrayer,
  }) {
    return PrayerState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedDateRecords: selectedDateRecords ?? this.selectedDateRecords,
      todayRecords: todayRecords ?? this.todayRecords,
      nextPrayer: nextPrayer ?? this.nextPrayer,
      timeToNextPrayer: timeToNextPrayer ?? this.timeToNextPrayer,
    );
  }
}

final prayerTimeServiceProvider = Provider<PrayerTimeService>((ref) => PrayerTimeService());

final prayerProvider = StateNotifierProvider<PrayerNotifier, PrayerState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final prayerTimeService = ref.watch(prayerTimeServiceProvider);
  final settings = ref.watch(settingsProvider);

  return PrayerNotifier(storage, prayerTimeService, settings);
});

class PrayerNotifier extends StateNotifier<PrayerState> {
  final StorageService _storage;
  final PrayerTimeService _prayerTimeService;
  final AppSettings _settings;
  Timer? _countdownTimer;

  PrayerNotifier(this._storage, this._prayerTimeService, this._settings)
      : super(PrayerState(
          selectedDate: DateTime.now(),
          selectedDateRecords: [],
          todayRecords: [],
        )) {
    initToday();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // Initialize and load today's records
  Future<void> initToday() async {
    final now = DateTime.now();
    await _loadRecordsForDate(now, isToday: true);
    await selectDate(now);
  }

  // Select a new date (e.g. from calendar navigation)
  Future<void> selectDate(DateTime date) async {
    await _loadRecordsForDate(date, isToday: false);
  }

  // Load records from local storage or create them if they do not exist
  Future<void> _loadRecordsForDate(DateTime date, {required bool isToday}) async {
    var records = _storage.getPrayerRecordsForDate(date);

    // If records do not exist and the date is not in the future, create them
    // Note: Future records can also be pre-calculated so the user can view future times.
    if (records.isEmpty) {
      records = _generateDefaultRecordsForDate(date);
      await _storage.savePrayerRecords(records);
    } else {
      // Check if prayer times need to be recalculated due to settings change (latitude, longitude, etc.)
      // We will perform a soft recalculate that preserves completion statuses.
      records = _recalculateTimesForRecords(records, date);
      await _storage.savePrayerRecords(records);
    }

    // Update statuses for today/past records to 'missed' if they are unchecked and past their time
    final now = DateTime.now();
    bool updatedStatus = false;
    for (var record in records) {
      if (record.status != 'completed') {
        final isPast = record.prayerTime.isBefore(now);
        final isPastDay = DateTime(record.date.year, record.date.month, record.date.day)
            .isBefore(DateTime(now.year, now.month, now.day));
        
        final targetStatus = (isPast || isPastDay) ? 'missed' : 'pending';
        if (record.status != targetStatus) {
          record.status = targetStatus;
          updatedStatus = true;
        }
      }
    }
    if (updatedStatus) {
      await _storage.savePrayerRecords(records);
    }

    if (isToday) {
      state = state.copyWith(todayRecords: records);
      _updateNextPrayer();
    } else {
      state = state.copyWith(
        selectedDate: date,
        selectedDateRecords: records,
      );
      // If selected date is today, sync todayRecords as well
      if (_formatDateKey(date) == _formatDateKey(now)) {
        state = state.copyWith(todayRecords: records);
        _updateNextPrayer();
      }
    }
  }

  // Trigger recalculation of today's and selected date's prayer times
  Future<void> recalculateTimes() async {
    await _loadRecordsForDate(state.selectedDate, isToday: false);
    await _loadRecordsForDate(DateTime.now(), isToday: true);
  }

  // Toggle checklist status
  Future<void> togglePrayerStatus(String id, bool completed) async {
    final record = _storage.getPrayerRecord(id);
    if (record == null) return;

    // Check if future date - optional restriction, calendar rules say: "Future dates never show as completed."
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final recordDay = DateTime(record.date.year, record.date.month, record.date.day);
    if (recordDay.isAfter(todayMidnight) && completed) {
      // Do not allow checking future dates
      return;
    }

    if (completed) {
      record.status = 'completed';
      record.completedAt = DateTime.now();
    } else {
      // Determine if it was missed or pending before completion
      final isPast = record.prayerTime.isBefore(now);
      final isPastDay = recordDay.isBefore(todayMidnight);
      record.status = (isPast || isPastDay) ? 'missed' : 'pending';
      record.completedAt = null;
    }

    await _storage.savePrayerRecord(record);

    // Refresh current states
    await _loadRecordsForDate(state.selectedDate, isToday: false);
    final selectedDateKey = _formatDateKey(state.selectedDate);
    final todayKey = _formatDateKey(now);
    if (selectedDateKey == todayKey) {
      state = state.copyWith(todayRecords: state.selectedDateRecords);
      _updateNextPrayer();
    } else {
      await _loadRecordsForDate(now, isToday: true);
    }
  }

  // Helper: generate defaults
  List<PrayerRecord> _generateDefaultRecordsForDate(DateTime date) {
    final timesMap = _prayerTimeService.getPrayerTimesMap(
      latitude: _settings.latitude,
      longitude: _settings.longitude,
      date: date,
      method: _settings.calculationMethod,
      asrMethod: _settings.asrMethod,
    );

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final recordDay = DateTime(date.year, date.month, date.day);

    return timesMap.entries.map((entry) {
      final name = entry.key;
      final time = entry.value;
      
      final isPast = time.isBefore(now);
      final isPastDay = recordDay.isBefore(todayMidnight);
      final initialStatus = (isPast || isPastDay) ? 'missed' : 'pending';

      return PrayerRecord(
        id: "${_formatDateKey(date)}_$name",
        date: date,
        prayerName: name,
        prayerTime: time,
        status: initialStatus,
      );
    }).toList();
  }

  // Helper: update times but keep status
  List<PrayerRecord> _recalculateTimesForRecords(List<PrayerRecord> existingRecords, DateTime date) {
    final timesMap = _prayerTimeService.getPrayerTimesMap(
      latitude: _settings.latitude,
      longitude: _settings.longitude,
      date: date,
      method: _settings.calculationMethod,
      asrMethod: _settings.asrMethod,
    );

    return existingRecords.map((record) {
      final newTime = timesMap[record.prayerName];
      if (newTime != null) {
        return record.copyWith(prayerTime: newTime);
      }
      return record;
    }).toList();
  }

  // Helper: calculate next prayer and update countdown
  void _updateNextPrayer() {
    if (state.todayRecords.isEmpty) return;

    final now = DateTime.now();
    
    // Sort today's records by time
    final sorted = List<PrayerRecord>.from(state.todayRecords)
      ..sort((a, b) => a.prayerTime.compareTo(b.prayerTime));

    PrayerRecord? next;
    for (var record in sorted) {
      if (record.prayerTime.isAfter(now)) {
        next = record;
        break;
      }
    }

    // If all prayers today have passed, the next prayer is Fajr tomorrow
    if (next == null) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowTimes = _prayerTimeService.getPrayerTimesMap(
        latitude: _settings.latitude,
        longitude: _settings.longitude,
        date: tomorrow,
        method: _settings.calculationMethod,
        asrMethod: _settings.asrMethod,
      );
      
      final tomorrowFajrTime = tomorrowTimes['Fajr']!;
      next = PrayerRecord(
        id: "${_formatDateKey(tomorrow)}_Fajr",
        date: tomorrow,
        prayerName: 'Fajr',
        prayerTime: tomorrowFajrTime,
        status: 'pending',
      );
    }

    state = state.copyWith(
      nextPrayer: next,
      timeToNextPrayer: next.prayerTime.difference(now),
    );
  }

  // Countdown timer for next prayer
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      
      // Perform date rollover check if date changed
      final currentTodayKey = _formatDateKey(now);
      final lastLoadedTodayKey = state.todayRecords.isNotEmpty 
          ? _formatDateKey(state.todayRecords.first.date) 
          : "";

      if (lastLoadedTodayKey.isNotEmpty && currentTodayKey != lastLoadedTodayKey) {
        // Midnight rollover detected! Load new day
        initToday();
        return;
      }

      if (state.nextPrayer != null) {
        final diff = state.nextPrayer!.prayerTime.difference(now);
        if (diff.isNegative) {
          // Time passed! Update next prayer
          _loadRecordsForDate(now, isToday: true);
        } else {
          state = state.copyWith(timeToNextPrayer: diff);
        }
      }
    });
  }

  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
