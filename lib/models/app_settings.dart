import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings extends HiveObject {
  @HiveField(0)
  String location;

  @HiveField(1)
  double latitude;

  @HiveField(2)
  double longitude;

  @HiveField(3)
  String country;

  @HiveField(4)
  String city;

  @HiveField(5)
  String timezone;

  @HiveField(6)
  String calculationMethod; // e.g., 'MWL', 'KARACHI', etc.

  @HiveField(7)
  String asrMethod; // 'STANDARD' (Shafi'i, Maliki, Hanbali) or 'HANAFI'

  @HiveField(8)
  bool notificationsEnabled;

  @HiveField(9)
  String theme; // 'light' | 'dark' | 'system'

  @HiveField(10)
  String language; // 'en'

  @HiveField(11)
  String timeFormat; // '12h' | '24h'

  @HiveField(12)
  int hijriOffset; // For Hijri adjustment (-2, -1, 0, 1, 2)

  @HiveField(13)
  bool fajrNotifications;

  @HiveField(14)
  bool dhuhrNotifications;

  @HiveField(15)
  bool asrNotifications;

  @HiveField(16)
  bool maghribNotifications;

  @HiveField(17)
  bool ishaNotifications;

  @HiveField(18)
  int notificationLeadTime; // in minutes (0, 5, 10, 15, 30)

  AppSettings({
    this.location = "London, United Kingdom",
    this.latitude = 51.5074,
    this.longitude = -0.1278,
    this.country = "United Kingdom",
    this.city = "London",
    this.timezone = "Europe/London",
    this.calculationMethod = "MWL",
    this.asrMethod = "STANDARD",
    this.notificationsEnabled = true,
    this.theme = "system",
    this.language = "en",
    this.timeFormat = "12h",
    this.hijriOffset = 0,
    this.fajrNotifications = true,
    this.dhuhrNotifications = true,
    this.asrNotifications = true,
    this.maghribNotifications = true,
    this.ishaNotifications = true,
    this.notificationLeadTime = 0,
  });

  AppSettings copyWith({
    String? location,
    double? latitude,
    double? longitude,
    String? country,
    String? city,
    String? timezone,
    String? calculationMethod,
    String? asrMethod,
    bool? notificationsEnabled,
    String? theme,
    String? language,
    String? timeFormat,
    int? hijriOffset,
    bool? fajrNotifications,
    bool? dhuhrNotifications,
    bool? asrNotifications,
    bool? maghribNotifications,
    bool? ishaNotifications,
    int? notificationLeadTime,
  }) {
    return AppSettings(
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      country: country ?? this.country,
      city: city ?? this.city,
      timezone: timezone ?? this.timezone,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      asrMethod: asrMethod ?? this.asrMethod,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      timeFormat: timeFormat ?? this.timeFormat,
      hijriOffset: hijriOffset ?? this.hijriOffset,
      fajrNotifications: fajrNotifications ?? this.fajrNotifications,
      dhuhrNotifications: dhuhrNotifications ?? this.dhuhrNotifications,
      asrNotifications: asrNotifications ?? this.asrNotifications,
      maghribNotifications: maghribNotifications ?? this.maghribNotifications,
      ishaNotifications: ishaNotifications ?? this.ishaNotifications,
      notificationLeadTime: notificationLeadTime ?? this.notificationLeadTime,
    );
  }
}
