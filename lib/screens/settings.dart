import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/prayer_provider.dart';
import '../services/location_service.dart';
import '../utils/theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final LocationService _locationService = LocationService();
  bool _isDetectingLocation = false;

  Future<void> _detectLocation() async {
    setState(() {
      _isDetectingLocation = true;
    });

    try {
      final details = await _locationService.getCurrentLocation();
      await ref.read(settingsProvider.notifier).updateLocation(
            location: "${details.city}, ${details.country}",
            latitude: details.latitude,
            longitude: details.longitude,
            country: details.country,
            city: details.city,
            timezone: details.timezone,
          );

      await ref.read(prayerProvider.notifier).recalculateTimes();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Location updated to ${details.city}!"),
          backgroundColor: AppTheme.completedColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Location Detection Failed"),
          content: Text(e.toString().replaceAll("Exception: ", "")),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
      }
    }
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset All Data?"),
        content: const Text(
          "This will clear all your prayer completion history, Qaza counters, and custom settings. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.missedColor),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(settingsProvider.notifier).resetAllData();
              await ref.read(prayerProvider.notifier).initToday();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("App data has been reset to defaults."),
                  ),
                );
              }
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    final calculationMethods = {
      'MWL': 'Muslim World League',
      'KARACHI': 'Univ. of Islamic Sciences Karachi',
      'EGYPTIAN': 'Egyptian General Authority',
      'ISNA': 'ISNA (North America)',
      'UMM_AL_QURA': 'Umm Al-Qura (Makkah)',
      'DUBAI': 'Dubai',
      'KUWAIT': 'Kuwait',
      'QATAR': 'Qatar',
      'SINGAPORE': 'Singapore',
      'TURKEY': 'Turkey',
      'TEHRAN': 'Tehran',
    };

    final presetCities = LocationService.getManualPresetCities();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // LOCATION SECTION
          _buildSectionHeader("Location Settings"),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Current Location",
                            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            settings.location,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Icon(Icons.location_on, color: AppTheme.primaryColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Coordinates: ${settings.latitude.toStringAsFixed(4)}°, ${settings.longitude.toStringAsFixed(4)}°",
                    style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // GPS Detect Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isDetectingLocation ? null : _detectLocation,
                          icon: _isDetectingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(_isDetectingLocation ? "Detecting..." : "Detect Location (GPS)"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Preset Fallback Cities
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Select Preset City (GPS Fallback)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    initialValue: presetCities.any((c) => c.city == settings.city) ? settings.city : null,
                    items: presetCities.map((c) {
                      return DropdownMenuItem(
                        value: c.city,
                        child: Text("${c.city}, ${c.country}"),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      if (val == null) return;
                      final selected = presetCities.firstWhere((c) => c.city == val);
                      await settingsNotifier.updateLocation(
                        location: "${selected.city}, ${selected.country}",
                        latitude: selected.latitude,
                        longitude: selected.longitude,
                        country: selected.country,
                        city: selected.city,
                        timezone: selected.timezone,
                      );
                      await ref.read(prayerProvider.notifier).recalculateTimes();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // PRAYER CALCULATION
          _buildSectionHeader("Prayer Calculation Rules"),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Calculation Method",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    initialValue: settings.calculationMethod,
                    items: calculationMethods.entries.map((e) {
                      return DropdownMenuItem(value: e.key, child: Text(e.value));
                    }).toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        await settingsNotifier.updateCalculationMethod(val);
                        await ref.read(prayerProvider.notifier).recalculateTimes();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Asr Jurisprudence (Madhab)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    initialValue: settings.asrMethod,
                    items: const [
                      DropdownMenuItem(value: 'STANDARD', child: Text("Standard (Shafi'i, Maliki, Hanbali)")),
                      DropdownMenuItem(value: 'HANAFI', child: Text("Hanafi")),
                    ],
                    onChanged: (val) async {
                      if (val != null) {
                        await settingsNotifier.updateAsrMethod(val);
                        await ref.read(prayerProvider.notifier).recalculateTimes();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Hijri Adjustment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hijri Adjustment", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Shift calendar date offset", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: settings.hijriOffset > -2
                                ? () => settingsNotifier.updateHijriOffset(settings.hijriOffset - 1)
                                : null,
                          ),
                          Text(
                            "${settings.hijriOffset > 0 ? '+' : ''}${settings.hijriOffset} Days",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: settings.hijriOffset < 2
                                ? () => settingsNotifier.updateHijriOffset(settings.hijriOffset + 1)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // REMINDERS
          _buildSectionHeader("Prayer Reminders"),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Enable Reminders", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Receive local alerts for prayer times"),
                  value: settings.notificationsEnabled,
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: (val) => settingsNotifier.updateNotificationsEnabled(val),
                ),
                if (settings.notificationsEnabled) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: "Alert Timing Offset",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      initialValue: settings.notificationLeadTime,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text("At prayer time")),
                        DropdownMenuItem(value: 5, child: Text("5 minutes before")),
                        DropdownMenuItem(value: 10, child: Text("10 minutes before")),
                        DropdownMenuItem(value: 15, child: Text("15 minutes before")),
                        DropdownMenuItem(value: 30, child: Text("30 minutes before")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          settingsNotifier.updateNotificationLeadTime(val);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  _buildPrayerReminderToggle("Fajr", settings.fajrNotifications, settingsNotifier),
                  _buildPrayerReminderToggle("Dhuhr", settings.dhuhrNotifications, settingsNotifier),
                  _buildPrayerReminderToggle("Asr", settings.asrNotifications, settingsNotifier),
                  _buildPrayerReminderToggle("Maghrib", settings.maghribNotifications, settingsNotifier),
                  _buildPrayerReminderToggle("Isha", settings.ishaNotifications, settingsNotifier),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // APPEARANCE & SYSTEM
          _buildSectionHeader("Appearance & System"),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "App Theme Mode",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    initialValue: settings.theme,
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text("System Default")),
                      DropdownMenuItem(value: 'light', child: Text("Light Mode")),
                      DropdownMenuItem(value: 'dark', child: Text("Dark Mode")),
                    ],
                    onChanged: (val) {
                      if (val != null) settingsNotifier.updateTheme(val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Time Format",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    initialValue: settings.timeFormat,
                    items: const [
                      DropdownMenuItem(value: '12h', child: Text("12-Hour format (am/pm)")),
                      DropdownMenuItem(value: '24h', child: Text("24-Hour format")),
                    ],
                    onChanged: (val) {
                      if (val != null) settingsNotifier.updateTimeFormat(val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // OTHER / RESET
          _buildSectionHeader("Other Actions"),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryColor),
                  title: const Text("Privacy Statement"),
                  subtitle: const Text("Offline-first. No data leaves your device."),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Privacy Respect Policy"),
                        content: const Text(
                          "Namaz Companion is built as a privacy-respecting tool. No user logins are required, no trackers are integrated, and all compiled history, coordinates, and statistics live exclusively in the local Hive database on your handset.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: AppTheme.missedColor),
                  title: const Text("Clear and Reset All Data", style: TextStyle(color: AppTheme.missedColor)),
                  subtitle: const Text("Delete all settings and completion logs"),
                  onTap: _showResetConfirmDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildPrayerReminderToggle(String prayerName, bool value, SettingsNotifier notifier) {
    return SwitchListTile(
      title: Text("Remind for $prayerName"),
      value: value,
      activeThumbColor: AppTheme.primaryColor,
      onChanged: (val) {
        notifier.updatePrayerNotification(prayerName, val);
      },
    );
  }
}
