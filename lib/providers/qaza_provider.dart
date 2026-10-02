import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/qaza_record.dart';
import '../services/storage_service.dart';
import 'settings_provider.dart';

class QazaState {
  final List<QazaRecord> outstandingRecords;
  final List<QazaRecord> completedRecords;

  QazaState({
    required this.outstandingRecords,
    required this.completedRecords,
  });

  int get totalRemaining => outstandingRecords.fold(0, (sum, r) => sum + r.quantity);
  int get totalCompleted => completedRecords.fold(0, (sum, r) => sum + r.quantity);
  int get totalCount => totalRemaining + totalCompleted;

  double get progressPercentage {
    final total = totalCount;
    if (total == 0) return 0.0;
    return totalCompleted / total;
  }
}

final qazaProvider = StateNotifierProvider<QazaNotifier, QazaState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return QazaNotifier(storage);
});

class QazaNotifier extends StateNotifier<QazaState> {
  final StorageService _storage;

  QazaNotifier(this._storage)
      : super(QazaState(outstandingRecords: [], completedRecords: [])) {
    _loadQazaRecords();
  }

  void _loadQazaRecords() {
    final List<QazaRecord> outstanding = [];
    final List<QazaRecord> completed = [];

    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    for (final prayer in prayers) {
      final idLower = prayer.toLowerCase();
      
      // Get or create outstanding
      var outRecord = _storage.getQazaRecord(idLower);
      if (outRecord == null) {
        outRecord = QazaRecord(
          id: idLower,
          prayerName: prayer,
          quantity: 0,
          date: DateTime.now(),
        );
        _storage.saveQazaRecord(outRecord);
      }
      outstanding.add(outRecord);

      // Get or create completed
      final completedId = "${idLower}_completed";
      var compRecord = _storage.getQazaRecord(completedId);
      if (compRecord == null) {
        compRecord = QazaRecord(
          id: completedId,
          prayerName: prayer,
          quantity: 0,
          date: DateTime.now(),
        );
        _storage.saveQazaRecord(compRecord);
      }
      completed.add(compRecord);
    }

    state = QazaState(
      outstandingRecords: outstanding,
      completedRecords: completed,
    );
  }

  Future<void> incrementQaza(String prayerName) async {
    final idLower = prayerName.toLowerCase();
    final record = _storage.getQazaRecord(idLower);
    if (record != null) {
      record.quantity++;
      record.date = DateTime.now();
      await _storage.saveQazaRecord(record);
      _loadQazaRecords();
    }
  }

  Future<void> decrementQaza(String prayerName) async {
    final idLower = prayerName.toLowerCase();
    final record = _storage.getQazaRecord(idLower);
    
    if (record != null && record.quantity > 0) {
      record.quantity--;
      record.date = DateTime.now();
      record.completedAt = DateTime.now();
      await _storage.saveQazaRecord(record);

      // Increment completed counter
      final completedId = "${idLower}_completed";
      final compRecord = _storage.getQazaRecord(completedId);
      if (compRecord != null) {
        compRecord.quantity++;
        compRecord.date = DateTime.now();
        compRecord.completedAt = DateTime.now();
        await _storage.saveQazaRecord(compRecord);
      }
      
      _loadQazaRecords();
    }
  }

  Future<void> resetQaza() async {
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    for (final prayer in prayers) {
      final idLower = prayer.toLowerCase();
      final outRecord = _storage.getQazaRecord(idLower);
      if (outRecord != null) {
        outRecord.quantity = 0;
        outRecord.date = DateTime.now();
        await _storage.saveQazaRecord(outRecord);
      }

      final completedId = "${idLower}_completed";
      final compRecord = _storage.getQazaRecord(completedId);
      if (compRecord != null) {
        compRecord.quantity = 0;
        compRecord.date = DateTime.now();
        await _storage.saveQazaRecord(compRecord);
      }
    }
    _loadQazaRecords();
  }
}
