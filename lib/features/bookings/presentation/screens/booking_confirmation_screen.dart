import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_date_formatter.dart';
import '../../../../core/widgets/cached_image_box.dart';
import '../../../../core/widgets/doctorac_headers.dart';
import '../../../../core/widgets/sticky_bottom_bar.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/booking_model.dart';
import '../providers/bookings_provider.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  const BookingConfirmationScreen({super.key, required this.draft});

  final BookingDraft draft;

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen> {
  String _patientName = '';
  String _patientPhone = '';
  bool _initializedFromProfile = false;
  bool _isSubmitting = false;

  void _syncFromProfile() {
    if (_initializedFromProfile) return;
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile != null && profile.id.isNotEmpty) {
      _patientName = profile.fullName.isNotEmpty
          ? profile.fullName
          : profile.email;
      _patientPhone = profile.phone;
      _initializedFromProfile = true;
    }
  }

  Future<void> _editPatientInfo() async {
    final nameCtrl = TextEditingController(text: _patientName);
    final phoneCtrl = TextEditingController(text: _patientPhone);

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'تعديل بيانات المريض',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم المريض',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (updated == true && mounted) {
      setState(() {
        if (nameCtrl.text.trim().isNotEmpty) {
          _patientName = nameCtrl.text.trim();
        }
        if (phoneCtrl.text.trim().isNotEmpty) {
          _patientPhone = phoneCtrl.text.trim();
        }
      });
    }
    nameCtrl.dispose();
    phoneCtrl.dispose();
  }

  Future<void> _confirmBooking() async {
    setState(() => _isSubmitting = true);
    try {
      final draft = widget.draft;
      final selectedDate = draft.selectedDate ?? DateTime.now();
      final prefix = draft.bookingType == 'doctor'
          ? 'DRC'
          : draft.bookingType == 'lab'
              ? 'LAB'
              : 'RAD';
      final refCode = ArabicDateFormatter.generateBookingRef(
        prefix: prefix,
        date: selectedDate,
      );

      final booking = BookingModel(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        referenceCode: refCode,
        bookingType: draft.bookingType,
        providerId: draft.providerId,
        providerName: draft.bookingType == 'doctor'
            ? draft.providerName
            : draft.serviceTitle,
        providerSubtitle: draft.bookingType == 'doctor'
            ? draft.providerSubtitle
            : draft.providerName,
        providerImageUrl: draft.providerImageUrl,
        serviceTitle: draft.serviceTitle,
        locationText: draft.address,
        appointmentDate: selectedDate,
        appointmentTime: ArabicDateFormatter.expandPeriod(
          draft.selectedTime ?? '6:30 م',
        ),
        patientName: _patientName,
        patientPhone: _patientPhone,
        paymentMethod: draft.paymentMethod,
        price: draft.price,
        bookingFee: 0,
        status: draft.bookingType == 'doctor' ? 'confirmed' : 'scheduled',
      );

      final created =
          await ref.read(bookingsProvider.notifier).addBooking(booking);

      if (!mounted) return;
      context.go('/booking/success', extra: created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تأكيد الحجز حالياً، يرجى المحاولة مرة أخرى.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncFromProfile();
    final draft = widget.draft;
    final selectedDate = draft.selectedDate ?? DateTime.now();
    final expandedTime =
        ArabicDateFormatter.expandPeriod(draft.selectedTime ?? '6:30 م');

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: StickyBottomActionBar(
        priceText: '${draft.price} جنيه',
        subtitleText: 'الإجمالي شامل الرسوم',
        primaryLabel: 'تأكيد الحجز',
        isLoading: _isSubmitting,
        onPressed: _confirmBooking,
      ),
      body: SafeArea(
        child: Column(
          children: [
            DoctoracDetailHeader(
              title: 'تأكيد الحجز',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Provider Summary Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Row(
                        children: [
                          if (draft.providerImageUrl != null &&
                              draft.providerImageUrl!.isNotEmpty)
                            CachedImageBox(
                              imageUrl: draft.providerImageUrl,
                              width: 56,
                              height: 56,
                              isCircle: true,
                            )
                          else
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.mintSurface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                draft.bookingType == 'lab'
                                    ? Icons.science_outlined
                                    : Icons.biotech_outlined,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  draft.providerName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  draft.providerSubtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Appointment Details Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تفاصيل الموعد',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _DetailRow(
                            label: 'التاريخ',
                            value: ArabicDateFormatter.fullArabicDate(
                              selectedDate,
                            ),
                            isBold: true,
                          ),
                          const SizedBox(height: 10),
                          _DetailRow(
                            label: 'الوقت',
                            value: expandedTime,
                          ),
                          const SizedBox(height: 10),
                          _DetailRow(
                            label: 'المكان',
                            value: draft.locationText,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Patient Info Card with "تعديل"
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'بيانات المريض',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              GestureDetector(
                                onTap: _editPatientInfo,
                                child: const Text(
                                  'تعديل',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _patientName.isNotEmpty
                                ? _patientName
                                : 'اضغط تعديل لإدخال اسم المريض',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _patientPhone.isNotEmpty
                                ? _patientPhone
                                : 'اضغط تعديل لإضافة رقم الهاتف',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment Method & Price Breakdown Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'طريقة الدفع',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mintSurface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.payments_outlined,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  draft.paymentMethod,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                draft.bookingType == 'doctor'
                                    ? 'سعر الكشف'
                                    : draft.bookingType == 'lab'
                                        ? 'سعر التحليل'
                                        : 'سعر الأشعة',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${draft.price} جنيه',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'رسوم الحجز',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'مجاناً',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Text(
                      'بتأكيد الحجز، أنت توافق على شروط الحجز\nوسياسة الإلغاء. لا يلزم الدفع الآن.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
