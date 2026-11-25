import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_date_formatter.dart';
import '../../../../core/utils/maps_launcher.dart';
import '../../../../core/widgets/cached_image_box.dart';
import '../../../../core/widgets/doctorac_headers.dart';
import '../../../../core/widgets/sticky_bottom_bar.dart';
import '../../domain/booking_model.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key, required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: StickyBottomActionBar(
        primaryLabel: 'عرض حجوزاتي',
        fullWidthButton: true,
        onPressed: () => context.go('/bookings'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            DoctoracDetailHeader(
              title: 'تم الحجز بنجاح',
              onBack: () => context.go('/home'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Column(
                  children: [
                    // Green Checkmark Concentric Circle
                    Container(
                      width: 102,
                      height: 102,
                      decoration: const BoxDecoration(
                        color: AppColors.mintSurface,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'تم حجز موعدك بنجاح!',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'نتمنى لك زيارة مطمئنة وصحة دائمة.\nستصلك رسالة بتفاصيل الحجز على هاتفك.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.5,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reference & Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'رقم الحجز',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              booking.referenceCode,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(
                              color: AppColors.divider,
                              height: 1,
                            ),
                          ),
                          Row(
                            children: [
                              if (booking.providerImageUrl != null &&
                                  booking.providerImageUrl!.isNotEmpty)
                                CachedImageBox(
                                  imageUrl: booking.providerImageUrl,
                                  width: 52,
                                  height: 52,
                                  isCircle: true,
                                )
                              else
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.mintSurface,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    booking.bookingType == 'lab'
                                        ? Icons.science_outlined
                                        : Icons.biotech_outlined,
                                    color: AppColors.primary,
                                  ),
                                ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.providerName,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      booking.providerSubtitle,
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
                          const SizedBox(height: 16),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ArabicDateFormatter.fullArabicDate(
                                    booking.appointmentDate,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${booking.appointmentTime}  •  ${booking.paymentMethod}: ${booking.price} جنيه',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  booking.locationText,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // "+ إضافة الموعد إلى التقويم" Soft Mint Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            ExternalLauncher.addAppointmentToCalendar(
                          context: context,
                          title: 'موعد دكتوراك: ${booking.providerName}',
                          location: booking.locationText,
                          details:
                              'رقم الحجز: ${booking.referenceCode} - ${booking.serviceTitle}',
                          date: booking.appointmentDate,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mintSurface,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 22),
                        label: const Text(
                          'إضافة الموعد إلى التقويم',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: const Text(
                        'العودة للرئيسية',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
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
