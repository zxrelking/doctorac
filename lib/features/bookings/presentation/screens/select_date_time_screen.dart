import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_date_formatter.dart';
import '../../../../core/widgets/cached_image_box.dart';
import '../../../../core/widgets/doctorac_headers.dart';
import '../../../../core/widgets/sticky_bottom_bar.dart';
import '../../domain/booking_model.dart';
import '../providers/bookings_provider.dart';

class SelectDateTimeScreen extends ConsumerStatefulWidget {
  const SelectDateTimeScreen({super.key, required this.draft});

  final BookingDraft draft;

  @override
  ConsumerState<SelectDateTimeScreen> createState() =>
      _SelectDateTimeScreenState();
}

class _SelectDateTimeScreenState extends ConsumerState<SelectDateTimeScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late String _selectedSlot;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.draft.selectedDate ??
        DateTime.now().add(const Duration(days: 1));
    _focusedDay = initial;
    _selectedDay = initial;
    _selectedSlot = widget.draft.selectedTime ??
        (widget.draft.availableSlots.length > 3
            ? widget.draft.availableSlots[3]
            : widget.draft.availableSlots.first);
  }

  Future<void> _onContinue() async {
    // Reschedule existing booking flow
    if (widget.draft.rescheduleBookingId != null) {
      setState(() => _isSaving = true);
      try {
        await ref.read(bookingsProvider.notifier).rescheduleBooking(
              bookingId: widget.draft.rescheduleBookingId!,
              newDate: _selectedDay,
              newTime: ArabicDateFormatter.expandPeriod(_selectedSlot),
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعديل موعد الحجز بنجاح!')),
        );
        context.pop();
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
      return;
    }

    // Standard new booking flow -> Booking Confirmation
    final updatedDraft = widget.draft.copyWith(
      selectedDate: _selectedDay,
      selectedTime: _selectedSlot,
    );
    context.push('/booking/confirm', extra: updatedDraft);
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final isReschedule = draft.rescheduleBookingId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: StickyBottomActionBar(
        priceText: '${draft.price} جنيه',
        subtitleText: draft.bookingType == 'doctor'
            ? 'إجمالي الكشف'
            : draft.bookingType == 'lab'
                ? 'إجمالي التحليل'
                : 'إجمالي الأشعة',
        primaryLabel: isReschedule ? 'تأكيد إعادة الجدولة' : 'متابعة',
        isLoading: _isSaving,
        onPressed: _onContinue,
      ),
      body: SafeArea(
        child: Column(
          children: [
            DoctoracDetailHeader(
              title: isReschedule ? 'إعادة جدولة الموعد' : 'اختيار الموعد',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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

                    const SizedBox(height: 18),

                    // Interactive Monthly Calendar Card
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'اختر يوم الزيارة',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Custom Month Header matching Figma
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => setState(() {
                                  _focusedDay = DateTime(
                                    _focusedDay.year,
                                    _focusedDay.month - 1,
                                  );
                                }),
                                icon: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              Text(
                                ArabicDateFormatter.monthYear(_focusedDay),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() {
                                  _focusedDay = DateTime(
                                    _focusedDay.year,
                                    _focusedDay.month + 1,
                                  );
                                }),
                                icon: const Icon(
                                  Icons.chevron_left_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TableCalendar(
                            firstDay: DateTime.now()
                                .subtract(const Duration(days: 1)),
                            lastDay: DateTime.now()
                                .add(const Duration(days: 365)),
                            focusedDay: _focusedDay,
                            startingDayOfWeek: StartingDayOfWeek.saturday,
                            headerVisible: false,
                            daysOfWeekHeight: 28,
                            rowHeight: 42,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            onDaySelected: (selected, focused) {
                              setState(() {
                                _selectedDay = selected;
                                _focusedDay = focused;
                              });
                            },
                            onPageChanged: (focused) {
                              setState(() => _focusedDay = focused);
                            },
                            calendarBuilders: CalendarBuilders(
                              dowBuilder: (context, day) {
                                final label = ArabicDateFormatter
                                    .shortWeekdays[day.weekday - 1];
                                return Center(
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                              selectedBuilder: (context, day, _) => Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              todayBuilder: (context, day, _) => Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.mintSurface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ),
                            calendarStyle: const CalendarStyle(
                              outsideDaysVisible: false,
                              defaultTextStyle: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                              weekendTextStyle: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                              disabledTextStyle: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Time Slots Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'المواعيد المتاحة',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          ArabicDateFormatter.weekdayDayMonth(_selectedDay),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3x2 Time Slot Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: draft.availableSlots.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.25,
                      ),
                      itemBuilder: (context, index) {
                        final slot = draft.availableSlots[index];
                        final selected = slot == _selectedSlot;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSlot = slot),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color:
                                  selected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.cardBorder,
                                width: 1.2,
                              ),
                              boxShadow: selected ? null : AppColors.softShadow,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              slot,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // 15-min Early Arrival Notice Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.mintSurface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'يرجى الحضور قبل الموعد بـ 15 دقيقة',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'يمكنك تعديل الموعد من صفحة حجوزاتي.',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
