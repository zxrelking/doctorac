import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Crisp 3D-style Doctorac emerald medical cross logo + "Doctorac" wordmark.
class DoctoracLogo extends StatelessWidget {
  const DoctoracLogo({
    super.key,
    this.iconSize = 32,
    this.fontSize = 22,
    this.axis = Axis.horizontal,
    this.spacing = 8,
  });

  final double iconSize;
  final double fontSize;
  final Axis axis;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final cross = DoctoracCrossMark(size: iconSize);
    final wordmark = Directionality(
      textDirection: TextDirection.ltr,
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            letterSpacing: -0.4,
            height: 1.1,
          ),
          children: const [
            TextSpan(
              text: 'Doctor',
              style: TextStyle(
                color: Color(0xFF0E1614),
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: 'ac',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    if (axis == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          cross,
          SizedBox(height: spacing),
          wordmark,
        ],
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          cross,
          SizedBox(width: spacing),
          wordmark,
        ],
      ),
    );
  }
}

class DoctoracCrossMark extends StatelessWidget {
  const DoctoracCrossMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DoctoracCrossPainter(),
      ),
    );
  }
}

class _DoctoracCrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final arm = w * 0.30;
    final start = (w - arm) / 2;
    final radius = Radius.circular(w * 0.11);

    // Base cross path
    final verticalRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(start, 0, arm, h),
      radius,
    );
    final horizontalRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, start, w, arm),
      radius,
    );

    final crossPath = Path.combine(
      PathOperation.union,
      Path()..addRRect(verticalRect),
      Path()..addRRect(horizontalRect),
    );

    // Soft drop shadow
    canvas.drawShadow(crossPath, const Color(0x400E4D3B), w * 0.08, false);

    canvas.save();
    canvas.clipPath(crossPath);

    // Base rich gradient
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xFF349A7B),
          Color(0xFF1A6B54),
          Color(0xFF0D4435),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), basePaint);

    // Top-right bright emerald facet (3D folded look matching Figma)
    final topRightFacet = Path()
      ..moveTo(w * 0.50, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.50)
      ..quadraticBezierTo(w * 0.52, h * 0.50, w * 0.50, 0)
      ..close();
    canvas.drawPath(
      topRightFacet,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3EA686), Color(0xFF1D745B)],
        ).createShader(Rect.fromLTWH(w * 0.5, 0, w * 0.5, h * 0.5)),
    );

    // Bottom-left deep teal facet
    final bottomLeftFacet = Path()
      ..moveTo(0, h * 0.50)
      ..lineTo(w * 0.50, h * 0.50)
      ..lineTo(w * 0.50, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      bottomLeftFacet,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF237B61), Color(0xFF0F4C3B)],
        ).createShader(Rect.fromLTWH(0, h * 0.5, w * 0.5, h * 0.5)),
    );

    // Dark curved 4-point center star fold (signature Doctorac detail)
    final cx = w * 0.50;
    final cy = h * 0.50;
    final starPath = Path()
      ..moveTo(cx, cy - h * 0.34)
      ..quadraticBezierTo(cx, cy, cx + w * 0.34, cy)
      ..quadraticBezierTo(cx, cy, cx, cy + h * 0.34)
      ..quadraticBezierTo(cx, cy, cx - w * 0.34, cy)
      ..quadraticBezierTo(cx, cy, cx, cy - h * 0.34)
      ..close();

    canvas.drawPath(
      starPath,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF07281F), Color(0xFF0E4536)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.34)),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
