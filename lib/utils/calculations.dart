import 'package:adhan/adhan.dart';

/// Utility class for geographic calculations related to prayer
class GeographicCalculations {
  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;

  /// Calculate the Qibla bearing (direction to Kaaba) in degrees from North [0, 360).
  static double calculateQiblaDirection(double latitude, double longitude) {
    // Edge case: if coordinates match Kaaba precisely
    if ((latitude - kaabaLatitude).abs() < 0.0001 &&
        (longitude - kaabaLongitude).abs() < 0.0001) {
      return 0.0;
    }

    final qibla = Qibla(Coordinates(latitude, longitude));
    final double direction = qibla.direction;
    return (direction % 360.0 + 360.0) % 360.0;
  }
}
