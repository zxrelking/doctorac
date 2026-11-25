import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/location/egypt_governorates.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_date_formatter.dart';
import '../../../../core/utils/maps_launcher.dart';
import '../../../../core/widgets/cached_image_box.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../bookings/domain/booking_model.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';
import '../../../orders/domain/order_model.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/map_place_model.dart';

class MapPlaceBottomSheet extends ConsumerStatefulWidget {
  const MapPlaceBottomSheet({
    super.key,
    required this.place,
    required this.userPosition,
    required this.onShowRoute,
  });

  final MapPlaceModel place;
  final LatLng userPosition;
  final VoidCallback onShowRoute;

  @override
  ConsumerState<MapPlaceBottomSheet> createState() =>
      _MapPlaceBottomSheetState();
}

class _MapPlaceBottomSheetState extends ConsumerState<MapPlaceBottomSheet> {
  // Doctor / Hospital booking selection
  int _selectedServiceIndex = 0;
  int _selectedDayOffset = 0; // 0 = اليوم, 1 = غداً
  late String _selectedSlot;

  // Pharmacy cart quantities (productId -> quantity)
  final Map<String, int> _cart = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.place.availableSlots.isNotEmpty
        ? widget.place.availableSlots.first
        : '5:00 م';
    if (widget.place.category == MapPlaceCategory.pharmacy &&
        widget.place.products.isNotEmpty) {
      _cart[widget.place.products.first.id] = 1;
    }
  }

  Color get _badgeBg {
    switch (widget.place.category) {
      case MapPlaceCategory.hospital:
        return AppColors.dangerBg;
      case MapPlaceCategory.pharmacy:
        return AppColors.mintSurface;
      case MapPlaceCategory.doctor:
        return const Color(0xFFE6F4F1);
    }
  }

  Color get _badgeFg {
    switch (widget.place.category) {
      case MapPlaceCategory.hospital:
        return AppColors.danger;
      case MapPlaceCategory.pharmacy:
        return AppColors.primary;
      case MapPlaceCategory.doctor:
        return AppColors.primaryDark;
    }
  }

  IconData get _categoryIcon {
    switch (widget.place.category) {
      case MapPlaceCategory.hospital:
        return Icons.local_hospital_rounded;
      case MapPlaceCategory.pharmacy:
        return Icons.medication_rounded;
      case MapPlaceCategory.doctor:
        return Icons.medical_services_rounded;
    }
  }

  int get _pharmacySubtotal {
    int sum = 0;
    for (final p in widget.place.products) {
      final qty = _cart[p.id] ?? 0;
      sum += p.price * qty;
    }
    return sum;
  }

  int get _pharmacyItemCount =>
      _cart.values.fold<int>(0, (prev, qty) => prev + qty);

  Future<void> _submitAppointment() async {
    setState(() => _isSubmitting = true);
    try {
      final place = widget.place;
      final profile = ref.read(profileProvider).valueOrNull;
      final service = place.services.isNotEmpty
          ? place.services[_selectedServiceIndex]
          : MapServiceItem(
              id: 'default',
              name: 'كشف طبي',
              price: place.consultationFee,
            );

      final apptDate = DateTime.now().add(Duration(days: _selectedDayOffset));
      final isHospital = place.category == MapPlaceCategory.hospital;
      final refCode = ArabicDateFormatter.generateBookingRef(
        prefix: isHospital ? 'HSP' : 'DOC',
        date: apptDate,
      );

      final booking = BookingModel(
        id: 'map-bk-${DateTime.now().millisecondsSinceEpoch}',
        referenceCode: '#$refCode',
        bookingType: isHospital ? 'hospital' : 'doctor',
        providerId: place.databaseUuid ?? '',
        providerName: place.name,
        providerSubtitle: '${service.name} • ${place.subtitle}',
        providerImageUrl: place.imageUrl,
        serviceTitle: service.name,
        locationText: place.address,
        appointmentDate: apptDate,
        appointmentTime: ArabicDateFormatter.expandPeriod(_selectedSlot),
        patientName: (profile?.fullName ?? '').trim().isNotEmpty
            ? profile!.fullName
            : (profile?.email ?? 'مستخدم دكتوراك'),
        patientPhone: (profile?.phone ?? '').trim(),
        paymentMethod: isHospital
            ? 'الدفع نقداً في المستشفى'
            : 'الدفع نقداً في العيادة',
        price: service.price,
        status: 'confirmed',
      );

      await ref.read(bookingsProvider.notifier).addBooking(booking);

      if (!mounted) return;
      final router = GoRouter.of(context);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Text('تم حجز موعدك في ${place.name} بنجاح (#$refCode)'),
          action: SnackBarAction(
            label: 'مواعيدي',
            textColor: AppColors.primaryLight,
            onPressed: () => router.go('/bookings'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('تسجيل الدخول')
                ? 'يرجى تسجيل الدخول أولاً لإتمام الحجز.'
                : 'تعذر إتمام الحجز حالياً، يرجى المحاولة مرة أخرى.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitPharmacyOrder() async {
    if (_pharmacyItemCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار منتج واحد على الأقل للطلب.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final place = widget.place;
      final profile = ref.read(profileProvider).valueOrNull;
      final loc = ref.read(userLocationProvider);
      final now = DateTime.now();
      final refCode =
          '#ORD-${1000 + (now.millisecondsSinceEpoch % 8999)}';

      final selectedSummaries = <String>[];
      for (final p in place.products) {
        final qty = _cart[p.id] ?? 0;
        if (qty > 0) {
          selectedSummaries.add(qty > 1 ? '${p.name} (×$qty)' : p.name);
        }
      }

      final deliveryAddr = (profile?.address ?? '').trim().isNotEmpty
          ? profile!.address
          : (loc.detailedAddress ?? loc.displayLabel);

      final order = OrderModel(
        id: 'map-ord-${now.millisecondsSinceEpoch}',
        referenceCode: refCode,
        orderType: 'pharmacy',
        providerId: place.databaseUuid ?? '',
        providerName: place.name,
        providerSubtitle: 'طلب مباشر من الخريطة • توصيل سريع',
        itemsSummary: selectedSummaries.join(' + '),
        totalPrice: _pharmacySubtotal + place.deliveryFee,
        status: 'on_the_way',
        deliveryAddress: deliveryAddr,
        orderDateText:
            'اليوم، ${now.day} ${ArabicDateFormatter.months[now.month - 1]}',
      );

      await ref.read(ordersProvider.notifier).createOrder(order);

      if (!mounted) return;
      final router = GoRouter.of(context);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Text('تم إرسال طلبك من ${place.name} بنجاح ($refCode)'),
          action: SnackBarAction(
            label: 'طلباتي',
            textColor: AppColors.primaryLight,
            onPressed: () => router.go('/orders'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('تسجيل الدخول')
                ? 'يرجى تسجيل الدخول أولاً لإرسال الطلب.'
                : 'تعذر إرسال الطلب حالياً، يرجى المحاولة مرة أخرى.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final distanceKm = EgyptGovernorates.distanceKm(
      widget.userPosition.latitude,
      widget.userPosition.longitude,
      place.latitude,
      place.longitude,
    );
    final isPharmacy = place.category == MapPlaceCategory.pharmacy;

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    // 1. Header Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (place.imageUrl != null &&
                                  place.imageUrl!.isNotEmpty)
                                CachedImageBox(
                                  imageUrl: place.imageUrl,
                                  width: 62,
                                  height: 62,
                                  borderRadius: 16,
                                  fallbackIcon: _categoryIcon,
                                )
                              else
                                Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    color: _badgeBg,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    _categoryIcon,
                                    color: _badgeFg,
                                    size: 30,
                                  ),
                                ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _badgeBg,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            place.category.arabicLabel,
                                            style: TextStyle(
                                              color: _badgeFg,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.star_rounded,
                                          color: AppColors.starAmber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${place.rating.toStringAsFixed(1)} (${place.reviewsCount})',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      place.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 17.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      place.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    place.address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.mintSurface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${distanceKm.toStringAsFixed(1)} كم',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 2. Two Side-by-Side Navigation Buttons
                    Row(
                      children: [
                        // Button 1: Show Route / Go (In-App Blue Polyline)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onShowRoute();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              icon: const Icon(
                                Icons.directions_rounded,
                                size: 20,
                              ),
                              label: const Text(
                                'عرض المسار / انطلق',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Button 2: Open in Google Maps
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  ExternalLauncher.openGoogleMapsDirections(
                                context: context,
                                destinationLat: place.latitude,
                                destinationLng: place.longitude,
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.mintBorder,
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              icon: const Icon(Icons.map_outlined, size: 19),
                              label: const Text(
                                'خرائط جوجل',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // 3. Direct Booking (Doctor/Hospital) OR Buying (Pharmacy)
                    if (isPharmacy)
                      _buildPharmacyOrderSection(place)
                    else
                      _buildBookingSection(place),
                  ],
                ),
              ),

              // Sticky Action Footer inside Bottom Sheet
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: AppColors.divider),
                  ),
                  boxShadow: AppColors.bottomBarShadow,
                ),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPharmacy
                              ? '${_pharmacySubtotal + (_pharmacyItemCount > 0 ? place.deliveryFee : 0)} جنيه'
                              : '${place.services.isNotEmpty ? place.services[_selectedServiceIndex].price : place.consultationFee} جنيه',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          isPharmacy
                              ? 'شامل توصيل ${place.deliveryFee} جنيه'
                              : (_selectedDayOffset == 0
                                  ? 'اليوم • $_selectedSlot'
                                  : 'غداً • $_selectedSlot'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SolidTealButton(
                        label: isPharmacy ? 'اطلب واشترِ الآن' : 'حجز موعد الآن',
                        isLoading: _isSubmitting,
                        height: 50,
                        borderRadius: 16,
                        onPressed: isPharmacy
                            ? _submitPharmacyOrder
                            : _submitAppointment,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingSection(MapPlaceModel place) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر الخدمة',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(place.services.length, (i) {
          final srv = place.services[i];
          final selected = i == _selectedServiceIndex;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedServiceIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.mintSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            srv.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (srv.subtitle.isNotEmpty)
                            Text(
                              srv.subtitle,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${srv.price} جنيه',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'اختر الموعد المناسب',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Row(
              children: [
                _MiniDayChip(
                  label: 'اليوم',
                  selected: _selectedDayOffset == 0,
                  onTap: () => setState(() => _selectedDayOffset = 0),
                ),
                const SizedBox(width: 8),
                _MiniDayChip(
                  label: 'غداً',
                  selected: _selectedDayOffset == 1,
                  onTap: () => setState(() => _selectedDayOffset = 1),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: place.availableSlots.map((slot) {
            final selected = slot == _selectedSlot;
            return GestureDetector(
              onTap: () => setState(() => _selectedSlot = slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  slot,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPharmacyOrderSection(MapPlaceModel place) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'الأدوية والمنتجات المتاحة',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_pharmacyItemCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mintSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_pharmacyItemCount أصناف',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ...place.products.map((prod) {
          final qty = _cart[prod.id] ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: qty > 0 ? AppColors.mintSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: qty > 0 ? AppColors.mintBorder : AppColors.cardBorder,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prod.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (prod.subtitle.isNotEmpty)
                        Text(
                          prod.subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${prod.price} جنيه',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    if (qty > 0) ...[
                      _QtyButton(
                        icon: Icons.remove_rounded,
                        onTap: () => setState(() {
                          if (qty <= 1) {
                            _cart.remove(prod.id);
                          } else {
                            _cart[prod.id] = qty - 1;
                          }
                        }),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$qty',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    _QtyButton(
                      icon: Icons.add_rounded,
                      filled: true,
                      onTap: () => setState(() => _cart[prod.id] = qty + 1),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _MiniDayChip extends StatelessWidget {
  const _MiniDayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.mintChipActive : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: filled ? AppColors.primary : AppColors.mintBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: filled ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }
}
