import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Header used on list & tab screens (الأطباء، المعامل، الصيدليات، الأشعة، مواعيدي، طلباتي، حسابي).
/// Matches exact Figma: soft mint circular back chevron + bold title on the right, optional subtitle below.
class DoctoracListHeader extends StatelessWidget {
  const DoctoracListHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null) ...[
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.mintSurface,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
          ),
        ],
      ],
    );
  }
}

/// Header used on detail & booking screens (تفاصيل الطبيب، اختيار الموعد، تأكيد الحجز، etc.).
/// Matches exact Figma: centered bold title + white circular back arrow on RTL start (right).
class DoctoracDetailHeader extends StatelessWidget {
  const DoctoracDetailHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.softShadow,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home section header with teal vertical bar accent (خدماتنا / أفضل الأطباء).
class DoctoracSectionTitle extends StatelessWidget {
  const DoctoracSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            if (actionLabel != null && onAction != null)
              GestureDetector(
                onTap: onAction,
                child: Text(
                  actionLabel!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
          ),
        ],
      ],
    );
  }
}
