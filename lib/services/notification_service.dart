import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/app_settings.dart';
import '../services/prayer_time_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle click on notification if needed
      },
    );
  }

  Future<bool> requestPermissions() async {
    // Request permission for Android (13+)
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    // Request permission for iOS
    final iosImplementation = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    return true;
  }

  /// Cancel all scheduled alerts and reschedule for the next 7 days based on settings.
  Future<void> reschedulePrayerReminders(AppSettings settings) async {
    await _plugin.cancelAll();

    if (!settings.notificationsEnabled) return;

    tz.Location location;
    try {
      location = tz.getLocation(settings.timezone);
    } catch (_) {
      location = tz.UTC;
    }

    final now = DateTime.now();
    int notificationId = 0;

    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    // Schedule notifications for the next 7 days
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      
      final timesMap = _prayerTimeService.getPrayerTimesMap(
        latitude: settings.latitude,
        longitude: settings.longitude,
        date: date,
        method: settings.calculationMethod,
        asrMethod: settings.asrMethod,
      );

      for (final prayerName in prayers) {
        // Check if reminder is enabled for this prayer
        bool isEnabled = false;
        switch (prayerName) {
          case 'Fajr':
            isEnabled = settings.fajrNotifications;
            break;
          case 'Dhuhr':
            isEnabled = settings.dhuhrNotifications;
            break;
          case 'Asr':
            isEnabled = settings.asrNotifications;
            break;
          case 'Maghrib':
            isEnabled = settings.maghribNotifications;
            break;
          case 'Isha':
            isEnabled = settings.ishaNotifications;
            break;
        }

        if (!isEnabled) continue;

        final prayerTime = timesMap[prayerName]!;
        // Apply lead time offset
        final alertTime = prayerTime.subtract(Duration(minutes: settings.notificationLeadTime));

        // Skip if alert time is in the past
        if (alertTime.isBefore(now)) continue;

        final scheduledTZTime = tz.TZDateTime.from(alertTime, location);

        const androidDetails = AndroidNotificationDetails(
          'prayer_reminders_channel',
          'Prayer Reminders',
          channelDescription: 'Offline reminders for daily prayers',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('notification_sound'), // fallback to default if missing
          playSound: true,
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        );

        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        String title = "Namaz Companion";
        String body = settings.notificationLeadTime == 0
            ? "It is time for $prayerName prayer."
            : "$prayerName prayer starts in ${settings.notificationLeadTime} minutes.";

        await _plugin.zonedSchedule(
          notificationId++,
          title,
          body,
          scheduledTZTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }
}
