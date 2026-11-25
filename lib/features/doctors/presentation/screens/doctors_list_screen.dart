import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/location/egypt_governorates.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_image_box.dart';
import '../../../../core/widgets/doctorac_headers.dart';
import '../../domain/doctor_model.dart';
import '../providers/doctors_provider.dart';

class DoctorsListScreen extends ConsumerStatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  ConsumerState<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends ConsumerState<DoctorsListScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  String _query = '';

  static const List<String> _categories = [
    'الكل',
    'قلب وأوعية',
    'باطنة',
    'أطفال',
    'جلدية',
    'عيون',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(doctorsListProvider);
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
                title: 'الأطباء',
                subtitle: 'اختار الطبيب المناسب واحجز موعدك بسهولة.',
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
                    hintText: 'ابحث باسم الطبيب أو التخصص...',
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
            // Horizontal Filter Chips
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
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
                        cat,
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
            // Doctors List
            Expanded(
              child: doctorsAsync.when(
                data: (doctors) {
                  final filtered = doctors.where((d) {
                    final matchesCategory = _selectedCategory == 'الكل' ||
                        d.specialtyCategory == _selectedCategory;
                    final q = _query.toLowerCase();
                    final matchesQuery = q.isEmpty ||
                        d.name.toLowerCase().contains(q) ||
                        d.specialty.toLowerCase().contains(q) ||
                        d.specialtyCategory.toLowerCase().contains(q) ||
                        d.city.toLowerCase().contains(q) ||
                        d.governorate.toLowerCase().contains(q);
                    return matchesCategory && matchesQuery;
                  }).toList();

                  // Sort nearest to user's real GPS / selected governorate first
                  filtered.sort((a, b) {
                    if (!locState.isAllEgypt) {
                      final aIn = a.governorate == locState.governorate ? 0 : 1;
                      final bIn = b.governorate == locState.governorate ? 0 : 1;
                      if (aIn != bIn) return aIn.compareTo(bIn);
                    }
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

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا يوجد أطباء مطابقون للبحث حالياً',
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
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      return _DoctorListCard(
                        doctor: doc,
                        onTap: () => context.push('/doctors/${doc.id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (_, __) => const Center(
                  child: Text('حدث خطأ أثناء تحميل قائمة الأطباء'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorListCard extends StatelessWidget {
  const _DoctorListCard({
    required this.doctor,
    required this.onTap,
  });

  final DoctorModel doctor;
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
                CachedImageBox(
                  imageUrl: doctor.photoUrl,
                  width: 78,
                  height: 78,
                  borderRadius: 16,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${doctor.specialty} • ${doctor.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            doctor.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '${doctor.consultationFee} جنيه',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
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
                      horizontal: 20,
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
