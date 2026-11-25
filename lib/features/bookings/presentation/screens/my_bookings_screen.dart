import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_date_formatter.dart';
import '../../../../core/widgets/cached_image_box.dart';
import '../../../../core/widgets/doctorac_headers.dart';
import '../../domain/booking_model.dart';
import '../providers/bookings_provider.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  String _selectedTab = 'القادمة'; // القادمة | السابقة

  void _showBookingDetails(BookingModel booking) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'تفاصيل الحجز',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      booking.referenceCode,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SheetRow(label: 'الخدمة', value: booking.providerName),
              _SheetRow(label: 'التخصص / الجهة', value: booking.providerSubtitle),
              _SheetRow(
                label: 'التاريخ',
                value: ArabicDateFormatter.fullArabicDate(
                  booking.appointmentDate,
                ),
              ),
              _SheetRow(label: 'الوقت', value: booking.appointmentTime),
              _SheetRow(label: 'العنوان', value: booking.locationText),
              _SheetRow(label: 'اسم المريض', value: booking.patientName),
              _SheetRow(label: 'طريقة الدفع', value: booking.paymentMethod),
              _SheetRow(label: 'الإجمالي', value: '${booking.price} جنيه'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('حسناً'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BookingModel booking) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'إلغاء الحجز',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'هل أنت متأكد من إلغاء حجز "${booking.providerName}" (${booking.referenceCode})؟',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، إلغاء الحجز'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await ref.read(bookingsProvider.notifier).cancelBooking(booking.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء الحجز بنجاح')),
      );
    }
  }

  void _reschedule(BookingModel booking) {
    final draft = BookingDraft(
      bookingType: booking.bookingType,
      providerId: booking.providerId,
      providerName: booking.providerName,
      providerSubtitle: booking.providerSubtitle,
      providerImageUrl: booking.providerImageUrl,
      serviceTitle: booking.serviceTitle,
      locationText: booking.locationText,
      address: booking.locationText,
      price: booking.price,
      paymentMethod: booking.paymentMethod,
      selectedDate: booking.appointmentDate,
      rescheduleBookingId: booking.id,
    );
    context.push('/booking/select-date-time', extra: draft);
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(bookingsProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DoctoracListHeader(
                        title: 'مواعيدي',
                        subtitle: 'تابع مواعيدك الطبية القادمة والسابقة.',
                        onBack: () => context.go('/home'),
                      ),
                      const SizedBox(height: 18),
                      // Filter Pills (القادمة | السابقة)
                      Row(
                        children: [
                          _FilterPill(
                            label: 'القادمة',
                            isSelected: _selectedTab == 'القادمة',
                            onTap: () =>
                                setState(() => _selectedTab = 'القادمة'),
                          ),
                          const SizedBox(width: 10),
                          _FilterPill(
                            label: 'السابقة',
                            isSelected: _selectedTab == 'السابقة',
                            onTap: () =>
                                setState(() => _selectedTab = 'السابقة'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              bookingsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (_, __) => const SliverFillRemaining(
                  child: Center(child: Text('تعذر تحميل المواعيد')),
                ),
                data: (bookings) {
                  final filtered = bookings.where((b) {
                    return _selectedTab == 'القادمة'
                        ? b.isUpcoming
                        : !b.isUpcoming;
                  }).toList();

                  if (filtered.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 46,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedTab == 'القادمة'
                                    ? 'لا توجد مواعيد قادمة حالياً'
                                    : 'لا توجد مواعيد سابقة حتى الآن',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        ...filtered.map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _BookingCard(
                              booking: b,
                              onDetails: () => _showBookingDetails(b),
                              onCancel: b.isUpcoming
                                  ? () => _confirmCancel(b)
                                  : null,
                              onSecondaryAction: b.isUpcoming
                                  ? ((b.bookingType == 'doctor' ||
                                          b.bookingType == 'hospital')
                                      ? () => _reschedule(b)
                                      : () => _confirmCancel(b))
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'كل تفاصيل زيارتك في مكان واحد، لصحة أفضل.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintChipActive : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? AppColors.mintBorder : AppColors.cardBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onDetails,
    this.onCancel,
    this.onSecondaryAction,
  });

  final BookingModel booking;
  final VoidCallback onDetails;
  final VoidCallback? onCancel;
  final VoidCallback? onSecondaryAction;

  Color get _statusBg {
    switch (booking.status) {
      case 'scheduled':
        return AppColors.scheduledBg;
      case 'cancelled':
        return AppColors.dangerBg;
      default:
        return AppColors.mintSurface;
    }
  }

  Color get _statusFg {
    switch (booking.status) {
      case 'scheduled':
        return AppColors.scheduledText;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = booking.bookingType == 'doctor';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status pill + Reference Code + Red X Cancel Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  booking.arabicStatus,
                  style: TextStyle(
                    color: _statusFg,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  booking.referenceCode,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onCancel != null) ...[
                const SizedBox(width: 10),
                Tooltip(
                  message: 'إلغاء الموعد',
                  child: InkWell(
                    onTap: onCancel,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.danger,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // Provider info row
          Row(
            children: [
              if (isDoctor &&
                  booking.providerImageUrl != null &&
                  booking.providerImageUrl!.isNotEmpty)
                CachedImageBox(
                  imageUrl: booking.providerImageUrl,
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
                  alignment: Alignment.center,
                  child: Icon(
                    booking.bookingType == 'hospital'
                        ? Icons.local_hospital_outlined
                        : booking.bookingType == 'lab'
                            ? Icons.science_outlined
                            : booking.bookingType == 'doctor'
                                ? Icons.medical_services_outlined
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
                      booking.providerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.providerSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      booking.locationText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Date & Time Mint Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.mintSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ArabicDateFormatter.weekdayDayMonth(
                      booking.appointmentDate,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 18,
                  color: AppColors.mintBorder,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                const Icon(
                  Icons.access_time_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  booking.appointmentTime,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Action Buttons Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mintSurface,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'تفاصيل الحجز',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              if (onSecondaryAction != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: onSecondaryAction,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                          color: AppColors.mintBorder,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isDoctor ? 'إعادة جدولة' : 'إلغاء',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
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
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
