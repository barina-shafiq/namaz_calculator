import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden in main.dart');
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('NotificationService must be overridden in main.dart');
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final notifications = ref.watch(notificationServiceProvider);
  return SettingsNotifier(storage, notifications);
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storage;
  final NotificationService _notifications;

  SettingsNotifier(this._storage, this._notifications) : super(_storage.getSettings()) {
    // Schedule initial reminders on startup
    _notifications.reschedulePrayerReminders(state);
  }

  Future<void> updateLocation({
    required String location,
    required double latitude,
    required double longitude,
    required String country,
    required String city,
    required String timezone,
  }) async {
    final updated = state.copyWith(
      location: location,
      latitude: latitude,
      longitude: longitude,
      country: country,
      city: city,
      timezone: timezone,
    );
    await _storage.saveSettings(updated);
    state = updated;
    await _notifications.reschedulePrayerReminders(updated);
  }

  Future<void> updateCalculationMethod(String method) async {
    final updated = state.copyWith(calculationMethod: method);
    await _storage.saveSettings(updated);
    state = updated;
    await _notifications.reschedulePrayerReminders(updated);
  }

  Future<void> updateAsrMethod(String asrMethod) async {
    final updated = state.copyWith(asrMethod: asrMethod);
    await _storage.saveSettings(updated);
    state = updated;
    await _notifications.reschedulePrayerReminders(updated);
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    final updated = state.copyWith(notificationsEnabled: enabled);
    await _storage.saveSettings(updated);
    state = updated;
    await _notifications.reschedulePrayerReminders(updated);
  }

  Future<void> updateTheme(String theme) async {
    final updated = state.copyWith(theme: theme);
    await _storage.saveSettings(updated);
    state = updated;
  }

  Future<void> updateTimeFormat(String timeFormat) async {
    final updated = state.copyWith(timeFormat: timeFormat);
    await _storage.saveSettings(updated);
    state = updated;
  }

  Future<void> updateHijriOffset(int offset) async {
    final updated = state.copyWith(hijriOffset: offset);
    await _storage.saveSettings(updated);
    state = updated;
  }

  Future<void> updatePrayerNotification(String prayerName, bool enabled) async {
    AppSettings updated;
    switch (prayerName) {
      case 'Fajr':
        updated = state.copyWith(fajrNotifications: enabled);
        break;
      case 'Dhuhr':
        updated = state.copyWith(dhuhrNotifications: enabled);
        break;
      case 'Asr':
        updated = state.copyWith(asrNotifications: enabled);
        break;
      case 'Maghrib':
        updated = state.copyWith(maghribNotifications: enabled);
        break;
      case 'Isha':
        updated = state.copyWith(ishaNotifications: enabled);
        break;
      default:
        return;
    }
    await _storage.saveSettings(updated);
    state = updated;
    await _notifications.reschedulePrayerReminders(updated);
  }

  Future<void> updateNotificationLeadTime(int minutes) async {
    final updated = state.copyWith(notificationLeadTime: minutes);
    await _storage.saveSettings(updated);
    state = updated;
    await _notifications.reschedulePrayerReminders(updated);
  }

  Future<void> resetAllData() async {
    await _storage.clearAllData();
    state = _storage.getSettings();
    await _notifications.reschedulePrayerReminders(state);
  }
}
