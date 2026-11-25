import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/maps_launcher.dart';
import '../../../../core/widgets/cached_image_box.dart';
import '../../../../core/widgets/doctorac_headers.dart';
import '../../../../core/widgets/map_preview_card.dart';
import '../../../../core/widgets/sticky_bottom_bar.dart';
import '../../../bookings/domain/booking_model.dart';
import '../providers/doctors_provider.dart';

class DoctorDetailsScreen extends ConsumerWidget {
  const DoctorDetailsScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorAsync = ref.watch(doctorByIdProvider(doctorId));

    return doctorAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              DoctoracDetailHeader(
                title: 'تفاصيل الطبيب',
                onBack: () => context.pop(),
              ),
              const Expanded(
                child: Center(child: Text('تعذر تحميل بيانات الطبيب')),
              ),
            ],
          ),
        ),
      ),
      data: (doctor) {
        if (doctor == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  DoctoracDetailHeader(
                    title: 'تفاصيل الطبيب',
                    onBack: () => context.pop(),
                  ),
                  const Expanded(
                    child: Center(child: Text('الطبيب غير موجود')),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          bottomNavigationBar: StickyBottomActionBar(
            priceText: '${doctor.consultationFee} جنيه',
            subtitleText: 'سعر الكشف',
            primaryLabel: 'احجز موعدك الآن',
            onPressed: () {
              final draft = BookingDraft(
                bookingType: 'doctor',
                providerId: doctor.id,
                providerName: doctor.name,
                providerSubtitle: doctor.specialty,
                providerImageUrl: doctor.photoUrl,
                serviceTitle: 'كشف طبي - ${doctor.name}',
                locationText: 'عيادة ${doctor.name} • ${doctor.city}',
                address: doctor.address,
                price: doctor.consultationFee,
                paymentMethod: 'الدفع نقداً في العيادة',
                availableSlots: doctor.availableSlots,
              );
              context.push('/booking/select-date-time', extra: draft);
            },
          ),
          body: SafeArea(
            child: Column(
              children: [
                DoctoracDetailHeader(
                  title: 'تفاصيل الطبيب',
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Doctor Profile Card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.cardBorder),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CachedImageBox(
                                    imageUrl: doctor.photoUrl,
                                    width: 78,
                                    height: 78,
                                    isCircle: true,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doctor.name,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          doctor.specialty,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.mintSurface,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      '${doctor.experienceYears} سنة خبرة',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.starAmber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    doctor.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${doctor.reviewsCount} تقييم)',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3 Metric Cards Row (الكشف، مدة الانتظار، الموقع)
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: 'الكشف',
                                value: '${doctor.consultationFee} جنيه',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricCard(
                                label: 'مدة الانتظار',
                                value: '${doctor.waitTimeMinutes} دقيقة',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MetricCard(
                                label: 'الموقع',
                                value: doctor.city,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // Bio Section
                        const Text(
                          'نبذة عن الطبيب',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          doctor.bio,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.65,
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Clinic Address Map Card
                        MapPreviewCard(
                          title: 'عنوان العيادة',
                          address: doctor.address,
                          onDirectionsTap: () =>
                              ExternalLauncher.openGoogleMaps(
                            context: context,
                            latitude: doctor.latitude,
                            longitude: doctor.longitude,
                            label: doctor.address,
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
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
