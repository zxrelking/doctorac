import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Exact Figma stylized vector map preview card used on Doctor Details screen.
class MapPreviewCard extends StatelessWidget {
  const MapPreviewCard({
    super.key,
    required this.title,
    required this.address,
    required this.onDirectionsTap,
  });

  final String title;
  final String address;
  final VoidCallback onDirectionsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 118,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StylizedMapPainter(),
                  ),
                ),
                // Pin positioned slightly right-center matching Figma
                const Positioned(
                  top: 26,
                  right: 110,
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                // "عرض الاتجاهات" pill button on bottom-left (RTL end)
                PositionedDirectional(
                  end: 14,
                  bottom: 16,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 2,
                    shadowColor: const Color(0x220E2A22),
                    child: InkWell(
                      onTap: onDirectionsTap,
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'عرض الاتجاهات',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
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
    );
  }
}

class _StylizedMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Soft sage-mint background blocks
    final bgPaint = Paint()..color = const Color(0xFFE7F1ED);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Park / highlight block
    final parkPaint = Paint()..color = const Color(0xFFCDE1D9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.44, size.height * 0.44, 52, 28),
        const Radius.circular(8),
      ),
      parkPaint,
    );

    // Subtle white street grid
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;

    // Horizontal roads
    canvas.drawLine(
      Offset(0, size.height * 0.30),
      Offset(size.width, size.height * 0.30),
      roadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.76),
      Offset(size.width, size.height * 0.76),
      roadPaint,
    );

    // Vertical roads
    for (final x in [0.18, 0.40, 0.72]) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        roadPaint,
      );
    }

    // Diagonal route line
    final routePaint = Paint()
      ..color = const Color(0xFFB5D3C7)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.65)
      ..lineTo(size.width * 0.42, size.height * 0.22)
      ..lineTo(size.width, size.height * 0.46);
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
