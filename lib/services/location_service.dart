import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationDetails {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String timezone;

  LocationDetails({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.timezone,
  });
}

class LocationService {
  /// Fetch current GPS location and resolve city/country names
  Future<LocationDetails> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled on your device.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied. Please enable them in system settings.');
    }

    // Get current position
    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );

    // Reverse geocode position to find city/country names
    String city = 'Unknown City';
    String country = 'Unknown Country';
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        city = placemark.locality ?? placemark.subAdministrativeArea ?? 'Unknown City';
        country = placemark.country ?? 'Unknown Country';
      }
    } catch (_) {
      // Graceful fallback for offline geocoding failure
    }

    // Guess timezone based on coordinates/country (simplified offline mapping)
    final timezone = _guessTimezone(position.latitude, position.longitude, country);

    return LocationDetails(
      latitude: position.latitude,
      longitude: position.longitude,
      city: city,
      country: country,
      timezone: timezone,
    );
  }

  /// List of major cities for manual selection when GPS is disabled
  static List<LocationDetails> getManualPresetCities() {
    return [
      LocationDetails(
        latitude: 21.3891,
        longitude: 39.8579,
        city: 'Mecca',
        country: 'Saudi Arabia',
        timezone: 'Asia/Riyadh',
      ),
      LocationDetails(
        latitude: 51.5074,
        longitude: -0.1278,
        city: 'London',
        country: 'United Kingdom',
        timezone: 'Europe/London',
      ),
      LocationDetails(
        latitude: 24.8607,
        longitude: 67.0011,
        city: 'Karachi',
        country: 'Pakistan',
        timezone: 'Asia/Karachi',
      ),
      LocationDetails(
        latitude: 30.0444,
        longitude: 31.2357,
        city: 'Cairo',
        country: 'Egypt',
        timezone: 'Africa/Cairo',
      ),
      LocationDetails(
        latitude: 40.7128,
        longitude: -74.0060,
        city: 'New York',
        country: 'United States',
        timezone: 'America/New_York',
      ),
      LocationDetails(
        latitude: 1.3521,
        longitude: 103.8198,
        city: 'Singapore',
        country: 'Singapore',
        timezone: 'Asia/Singapore',
      ),
      LocationDetails(
        latitude: 25.2048,
        longitude: 55.2708,
        city: 'Dubai',
        country: 'United Arab Emirates',
        timezone: 'Asia/Dubai',
      ),
      LocationDetails(
        latitude: -33.8688,
        longitude: 151.2093,
        city: 'Sydney',
        country: 'Australia',
        timezone: 'Australia/Sydney',
      ),
    ];
  }

  String _guessTimezone(double lat, double lng, String country) {
    // Basic approximate mapping for support
    if (country.toLowerCase().contains('pakistan')) return 'Asia/Karachi';
    if (country.toLowerCase().contains('saudi arabia')) return 'Asia/Riyadh';
    if (country.toLowerCase().contains('united kingdom')) return 'Europe/London';
    if (country.toLowerCase().contains('egypt')) return 'Africa/Cairo';
    if (country.toLowerCase().contains('united states') && lng < -100) return 'America/Los_Angeles';
    if (country.toLowerCase().contains('united states')) return 'America/New_York';
    if (country.toLowerCase().contains('singapore')) return 'Asia/Singapore';
    if (country.toLowerCase().contains('emirates') || country.toLowerCase().contains('dubai')) return 'Asia/Dubai';
    if (country.toLowerCase().contains('australia')) return 'Australia/Sydney';
    
    // Default fallback based on longitude
    final offsetHours = (lng / 15.0).round();
    if (offsetHours >= 0) {
      return "Etc/GMT-$offsetHours";
    } else {
      return "Etc/GMT+${offsetHours.abs()}";
    }
  }
}
