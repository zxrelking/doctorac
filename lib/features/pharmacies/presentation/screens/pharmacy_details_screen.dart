import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/location/egypt_governorates.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_date_formatter.dart';
import '../../../../core/utils/maps_launcher.dart';
import '../../../../core/widgets/doctorac_headers.dart';
import '../../../../core/widgets/sticky_bottom_bar.dart';
import '../../../orders/domain/order_model.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/pharmacy_model.dart';
import '../providers/pharmacies_provider.dart';

class PharmacyDetailsScreen extends ConsumerStatefulWidget {
  const PharmacyDetailsScreen({super.key, required this.pharmacyId});

  final String pharmacyId;

  @override
  ConsumerState<PharmacyDetailsScreen> createState() =>
      _PharmacyDetailsScreenState();
}

class _PharmacyDetailsScreenState extends ConsumerState<PharmacyDetailsScreen> {
  final _picker = ImagePicker();
  File? _prescriptionFile;
  bool _isUploading = false;

  Future<void> _pickAndUploadPrescription(PharmacyModel pharmacy) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'رفع صورة الروشتة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'التقاط صورة بالكاميرا',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'اختيار من معرض الصور',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      _prescriptionFile = File(picked.path);
      _isUploading = true;
    });

    try {
      final url = await ref
          .read(pharmaciesRepositoryProvider)
          .uploadPrescription(_prescriptionFile!);
      await _submitPharmacyOrder(
        pharmacy: pharmacy,
        itemsSummary: 'روشتة طبية مرفوعة (جاري المراجعة والتسعير)',
        totalPrice: 150 + pharmacy.deliveryFee,
        prescriptionUrl: url,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر رفع الروشتة، يرجى المحاولة مرة أخرى')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _openMedicineOrderSheet(PharmacyModel pharmacy) async {
    final notesCtrl = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'اطلب أدويتك من ${pharmacy.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'اكتب أسماء الأدوية أو المستلزمات المطلوبة وسيتم توصيلها لباب منزلك.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'مثال: بنادول إكسترا، فيتامين C، كريم مرطب...',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('تأكيد الطلب'),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final summary = notesCtrl.text.trim().isEmpty
          ? 'طلب أدوية ومستلزمات طبية'
          : notesCtrl.text.trim();
      setState(() => _isUploading = true);
      try {
        await _submitPharmacyOrder(
          pharmacy: pharmacy,
          itemsSummary: summary,
          totalPrice: 220 + pharmacy.deliveryFee,
        );
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
    notesCtrl.dispose();
  }

  Future<void> _submitPharmacyOrder({
    required PharmacyModel pharmacy,
    required String itemsSummary,
    required int totalPrice,
    String? prescriptionUrl,
  }) async {
    final profile = ref.read(profileProvider).valueOrNull;
    final locState = ref.read(userLocationProvider);
    final refCode =
        '#ORD-${1000 + (DateTime.now().millisecondsSinceEpoch % 8999)}';
    final now = DateTime.now();
    final deliveryAddr = (profile?.address ?? '').trim().isNotEmpty
        ? profile!.address
        : (locState.detailedAddress ?? locState.displayLabel);

    final order = OrderModel(
      id: 'local-ord-${now.millisecondsSinceEpoch}',
      referenceCode: refCode,
      orderType: 'pharmacy',
      providerId: pharmacy.id,
      providerName: pharmacy.name,
      providerSubtitle: 'أدوية وعناية • توصيل إلى ${pharmacy.governorate}',
      itemsSummary: itemsSummary,
      totalPrice: totalPrice,
      status: 'on_the_way',
      prescriptionUrl: prescriptionUrl,
      deliveryAddress: deliveryAddr,
      orderDateText:
          'اليوم، ${now.day} ${ArabicDateFormatter.months[now.month - 1]}',
    );

    await ref.read(ordersProvider.notifier).createOrder(order);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال طلبك بنجاح! رقم الطلب $refCode'),
        action: SnackBarAction(
          label: 'طلباتي',
          textColor: AppColors.primaryLight,
          onPressed: () => context.go('/orders'),
        ),
      ),
    );
    context.go('/orders');
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyAsync = ref.watch(pharmacyByIdProvider(widget.pharmacyId));

    return pharmacyAsync.when(
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
                title: 'تفاصيل الصيدلية',
                onBack: () => context.pop(),
              ),
              const Expanded(
                child: Center(child: Text('تعذر تحميل بيانات الصيدلية')),
              ),
            ],
          ),
        ),
      ),
      data: (pharmacy) {
        if (pharmacy == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  DoctoracDetailHeader(
                    title: 'تفاصيل الصيدلية',
                    onBack: () => context.pop(),
                  ),
                  const Expanded(
                    child: Center(child: Text('الصيدلية غير موجودة')),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          bottomNavigationBar: StickyBottomActionBar(
            priceText: 'توصيل سريع',
            subtitleText: 'خلال ${pharmacy.deliveryTimeText}',
            primaryLabel: 'اطلب أدويتك الآن',
            isLoading: _isUploading,
            onPressed: () => _openMedicineOrderSheet(pharmacy),
          ),
          body: SafeArea(
            child: Column(
              children: [
                DoctoracDetailHeader(
                  title: 'تفاصيل الصيدلية',
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pharmacy Header Card with Custom Medical Logo Badge
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
                                      Icons.local_hospital_outlined,
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
                                          pharmacy.shortName.isNotEmpty
                                              ? pharmacy.shortName
                                              : pharmacy.name,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          pharmacy.tagline,
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
                                  Text(
                                    pharmacy.isOpen24h
                                        ? 'مفتوح الآن • 24 ساعة'
                                        : 'مفتوح الآن',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        pharmacy.rating.toStringAsFixed(1),
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
                                        '(${pharmacy.reviewsCount} تقييم)',
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
                        Builder(
                          builder: (_) {
                            final loc = ref.watch(userLocationProvider);
                            final realDist = EgyptGovernorates.distanceKm(
                              loc.latitude,
                              loc.longitude,
                              pharmacy.latitude,
                              pharmacy.longitude,
                            );
                            return Row(
                              children: [
                                Expanded(
                                  child: _PharmacyInfoBox(
                                    label: 'المسافة',
                                    value: '${realDist.toStringAsFixed(1)} كم',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _PharmacyInfoBox(
                                    label: 'رسوم التوصيل',
                                    value: '${pharmacy.deliveryFee} جنيه',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _PharmacyInfoBox(
                                    label: 'التوصيل',
                                    value: pharmacy.deliveryTimeText,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 22),

                        // Services List
                        const Text(
                          'كل ما تحتاجه لصحتك',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PharmacyServiceRow(
                          title: 'الأدوية والمستلزمات',
                          subtitle: 'وصفاتك ومنتجات العناية اليومية',
                          onTap: () => _openMedicineOrderSheet(pharmacy),
                        ),
                        const SizedBox(height: 10),
                        _PharmacyServiceRow(
                          title: 'استشارة صيدلي',
                          subtitle: 'مساعدة في الاستخدام والجرعات',
                          onTap: () => ExternalLauncher.openSupport(context),
                        ),
                        const SizedBox(height: 10),
                        _PharmacyServiceRow(
                          title: 'خدمة التوصيل',
                          subtitle: 'إلى باب منزلك في ${pharmacy.governorate}',
                          onTap: () => _openMedicineOrderSheet(pharmacy),
                        ),

                        const SizedBox(height: 18),

                        // Interactive Upload Prescription Card
                        GestureDetector(
                          onTap: _isUploading
                              ? null
                              : () => _pickAndUploadPrescription(pharmacy),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.mintSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.mintBorder
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: _isUploading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.file_upload_outlined,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'لديك روشتة؟',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _prescriptionFile != null
                                            ? 'تم اختيار صورة الروشتة — اضغط لتغييرها'
                                            : 'ارفع صورة الروشتة لطلب أدويتك بسهولة',
                                        style: const TextStyle(
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
                                pharmacy.address,
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
                                    pharmacy.city,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        ExternalLauncher.openGoogleMaps(
                                      context: context,
                                      latitude: pharmacy.latitude,
                                      longitude: pharmacy.longitude,
                                      label: pharmacy.address,
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

class _PharmacyInfoBox extends StatelessWidget {
  const _PharmacyInfoBox({required this.label, required this.value});

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

class _PharmacyServiceRow extends StatelessWidget {
  const _PharmacyServiceRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
