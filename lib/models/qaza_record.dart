import 'package:hive/hive.dart';

part 'qaza_record.g.dart';

@HiveType(typeId: 1)
class QazaRecord extends HiveObject {
  @HiveField(0)
  final String id; // format: "prayerName"

  @HiveField(1)
  final String prayerName; // Fajr, Dhuhr, Asr, Maghrib, Isha

  @HiveField(2)
  int quantity;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  DateTime? completedAt;

  QazaRecord({
    required this.id,
    required this.prayerName,
    required this.quantity,
    required this.date,
    this.completedAt,
  });

  QazaRecord copyWith({
    String? id,
    String? prayerName,
    int? quantity,
    DateTime? date,
    DateTime? completedAt,
  }) {
    return QazaRecord(
      id: id ?? this.id,
      prayerName: prayerName ?? this.prayerName,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
