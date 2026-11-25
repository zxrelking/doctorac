import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/location/egypt_governorates.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_image_box.dart';
import '../../../../core/widgets/doctorac_headers.dart';
import '../../domain/pharmacy_model.dart';
import '../providers/pharmacies_provider.dart';

class PharmaciesListScreen extends ConsumerStatefulWidget {
  const PharmaciesListScreen({super.key});

  @override
  ConsumerState<PharmaciesListScreen> createState() =>
      _PharmaciesListScreenState();
}

class _PharmaciesListScreenState extends ConsumerState<PharmaciesListScreen> {
  final _searchController = TextEditingController();
  String _selectedChip = 'الأقرب إليك';
  String _query = '';

  static const List<String> _chips = [
    'الأقرب إليك',
    'مفتوحة الآن',
    'توصيل منزلي',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pharmaciesAsync = ref.watch(pharmaciesListProvider);
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
                title: 'الصيدليات',
                subtitle: 'اعثر على أقرب صيدلية واطلب أدويتك للمنزل.',
                onBack: () => context.pop(),
              ),
            ),
            const SizedBox(height: 18),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppColors.softShadow,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن صيدلية أو دواء...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                            ),
                          )
                        : const Padding(
                            padding: EdgeInsetsDirectional.only(end: 14),
                            child: Icon(
                              Icons.search_rounded,
                              color: AppColors.textPrimary,
                              size: 24,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Filter Chips
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final chip = _chips[index];
                  final selected = chip == _selectedChip;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedChip = chip),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.mintChipActive
                            : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected
                              ? AppColors.mintBorder
                              : AppColors.cardBorder,
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        chip,
                        style: TextStyle(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 13.5,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Pharmacies List
            Expanded(
              child: pharmaciesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (_, __) => const Center(
                  child: Text('تعذر تحميل قائمة الصيدليات'),
                ),
                data: (pharmacies) {
                  final list = List<PharmacyModel>.from(pharmacies).where((p) {
                    if (_selectedChip == 'مفتوحة الآن' && !p.isOpenNow) {
                      return false;
                    }
                    if (_selectedChip == 'توصيل منزلي' &&
                        !p.deliveryAvailable) {
                      return false;
                    }
                    final q = _query.toLowerCase();
                    if (q.isNotEmpty &&
                        !p.name.toLowerCase().contains(q) &&
                        !p.address.toLowerCase().contains(q) &&
                        !p.governorate.toLowerCase().contains(q)) {
                      return false;
                    }
                    return true;
                  }).toList();

                  // Sort by real Haversine distance from user's GPS / selected governorate
                  list.sort((a, b) {
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

                  if (list.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد صيدليات مطابقة للبحث حالياً',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final pharmacy = list[index];
                      final realDist = EgyptGovernorates.distanceKm(
                        locState.latitude,
                        locState.longitude,
                        pharmacy.latitude,
                        pharmacy.longitude,
                      );
                      return _PharmacyCard(
                        pharmacy: pharmacy,
                        realDistanceKm: realDist,
                        onTap: () => context.push('/pharmacies/${pharmacy.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  const _PharmacyCard({
    required this.pharmacy,
    required this.realDistanceKm,
    required this.onTap,
  });

  final PharmacyModel pharmacy;
  final double realDistanceKm;
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
                Stack(
                  children: [
                    CachedImageBox(
                      imageUrl: pharmacy.storefrontUrl,
                      width: 82,
                      height: 82,
                      borderRadius: 18,
                      fallbackIcon: Icons.local_pharmacy_outlined,
                    ),
                    PositionedDirectional(
                      top: 6,
                      start: 6,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.name,
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
                        '${realDistanceKm.toStringAsFixed(1)} كم • ${pharmacy.governorate} • ${pharmacy.isOpenNow ? "مفتوحة الآن" : "مغلقة"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pharmacy.deliveryAvailable
                            ? 'توصيل متاح'
                            : 'استلام من الفرع',
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
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text(
                    'اطلب الآن',
                    style: TextStyle(
                      fontSize: 13.5,
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
