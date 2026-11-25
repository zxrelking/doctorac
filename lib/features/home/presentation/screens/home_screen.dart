import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/location/egypt_governorates.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_image_box.dart';
import '../../../../core/widgets/doctorac_headers.dart';
import '../../../../core/widgets/doctorac_logo.dart';
import '../../../../core/widgets/user_avatar_circle.dart';
import '../../../doctors/domain/doctor_model.dart';
import '../../../doctors/presentation/providers/doctors_provider.dart';
import '../../../labs/domain/lab_model.dart';
import '../../../labs/presentation/providers/labs_provider.dart';
import '../../../pharmacies/domain/pharmacy_model.dart';
import '../../../pharmacies/presentation/providers/pharmacies_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../radiology/domain/radiology_model.dart';
import '../../../radiology/presentation/providers/radiology_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Request real GPS location automatically on first Home open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(userLocationProvider.notifier).autoDetectOnce();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showLocationPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _EgyptLocationPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final doctorsAsync = ref.watch(doctorsListProvider);
    final labsAsync = ref.watch(labsListProvider);
    final pharmaciesAsync = ref.watch(pharmaciesListProvider);
    final radiologyAsync = ref.watch(radiologyCentersProvider);
    final locState = ref.watch(userLocationProvider);

    final profile = profileAsync.valueOrNull;
    final avatarUrl = profile?.avatarUrl ?? '';
    final initials = profile?.initials ?? 'د';
    final firstName = (profile?.fullName ?? '').trim().split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: Real User Avatar on RTL start, Doctorac Logo + Real GPS Location on RTL end
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: UserAvatarCircle(
                      avatarUrl: avatarUrl,
                      initials: initials,
                      size: 44,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const DoctoracLogo(
                        iconSize: 28,
                        fontSize: 21,
                        spacing: 6,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showLocationPicker,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  locState.isDetecting
                                      ? 'جاري تحديد موقعك...'
                                      : (locState.isGpsDetected
                                          ? 'موقعي الحالي (GPS)'
                                          : 'موقعي الحالي'),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 165),
                                      child: Text(
                                        locState.displayLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            locState.isDetecting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : Icon(
                                    locState.isGpsDetected
                                        ? Icons.my_location_rounded
                                        : Icons.location_on_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Hero Section with Heartbeat ECG Background Graphic
              Stack(
                clipBehavior: Clip.none,
                children: [
                  PositionedDirectional(
                    end: -20,
                    top: 12,
                    child: Container(
                      width: 170,
                      height: 125,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(64),
                        gradient: RadialGradient(
                          colors: [
                            AppColors.mintGlow.withValues(alpha: 0.85),
                            AppColors.background.withValues(alpha: 0),
                          ],
                        ),
                      ),
                      child: CustomPaint(
                        painter: _HeartbeatGraphicPainter(),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstName.isNotEmpty
                            ? 'مرحباً بك يا $firstName في دكتوراك'
                            : 'مرحبا بك في دكتوراك',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.cairo(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                          children: const [
                            TextSpan(
                              text: 'صحتك، ',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            TextSpan(
                              text: 'أولويتنا.',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'كل ما تحتاجه لصحتك في مكان واحد في جميع محافظات مصر.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Global Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppColors.cardShadow,
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
                    hintText: 'ابحث عن دكتور، دواء، تحليل، محافظة...',
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
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                  ),
                ),
              ),

              // Global Live Search Results
              if (_query.isNotEmpty) ...[
                const SizedBox(height: 18),
                _GlobalSearchResults(
                  query: _query,
                  doctors: doctorsAsync.valueOrNull ?? const [],
                  labs: labsAsync.valueOrNull ?? const [],
                  pharmacies: pharmaciesAsync.valueOrNull ?? const [],
                  centers: radiologyAsync.valueOrNull ?? const [],
                ),
              ] else ...[
                const SizedBox(height: 26),

                // "خدماتنا" Section
                const DoctoracSectionTitle(
                  title: 'خدماتنا',
                  subtitle: 'كل الخدمات الطبية في مكان واحد.',
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.72,
                  children: [
                    _ServiceGridCard(
                      title: 'الأطباء',
                      subtitle: 'احجز مع أفضل\nالأطباء',
                      icon: Icons.medical_services_outlined,
                      onTap: () => context.push('/doctors'),
                    ),
                    _ServiceGridCard(
                      title: 'المعامل',
                      subtitle: 'احجز تحاليلك',
                      icon: Icons.science_outlined,
                      onTap: () => context.push('/labs'),
                    ),
                    _ServiceGridCard(
                      title: 'الصيدليات',
                      subtitle: 'اطلب أدويتك\nالآن',
                      icon: Icons.medication_outlined,
                      onTap: () => context.push('/pharmacies'),
                    ),
                    _ServiceGridCard(
                      title: 'الأشعة',
                      subtitle: 'احجز فحوصات\nالأشعة',
                      icon: Icons.biotech_outlined,
                      onTap: () => context.push('/radiology'),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // "أفضل الأطباء" Section (smartly prioritized for user's real governorate)
                DoctoracSectionTitle(
                  title: locState.isAllEgypt
                      ? 'أفضل الأطباء في مصر'
                      : 'أفضل الأطباء في ${locState.governorate}',
                  actionLabel: 'عرض الكل',
                  onAction: () => context.push('/doctors'),
                ),
                const SizedBox(height: 14),
                doctorsAsync.when(
                  data: (doctors) {
                    final sorted = List<DoctorModel>.from(doctors);
                    if (!locState.isAllEgypt) {
                      final inGov = sorted
                          .where((d) => d.governorate == locState.governorate)
                          .toList();
                      final others = sorted
                          .where((d) => d.governorate != locState.governorate)
                          .toList();
                      others.sort((a, b) {
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
                      sorted
                        ..clear()
                        ..addAll(inGov)
                        ..addAll(others);
                    }
                    final list = sorted.take(5).toList();
                    return Column(
                      children: list
                          .map(
                            (doc) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _HomeDoctorCard(
                                doctor: doc,
                                onTap: () => context.push('/doctors/${doc.id}'),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EgyptLocationPickerSheet extends ConsumerStatefulWidget {
  const _EgyptLocationPickerSheet();

  @override
  ConsumerState<_EgyptLocationPickerSheet> createState() =>
      _EgyptLocationPickerSheetState();
}

class _EgyptLocationPickerSheetState
    extends ConsumerState<_EgyptLocationPickerSheet> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final locState = ref.watch(userLocationProvider);
    final filtered = EgyptGovernorates.all.where((g) {
      if (_filter.isEmpty) return true;
      return g.name.contains(_filter) || g.capital.contains(_filter);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollCtrl) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
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
              const SizedBox(height: 14),
              const Text(
                'اختر موقعك في مصر',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              // Real GPS Detection Button
              InkWell(
                onTap: locState.isDetecting
                    ? null
                    : () async {
                        final ok = await ref
                            .read(userLocationProvider.notifier)
                            .detectRealGpsLocation(silentIfDenied: false);
                        if (!ctx.mounted) return;
                        final latest = ref.read(userLocationProvider);
                        if (ok) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم تحديد موقعك الفعلي: ${latest.displayLabel}',
                              ),
                            ),
                          );
                        } else if (latest.errorMessage != null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(latest.errorMessage!)),
                          );
                        }
                      },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.mintSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.mintBorder),
                  ),
                  child: Row(
                    children: [
                      locState.isDetecting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تحديد موقعي الحالي تلقائياً (GPS)',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'احصل على أقرب الأطباء والصيدليات والمعامل لك',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Search inside 27 Governorates
              TextField(
                onChanged: (v) => setState(() => _filter = v.trim()),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن محافظتك (القاهرة، الجيزة، الإسكندرية...)',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: filtered.length,
                  itemBuilder: (_, index) {
                    final gov = filtered[index];
                    final selected = locState.governorate == gov.name;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        gov.name == EgyptGovernorates.allEgyptName
                            ? Icons.public_rounded
                            : Icons.location_on_rounded,
                        color:
                            selected ? AppColors.primary : AppColors.textMuted,
                      ),
                      title: Text(
                        gov.name == EgyptGovernorates.allEgyptName
                            ? 'كل محافظات مصر'
                            : '${gov.name} (${gov.capital})',
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () {
                        ref
                            .read(userLocationProvider.notifier)
                            .selectGovernorate(gov);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceGridCard extends StatelessWidget {
  const _ServiceGridCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.mintSurface,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeDoctorCard extends StatelessWidget {
  const _HomeDoctorCard({
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
                  width: 82,
                  height: 82,
                  borderRadius: 16,
                ),
                const SizedBox(width: 12),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.specialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.starAmber,
                            size: 16,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            doctor.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '  |  ${doctor.reviewsCount} تقييم',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.textMuted,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${doctor.hospitalName} • ${doctor.city}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${doctor.consultationFee} جنيه',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'احجز الآن',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlobalSearchResults extends StatelessWidget {
  const _GlobalSearchResults({
    required this.query,
    required this.doctors,
    required this.labs,
    required this.pharmacies,
    required this.centers,
  });

  final String query;
  final List<DoctorModel> doctors;
  final List<LabModel> labs;
  final List<PharmacyModel> pharmacies;
  final List<RadiologyCenterModel> centers;

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final matchedDoctors = doctors
        .where(
          (d) =>
              d.name.toLowerCase().contains(q) ||
              d.specialty.toLowerCase().contains(q) ||
              d.specialtyCategory.toLowerCase().contains(q) ||
              d.city.toLowerCase().contains(q) ||
              d.governorate.toLowerCase().contains(q),
        )
        .toList();

    final matchedLabs = labs
        .where(
          (l) =>
              l.name.toLowerCase().contains(q) ||
              l.governorate.toLowerCase().contains(q) ||
              l.city.toLowerCase().contains(q) ||
              l.tests.any((t) => t.name.toLowerCase().contains(q)),
        )
        .toList();

    final matchedPharmacies = pharmacies
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.address.toLowerCase().contains(q) ||
              p.governorate.toLowerCase().contains(q),
        )
        .toList();

    final matchedRadiology = centers
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.governorate.toLowerCase().contains(q) ||
              c.scans.any((s) => s.name.toLowerCase().contains(q)),
        )
        .toList();

    final hasAny = matchedDoctors.isNotEmpty ||
        matchedLabs.isNotEmpty ||
        matchedPharmacies.isNotEmpty ||
        matchedRadiology.isNotEmpty;

    if (!hasAny) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Column(
          children: [
            Icon(Icons.search_off_rounded, size: 42, color: AppColors.textMuted),
            SizedBox(height: 10),
            Text(
              'لا توجد نتائج مطابقة لبحثك',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'جرّب البحث باسم طبيب، تحليل، صيدلية، أشعة أو محافظة.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (matchedDoctors.isNotEmpty) ...[
          const DoctoracSectionTitle(title: 'الأطباء'),
          const SizedBox(height: 10),
          ...matchedDoctors.map(
            (doc) => _SearchResultTile(
              title: doc.name,
              subtitle:
                  '${doc.specialty} • ${doc.city} • ${doc.consultationFee} جنيه',
              icon: Icons.medical_services_outlined,
              onTap: () => context.push('/doctors/${doc.id}'),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (matchedLabs.isNotEmpty) ...[
          const DoctoracSectionTitle(title: 'المعامل والتحاليل'),
          const SizedBox(height: 10),
          ...matchedLabs.map(
            (lab) => _SearchResultTile(
              title: lab.name,
              subtitle: '${lab.governorate} • ${lab.address}',
              icon: Icons.science_outlined,
              onTap: () => context.push('/labs/${lab.id}'),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (matchedPharmacies.isNotEmpty) ...[
          const DoctoracSectionTitle(title: 'الصيدليات'),
          const SizedBox(height: 10),
          ...matchedPharmacies.map(
            (p) => _SearchResultTile(
              title: p.name,
              subtitle: '${p.governorate} • توصيل ${p.deliveryTimeText}',
              icon: Icons.medication_outlined,
              onTap: () => context.push('/pharmacies/${p.id}'),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (matchedRadiology.isNotEmpty) ...[
          const DoctoracSectionTitle(title: 'الأشعة'),
          const SizedBox(height: 10),
          ...matchedRadiology.map(
            (c) => _SearchResultTile(
              title: c.name,
              subtitle: '${c.governorate} • ${c.address}',
              icon: Icons.biotech_outlined,
              onTap: () => context.push('/radiology/${c.id}'),
            ),
          ),
        ],
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.softShadow,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.mintSurface,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_left_rounded,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _HeartbeatGraphicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.24)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(16, size.height * 0.58)
      ..lineTo(42, size.height * 0.58)
      ..lineTo(50, size.height * 0.36)
      ..lineTo(60, size.height * 0.74)
      ..lineTo(70, size.height * 0.44)
      ..lineTo(78, size.height * 0.58)
      ..lineTo(96, size.height * 0.58);
    canvas.drawPath(path, paint);

    const hx = 104.0;
    final hy = size.height * 0.48;
    final heart = Path()
      ..moveTo(hx, hy + 18)
      ..cubicTo(hx - 24, hy + 4, hx - 22, hy - 18, hx, hy - 6)
      ..cubicTo(hx + 22, hy - 18, hx + 24, hy + 4, hx, hy + 18)
      ..close();
    canvas.drawPath(heart, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
