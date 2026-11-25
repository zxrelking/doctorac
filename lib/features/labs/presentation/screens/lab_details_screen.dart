import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/maps_launcher.dart';
import '../../../../core/widgets/doctorac_headers.dart';
import '../../../../core/widgets/sticky_bottom_bar.dart';
import '../../../bookings/domain/booking_model.dart';
import '../../domain/lab_model.dart';
import '../providers/labs_provider.dart';

class LabDetailsScreen extends ConsumerStatefulWidget {
  const LabDetailsScreen({
    super.key,
    required this.labId,
    this.initialTestId,
  });

  final String labId;
  final String? initialTestId;

  @override
  ConsumerState<LabDetailsScreen> createState() => _LabDetailsScreenState();
}

class _LabDetailsScreenState extends ConsumerState<LabDetailsScreen> {
  String? _selectedTestId;

  @override
  void initState() {
    super.initState();
    _selectedTestId = widget.initialTestId;
  }

  @override
  Widget build(BuildContext context) {
    final labAsync = ref.watch(labByIdProvider(widget.labId));

    return labAsync.when(
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
                title: 'تفاصيل المعمل والتحليل',
                onBack: () => context.pop(),
              ),
              const Expanded(
                child: Center(child: Text('تعذر تحميل بيانات المعمل')),
              ),
            ],
          ),
        ),
      ),
      data: (lab) {
        if (lab == null || lab.tests.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  DoctoracDetailHeader(
                    title: 'تفاصيل المعمل والتحليل',
                    onBack: () => context.pop(),
                  ),
                  const Expanded(
                    child: Center(child: Text('بيانات المعمل غير متاحة حالياً')),
                  ),
                ],
              ),
            ),
          );
        }

        final LabTestModel selectedTest = lab.tests.firstWhere(
          (t) => t.id == _selectedTestId,
          orElse: () => lab.tests.first,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          bottomNavigationBar: StickyBottomActionBar(
            priceText: '${selectedTest.price} جنيه',
            subtitleText: selectedTest.shortName,
            primaryLabel: 'احجز التحليل',
            onPressed: () {
              final draft = BookingDraft(
                bookingType: 'lab',
                providerId: lab.id,
                providerName: lab.name,
                providerSubtitle: selectedTest.name,
                serviceTitle: selectedTest.name,
                locationText: '${lab.name} • ${lab.city}',
                address: lab.address,
                price: selectedTest.price,
                paymentMethod: 'الدفع نقداً في المعمل',
                availableSlots: const [
                  '8:30 ص',
                  '9:00 ص',
                  '10:00 ص',
                  '11:30 ص',
                  '1:00 م',
                  '4:00 م',
                ],
              );
              context.push('/booking/select-date-time', extra: draft);
            },
          ),
          body: SafeArea(
            child: Column(
              children: [
                DoctoracDetailHeader(
                  title: 'تفاصيل المعمل والتحليل',
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Lab Header Card
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
                                      Icons.science_outlined,
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
                                          lab.name,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lab.tagline,
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
                                    'معمل معتمد • نتائج إلكترونية',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        lab.rating.toStringAsFixed(1),
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
                                        '(${lab.reviewsCount} تقييم)',
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
                              child: _InfoTile(
                                label: 'مواعيد العمل',
                                value: lab.workingHours,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _InfoTile(
                                label: 'زيارة منزلية',
                                value: lab.homeVisitAvailable
                                    ? 'متاحة'
                                    : 'غير متاحة',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _InfoTile(
                                label: 'النتائج',
                                value: lab.resultsTurnaround,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // Selectable Radio List of Tests
                        const Text(
                          'اختر التحليل المناسب',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...lab.tests.map((test) {
                          final isSelected = test.id == selectedTest.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedTestId = test.id),
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
                                          : Icons.radio_button_unchecked_rounded,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        test.name,
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
                                      '${test.price} جنيه',
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

                        // "قبل زيارتك" Info Box
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
                                Icons.info_outline_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'قبل زيارتك',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedTest.prepNotes,
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
                                lab.address,
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
                                    lab.city,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        ExternalLauncher.openGoogleMaps(
                                      context: context,
                                      latitude: lab.latitude,
                                      longitude: lab.longitude,
                                      label: lab.address,
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

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
