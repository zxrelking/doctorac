import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'egypt_governorates.dart';

class UserLocationState {
  const UserLocationState({
    required this.governorate,
    required this.displayLabel,
    required this.latitude,
    required this.longitude,
    this.detailedAddress,
    this.isGpsDetected = false,
    this.isDetecting = false,
    this.errorMessage,
  });

  final String governorate; // e.g. 'كل مصر', 'القاهرة', 'الدقهلية'...
  final String displayLabel; // e.g. 'المعادي، القاهرة' or 'كل مصر'
  final double latitude;
  final double longitude;
  final String? detailedAddress;
  final bool isGpsDetected;
  final bool isDetecting;
  final String? errorMessage;

  bool get isAllEgypt => governorate == EgyptGovernorates.allEgyptName;

  UserLocationState copyWith({
    String? governorate,
    String? displayLabel,
    double? latitude,
    double? longitude,
    String? detailedAddress,
    bool? isGpsDetected,
    bool? isDetecting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UserLocationState(
      governorate: governorate ?? this.governorate,
      displayLabel: displayLabel ?? this.displayLabel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      detailedAddress: detailedAddress ?? this.detailedAddress,
      isGpsDetected: isGpsDetected ?? this.isGpsDetected,
      isDetecting: isDetecting ?? this.isDetecting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class UserLocationNotifier extends StateNotifier<UserLocationState> {
  UserLocationNotifier()
      : super(
          const UserLocationState(
            governorate: EgyptGovernorates.allEgyptName,
            displayLabel: 'كل مصر',
            latitude: 30.0444,
            longitude: 31.2357,
          ),
        );

  bool _hasAttemptedAutoDetect = false;

  Future<void> autoDetectOnce() async {
    if (_hasAttemptedAutoDetect) return;
    _hasAttemptedAutoDetect = true;
    await detectRealGpsLocation(silentIfDenied: true);
  }

  /// Requests real Android GPS location, reverse-geocodes to Arabic area/city,
  /// and matches to the user's exact Egyptian Governorate.
  Future<bool> detectRealGpsLocation({bool silentIfDenied = false}) async {
    state = state.copyWith(isDetecting: true, clearError: true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isDetecting: false,
          errorMessage: silentIfDenied
              ? null
              : 'يرجى تفعيل خدمة الموقع (GPS) على هاتفك أولاً.',
        );
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isDetecting: false,
          errorMessage: silentIfDenied
              ? null
              : 'لم يتم منح صلاحية الموقع. يمكنك تفعيلها من إعدادات الهاتف أو اختيار محافظتك يدوياً.',
        );
        return false;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        state = state.copyWith(
          isDetecting: false,
          errorMessage: silentIfDenied
              ? null
              : 'تعذر قراءة موقعك الحالي عبر GPS. جرّب مرة أخرى أو اختر محافظتك.',
        );
        return false;
      }

      final lat = position.latitude;
      final lng = position.longitude;

      // Match nearest Egyptian governorate by real GPS coordinates
      final matchedGov = EgyptGovernorates.nearestGovernorate(lat, lng);
      String label = '${matchedGov.capital}، ${matchedGov.name}';
      String detailed = '${matchedGov.capital}، ${matchedGov.name}، مصر';

      // Reverse-geocode for real neighborhood / street / city name
      try {
        await setLocaleIdentifier('ar_EG');
        final placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
            if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
            if ((p.administrativeArea ?? '').trim().isNotEmpty)
              p.administrativeArea!.trim(),
          ];
          final unique = parts.toSet().toList();
          if (unique.isNotEmpty) {
            label = unique.take(2).join('، ');
            detailed = unique.join('، ');
          }
        }
      } catch (_) {
        // Keep exact matched Egyptian governorate label if Geocoder is offline
      }

      state = UserLocationState(
        governorate: matchedGov.name,
        displayLabel: label,
        latitude: lat,
        longitude: lng,
        detailedAddress: detailed,
        isGpsDetected: true,
        isDetecting: false,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isDetecting: false,
        errorMessage: silentIfDenied
            ? null
            : 'حدث خطأ أثناء تحديد موقعك الحالي.',
      );
      return false;
    }
  }

  void selectGovernorate(EgyptGovernorate gov) {
    state = UserLocationState(
      governorate: gov.name,
      displayLabel: gov.displayLabel,
      latitude: gov.latitude,
      longitude: gov.longitude,
      detailedAddress: gov.displayLabel,
      isGpsDetected: false,
      isDetecting: false,
    );
  }
}

final userLocationProvider =
    StateNotifierProvider<UserLocationNotifier, UserLocationState>((ref) {
  return UserLocationNotifier();
});
