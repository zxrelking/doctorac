import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_date_formatter.dart';
import '../../../../core/utils/maps_launcher.dart';
import '../../../../core/widgets/doctorac_headers.dart';
import '../../domain/order_model.dart';
import '../providers/orders_provider.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  String _selectedFilter = 'الكل'; // الكل | الأدوية | التحاليل والأشعة

  Future<void> _reorder(OrderModel order) async {
    final now = DateTime.now();
    final refCode =
        '#ORD-${1000 + (now.millisecondsSinceEpoch % 8999)}';
    final duplicate = OrderModel(
      id: 'local-ord-${now.millisecondsSinceEpoch}',
      referenceCode: refCode,
      orderType: order.orderType,
      providerId: order.providerId,
      providerName: order.providerName,
      providerSubtitle: order.providerSubtitle,
      itemsSummary: order.itemsSummary,
      totalPrice: order.totalPrice,
      status: 'on_the_way',
      prescriptionUrl: order.prescriptionUrl,
      deliveryAddress: order.deliveryAddress,
      orderDateText:
          'اليوم، ${now.day} ${ArabicDateFormatter.months[now.month - 1]}',
    );
    await ref.read(ordersProvider.notifier).createOrder(duplicate);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إعادة الطلب بنجاح ($refCode)')),
    );
  }

  Future<void> _confirmCancelOrder(OrderModel order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'إلغاء الطلب',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'هل أنت متأكد من إلغاء طلب "${order.providerName}" (${order.referenceCode})؟',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، إلغاء الطلب'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await ref.read(ordersProvider.notifier).cancelOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء الطلب بنجاح')),
      );
    }
  }

  void _showTrackingSheet(OrderModel order) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'تتبع الطلب',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      order.referenceCode,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${order.providerName} • ${order.deliveryAddress}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 20),
              const _TrackingStep(
                title: 'تم استلام الطلب ومراجعة الأصناف',
                subtitle: 'مكتمل',
                done: true,
              ),
              const _TrackingStep(
                title: 'جاري التجهيز في الصيدلية',
                subtitle: 'مكتمل',
                done: true,
              ),
              const _TrackingStep(
                title: 'المندوب في الطريق إليك',
                subtitle: 'الوقت المتوقع للوصول: 20 دقيقة',
                done: true,
                isCurrent: true,
              ),
              const _TrackingStep(
                title: 'تم التسليم بنجاح',
                subtitle: 'قريباً',
                done: false,
                isLast: true,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLabResultSheet(OrderModel order) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'نتيجة ${order.providerName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mintSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'معتمدة',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${order.providerSubtitle} • ${order.orderDateText}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  children: [
                    _ResultMetricRow(
                      name: 'Hemoglobin (Hb)',
                      value: '13.4 g/dL',
                      range: '12.0 - 15.5',
                    ),
                    Divider(color: AppColors.divider, height: 18),
                    _ResultMetricRow(
                      name: 'WBC Count',
                      value: '6.8 x10³/µL',
                      range: '4.5 - 11.0',
                    ),
                    Divider(color: AppColors.divider, height: 18),
                    _ResultMetricRow(
                      name: 'Platelets',
                      value: '265 x10³/µL',
                      range: '150 - 450',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ملاحظة الطبيب: جميع المؤشرات ضمن المعدل الطبيعي.',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('حسناً'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تفاصيل الطلب ${order.referenceCode}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Text('مقدم الخدمة: ${order.providerName}'),
              const SizedBox(height: 6),
              Text('الأصناف: ${order.itemsSummary}'),
              const SizedBox(height: 6),
              Text('العنوان: ${order.deliveryAddress}'),
              const SizedBox(height: 6),
              Text('التاريخ: ${order.orderDateText}'),
              const SizedBox(height: 6),
              Text(
                'الإجمالي: ${order.totalPrice} جنيه',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DoctoracListHeader(
                        title: 'طلباتي',
                        subtitle: 'تابع طلبات الأدوية والتحاليل والأشعة.',
                        onBack: () => context.go('/home'),
                      ),
                      const SizedBox(height: 18),
                      // Filter Pills (الكل | الأدوية | التحاليل والأشعة)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _OrderFilterChip(
                              label: 'الكل',
                              isSelected: _selectedFilter == 'الكل',
                              onTap: () =>
                                  setState(() => _selectedFilter = 'الكل'),
                            ),
                            const SizedBox(width: 10),
                            _OrderFilterChip(
                              label: 'الأدوية',
                              isSelected: _selectedFilter == 'الأدوية',
                              onTap: () =>
                                  setState(() => _selectedFilter = 'الأدوية'),
                            ),
                            const SizedBox(width: 10),
                            _OrderFilterChip(
                              label: 'التحاليل والأشعة',
                              isSelected:
                                  _selectedFilter == 'التحاليل والأشعة',
                              onTap: () => setState(
                                () => _selectedFilter = 'التحاليل والأشعة',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              ordersAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (_, __) => const SliverFillRemaining(
                  child: Center(child: Text('تعذر تحميل الطلبات')),
                ),
                data: (orders) {
                  final filtered = orders.where((o) {
                    if (_selectedFilter == 'الأدوية') {
                      return o.orderType == 'pharmacy';
                    }
                    if (_selectedFilter == 'التحاليل والأشعة') {
                      return o.orderType == 'lab' ||
                          o.orderType == 'radiology';
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'لا توجد طلبات في هذا القسم حالياً',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        ...filtered.map(
                          (order) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _OrderCard(
                              order: order,
                              onCancel: order.isCancellable
                                  ? () => _confirmCancelOrder(order)
                                  : null,
                              onPrimaryAction: () =>
                                  order.orderType == 'pharmacy'
                                      ? _reorder(order)
                                      : _showLabResultSheet(order),
                              onSecondaryAction: () =>
                                  order.orderType == 'pharmacy'
                                      ? _showTrackingSheet(order)
                                      : _showOrderDetails(order),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                ExternalLauncher.openSupport(context),
                            child: const Text(
                              'تحتاج مساعدة في طلبك؟ تواصل مع الدعم',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderFilterChip extends StatelessWidget {
  const _OrderFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintChipActive : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? AppColors.mintBorder : AppColors.cardBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    this.onCancel,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  final OrderModel order;
  final VoidCallback? onCancel;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final isPharmacy = order.orderType == 'pharmacy';
    final isCancelled = order.status == 'cancelled';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? AppColors.dangerBg
                      : AppColors.mintSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.arabicStatus,
                  style: TextStyle(
                    color: isCancelled ? AppColors.danger : AppColors.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  order.referenceCode,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onCancel != null) ...[
                const SizedBox(width: 10),
                Tooltip(
                  message: 'إلغاء الطلب',
                  child: InkWell(
                    onTap: onCancel,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.danger,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.mintSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isPharmacy
                      ? Icons.local_hospital_outlined
                      : order.orderType == 'lab'
                          ? Icons.science_outlined
                          : Icons.biotech_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.providerName,
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
                      order.providerSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.itemsSummary,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Date + Total Mint Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.mintSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.orderDateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 26,
                  color: AppColors.mintBorder,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'الإجمالي',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${order.totalPrice} جنيه',
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onPrimaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mintSurface,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isPharmacy ? 'إعادة الطلب' : 'عرض النتيجة',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onSecondaryAction,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.mintBorder,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isPharmacy ? 'تتبع الطلب' : 'تفاصيل الطلب',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackingStep extends StatelessWidget {
  const _TrackingStep({
    required this.title,
    required this.subtitle,
    required this.done,
    this.isCurrent = false,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final bool done;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: done ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? AppColors.primary : AppColors.mintBorder,
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: done ? AppColors.primary : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isCurrent
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
        ),
      ],
    );
  }
}

class _ResultMetricRow extends StatelessWidget {
  const _ResultMetricRow({
    required this.name,
    required this.value,
    required this.range,
  });

  final String name;
  final String value;
  final String range;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              name,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              'المعدل: $range',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
