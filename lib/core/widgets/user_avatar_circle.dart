import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'cached_image_box.dart';

/// Displays the user's real avatar (uploaded photo or Google photo),
/// or a clean medical-teal initials badge when no photo has been uploaded yet.
class UserAvatarCircle extends StatelessWidget {
  const UserAvatarCircle({
    super.key,
    required this.avatarUrl,
    required this.initials,
    this.size = 44,
    this.borderWidth = 2,
  });

  final String avatarUrl;
  final String initials;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.mintBorder, width: borderWidth),
      ),
      child: avatarUrl.trim().isNotEmpty
          ? CachedImageBox(
              imageUrl: avatarUrl,
              width: size,
              height: size,
              isCircle: true,
            )
          : Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: AppColors.mintSurface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}
