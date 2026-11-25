import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/location/egypt_governorates.dart';
import '../../../doctors/domain/doctor_model.dart';
import '../../../doctors/presentation/providers/doctors_provider.dart';
import '../../../pharmacies/domain/pharmacy_model.dart';
import '../../../pharmacies/presentation/providers/pharmacies_provider.dart';
import '../../data/routing_service.dart';
import '../../domain/map_place_model.dart';

final osrmRoutingServiceProvider = Provider<OsrmRoutingService>((ref) {
  return OsrmRoutingService();
});

const List<MapServiceItem> _defaultPharmacyProducts = [
  MapServiceItem(
    id: 'prod_panadol',
    name: 'بنادول إكسترا (24 قرص)',
    subtitle: 'مسكن سريع وخافض للحرارة',
    price: 55,
  ),
  MapServiceItem(
    id: 'prod_vitc',
    name: 'فيتامين سي 1000 مجم فوار',
    subtitle: 'دعم المناعة اليومي',
    price: 75,
  ),
  MapServiceItem(
    id: 'prod_augmentin',
    name: 'أوجمنتين 1 جم (14 قرص)',
    subtitle: 'مضاد حيوي واسع المجال',
    price: 145,
  ),
  MapServiceItem(
    id: 'prod_vitd',
    name: 'فيتامين د3 5000 وحدة',
    subtitle: 'لصحة العظام والمناعة',
    price: 120,
  ),
  MapServiceItem(
    id: 'prod_omeprazole',
    name: 'أوميبرازول 20 مجم',
    subtitle: 'لعلاج الحموضة وقرحة المعدة',
    price: 65,
  ),
  MapServiceItem(
    id: 'prod_firstaid',
    name: 'مطهر بيتادين + شاش طبي معقم',
    subtitle: 'مستلزمات إسعافات أولية',
    price: 85,
  ),
];

const List<MapServiceItem> _defaultHospitalServices = [
  MapServiceItem(
    id: 'srv_er',
    name: 'كشف طوارئ واستقبال فوري',
    subtitle: 'متاح 24 ساعة',
    price: 200,
  ),
  MapServiceItem(
    id: 'srv_internal',
    name: 'كشف عيادة الباطنة والقلب',
    subtitle: 'مع استشاري متخصص',
    price: 300,
  ),
  MapServiceItem(
    id: 'srv_ecg',
    name: 'رسم قلب (ECG) وفحص شامل',
    subtitle: 'تقرير فوري',
    price: 250,
  ),
  MapServiceItem(
    id: 'srv_pediatric',
    name: 'عيادة طب الأطفال',
    subtitle: 'فحص ومتابعة',
    price: 260,
  ),
];

