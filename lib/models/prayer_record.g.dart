// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrayerRecordAdapter extends TypeAdapter<PrayerRecord> {
  @override
  final int typeId = 0;

  @override
  PrayerRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrayerRecord(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      prayerName: fields[2] as String,
      prayerTime: fields[3] as DateTime,
      status: fields[4] as String,
      completedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PrayerRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.prayerName)
      ..writeByte(3)
      ..write(obj.prayerTime)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
