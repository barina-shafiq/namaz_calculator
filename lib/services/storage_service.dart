import 'package:hive_flutter/hive_flutter.dart';
import '../models/prayer_record.dart';
import '../models/qaza_record.dart';
import '../models/app_settings.dart';

class StorageService {
  static const String _settingsBoxName = 'settings_box';
  static const String _prayerRecordsBoxName = 'prayer_records_box';
  static const String _qazaRecordsBoxName = 'qaza_records_box';

  late Box<AppSettings> _settingsBox;
  late Box<PrayerRecord> _prayerRecordsBox;
  late Box<QazaRecord> _qazaRecordsBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // Register Hive Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PrayerRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(QazaRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }

    // Open Boxes
    _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);
    _prayerRecordsBox = await Hive.openBox<PrayerRecord>(_prayerRecordsBoxName);
    _qazaRecordsBox = await Hive.openBox<QazaRecord>(_qazaRecordsBoxName);

    // Initialize settings if empty
    if (_settingsBox.isEmpty) {
      await saveSettings(AppSettings());
    }

    // Initialize Qaza records if empty
    if (_qazaRecordsBox.isEmpty) {
      final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
      for (final prayer in prayers) {
        await saveQazaRecord(
          QazaRecord(
            id: prayer.toLowerCase(),
            prayerName: prayer,
            quantity: 0,
            date: DateTime.now(),
          ),
        );
      }
    }
  }

  // --- App Settings ---
  AppSettings getSettings() {
    return _settingsBox.get('current_settings') ?? AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put('current_settings', settings);
  }

  // --- Prayer Records ---
  List<PrayerRecord> getAllPrayerRecords() {
    return _prayerRecordsBox.values.toList();
  }

  PrayerRecord? getPrayerRecord(String id) {
    return _prayerRecordsBox.get(id);
  }

  List<PrayerRecord> getPrayerRecordsForDate(DateTime date) {
    final dateStr = _formatDateKey(date);
    return _prayerRecordsBox.values
        .where((record) => _formatDateKey(record.date) == dateStr)
        .toList();
  }

  Future<void> savePrayerRecord(PrayerRecord record) async {
    await _prayerRecordsBox.put(record.id, record);
  }

  Future<void> savePrayerRecords(List<PrayerRecord> records) async {
    final Map<String, PrayerRecord> entries = {
      for (var record in records) record.id: record
    };
    await _prayerRecordsBox.putAll(entries);
  }

  // --- Qaza Records ---
  List<QazaRecord> getAllQazaRecords() {
    return _qazaRecordsBox.values.toList();
  }

  QazaRecord? getQazaRecord(String prayerName) {
    return _qazaRecordsBox.get(prayerName.toLowerCase());
  }

  Future<void> saveQazaRecord(QazaRecord record) async {
    await _qazaRecordsBox.put(record.id, record);
  }

  // --- Utility ---
  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> clearAllData() async {
    await _settingsBox.clear();
    await _prayerRecordsBox.clear();
    await _qazaRecordsBox.clear();
    
    // Re-initialize default settings and Qaza logs
    await saveSettings(AppSettings());
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    for (final prayer in prayers) {
      await saveQazaRecord(
        QazaRecord(
          id: prayer.toLowerCase(),
          prayerName: prayer,
          quantity: 0,
          date: DateTime.now(),
        ),
      );
    }
  }
}
