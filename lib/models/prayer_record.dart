import 'package:hive/hive.dart';

part 'prayer_record.g.dart';

@HiveType(typeId: 0)
class PrayerRecord extends HiveObject {
  @HiveField(0)
  final String id; // format: "YYYY-MM-DD_prayerName"

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String prayerName; // Fajr, Dhuhr, Asr, Maghrib, Isha

  @HiveField(3)
  final DateTime prayerTime;

  @HiveField(4)
  String status; // 'pending' | 'completed' | 'missed'

  @HiveField(5)
  DateTime? completedAt;

  PrayerRecord({
    required this.id,
    required this.date,
    required this.prayerName,
    required this.prayerTime,
    required this.status,
    this.completedAt,
  });

  PrayerRecord copyWith({
    String? id,
    DateTime? date,
    String? prayerName,
    DateTime? prayerTime,
    String? status,
    DateTime? completedAt,
  }) {
    return PrayerRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      prayerName: prayerName ?? this.prayerName,
      prayerTime: prayerTime ?? this.prayerTime,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
