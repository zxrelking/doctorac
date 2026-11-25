import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Production-grade network/local image widget with shimmer loading & graceful fallback.
class CachedImageBox extends StatelessWidget {
  const CachedImageBox({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.isCircle = false,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.person_rounded,
    this.backgroundColor = AppColors.mintSurface,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isCircle;
  final BoxFit fit;
  final IconData fallbackIcon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';

    Widget child;
    if (url.isEmpty) {
      child = _buildFallback();
    } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final file = File(url);
      if (file.existsSync()) {
        child = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      } else {
        child = _buildFallback();
      }
    } else {
      child = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: AppColors.mintSurface,
          highlightColor: Colors.white,
          child: Container(
            width: width,
            height: height,
            color: AppColors.mintSurface,
          ),
        ),
        errorWidget: (_, __, ___) => _buildFallback(),
      );
    }

    if (isCircle) {
      return ClipOval(
        child: Container(
          width: width,
          height: height,
          color: backgroundColor,
          child: child,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: backgroundColor,
        child: child,
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: AppColors.primary,
        size: (width ?? 48) * 0.45,
      ),
    );
  }
}
