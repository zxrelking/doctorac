import 'package:flutter/material.dart';

/// Doctorac exact 1:1 Figma color tokens.
class AppColors {
  AppColors._();

  // Brand Primary
  static const Color primary = Color(0xFF1A6B54);
  static const Color primaryDark = Color(0xFF145E4A);
  static const Color primaryDeep = Color(0xFF0E4D3B);
  static const Color primaryLight = Color(0xFF52B79B);
  static const Color primaryAccent = Color(0xFF2B8C70);

  // Soft Mint Surfaces
  static const Color mintSurface = Color(0xFFEBF5F1);
  static const Color mintChipActive = Color(0xFFE3F2EC);
  static const Color mintBorder = Color(0xFFC8E3D8);
  static const Color mintGlow = Color(0xFFDCEEE7);

  // Backgrounds & Cards
  static const Color background = Color(0xFFF8FAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFFFFFFF);
  static const Color inputSoftFill = Color(0xFFF3F6F5);
  static const Color cardBorder = Color(0xFFEDF2F0);
  static const Color divider = Color(0xFFEAEFED);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFF12211D);
  static const Color textSecondary = Color(0xFF6B7B76);
  static const Color textMuted = Color(0xFF94A39E);

  // Status & Accents
  static const Color starAmber = Color(0xFFF5A623);
  static const Color ratingText = Color(0xFFA66614);
  static const Color scheduledBg = Color(0xFFFDF2DC);
  static const Color scheduledText = Color(0xFFA46610);
  static const Color danger = Color(0xFFD64545);
  static const Color dangerBg = Color(0xFFFDECEC);

  // Lab Icon Soft Tints (matching Labs List Figma)
  static const Color labBloodBg = Color(0xFFFAECEE);
  static const Color labVitaminBg = Color(0xFFFAF6E8);
  static const Color labLiverBg = Color(0xFFF8EFEF);
  static const Color radiologyIconBg = Color(0xFFEAF3F2);

  // Gradients
  static const LinearGradient authButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryLight, primary, primaryDark],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient radiologyBannerGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF167258), Color(0xFF0E4F3D)],
  );

  // Shadows
  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x0D0E2A22),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get softShadow => const [
        BoxShadow(
          color: Color(0x0A0E2A22),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get buttonShadow => const [
        BoxShadow(
          color: Color(0x2E1A6B54),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get bottomBarShadow => const [
        BoxShadow(
          color: Color(0x120E2A22),
          blurRadius: 20,
          offset: Offset(0, -4),
        ),
      ];
}
