import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'gradient_button.dart';

/// Fixed Sticky Bottom Action Bar (Price/Title on RTL start + Primary CTA on RTL end).
/// Anchored to `Scaffold.bottomNavigationBar` so scrollable body never gets obscured.
class StickyBottomActionBar extends StatelessWidget {
  const StickyBottomActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPressed,
    this.priceText,
    this.subtitleText,
    this.isLoading = false,
    this.fullWidthButton = false,
  });

  final String primaryLabel;
  final VoidCallback? onPressed;
  final String? priceText;
  final String? subtitleText;
  final bool isLoading;
  final bool fullWidthButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
        boxShadow: AppColors.bottomBarShadow,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: fullWidthButton
              ? SolidTealButton(
                  label: primaryLabel,
                  onPressed: onPressed,
                  isLoading: isLoading,
                  height: 54,
                  borderRadius: 16,
                  fontSize: 16,
                )
              : Row(
                  children: [
                    if (priceText != null) ...[
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            priceText!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          if (subtitleText != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitleText!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(width: 18),
                    ],
                    Expanded(
                      child: SolidTealButton(
                        label: primaryLabel,
                        onPressed: onPressed,
                        isLoading: isLoading,
                        height: 52,
                        borderRadius: 16,
                        fontSize: 15.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
