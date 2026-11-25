class DoctorModel {
  const DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.specialtyCategory,
    required this.bio,
    required this.experienceYears,
    required this.rating,
    required this.reviewsCount,
    required this.consultationFee,
    required this.waitTimeMinutes,
    required this.hospitalName,
    required this.city,
    this.governorate = 'الدقهلية',
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.photoUrl,
    required this.isFeatured,
    required this.availableSlots,
  });

  final String id;
  final String name;
  final String specialty;
  final String specialtyCategory;
  final String bio;
  final int experienceYears;
  final double rating;
  final int reviewsCount;
  final int consultationFee;
  final int waitTimeMinutes;
  final String hospitalName;
  final String city;
  final String governorate;
  final String address;
  final double latitude;
  final double longitude;
  final String photoUrl;
  final bool isFeatured;
  final List<String> availableSlots;

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final slotsRaw = json['available_slots'];
    final slots = slotsRaw is List
        ? slotsRaw.map((e) => e.toString()).toList()
        : const ['5:00 م', '5:30 م', '6:00 م', '6:30 م', '7:00 م', '7:30 م'];

    return DoctorModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? '',
      specialtyCategory: json['specialty_category']?.toString() ?? 'باطنة',
      bio: json['bio']?.toString() ?? '',
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 10,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 100,
      consultationFee: (json['consultation_fee'] as num?)?.toInt() ?? 250,
      waitTimeMinutes: (json['wait_time_minutes'] as num?)?.toInt() ?? 15,
      hospitalName: json['hospital_name']?.toString() ?? 'مستشفى السلام',
      city: json['city']?.toString() ?? 'المنصورة',
      governorate: json['governorate']?.toString() ??
          json['city']?.toString() ??
          'الدقهلية',
      address: json['address']?.toString() ?? 'شارع الجمهورية، المنصورة',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 31.0419,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 31.3785,
      photoUrl: json['photo_url']?.toString() ?? '',
      isFeatured: json['is_featured'] == true,
      availableSlots: slots,
    );
  }
}
