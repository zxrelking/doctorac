class RadiologyCenterModel {
  const RadiologyCenterModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.rating,
    required this.reviewsCount,
    required this.workingHours,
    required this.waitTimeText,
    required this.reportTurnaround,
    required this.address,
    required this.city,
    this.governorate = 'الدقهلية',
    required this.latitude,
    required this.longitude,
    required this.safetyWarning,
    this.scans = const [],
  });

  final String id;
  final String name;
  final String tagline;
  final double rating;
  final int reviewsCount;
  final String workingHours;
  final String waitTimeText;
  final String reportTurnaround;
  final String address;
  final String city;
  final String governorate;
  final double latitude;
  final double longitude;
  final String safetyWarning;
  final List<RadiologyScanModel> scans;

  RadiologyCenterModel copyWith({List<RadiologyScanModel>? scans}) {
    return RadiologyCenterModel(
      id: id,
      name: name,
      tagline: tagline,
      rating: rating,
      reviewsCount: reviewsCount,
      workingHours: workingHours,
      waitTimeText: waitTimeText,
      reportTurnaround: reportTurnaround,
      address: address,
      city: city,
      latitude: latitude,
      longitude: longitude,
      safetyWarning: safetyWarning,
      scans: scans ?? this.scans,
    );
  }

  factory RadiologyCenterModel.fromJson(Map<String, dynamic> json) {
    final scansJson = json['radiology_scans'] as List<dynamic>?;
    return RadiologyCenterModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      tagline: json['tagline']?.toString() ?? 'تشخيص أدق بأحدث أجهزة التصوير',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 175,
      workingHours: json['working_hours']?.toString() ?? '9 ص - 11 م',
      waitTimeText: json['wait_time_text']?.toString() ?? '20 دقيقة',
      reportTurnaround:
          json['report_turnaround']?.toString() ?? 'خلال 24 ساعة',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? 'المنصورة، مصر',
      governorate: json['governorate']?.toString() ?? 'الدقهلية',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 31.0418,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 31.3742,
      safetyWarning: json['safety_warning']?.toString() ??
          'أبلغ المركز عن أي أجهزة أو غرسات معدنية.',
      scans: scansJson != null
          ? scansJson
              .map(
                (e) => RadiologyScanModel.fromJson(e as Map<String, dynamic>),
              )
              .toList()
          : const [],
    );
  }
}

class RadiologyScanModel {
  const RadiologyScanModel({
    required this.id,
    required this.centerId,
    required this.name,
    required this.shortName,
    required this.scanType,
    required this.price,
    required this.safetyNotes,
  });

  final String id;
  final String centerId;
  final String name;
  final String shortName;
  final String scanType; // MRI | CT | X-Ray | Ultrasound
  final int price;
  final String safetyNotes;

  factory RadiologyScanModel.fromJson(Map<String, dynamic> json) {
    return RadiologyScanModel(
      id: json['id']?.toString() ?? '',
      centerId: json['center_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shortName: json['short_name']?.toString() ?? '',
      scanType: json['scan_type']?.toString() ?? 'MRI',
      price: (json['price'] as num?)?.toInt() ?? 650,
      safetyNotes: json['safety_notes']?.toString() ??
          'أبلغ المركز عن أي أجهزة أو غرسات معدنية.',
    );
  }
}
