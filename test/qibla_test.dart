import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_companion/utils/calculations.dart';

void main() {
  group('GeographicCalculations - Qibla Direction', () {
    test('London Qibla bearing should be approx 118.9°', () {
      final bearing = GeographicCalculations.calculateQiblaDirection(51.5074, -0.1278);
      expect(bearing, closeTo(118.9, 0.5));
    });

    test('Karachi Qibla bearing should be approx 267.7°', () {
      final bearing = GeographicCalculations.calculateQiblaDirection(24.8607, 67.0011);
      expect(bearing, closeTo(267.7, 0.5));
    });

    test('Cairo Qibla bearing should be approx 136.2°', () {
      final bearing = GeographicCalculations.calculateQiblaDirection(30.0444, 31.2357);
      expect(bearing, closeTo(136.2, 0.5));
    });

    test('New York Qibla bearing should be approx 58.5°', () {
      final bearing = GeographicCalculations.calculateQiblaDirection(40.7128, -74.0060);
      expect(bearing, closeTo(58.5, 0.5));
    });

    test('Tokyo Qibla bearing should be approx 293.0°', () {
      final bearing = GeographicCalculations.calculateQiblaDirection(35.6762, 139.6503);
      expect(bearing, closeTo(293.0, 0.5));
    });

    test('At Kaaba Qibla bearing should return 0.0°', () {
      final bearing = GeographicCalculations.calculateQiblaDirection(21.4225, 39.8262);
      expect(bearing, equals(0.0));
    });
  });
}
