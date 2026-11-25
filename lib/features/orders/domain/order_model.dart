class OrderModel {
  const OrderModel({
    required this.id,
    required this.referenceCode,
    required this.orderType, // pharmacy | lab | radiology
    required this.providerId,
    required this.providerName,
    required this.providerSubtitle,
    required this.itemsSummary,
    required this.totalPrice,
    required this.status, // on_the_way | processing | result_ready | delivered | cancelled
    this.prescriptionUrl,
    this.resultFileUrl,
    required this.deliveryAddress,
    required this.orderDateText,
  });

  final String id;
  final String referenceCode;
  final String orderType;
  final String providerId;
  final String providerName;
  final String providerSubtitle;
  final String itemsSummary;
  final int totalPrice;
  final String status;
  final String? prescriptionUrl;
  final String? resultFileUrl;
  final String deliveryAddress;
  final String orderDateText;

  bool get isCancellable => status == 'on_the_way' || status == 'processing';

  OrderModel copyWith({String? status}) {
    return OrderModel(
      id: id,
      referenceCode: referenceCode,
      orderType: orderType,
      providerId: providerId,
      providerName: providerName,
      providerSubtitle: providerSubtitle,
      itemsSummary: itemsSummary,
      totalPrice: totalPrice,
      status: status ?? this.status,
      prescriptionUrl: prescriptionUrl,
      resultFileUrl: resultFileUrl,
      deliveryAddress: deliveryAddress,
      orderDateText: orderDateText,
    );
  }

  String get arabicStatus {
    switch (status) {
      case 'on_the_way':
        return 'في الطريق';
      case 'processing':
        return 'قيد التجهيز';
      case 'result_ready':
        return 'النتيجة جاهزة';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'قيد التجهيز';
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
      referenceCode: json['reference_code']?.toString() ?? '#ORD-5021',
      orderType: json['order_type']?.toString() ?? 'pharmacy',
      providerId: json['provider_id']?.toString() ?? '',
      providerName: json['provider_name']?.toString() ?? '',
      providerSubtitle: json['provider_subtitle']?.toString() ?? '',
      itemsSummary: json['items_summary']?.toString() ?? '',
      totalPrice: (json['total_price'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'on_the_way',
      prescriptionUrl: json['prescription_url']?.toString(),
      resultFileUrl: json['result_file_url']?.toString(),
      deliveryAddress:
          json['delivery_address']?.toString() ?? 'المنصورة، مصر',
      orderDateText: json['order_date_text']?.toString() ?? 'اليوم',
    );
  }

  Map<String, dynamic> toInsertJson(String userId) {
    return {
      'user_id': userId,
      'reference_code': referenceCode,
      'order_type': orderType,
      'provider_id': providerId.isEmpty ? null : providerId,
      'provider_name': providerName,
      'provider_subtitle': providerSubtitle,
      'items_summary': itemsSummary,
      'total_price': totalPrice,
      'status': status,
      'prescription_url': prescriptionUrl,
      'result_file_url': resultFileUrl,
      'delivery_address': deliveryAddress,
      'order_date_text': orderDateText,
    };
  }
}
