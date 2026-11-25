class BookingModel {
  const BookingModel({
    required this.id,
    required this.referenceCode,
    required this.bookingType, // doctor | lab | radiology
    required this.providerId,
    required this.providerName,
    required this.providerSubtitle,
    this.providerImageUrl,
    required this.serviceTitle,
    required this.locationText,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.patientName,
    required this.patientPhone,
    required this.paymentMethod,
    required this.price,
    this.bookingFee = 0,
    required this.status, // confirmed | scheduled | completed | cancelled
    this.notes,
  });

  final String id;
  final String referenceCode;
  final String bookingType;
  final String providerId;
  final String providerName;
  final String providerSubtitle;
  final String? providerImageUrl;
  final String serviceTitle;
  final String locationText;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String patientName;
  final String patientPhone;
  final String paymentMethod;
  final int price;
  final int bookingFee;
  final String status;
  final String? notes;

  bool get isUpcoming => status == 'confirmed' || status == 'scheduled';

  String get arabicStatus {
    switch (status) {
      case 'confirmed':
        return 'مؤكد';
      case 'scheduled':
        return 'مجدول';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'مؤكد';
    }
  }

  BookingModel copyWith({
    DateTime? appointmentDate,
    String? appointmentTime,
    String? status,
    String? patientName,
    String? patientPhone,
  }) {
    return BookingModel(
      id: id,
      referenceCode: referenceCode,
      bookingType: bookingType,
      providerId: providerId,
      providerName: providerName,
      providerSubtitle: providerSubtitle,
      providerImageUrl: providerImageUrl,
      serviceTitle: serviceTitle,
      locationText: locationText,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      paymentMethod: paymentMethod,
      price: price,
      bookingFee: bookingFee,
      status: status ?? this.status,
      notes: notes,
    );
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final parsedDate = DateTime.tryParse(
          json['appointment_date']?.toString() ?? '',
        ) ??
        DateTime.now();
    return BookingModel(
      id: json['id']?.toString() ?? '',
      referenceCode: json['reference_code']?.toString() ?? '#DOC-0000',
      bookingType: json['booking_type']?.toString() ?? 'doctor',
      providerId: json['provider_id']?.toString() ?? '',
      providerName: json['provider_name']?.toString() ?? '',
      providerSubtitle: json['provider_subtitle']?.toString() ?? '',
      providerImageUrl: json['provider_image_url']?.toString(),
      serviceTitle: json['service_title']?.toString() ?? '',
      locationText: json['location_text']?.toString() ?? 'المنصورة، مصر',
      appointmentDate: parsedDate,
      appointmentTime: json['appointment_time']?.toString() ?? '05:00 مساءً',
      patientName: json['patient_name']?.toString() ?? 'سارة محمد',
      patientPhone: json['patient_phone']?.toString() ?? '01012345678',
      paymentMethod:
          json['payment_method']?.toString() ?? 'الدفع نقداً في العيادة',
      price: (json['price'] as num?)?.toInt() ?? 250,
      bookingFee: (json['booking_fee'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'confirmed',
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toInsertJson(String userId) {
    final y = appointmentDate.year.toString().padLeft(4, '0');
    final m = appointmentDate.month.toString().padLeft(2, '0');
    final d = appointmentDate.day.toString().padLeft(2, '0');
    return {
      'user_id': userId,
      'reference_code': referenceCode,
      'booking_type': bookingType,
      'provider_id': providerId.isEmpty ? null : providerId,
      'provider_name': providerName,
      'provider_subtitle': providerSubtitle,
      'provider_image_url': providerImageUrl,
      'service_title': serviceTitle,
      'location_text': locationText,
      'appointment_date': '$y-$m-$d',
      'appointment_time': appointmentTime,
      'patient_name': patientName,
      'patient_phone': patientPhone,
      'payment_method': paymentMethod,
      'price': price,
      'booking_fee': bookingFee,
      'status': status,
      'notes': notes,
    };
  }
}

/// Draft payload passed between Details -> Select Date/Time -> Confirm -> Success.
class BookingDraft {
  const BookingDraft({
    required this.bookingType,
    required this.providerId,
    required this.providerName,
    required this.providerSubtitle,
    this.providerImageUrl,
    required this.serviceTitle,
    required this.locationText,
    required this.address,
    required this.price,
    required this.paymentMethod,
    this.availableSlots = const [
      '5:00 م',
      '5:30 م',
      '6:00 م',
      '6:30 م',
      '7:00 م',
      '7:30 م',
    ],
    this.selectedDate,
    this.selectedTime,
    this.rescheduleBookingId,
  });

  final String bookingType; // doctor | lab | radiology
  final String providerId;
  final String providerName;
  final String providerSubtitle;
  final String? providerImageUrl;
  final String serviceTitle;
  final String locationText;
  final String address;
  final int price;
  final String paymentMethod;
  final List<String> availableSlots;
  final DateTime? selectedDate;
  final String? selectedTime;
  final String? rescheduleBookingId;

  BookingDraft copyWith({
    DateTime? selectedDate,
    String? selectedTime,
  }) {
    return BookingDraft(
      bookingType: bookingType,
      providerId: providerId,
      providerName: providerName,
      providerSubtitle: providerSubtitle,
      providerImageUrl: providerImageUrl,
      serviceTitle: serviceTitle,
      locationText: locationText,
      address: address,
      price: price,
      paymentMethod: paymentMethod,
      availableSlots: availableSlots,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      rescheduleBookingId: rescheduleBookingId,
    );
  }
}
