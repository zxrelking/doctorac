import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Auth linear gradient pill CTA button (#52B79B -> #145E4A) matching Figma 1:1.
class GradientCtaButton extends StatelessWidget {
  const GradientCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 56,
    this.borderRadius = 28,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? LinearGradient(
                colors: [
                  AppColors.primaryLight.withValues(alpha: 0.5),
                  AppColors.primaryDark.withValues(alpha: 0.5),
                ],
              )
            : AppColors.authButtonGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: onPressed == null ? null : AppColors.buttonShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Solid Deep Medical Teal pill button for cards & action bars.
class SolidTealButton extends StatelessWidget {
  const SolidTealButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 50,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.fontSize = 14.5,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55),
          padding: padding,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
