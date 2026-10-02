// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      location: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      country: fields[3] as String,
      city: fields[4] as String,
      timezone: fields[5] as String,
      calculationMethod: fields[6] as String,
      asrMethod: fields[7] as String,
      notificationsEnabled: fields[8] as bool,
      theme: fields[9] as String,
      language: fields[10] as String,
      timeFormat: fields[11] as String,
      hijriOffset: fields[12] as int,
      fajrNotifications: fields[13] as bool,
      dhuhrNotifications: fields[14] as bool,
      asrNotifications: fields[15] as bool,
      maghribNotifications: fields[16] as bool,
      ishaNotifications: fields[17] as bool,
      notificationLeadTime: fields[18] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.location)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.country)
      ..writeByte(4)
      ..write(obj.city)
      ..writeByte(5)
      ..write(obj.timezone)
      ..writeByte(6)
      ..write(obj.calculationMethod)
      ..writeByte(7)
      ..write(obj.asrMethod)
      ..writeByte(8)
      ..write(obj.notificationsEnabled)
      ..writeByte(9)
      ..write(obj.theme)
      ..writeByte(10)
      ..write(obj.language)
      ..writeByte(11)
      ..write(obj.timeFormat)
      ..writeByte(12)
      ..write(obj.hijriOffset)
      ..writeByte(13)
      ..write(obj.fajrNotifications)
      ..writeByte(14)
      ..write(obj.dhuhrNotifications)
      ..writeByte(15)
      ..write(obj.asrNotifications)
      ..writeByte(16)
      ..write(obj.maghribNotifications)
      ..writeByte(17)
      ..write(obj.ishaNotifications)
      ..writeByte(18)
      ..write(obj.notificationLeadTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
