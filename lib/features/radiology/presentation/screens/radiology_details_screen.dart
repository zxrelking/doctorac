import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/maps_launcher.dart';
import '../../../../core/widgets/doctorac_headers.dart';
import '../../../../core/widgets/sticky_bottom_bar.dart';
import '../../../bookings/domain/booking_model.dart';
import '../../domain/radiology_model.dart';
import '../providers/radiology_provider.dart';

class RadiologyDetailsScreen extends ConsumerStatefulWidget {
  const RadiologyDetailsScreen({
    super.key,
    required this.centerId,
    this.initialScanType,
  });

  final String centerId;
  final String? initialScanType;

  @override
  ConsumerState<RadiologyDetailsScreen> createState() =>
      _RadiologyDetailsScreenState();
}

class _RadiologyDetailsScreenState
    extends ConsumerState<RadiologyDetailsScreen> {
  String? _selectedScanId;

  @override
  Widget build(BuildContext context) {
    final centerAsync = ref.watch(radiologyCenterByIdProvider(widget.centerId));

    return centerAsync.when(
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
                title: 'تفاصيل الأشعة',
                onBack: () => context.pop(),
              ),
              const Expanded(
                child: Center(child: Text('تعذر تحميل بيانات مركز الأشعة')),
              ),
            ],
          ),
        ),
      ),
      data: (center) {
        if (center == null || center.scans.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  DoctoracDetailHeader(
                    title: 'تفاصيل الأشعة',
                    onBack: () => context.pop(),
                  ),
                  const Expanded(
                    child: Center(child: Text('بيانات مركز الأشعة غير متاحة')),
                  ),
                ],
              ),
            ),
          );
        }

        final RadiologyScanModel selectedScan = center.scans.firstWhere(
          (s) =>
              _selectedScanId != null
                  ? s.id == _selectedScanId
                  : (widget.initialScanType != null &&
                      s.scanType == widget.initialScanType),
          orElse: () => center.scans.first,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          bottomNavigationBar: StickyBottomActionBar(
            priceText: '${selectedScan.price} جنيه',
            subtitleText: selectedScan.shortName,
            primaryLabel: 'احجز الأشعة',
            onPressed: () {
              final draft = BookingDraft(
                bookingType: 'radiology',
                providerId: center.id,
                providerName: center.name,
                providerSubtitle: selectedScan.name,
                serviceTitle: selectedScan.name,
                locationText: '${center.name} • ${center.city}',
                address: center.address,
                price: selectedScan.price,
                paymentMethod: 'الدفع نقداً في المركز',
                availableSlots: const [
                  '10:00 ص',
                  '12:00 م',
                  '2:00 م',
                  '4:30 م',
                  '6:30 م',
                  '8:00 م',
                ],
              );
              context.push('/booking/select-date-time', extra: draft);
            },
          ),
          body: SafeArea(
            child: Column(
              children: [
                DoctoracDetailHeader(
                  title: 'تفاصيل الأشعة',
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Center Header Card
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
                                  Container(
                                    width: 74,
                                    height: 74,
                                    decoration: BoxDecoration(
                                      color: AppColors.mintSurface,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.center_focus_strong_outlined,
                                      color: AppColors.primary,
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          center.name,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          center.tagline,
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'أجهزة حديثة • فريق متخصص',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        center.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: AppColors.ratingText,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(
                                        Icons.star_rounded,
                                        color: AppColors.ratingText,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '(${center.reviewsCount} تقييم)',
                                        style: const TextStyle(
                                          color: AppColors.ratingText,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 3 Info Cards
                        Row(
                          children: [
                            Expanded(
                              child: _RadiologyInfoBox(
                                label: 'مواعيد العمل',
                                value: center.workingHours,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _RadiologyInfoBox(
                                label: 'الانتظار',
                                value: center.waitTimeText,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _RadiologyInfoBox(
                                label: 'التقرير',
                                value: center.reportTurnaround,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // Selectable Scan Types Radio List
                        const Text(
                          'اختر نوع الأشعة',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...center.scans.map((scan) {
                          final isSelected = scan.id == selectedScan.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedScanId = scan.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.mintSurface
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.mintBorder
                                        : AppColors.cardBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle_rounded
                                          : Icons
                                              .radio_button_unchecked_rounded,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        scan.name,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14.5,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${scan.price} جنيه',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 10),

                        // Important Safety Warning Box ("إرشادات مهمة")
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.mintSurface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'إرشادات مهمة',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedScan.safetyNotes,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Location & Contact Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cardBorder),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'الموقع وبيانات التواصل',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                center.address,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    center.city,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        ExternalLauncher.openGoogleMaps(
                                      context: context,
                                      latitude: center.latitude,
                                      longitude: center.longitude,
                                      label: center.address,
                                    ),
                                    child: const Row(
                                      children: [
                                        Text(
                                          'عرض الاتجاهات',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: AppColors.primary,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
      },
    );
  }
}

class _RadiologyInfoBox extends StatelessWidget {
  const _RadiologyInfoBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
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
              fontSize: 11.5,
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
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
