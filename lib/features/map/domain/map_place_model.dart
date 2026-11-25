import 'package:latlong2/latlong.dart';

enum MapPlaceCategory { hospital, pharmacy, doctor }

extension MapPlaceCategoryExt on MapPlaceCategory {
  String get arabicLabel {
    switch (this) {
      case MapPlaceCategory.hospital:
        return 'مستشفى';
      case MapPlaceCategory.pharmacy:
        return 'صيدلية';
      case MapPlaceCategory.doctor:
        return 'طبيب';
    }
  }

  String get pluralLabel {
    switch (this) {
      case MapPlaceCategory.hospital:
        return 'المستشفيات';
      case MapPlaceCategory.pharmacy:
        return 'الصيدليات';
      case MapPlaceCategory.doctor:
        return 'الأطباء';
    }
  }
}

class MapServiceItem {
  const MapServiceItem({
    required this.id,
    required this.name,
    required this.price,
    this.subtitle = '',
  });

  final String id;
  final String name;
  final int price;
  final String subtitle;
}

class MapPlaceModel {
  const MapPlaceModel({
    required this.id,
    this.databaseUuid,
    required this.name,
    required this.subtitle,
    required this.category,
    required this.rating,
    required this.reviewsCount,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.phone = '19600',
    this.consultationFee = 250,
    this.deliveryFee = 20,
    this.availableSlots = const [
      '5:00 م',
      '5:30 م',
      '6:00 م',
      '6:30 م',
      '7:00 م',
      '7:30 م',
    ],
    this.services = const [],
    this.products = const [],
  });

  final String id;

  /// Valid PostgreSQL UUID if sourced from a DB row, otherwise null (safe for UUID FK columns).
  final String? databaseUuid;
  final String name;
  final String subtitle;
  final MapPlaceCategory category;
  final double rating;
  final int reviewsCount;
  final String address;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String phone;
  final int consultationFee;
  final int deliveryFee;
  final List<String> availableSlots;
  final List<MapServiceItem> services;
  final List<MapServiceItem> products;

  LatLng get latLng => LatLng(latitude, longitude);
}

class ActiveRouteModel {
  const ActiveRouteModel({
    required this.destination,
    required this.polylinePoints,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final MapPlaceModel destination;
  final List<LatLng> polylinePoints;
  final double distanceKm;
  final int durationMinutes;
}
