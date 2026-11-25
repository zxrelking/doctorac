class PharmacyModel {
  const PharmacyModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.tagline,
    required this.storefrontUrl,
    required this.rating,
    required this.reviewsCount,
    required this.distanceKm,
    required this.isOpen24h,
    required this.isOpenNow,
    required this.deliveryAvailable,
    required this.deliveryFee,
    required this.deliveryTimeText,
    required this.address,
    required this.city,
    this.governorate = 'الدقهلية',
    required this.latitude,
    required this.longitude,
    required this.phone,
  });

  final String id;
  final String name;
  final String shortName;
  final String tagline;
  final String storefrontUrl;
  final double rating;
  final int reviewsCount;
  final double distanceKm;
  final bool isOpen24h;
  final bool isOpenNow;
  final bool deliveryAvailable;
  final int deliveryFee;
  final String deliveryTimeText;
  final String address;
  final String city;
  final String governorate;
  final double latitude;
  final double longitude;
  final String phone;

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shortName: json['short_name']?.toString() ?? '',
      tagline: json['tagline']?.toString() ?? 'أدويتك ورعايتك أقرب إليك',
      storefrontUrl: json['storefront_url']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 96,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 1.2,
      isOpen24h: json['is_open_24h'] == true,
      isOpenNow: json['is_open_now'] != false,
      deliveryAvailable: json['delivery_available'] != false,
      deliveryFee: (json['delivery_fee'] as num?)?.toInt() ?? 20,
      deliveryTimeText:
          json['delivery_time_text']?.toString() ?? '30-45 دقيقة',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? 'المنصورة، مصر',
      governorate: json['governorate']?.toString() ?? 'الدقهلية',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 31.0442,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 31.3587,
      phone: json['phone']?.toString() ?? '19600',
    );
  }
}
