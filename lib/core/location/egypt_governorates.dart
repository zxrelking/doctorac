import 'dart:math';

class EgyptGovernorate {
  const EgyptGovernorate({
    required this.name,
    required this.capital,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String capital;
  final double latitude;
  final double longitude;

  String get displayLabel => name == 'كل مصر' ? 'كل مصر' : '$name، مصر';
}

/// All 27 Egyptian Governorates + "كل مصر" (All Egypt) with exact coordinates
/// and Haversine real-world distance utilities.
class EgyptGovernorates {
  EgyptGovernorates._();

  static const String allEgyptName = 'كل مصر';

  static const EgyptGovernorate allEgypt = EgyptGovernorate(
    name: allEgyptName,
    capital: 'كل مصر',
    latitude: 30.0444,
    longitude: 31.2357,
  );

  static const List<EgyptGovernorate> all = [
    allEgypt,
    EgyptGovernorate(name: 'القاهرة', capital: 'القاهرة', latitude: 30.0444, longitude: 31.2357),
    EgyptGovernorate(name: 'الجيزة', capital: 'الجيزة', latitude: 30.0131, longitude: 31.2089),
    EgyptGovernorate(name: 'الإسكندرية', capital: 'الإسكندرية', latitude: 31.2001, longitude: 29.9187),
    EgyptGovernorate(name: 'الدقهلية', capital: 'المنصورة', latitude: 31.0409, longitude: 31.3785),
    EgyptGovernorate(name: 'الغربية', capital: 'طنطا', latitude: 30.7865, longitude: 31.0004),
    EgyptGovernorate(name: 'الشرقية', capital: 'الزقازيق', latitude: 30.5877, longitude: 31.5020),
    EgyptGovernorate(name: 'المنوفية', capital: 'شبين الكوم', latitude: 30.5586, longitude: 31.0118),
    EgyptGovernorate(name: 'القليوبية', capital: 'بنها', latitude: 30.4660, longitude: 31.1848),
    EgyptGovernorate(name: 'البحيرة', capital: 'دمنهور', latitude: 31.0364, longitude: 30.4682),
    EgyptGovernorate(name: 'كفر الشيخ', capital: 'كفر الشيخ', latitude: 31.1107, longitude: 30.9388),
    EgyptGovernorate(name: 'دمياط', capital: 'دمياط', latitude: 31.4175, longitude: 31.8144),
    EgyptGovernorate(name: 'بورسعيد', capital: 'بورسعيد', latitude: 31.2653, longitude: 32.3019),
    EgyptGovernorate(name: 'الإسماعيلية', capital: 'الإسماعيلية', latitude: 30.5965, longitude: 32.2715),
    EgyptGovernorate(name: 'السويس', capital: 'السويس', latitude: 29.9668, longitude: 32.5498),
    EgyptGovernorate(name: 'الفيوم', capital: 'الفيوم', latitude: 29.3084, longitude: 30.8428),
    EgyptGovernorate(name: 'بني سويف', capital: 'بني سويف', latitude: 29.0661, longitude: 31.0994),
    EgyptGovernorate(name: 'المنيا', capital: 'المنيا', latitude: 28.0871, longitude: 30.7618),
    EgyptGovernorate(name: 'أسيوط', capital: 'أسيوط', latitude: 27.1809, longitude: 31.1837),
    EgyptGovernorate(name: 'سوهاج', capital: 'سوهاج', latitude: 26.5569, longitude: 31.6948),
    EgyptGovernorate(name: 'قنا', capital: 'قنا', latitude: 26.1551, longitude: 32.7160),
    EgyptGovernorate(name: 'الأقصر', capital: 'الأقصر', latitude: 25.6872, longitude: 32.6396),
    EgyptGovernorate(name: 'أسوان', capital: 'أسوان', latitude: 24.0889, longitude: 32.8998),
    EgyptGovernorate(name: 'البحر الأحمر', capital: 'الغردقة', latitude: 27.2579, longitude: 33.8116),
    EgyptGovernorate(name: 'جنوب سيناء', capital: 'شرم الشيخ', latitude: 27.9158, longitude: 34.3299),
    EgyptGovernorate(name: 'شمال سيناء', capital: 'العريش', latitude: 31.1321, longitude: 33.8033),
    EgyptGovernorate(name: 'مطروح', capital: 'مرسى مطروح', latitude: 31.3543, longitude: 27.2373),
    EgyptGovernorate(name: 'الوادي الجديد', capital: 'الخارجة', latitude: 25.4390, longitude: 30.5586),
  ];

  /// Calculates real-world Haversine distance in kilometers between two GPS points.
  static double distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180.0);

  /// Finds the closest Egyptian governorate to the given GPS coordinates.
  static EgyptGovernorate nearestGovernorate(double lat, double lng) {
    EgyptGovernorate best = all[1]; // القاهرة fallback
    double bestDist = double.infinity;
    for (final gov in all.skip(1)) {
      final d = distanceKm(lat, lng, gov.latitude, gov.longitude);
      if (d < bestDist) {
        bestDist = d;
        best = gov;
      }
    }
    return best;
  }

  static EgyptGovernorate? findByName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final gov in all) {
      if (gov.name == name ||
          gov.capital == name ||
          name.contains(gov.name) ||
          name.contains(gov.capital)) {
        return gov;
      }
    }
    return null;
  }
}
