import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/location/egypt_governorates.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/maps_launcher.dart';
import '../../domain/map_place_model.dart';
import '../providers/map_provider.dart';
import '../widgets/map_place_bottom_sheet.dart';

class NearbyMapScreen extends ConsumerStatefulWidget {
  const NearbyMapScreen({super.key});

  @override
  ConsumerState<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends ConsumerState<NearbyMapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _pulseController;

  StreamSubscription<Position>? _positionSub;
  LatLng _livePosition = const LatLng(31.0409, 31.3785); // Initial fallback
  bool _hasGpsFix = false;
  bool _followUser = true;
  bool _gpsBlocked = false;
  String? _gpsStatusMessage;

  MapPlaceCategory? _selectedCategory; // null = الكل
  ActiveRouteModel? _activeRoute;
  bool _loadingRoute = false;
  DateTime _lastRouteRefresh = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    final savedLoc = ref.read(userLocationProvider);
    _livePosition = LatLng(savedLoc.latitude, savedLoc.longitude);
    _startLiveTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _startLiveTracking() async {
    setState(() {
      _gpsBlocked = false;
      _gpsStatusMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _gpsBlocked = true;
          _gpsStatusMessage = 'خدمة الموقع (GPS) مغلقة. فعّلها لتتبع موقعك المباشر.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _gpsBlocked = true;
          _gpsStatusMessage =
              'يرجى منح صلاحية الموقع (GPS) لعرض الأماكن الطبية القريبة منك.';
        });
        return;
      }

