import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/prayer_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/next_prayer_card.dart';
import '../widgets/progress_card.dart';
import '../widgets/prayer_card.dart';

class DailyNamazScreen extends ConsumerWidget {
  const DailyNamazScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerState = ref.watch(prayerProvider);
    final settings = ref.watch(settingsProvider);

    final todayRecords = prayerState.todayRecords;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(prayerProvider.notifier).initToday();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const NextPrayerCard(),
            const SizedBox(height: 16),
            ProgressCard(records: todayRecords),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Namaz",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Location: ${settings.city}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (todayRecords.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todayRecords.length,
                itemBuilder: (context, index) {
                  final record = todayRecords[index];
                  return PrayerCard(
                    record: record,
                    timeFormat: settings.timeFormat,
                    onToggle: (completed) {
                      ref.read(prayerProvider.notifier).togglePrayerStatus(record.id, completed);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
