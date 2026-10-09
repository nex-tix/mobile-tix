import 'package:flutter/material.dart';

/// Paints the iconic Uluwatu cliff, sea mist gradient, and tiered temple
/// silhouette matching Screen 1 (Login) from `newDesign`.
class UluwatuCliffPainter extends CustomPainter {
  const UluwatuCliffPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Scale factors relative to the 390x180 design viewport
    final scaleX = w / 390.0;
    final scaleY = h / 180.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 1. Far background subtle mountains & mist
    final mistPaint = Paint()
      ..color = const Color(0xFF1E282C).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    final mistPath = Path()
      ..moveTo(0, 130)
      ..cubicTo(70, 120, 140, 135, 210, 115)
      ..cubicTo(280, 95, 330, 110, 390, 100)
      ..lineTo(390, 180)
      ..lineTo(0, 180)
      ..close();
    canvas.drawPath(mistPath, mistPaint);

    // 2. Sea / Coastline gradient plane
    final seaPaint = Paint()
      ..color = const Color(0xFF242F34).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final seaPath = Path()
      ..moveTo(0, 145)
      ..cubicTo(90, 142, 180, 152, 270, 140)
      ..cubicTo(330, 132, 360, 138, 390, 134)
      ..lineTo(390, 180)
      ..lineTo(0, 180)
      ..close();
    canvas.drawPath(seaPath, seaPaint);

    // 3. Tanah Lot / Uluwatu tiered temple roof details
    final templeDetailPaint = Paint()
      ..color = const Color(0xFF1B2326)
      ..style = PaintingStyle.fill;

    // Multi-tier meru roofs
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 94, 18, 3),
        const Radius.circular(1.5),
      ),
      templeDetailPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(39, 88, 12, 3),
        const Radius.circular(1),
      ),
      templeDetailPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(42, 82, 6, 3),
        const Radius.circular(0.5),
      ),
      templeDetailPaint,
    );

    // Temple shrine base
    final shrinePath = Path()
      ..moveTo(30, 115)
      ..lineTo(60, 115)
      ..lineTo(52, 97)
      ..lineTo(38, 97)
      ..close();
    final shrinePaint = Paint()
      ..color = const Color(0xFF1D262A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(shrinePath, shrinePaint);

    // 4. Cliff base outcropping with cliff gradient
    final cliffRect = const Rect.fromLTWH(-20, 115, 260, 65);
    final cliffGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x33212B2F), Color(0xCC1A2327), Color(0xFF141C1F)],
      stops: [0.0, 0.6, 1.0],
    ).createShader(cliffRect);

    final cliffPaint = Paint()
      ..shader = cliffGrad
      ..style = PaintingStyle.fill;

    final cliffPath = Path()
      ..moveTo(-20, 180)
      ..lineTo(-10, 130)
      ..cubicTo(15, 125, 35, 115, 50, 122)
      ..cubicTo(68, 130, 75, 142, 95, 146)
      ..cubicTo(115, 150, 135, 162, 165, 170)
      ..cubicTo(185, 175, 220, 178, 240, 180)
      ..close();
    canvas.drawPath(cliffPath, cliffPaint);

    // 5. Distant right headland cliff
    final headlandPaint = Paint()
      ..color = const Color(0xFF182023).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final headlandPath = Path()
      ..moveTo(280, 180)
      ..cubicTo(310, 168, 340, 155, 365, 150)
      ..cubicTo(380, 147, 385, 148, 400, 145)
      ..lineTo(400, 180)
      ..close();
    canvas.drawPath(headlandPath, headlandPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