      // Immediate initial fix
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        _onNewPosition(pos, recenterNow: true);
      } catch (_) {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          _onNewPosition(last, recenterNow: true);
        }
      }

      // Continuous live GPS stream as the user moves
      await _positionSub?.cancel();
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (pos) => _onNewPosition(pos),
        onError: (_) {},
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gpsBlocked = true;
        _gpsStatusMessage = 'تعذر الاتصال بخدمة GPS حالياً.';
      });
    }
  }

  void _onNewPosition(Position pos, {bool recenterNow = false}) {
    if (!mounted) return;
    final next = LatLng(pos.latitude, pos.longitude);
    setState(() {
      _livePosition = next;
      _hasGpsFix = true;
      _gpsBlocked = false;
      _gpsStatusMessage = null;
    });

    if (_followUser || recenterNow) {
      try {
        _mapController.move(next, _mapController.camera.zoom.clamp(13.5, 17.0));
      } catch (_) {}
    }

    // Dynamically keep the blue route updated as the user moves (throttled every 12s)
    final route = _activeRoute;
    if (route != null &&
        DateTime.now().difference(_lastRouteRefresh).inSeconds >= 12) {
      _lastRouteRefresh = DateTime.now();
      _fetchAndDrawRoute(route.destination, fitBounds: false);
    }
  }

  Future<void> _fetchAndDrawRoute(
    MapPlaceModel destination, {
    bool fitBounds = true,
  }) async {
    setState(() {
      _loadingRoute = true;
      _followUser = false;
    });
    try {
      final route = await ref.read(osrmRoutingServiceProvider).fetchRoute(
            origin: _livePosition,
            destination: destination,
          );
      if (!mounted) return;
      setState(() {
        _activeRoute = route;
        _loadingRoute = false;
        _lastRouteRefresh = DateTime.now();
      });

      if (fitBounds && route.polylinePoints.length >= 2) {
        final bounds = LatLngBounds.fromPoints([
          _livePosition,
          destination.latLng,
          ...route.polylinePoints,
        ]);
        try {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.fromLTRB(48, 150, 48, 170),
            ),
          );
        } catch (_) {}
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRoute = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حساب المسار حالياً، حاول مرة أخرى.')),
      );
    }
  }

  void _clearRoute() {
    setState(() {
      _activeRoute = null;
      _followUser = true;
    });
    _recenterOnUser();
  }

  void _recenterOnUser() {
    setState(() => _followUser = true);
    try {
      _mapController.move(_livePosition, 15.0);
    } catch (_) {}
    if (!_hasGpsFix) {
      _startLiveTracking();
    }
  }

  void _openPlaceSheet(MapPlaceModel place) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MapPlaceBottomSheet(
        place: place,
        userPosition: _livePosition,
        onShowRoute: () => _fetchAndDrawRoute(place, fitBounds: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allPlaces = ref.watch(nearbyMapPlacesProvider(_livePosition));
    final visiblePlaces = _selectedCategory == null
        ? allPlaces
        : allPlaces.where((p) => p.category == _selectedCategory).toList();

    // Live remaining distance along active route
    final activeRoute = _activeRoute;
    final liveRemainingKm = activeRoute == null
        ? null
        : EgyptGovernorates.distanceKm(
            _livePosition.latitude,
            _livePosition.longitude,
            activeRoute.destination.latitude,
            activeRoute.destination.longitude,
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Interactive Free OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _livePosition,
              initialZoom: 14.2,
              minZoom: 5.5,
              maxZoom: 18.5,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && _followUser) {
                  setState(() => _followUser = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'io.doctorac.doctorac',
              ),

              // Blue In-App Navigation Route Polyline
              if (activeRoute != null)
                PolylineLayer(
                  polylines: [
                    // Outer deep blue stroke for road contrast
                    Polyline(
                      points: activeRoute.polylinePoints,
                      strokeWidth: 8.5,
                      color: const Color(0xFF1565C0).withValues(alpha: 0.35),
                    ),
                    // Primary vivid blue route polyline
                    Polyline(
                      points: activeRoute.polylinePoints,
                      strokeWidth: 5.2,
                      color: const Color(0xFF1E88E5),
                    ),
                  ],
                ),

              // Nearby Place Markers + Pulsing Blue Live User Marker
              MarkerLayer(
                markers: [
                  ...visiblePlaces.map(
                    (place) => Marker(
                      point: place.latLng,
                      width: 148,
                      height: 70,
                      alignment: Alignment.topCenter,
                      child: _PlaceMapMarker(
                        place: place,
                        isDestination: activeRoute?.destination.id == place.id,
                        onTap: () => _openPlaceSheet(place),
                      ),
                    ),
                  ),
                  // User's Live Pulsing Blue Dot Marker
                  Marker(
                    point: _livePosition,
                    width: 60,
                    height: 60,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) {
                        final t = _pulseController.value;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 18 + (38 * t),
                              height: 18 + (38 * t),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1E88E5)
                                    .withValues(alpha: (1 - t) * 0.38),
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E88E5),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x551E88E5),
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Top Overlay: Header + Filter Chips + Optional GPS Warning
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Floating Title Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: AppColors.mintSurface,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'الخريطة المباشرة القريبة منك',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                _hasGpsFix
                                    ? 'تتبع GPS مباشر • اضغط على أي مكان للحجز أو الطلب'
                                    : 'جاري قراءة موقعك عبر GPS...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick Filter Chips (الكل | المستشفيات | الصيدليات | الأطباء)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _MapFilterChip(
                          label: 'الكل',
                          icon: Icons.layers_outlined,
                          selected: _selectedCategory == null,
                          onTap: () => setState(() => _selectedCategory = null),
                        ),
                        const SizedBox(width: 8),
                        _MapFilterChip(
                          label: 'المستشفيات',
                          icon: Icons.local_hospital_outlined,
                          selected:
                              _selectedCategory == MapPlaceCategory.hospital,
                          onTap: () => setState(
                            () =>
                                _selectedCategory = MapPlaceCategory.hospital,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MapFilterChip(
                          label: 'الصيدليات',
                          icon: Icons.medication_outlined,
                          selected:
                              _selectedCategory == MapPlaceCategory.pharmacy,
                          onTap: () => setState(
                            () =>
                                _selectedCategory = MapPlaceCategory.pharmacy,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MapFilterChip(
                          label: 'الأطباء',
                          icon: Icons.medical_services_outlined,
                          selected:
                              _selectedCategory == MapPlaceCategory.doctor,
                          onTap: () => setState(
                            () => _selectedCategory = MapPlaceCategory.doctor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Graceful GPS Disabled / Permission Denied Banner
                  if (_gpsBlocked && _gpsStatusMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.gps_off_rounded,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _gpsStatusMessage!,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await Geolocator.openLocationSettings();
                              if (mounted) _startLiveTracking();
                            },
                            child: const Text(
                              'تفعيل',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 3. Loading Route Pill
          if (_loadingRoute)
            const Center(
              child: Card(
                color: Colors.white,
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'جاري رسم المسار...',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Active In-App Navigation Route Banner (with Distance, ETA & Clear Route)
          if (activeRoute != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.35),
                    width: 1.3,
                  ),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.directions_rounded,
                        color: Color(0xFF1E88E5),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            activeRoute.destination.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(liveRemainingKm ?? activeRoute.distanceKm).toStringAsFixed(1)} كم  •  حوالي ${activeRoute.durationMinutes} دقيقة',
                            style: const TextStyle(
                              color: Color(0xFF1E88E5),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'فتح في خرائط جوجل',
                      onPressed: () =>
                          ExternalLauncher.openGoogleMapsDirections(
                        context: context,
                        destinationLat: activeRoute.destination.latitude,
                        destinationLng: activeRoute.destination.longitude,
                      ),
                      icon: const Icon(
                        Icons.open_in_new_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearRoute,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.dangerBg,
                        foregroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'مسح المسار',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Floating "Re-center on Me" Button
          PositionedDirectional(
            end: 16,
            bottom: activeRoute != null ? 104 : 20,
            child: FloatingActionButton(
              heroTag: 'recenter_map_fab',
              onPressed: _recenterOnUser,
              backgroundColor: _followUser ? AppColors.primary : Colors.white,
              foregroundColor: _followUser ? Colors.white : AppColors.primary,
              elevation: 4,
              tooltip: 'إعادة التمركز على موقعي',
              child: const Icon(Icons.my_location_rounded, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapFilterChip extends StatelessWidget {
  const _MapFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: 1.2,
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceMapMarker extends StatelessWidget {
  const _PlaceMapMarker({
    required this.place,
    required this.isDestination,
    required this.onTap,
  });

  final MapPlaceModel place;
  final bool isDestination;
  final VoidCallback onTap;

  Color get _pinColor {
    if (isDestination) return const Color(0xFF1E88E5);
    switch (place.category) {
      case MapPlaceCategory.hospital:
        return AppColors.danger;
      case MapPlaceCategory.pharmacy:
        return AppColors.primary;
      case MapPlaceCategory.doctor:
        return const Color(0xFF0E7C7B);
    }
  }

  IconData get _pinIcon {
    switch (place.category) {
      case MapPlaceCategory.hospital:
        return Icons.local_hospital_rounded;
      case MapPlaceCategory.pharmacy:
        return Icons.medication_rounded;
      case MapPlaceCategory.doctor:
        return Icons.medical_services_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Place Name Label Pill above marker
          Container(
            constraints: const BoxConstraints(maxWidth: 142),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _pinColor.withValues(alpha: 0.45),
                width: 1.1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              place.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 3),
          // Custom Medical Pin Circle
          Container(
            width: isDestination ? 38 : 34,
            height: isDestination ? 38 : 34,
            decoration: BoxDecoration(
              color: _pinColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x38000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(_pinIcon, color: Colors.white, size: 17),
          ),
        ],
      ),
    );
  }
}
