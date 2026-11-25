import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/location/egypt_governorates.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/doctorac_headers.dart';
import '../../domain/radiology_model.dart';
import '../providers/radiology_provider.dart';

class RadiologyListScreen extends ConsumerWidget {
  const RadiologyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centersAsync = ref.watch(radiologyCentersProvider);
    final locState = ref.watch(userLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: DoctoracListHeader(
                title: 'الأشعة',
                subtitle: 'احجز فحوصاتك في مراكز أشعة موثوقة.',
                onBack: () => context.pop(),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: centersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (_, __) => const Center(
                  child: Text('تعذر تحميل خدمات الأشعة'),
                ),
                data: (centers) {
                  final sortedCenters = List<RadiologyCenterModel>.from(centers)
                    ..sort((a, b) {
                      final da = EgyptGovernorates.distanceKm(
                        locState.latitude,
                        locState.longitude,
                        a.latitude,
                        a.longitude,
                      );
                      final db = EgyptGovernorates.distanceKm(
                        locState.latitude,
                        locState.longitude,
                        b.latitude,
                        b.longitude,
                      );
                      return da.compareTo(db);
                    });
                  final scanCards = _buildScanTypeSummaries(sortedCenters);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    children: [
                      // Green 3D MRI Hero Banner matching Figma 1:1
                      Container(
                        height: 158,
                        decoration: BoxDecoration(
                          gradient: AppColors.radiologyBannerGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppColors.buttonShadow,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            PositionedDirectional(
                              end: -14,
                              top: 0,
                              bottom: 0,
                              width: 195,
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [
                                    Colors.transparent,
                                    Colors.white,
                                    Colors.white,
                                  ],
                                  stops: [0.0, 0.25, 1.0],
                                ).createShader(bounds),
                                blendMode: BlendMode.dstIn,
                                child: Image.asset(
                                  'assets/images/mri_banner.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.biotech_rounded,
                                      size: 72,
                                      color: Colors.white24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                20,
                                26,
                                160,
                                20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'أشعة متقدمة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'تقنيات حديثة ورعاية موثوقة.',
                                    style: TextStyle(
                                      color: Color(0xFFE1F3ED),
                                      fontSize: 13.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...scanCards.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _RadiologyTypeCard(
                            title: item.title,
                            startingPrice: item.minPrice,
                            icon: item.icon,
                            onTap: () => context.push(
                              '/radiology/${item.centerId}?scanType=${item.scanType}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ScanTypeSummary> _buildScanTypeSummaries(
    List<RadiologyCenterModel> centers,
  ) {
    final defaultCenterId = centers.isNotEmpty ? centers.first.id : '';
    final configs = [
      ('MRI', 'رنين مغناطيسي MRI', Icons.donut_large_rounded, 650),
      ('CT', 'أشعة مقطعية CT', Icons.radar_rounded, 450),
      ('X-Ray', 'أشعة سينية X-Ray', Icons.medical_information_outlined, 200),
      ('Ultrasound', 'موجات صوتية Ultrasound', Icons.waves_rounded, 300),
    ];

    return configs.map((cfg) {
      int? bestPrice;
      String bestCenterId = defaultCenterId;
      for (final center in centers) {
        for (final scan in center.scans) {
          if (scan.scanType == cfg.$1) {
            if (bestPrice == null || scan.price < bestPrice) {
              bestPrice = scan.price;
              bestCenterId = center.id;
            }
          }
        }
      }
      return _ScanTypeSummary(
        scanType: cfg.$1,
        title: cfg.$2,
        icon: cfg.$3,
        minPrice: bestPrice ?? cfg.$4,
        centerId: bestCenterId,
      );
    }).toList();
  }
}

class _ScanTypeSummary {
  const _ScanTypeSummary({
    required this.scanType,
    required this.title,
    required this.icon,
    required this.minPrice,
    required this.centerId,
  });

  final String scanType;
  final String title;
  final IconData icon;
  final int minPrice;
  final String centerId;
}

class _RadiologyTypeCard extends StatelessWidget {
  const _RadiologyTypeCard({
    required this.title,
    required this.startingPrice,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int startingPrice;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.radiologyIconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: AppColors.primary, size: 25),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'يبدأ من $startingPrice جنيه',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text(
                    'احجز',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
