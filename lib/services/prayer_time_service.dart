import 'package:adhan/adhan.dart';

class PrayerTimeService {
  PrayerTimes calculatePrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required String method,
    required String asrMethod,
  }) {
    final coordinates = Coordinates(latitude, longitude);
    final dateComponents = DateComponents.from(date);
    
    final params = _getParams(method);
    params.madhab = asrMethod.toUpperCase() == 'HANAFI' ? Madhab.hanafi : Madhab.shafi;

    return PrayerTimes(coordinates, dateComponents, params);
  }

  CalculationParameters _getParams(String method) {
    switch (method.toUpperCase()) {
      case 'MWL':
      case 'MUSLIM_WORLD_LEAGUE':
        return CalculationMethod.muslim_world_league.getParameters();
      case 'KARACHI':
        return CalculationMethod.karachi.getParameters();
      case 'EGYPTIAN':
        return CalculationMethod.egyptian.getParameters();
      case 'ISNA':
      case 'NORTH_AMERICA':
        return CalculationMethod.north_america.getParameters();
      case 'UMM_AL_QURA':
        return CalculationMethod.umm_al_qura.getParameters();
      case 'DUBAI':
        return CalculationMethod.dubai.getParameters();
      case 'KUWAIT':
        return CalculationMethod.kuwait.getParameters();
      case 'QATAR':
        return CalculationMethod.qatar.getParameters();
      case 'SINGAPORE':
        return CalculationMethod.singapore.getParameters();
      case 'TURKEY':
        return CalculationMethod.turkey.getParameters();
      case 'TEHRAN':
        return CalculationMethod.tehran.getParameters();
      default:
        return CalculationMethod.muslim_world_league.getParameters();
    }
  }

  // Get map of prayer times for a date
  Map<String, DateTime> getPrayerTimesMap({
    required double latitude,
    required double longitude,
    required DateTime date,
    required String method,
    required String asrMethod,
  }) {
    final times = calculatePrayerTimes(
      latitude: latitude,
      longitude: longitude,
      date: date,
      method: method,
      asrMethod: asrMethod,
    );

    return {
      'Fajr': times.fajr,
      'Dhuhr': times.dhuhr,
      'Asr': times.asr,
      'Maghrib': times.maghrib,
      'Isha': times.isha,
    };
  }
}
