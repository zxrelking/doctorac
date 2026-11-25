import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/location/egypt_governorates.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/doctorac_headers.dart';
import '../../domain/lab_model.dart';
import '../providers/labs_provider.dart';

class LabsListScreen extends ConsumerStatefulWidget {
  const LabsListScreen({super.key});

  @override
  ConsumerState<LabsListScreen> createState() => _LabsListScreenState();
}

class _LabsListScreenState extends ConsumerState<LabsListScreen> {
  final _searchController = TextEditingController();
  String _selectedChip = 'الأكثر طلباً';
  String _query = '';

  static const List<String> _chips = [
    'الأكثر طلباً',
    'تحاليل الدم',
    'فيتامينات',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labsAsync = ref.watch(labsListProvider);
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
                title: 'المعامل والتحاليل',
                subtitle: 'احجز التحليل واختر المعمل الأقرب إليك.',
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
                    hintText: 'ابحث عن اسم التحليل...',
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
            // Lab Tests List
            Expanded(
              child: labsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (_, __) => const Center(
                  child: Text('تعذر تحميل قائمة التحاليل'),
                ),
                data: (labs) {
                  final items = <_LabTestEntry>[];
                  for (final lab in labs) {
                    for (final test in lab.tests) {
                      items.add(_LabTestEntry(lab: lab, test: test));
                    }
                  }

                  final filtered = items.where((entry) {
                    final matchesChip = _selectedChip == 'الأكثر طلباً'
                        ? (entry.test.isPopular ||
                            entry.test.category == 'الأكثر طلباً')
                        : entry.test.category == _selectedChip;
                    final q = _query.toLowerCase();
                    final matchesQuery = q.isEmpty ||
                        entry.test.name.toLowerCase().contains(q) ||
                        entry.test.shortName.toLowerCase().contains(q) ||
                        entry.lab.name.toLowerCase().contains(q) ||
                        entry.lab.governorate.toLowerCase().contains(q);
                    return matchesChip && matchesQuery;
                  }).toList();

                  // Sort nearest to user's real GPS / selected governorate first
                  filtered.sort((a, b) {
                    if (!locState.isAllEgypt) {
                      final aIn =
                          a.lab.governorate == locState.governorate ? 0 : 1;
                      final bIn =
                          b.lab.governorate == locState.governorate ? 0 : 1;
                      if (aIn != bIn) return aIn.compareTo(bIn);
                    }
                    final da = EgyptGovernorates.distanceKm(
                      locState.latitude,
                      locState.longitude,
                      a.lab.latitude,
                      a.lab.longitude,
                    );
                    final db = EgyptGovernorates.distanceKm(
                      locState.latitude,
                      locState.longitude,
                      b.lab.latitude,
                      b.lab.longitude,
                    );
                    return da.compareTo(db);
                  });

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد تحاليل مطابقة للبحث حالياً',
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
                      final entry = filtered[index];
                      return _LabTestCard(
                        entry: entry,
                        onBook: () => context.push(
                          '/labs/${entry.lab.id}?testId=${entry.test.id}',
                        ),
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

class _LabTestEntry {
  const _LabTestEntry({required this.lab, required this.test});
  final LabModel lab;
  final LabTestModel test;
}

class _LabTestCard extends StatelessWidget {
  const _LabTestCard({
    required this.entry,
    required this.onBook,
  });

  final _LabTestEntry entry;
  final VoidCallback onBook;

  Color get _iconBg {
    switch (entry.test.iconType) {
      case 'vitamin':
        return AppColors.labVitaminBg;
      case 'liver':
        return AppColors.labLiverBg;
      default:
        return AppColors.labBloodBg;
    }
  }

  IconData get _iconData {
    switch (entry.test.iconType) {
      case 'vitamin':
        return Icons.wb_sunny_outlined;
      case 'cbc':
        return Icons.biotech_outlined;
      case 'liver':
        return Icons.monitor_heart_outlined;
      case 'kidney':
        return Icons.water_drop_outlined;
      case 'thyroid':
        return Icons.science_outlined;
      default:
        return Icons.bloodtype_outlined;
    }
  }

  Color get _iconColor {
    switch (entry.test.iconType) {
      case 'vitamin':
        return const Color(0xFFD99416);
      case 'liver':
        return const Color(0xFFB54747);
      default:
        return const Color(0xFFC93B4B);
    }
  }

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
          onTap: onBook,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 62,
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_iconData, color: _iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.test.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'متاح في ${entry.lab.name} ومعامل قريبة منك',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${entry.test.price} جنيه',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onBook,
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
                    'احجز الآن',
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
