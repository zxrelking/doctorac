import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../core/location/egypt_governorates.dart';
import '../domain/map_place_model.dart';

/// Free zero-API-key road routing via public OSRM server.
class OsrmRoutingService {
  static const String _baseUrl =
      'https://router.project-osrm.org/route/v1/driving';

  Future<ActiveRouteModel> fetchRoute({
    required LatLng origin,
    required MapPlaceModel destination,
  }) async {
    final dest = destination.latLng;
    final url = Uri.parse(
      '$_baseUrl/${origin.longitude},${origin.latitude};'
      '${dest.longitude},${dest.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(
        url,
        headers: const {'User-Agent': 'DoctoracApp/1.0 (io.doctorac.doctorac)'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final first = routes.first as Map<String, dynamic>;
          final distanceMeters = (first['distance'] as num?)?.toDouble() ?? 0;
          final durationSeconds = (first['duration'] as num?)?.toDouble() ?? 0;
          final geometry = first['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List<dynamic>? ?? [];

          final points = coords.map((pair) {
            final list = pair as List<dynamic>;
            return LatLng(
              (list[1] as num).toDouble(),
              (list[0] as num).toDouble(),
            );
          }).toList();

          if (points.length >= 2) {
            return ActiveRouteModel(
              destination: destination,
              polylinePoints: points,
              distanceKm: distanceMeters / 1000.0,
              durationMinutes: (durationSeconds / 60.0).ceil().clamp(1, 999),
            );
          }
        }
      }
    } catch (_) {
      // Fallback smoothly below if OSRM is temporarily unreachable
    }

    // Graceful fallback: direct line with estimated driving duration (~30 km/h city avg)
    final directKm = EgyptGovernorates.distanceKm(
      origin.latitude,
      origin.longitude,
      dest.latitude,
      dest.longitude,
    );
    final estMinutes = ((directKm / 28.0) * 60.0).ceil().clamp(2, 180);
    return ActiveRouteModel(
      destination: destination,
      polylinePoints: [origin, dest],
      distanceKm: directKm,
      durationMinutes: estMinutes,
    );
  }
}