/// Builds all map places from Supabase Doctors & Pharmacies + Hospitals,
/// and guarantees rich nearby Hospitals, Pharmacies & Doctors within 0.5–3 km
/// around the user's live GPS location for seamless real-world & demo testing.
List<MapPlaceModel> buildNearbyMapPlaces({
  required LatLng userPosition,
  required List<DoctorModel> doctors,
  required List<PharmacyModel> pharmacies,
}) {
  final places = <MapPlaceModel>[];

  // 1. Add real Doctors from Supabase
  for (final doc in doctors) {
    places.add(
      MapPlaceModel(
        id: 'doc_${doc.id}',
        databaseUuid: doc.id,
        name: doc.name,
        subtitle: doc.specialty,
        category: MapPlaceCategory.doctor,
        rating: doc.rating,
        reviewsCount: doc.reviewsCount,
        address: doc.address,
        latitude: doc.latitude,
        longitude: doc.longitude,
        imageUrl: doc.photoUrl,
        consultationFee: doc.consultationFee,
        availableSlots: doc.availableSlots,
        services: [
          MapServiceItem(
            id: 'consult_${doc.id}',
            name: 'كشف ${doc.specialtyCategory}',
            subtitle: doc.hospitalName,
            price: doc.consultationFee,
          ),
          MapServiceItem(
            id: 'followup_${doc.id}',
            name: 'استشارة ومتابعة',
            subtitle: 'مراجعة الفحوصات والتحاليل',
            price: (doc.consultationFee * 0.6).round(),
          ),
        ],
      ),
    );
  }

  // 2. Add real Pharmacies from Supabase
  for (final ph in pharmacies) {
    places.add(
      MapPlaceModel(
        id: 'ph_${ph.id}',
        databaseUuid: ph.id,
        name: ph.name,
        subtitle: ph.isOpen24h ? 'مفتوحة 24 ساعة • توصيل سريع' : ph.tagline,
        category: MapPlaceCategory.pharmacy,
        rating: ph.rating,
        reviewsCount: ph.reviewsCount,
        address: ph.address,
        latitude: ph.latitude,
        longitude: ph.longitude,
        imageUrl: ph.storefrontUrl,
        phone: ph.phone,
        deliveryFee: ph.deliveryFee,
        products: _defaultPharmacyProducts,
      ),
    );
  }

  // 3. Extract distinct Hospitals from existing doctors data
  final seenHospitals = <String>{};
  for (final doc in doctors) {
    final hospKey = '${doc.hospitalName}_${doc.city}';
    if (seenHospitals.add(hospKey) &&
        (doc.hospitalName.contains('مستشفى') ||
            doc.hospitalName.contains('مركز'))) {
      places.add(
        MapPlaceModel(
          id: 'hosp_${doc.id}',
          databaseUuid: null,
          name: doc.hospitalName,
          subtitle: 'مستشفى تخصصي • طوارئ 24 ساعة',
          category: MapPlaceCategory.hospital,
          rating: doc.rating,
          reviewsCount: doc.reviewsCount + 45,
          address: doc.address,
          latitude: doc.latitude + 0.0025,
          longitude: doc.longitude - 0.0025,
          consultationFee: 250,
          services: _defaultHospitalServices,
        ),
      );
    }
  }

  // 4. Demo-Ready Smart Nearby Fallback:
  // Ensure at least 2 Hospitals, 2 Pharmacies, and 2 Doctors exist within 0.5–3 km
  // of the user's actual live GPS location so nearby places always appear around them.
  int countNear(MapPlaceCategory cat) => places.where((p) {
        if (p.category != cat) return false;
        final d = EgyptGovernorates.distanceKm(
          userPosition.latitude,
          userPosition.longitude,
          p.latitude,
          p.longitude,
        );
        return d <= 5.0;
      }).length;

  final lat = userPosition.latitude;
  final lng = userPosition.longitude;

  if (countNear(MapPlaceCategory.hospital) < 2) {
    places.addAll([
      MapPlaceModel(
        id: 'nearby_hosp_1',
        name: 'مستشفى السلام التخصصي',
        subtitle: 'طوارئ 24 ساعة • جميع التخصصات',
        category: MapPlaceCategory.hospital,
        rating: 4.9,
        reviewsCount: 318,
        address: 'بالقرب من موقعك الحالي (على بُعد أقل من 1 كم)',
        latitude: lat + 0.0068,
        longitude: lng + 0.0052,
        consultationFee: 250,
        services: _defaultHospitalServices,
      ),
      MapPlaceModel(
        id: 'nearby_hosp_2',
        name: 'مستشفى دار الشفاء الدولي',
        subtitle: 'رعاية طبية متكاملة وعيادات خارجية',
        category: MapPlaceCategory.hospital,
        rating: 4.8,
        reviewsCount: 245,
        address: 'بالقرب من موقعك الحالي',
        latitude: lat - 0.0115,
        longitude: lng + 0.0085,
        consultationFee: 300,
        services: _defaultHospitalServices,
      ),
    ]);
  }

  if (countNear(MapPlaceCategory.pharmacy) < 2) {
    places.addAll([
      MapPlaceModel(
        id: 'nearby_ph_1',
        name: 'صيدلية العزبي القريبة',
        subtitle: 'مفتوحة 24 ساعة • توصيل خلال 25 دقيقة',
        category: MapPlaceCategory.pharmacy,
        rating: 4.9,
        reviewsCount: 412,
        address: 'الشارع الرئيسي بالقرب من موقعك الحالي',
        latitude: lat + 0.0045,
        longitude: lng - 0.0062,
        deliveryFee: 20,
        products: _defaultPharmacyProducts,
      ),
      MapPlaceModel(
        id: 'nearby_ph_2',
        name: 'صيدلية العائلة الصحية',
        subtitle: 'أدوية ومستلزمات طبية • توصيل منزلي',
        category: MapPlaceCategory.pharmacy,
        rating: 4.8,
        reviewsCount: 196,
        address: 'بالقرب من موقعك الحالي',
        latitude: lat - 0.0072,
        longitude: lng - 0.0091,
        deliveryFee: 15,
        products: _defaultPharmacyProducts,
      ),
    ]);
  }

  if (countNear(MapPlaceCategory.doctor) < 2) {
    final sampleDoc1 = doctors.isNotEmpty ? doctors.first : null;
    final sampleDoc2 = doctors.length > 1 ? doctors[1] : sampleDoc1;
    places.addAll([
      MapPlaceModel(
        id: 'nearby_doc_1',
        databaseUuid: sampleDoc1?.id,
        name: sampleDoc1?.name ?? 'د. أحمد حسن',
        subtitle: sampleDoc1?.specialty ?? 'أخصائي قلب وأوعية دموية',
        category: MapPlaceCategory.doctor,
        rating: sampleDoc1?.rating ?? 4.9,
        reviewsCount: sampleDoc1?.reviewsCount ?? 128,
        address: 'عيادات دكتوراك القريبة من موقعك',
        latitude: lat + 0.0092,
        longitude: lng - 0.0041,
        imageUrl: sampleDoc1?.photoUrl,
        consultationFee: sampleDoc1?.consultationFee ?? 250,
        availableSlots: sampleDoc1?.availableSlots ??
            const ['5:00 م', '5:30 م', '6:00 م', '6:30 م', '7:00 م', '7:30 م'],
        services: [
          MapServiceItem(
            id: 'nearby_srv_1',
            name: 'كشف ${sampleDoc1?.specialtyCategory ?? "قلب وأوعية"}',
            subtitle: 'كشف عيادة شامل',
            price: sampleDoc1?.consultationFee ?? 250,
          ),
          const MapServiceItem(
            id: 'nearby_srv_2',
            name: 'متابعة واستشارة سريعة',
            subtitle: 'مراجعة الفحوصات',
            price: 150,
          ),
        ],
      ),
      MapPlaceModel(
        id: 'nearby_doc_2',
        databaseUuid: sampleDoc2?.id,
        name: sampleDoc2?.name ?? 'د. محمد علي',
        subtitle: sampleDoc2?.specialty ?? 'أخصائي باطنة',
        category: MapPlaceCategory.doctor,
        rating: sampleDoc2?.rating ?? 4.8,
        reviewsCount: sampleDoc2?.reviewsCount ?? 114,
        address: 'برج الأطباء بالقرب من موقعك',
        latitude: lat - 0.0055,
        longitude: lng + 0.0110,
        imageUrl: sampleDoc2?.photoUrl,
        consultationFee: sampleDoc2?.consultationFee ?? 200,
        availableSlots: sampleDoc2?.availableSlots ??
            const ['4:00 م', '4:30 م', '5:00 م', '6:00 م', '6:30 م', '7:00 م'],
        services: [
          MapServiceItem(
            id: 'nearby_srv_3',
            name: 'كشف ${sampleDoc2?.specialtyCategory ?? "باطنة"}',
            subtitle: 'كشف عيادة شامل',
            price: sampleDoc2?.consultationFee ?? 200,
          ),
          const MapServiceItem(
            id: 'nearby_srv_4',
            name: 'متابعة واستشارة سريعة',
            subtitle: 'مراجعة التحاليل',
            price: 120,
          ),
        ],
      ),
    ]);
  }

  return places;
}

final nearbyMapPlacesProvider =
    Provider.family<List<MapPlaceModel>, LatLng>((ref, userPos) {
  final doctors = ref.watch(doctorsListProvider).valueOrNull ?? const [];
  final pharmacies = ref.watch(pharmaciesListProvider).valueOrNull ?? const [];
  return buildNearbyMapPlaces(
    userPosition: userPos,
    doctors: doctors,
    pharmacies: pharmacies,
  );
});
