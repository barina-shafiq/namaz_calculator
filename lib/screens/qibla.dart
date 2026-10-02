import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/settings_provider.dart';
import '../services/location_service.dart';
import '../utils/calculations.dart';
import '../utils/theme.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  double? _rawHeading;
  double? _smoothedHeading;
  bool _hasSensor = true;
  bool _isUpdatingLocation = false;
  bool _hasReceivedReading = false;
  bool _isInverted180 = false; // Toggle for hardware magnetometer 180° inversion correction

  @override
  void initState() {
    super.initState();
    _initCompass();
    _autoFetchGPSIfPermissionGranted();
  }

  /// Silently attempt to sync GPS location on load if permissions are enabled
  Future<void> _autoFetchGPSIfPermissionGranted() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final locationService = LocationService();
        final locationDetails = await locationService.getCurrentLocation();
        if (mounted) {
          await ref.read(settingsProvider.notifier).updateLocation(
            location: "${locationDetails.city}, ${locationDetails.country}",
            latitude: locationDetails.latitude,
            longitude: locationDetails.longitude,
            country: locationDetails.country,
            city: locationDetails.city,
            timezone: locationDetails.timezone,
          );
        }
      }
    } catch (_) {
      // Graceful fallback if offline or location disabled
    }
  }

  void _initCompass() {
    try {
      final compassStream = FlutterCompass.events;
      if (compassStream == null) {
        setState(() {
          _hasSensor = false;
        });
        return;
      }

      _compassSubscription = compassStream.listen(
        (event) {
          if (mounted) {
            if (event.heading != null) {
              final double newNorm = _normalizeHeading(event.heading!);
              setState(() {
                _rawHeading = event.heading;
                // Apply EMA low-pass filter to smooth sensor readings
                if (_smoothedHeading == null) {
                  _smoothedHeading = newNorm;
                } else {
                  // Handle angular wrap-around during smoothing
                  double delta = newNorm - _smoothedHeading!;
                  if (delta > 180) delta -= 360;
                  if (delta < -180) delta += 360;
                  _smoothedHeading = (_smoothedHeading! + 0.25 * delta) % 360.0;
                  if (_smoothedHeading! < 0) _smoothedHeading = _smoothedHeading! + 360.0;
                }
                _hasSensor = true;
                _hasReceivedReading = true;
              });
            } else if (!_hasReceivedReading) {
              setState(() {
                _hasSensor = false;
              });
            }
          }
        },
        onError: (error) {
          if (mounted && !_hasReceivedReading) {
            setState(() {
              _hasSensor = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted && !_hasReceivedReading) {
        setState(() {
          _hasSensor = false;
        });
      }
    }
  }

  Future<void> _refreshLocationGPS() async {
    setState(() {
      _isUpdatingLocation = true;
    });
    try {
      final locationService = LocationService();
      final locationDetails = await locationService.getCurrentLocation();
      
      await ref.read(settingsProvider.notifier).updateLocation(
        location: "${locationDetails.city}, ${locationDetails.country}",
        latitude: locationDetails.latitude,
        longitude: locationDetails.longitude,
        country: locationDetails.country,
        city: locationDetails.city,
        timezone: locationDetails.timezone,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Location updated to ${locationDetails.city}, ${locationDetails.country}"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.completedColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("GPS Error: ${e.toString().replaceAll('Exception: ', '')}. Select city manually."),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.missedColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingLocation = false;
        });
      }
    }
  }

  void _showLocationPicker(BuildContext context) {
    final cities = LocationService.getManualPresetCities();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(20.0),
          height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Set Location for Qibla",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(bottomSheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                leading: const Icon(Icons.my_location, color: AppTheme.primaryColor),
                title: const Text("Use GPS Auto-Location", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Detect current GPS coordinates"),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _refreshLocationGPS();
                },
              ),
              const SizedBox(height: 16),
              const Text(
                "Or Choose a City:",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: cities.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    final double qiblaForCity = GeographicCalculations.calculateQiblaDirection(
                      city.latitude,
                      city.longitude,
                    );
                    return ListTile(
                      title: Text("${city.city}, ${city.country}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("Qibla Bearing: ${qiblaForCity.toStringAsFixed(1)}°"),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () async {
                        await ref.read(settingsProvider.notifier).updateLocation(
                          location: "${city.city}, ${city.country}",
                          latitude: city.latitude,
                          longitude: city.longitude,
                          country: city.country,
                          city: city.city,
                          timezone: city.timezone,
                        );
                        if (bottomSheetContext.mounted) {
                          Navigator.pop(bottomSheetContext);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _normalizeHeading(double heading) {
    double norm = heading % 360.0;
    if (norm < 0) norm += 360.0;
    return norm;
  }

  String _formatHeadingText(double? heading) {
    if (heading == null) return "N/A";
    final double norm = _normalizeHeading(heading);
    int rounded = norm.round() % 360;
    return "$rounded°";
  }

  double _calculateDeltaAngle(double heading, double qiblaBearing) {
    double delta = (qiblaBearing - heading) % 360.0;
    if (delta > 180.0) delta -= 360.0;
    if (delta < -180.0) delta += 360.0;
    return delta;
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final double qiblaBearing = GeographicCalculations.calculateQiblaDirection(
      settings.latitude,
      settings.longitude,
    );

    double baseHeading = _smoothedHeading ?? (_rawHeading != null ? _normalizeHeading(_rawHeading!) : 0.0);
    // Apply 180° inversion correction if enabled
    final double headingToUse = _isInverted180 ? (baseHeading + 180.0) % 360.0 : baseHeading;

    final double deltaAngle = _calculateDeltaAngle(headingToUse, qiblaBearing);
    final bool isAligned = _hasSensor && deltaAngle.abs() <= 4.0;

    // Angle to rotate Qibla pointer in turns (0.0 to 1.0)
    final double pointerTurns = (qiblaBearing - headingToUse) / 360.0;
    // Angle to rotate compass dial in turns (-heading)
    final double dialTurns = -headingToUse / 360.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Current Location & Change Location Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.location,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${settings.latitude.toStringAsFixed(4)}°, ${settings.longitude.toStringAsFixed(4)}°",
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _isUpdatingLocation ? null : () => _showLocationPicker(context),
                  icon: _isUpdatingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_location_alt, size: 18),
                  label: const Text("Change", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Info Card (Bearing vs Heading + Invert 180° Button)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          "Qibla Bearing",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).hintColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${qiblaBearing.toStringAsFixed(1)}°",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Theme.of(context).dividerColor,
                    ),
                    Column(
                      children: [
                        Text(
                          "Your Heading",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).hintColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _hasSensor && _rawHeading != null
                              ? _formatHeadingText(headingToUse)
                              : "N/A",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isInverted180 ? "180° Inversion Active" : "Normal Sensor Mode",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _isInverted180 ? AppTheme.accentColor : Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isInverted180 = !_isInverted180;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isInverted180 ? "Reversed compass heading by 180°" : "Reset compass heading to normal"),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isInverted180
                              ? AppTheme.accentColor.withValues(alpha: 0.2)
                              : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isInverted180 ? AppTheme.accentColor : Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.flip_camera_android, size: 14),
                            SizedBox(width: 4),
                            Text(
                              "Flip 180°",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Alignment Guidance Banner
          if (_hasSensor && _rawHeading != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isAligned
                    ? AppTheme.completedColor.withValues(alpha: 0.12)
                    : AppTheme.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isAligned ? AppTheme.completedColor : AppTheme.accentColor,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAligned ? Icons.check_circle : (deltaAngle > 0 ? Icons.rotate_right : Icons.rotate_left),
                    color: isAligned ? AppTheme.completedColor : AppTheme.accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAligned
                        ? "Aligned with Kaaba!"
                        : (deltaAngle > 0
                            ? "Turn ${deltaAngle.abs().toStringAsFixed(0)}° Right ↻"
                            : "Turn ${deltaAngle.abs().toStringAsFixed(0)}° Left ↺"),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isAligned ? AppTheme.completedColor : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Compass display
          if (!_hasSensor)
            _buildNoSensorFallback(qiblaBearing)
          else
            _buildCompassVisual(dialTurns, pointerTurns, qiblaBearing, isAligned),

          const SizedBox(height: 32),

          // Technical Sensors Guidance Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.sensors, color: AppTheme.primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Sensor Calibration & Guidance",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTipItem("GPS Location provides your exact coordinates for calculating Qibla bearing."),
                _buildTipItem("Magnetometer + Accelerometer fuse to measure phone orientation & magnetic North."),
                _buildTipItem("If your phone sensor reads backwards, tap 'Flip 180°' above to reverse it."),
                _buildTipItem("Keep device flat in your palm away from metals, magnets, or computers."),
                _buildTipItem("Wave phone in a figure-eight (8) motion to calibrate magnetometer accuracy."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSensorFallback(double qiblaBearing) {
    return Container(
      height: 300,
      width: 300,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.missedColor.withValues(alpha: 0.2), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sensors_off_outlined,
              color: AppTheme.missedColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              "No Compass Sensor",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your device or emulator has no magnetometer sensor. Set phone to point to ${qiblaBearing.toStringAsFixed(0)}° relative to True North.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassVisual(double dialTurns, double pointerTurns, double qiblaBearing, bool isAligned) {
    // Qibla angle on dial ring in radians
    final double qiblaOnDialRad = qiblaBearing * (pi / 180.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow/ring that lights up green when aligned
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAligned
                ? AppTheme.completedColor.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border.all(
              color: isAligned
                  ? AppTheme.completedColor
                  : Theme.of(context).dividerColor.withValues(alpha: 0.1),
              width: isAligned ? 4.0 : 1.5,
            ),
            boxShadow: isAligned
                ? [
                    BoxShadow(
                      color: AppTheme.completedColor.withValues(alpha: 0.2),
                      blurRadius: 28,
                      spreadRadius: 6,
                    )
                  ]
                : null,
          ),
        ),

        // Compass Dial (Rotates smoothly with heading)
        AnimatedRotation(
          turns: dialTurns,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 270,
            height: 270,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardTheme.color,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cardinal direction indicators
                Positioned(
                  top: 12,
                  child: Text(
                    "N",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  child: Text(
                    "S",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  child: Text(
                    "W",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  child: Text(
                    "E",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),

                // Qibla Marker on the Dial Ring (Fixed at qiblaBearing relative to N)
                Transform.rotate(
                  angle: qiblaOnDialRad,
                  child: SizedBox(
                    width: 270,
                    height: 270,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: const Text(
                              "🕋 KAABA",
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Inner ring
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Qibla Pointer Needle (Rotates smoothly to point towards Qibla relative to phone top)
        AnimatedRotation(
          turns: pointerTurns,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: 270,
            height: 270,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pointer Needle Arrow pointing UP towards Qibla
                Positioned(
                  top: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isAligned ? AppTheme.completedColor : AppTheme.accentColor).withValues(alpha: 0.4),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.navigation,
                      color: isAligned ? AppTheme.completedColor : AppTheme.accentColor,
                      size: 38,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Center Hub
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAligned ? AppTheme.completedColor : AppTheme.accentColor,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
