class LabModel {
  const LabModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.rating,
    required this.reviewsCount,
    required this.workingHours,
    required this.homeVisitAvailable,
    required this.resultsTurnaround,
    required this.address,
    required this.city,
    this.governorate = 'الدقهلية',
    required this.latitude,
    required this.longitude,
    required this.isAccredited,
    this.tests = const [],
  });

  final String id;
  final String name;
  final String tagline;
  final double rating;
  final int reviewsCount;
  final String workingHours;
  final bool homeVisitAvailable;
  final String resultsTurnaround;
  final String address;
  final String city;
  final String governorate;
  final double latitude;
  final double longitude;
  final bool isAccredited;
  final List<LabTestModel> tests;

  LabModel copyWith({List<LabTestModel>? tests}) {
    return LabModel(
      id: id,
      name: name,
      tagline: tagline,
      rating: rating,
      reviewsCount: reviewsCount,
      workingHours: workingHours,
      homeVisitAvailable: homeVisitAvailable,
      resultsTurnaround: resultsTurnaround,
      address: address,
      city: city,
      latitude: latitude,
      longitude: longitude,
      isAccredited: isAccredited,
      tests: tests ?? this.tests,
    );
  }

  factory LabModel.fromJson(Map<String, dynamic> json) {
    final testsJson = json['lab_tests'] as List<dynamic>?;
    return LabModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      tagline: json['tagline']?.toString() ?? 'تحاليل دقيقة ورعاية تطمئنك',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 200,
      workingHours: json['working_hours']?.toString() ?? '8 ص - 10 م',
      homeVisitAvailable: json['home_visit_available'] != false,
      resultsTurnaround:
          json['results_turnaround']?.toString() ?? 'خلال 24 ساعة',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? 'المنصورة، مصر',
      governorate: json['governorate']?.toString() ?? 'الدقهلية',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 31.0425,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 31.3640,
      isAccredited: json['is_accredited'] != false,
      tests: testsJson != null
          ? testsJson
              .map((e) => LabTestModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}

class LabTestModel {
  const LabTestModel({
    required this.id,
    required this.labId,
    required this.name,
    required this.shortName,
    required this.category,
    required this.price,
    required this.prepNotes,
    required this.iconType,
    required this.isPopular,
  });

  final String id;
  final String labId;
  final String name;
  final String shortName;
  final String category;
  final int price;
  final String prepNotes;
  final String iconType;
  final bool isPopular;

  factory LabTestModel.fromJson(Map<String, dynamic> json) {
    return LabTestModel(
      id: json['id']?.toString() ?? '',
      labId: json['lab_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shortName: json['short_name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'الأكثر طلباً',
      price: (json['price'] as num?)?.toInt() ?? 180,
      prepNotes: json['prep_notes']?.toString() ??
          'صورة الدم الكاملة لا تتطلب صياماً عادةً.',
      iconType: json['icon_type']?.toString() ?? 'blood',
      isPopular: json['is_popular'] == true,
    );
  }
}
