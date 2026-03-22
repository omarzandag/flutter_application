import 'package:flutter/material.dart';

class StadiumPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Colors
    final lightGrass = const Color(0xFF4CAF50);
    final darkGrass = const Color(0xFF388E3C);
    final lineColor = Colors.white.withOpacity(0.8);
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw grass stripes
    const int stripeCount = 10;
    final double stripeHeight = size.height / stripeCount;
    for (int i = 0; i < stripeCount; i++) {
      final rect = Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight);
      final paint = Paint()..color = (i % 2 == 0) ? lightGrass : darkGrass;
      canvas.drawRect(rect, paint);
    }

    // Draw outer boundary
    final fieldRect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    canvas.drawRect(fieldRect, linePaint);

    // Center line
    canvas.drawLine(
      Offset(10, size.height / 2),
      Offset(size.width - 10, size.height / 2),
      linePaint,
    );

    // Center circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.15,
      linePaint,
    );
    // Center spot
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      3,
      Paint()..color = lineColor,
    );

    // Penalty Areas
    final double penaltyAreaWidth = size.width * 0.5;
    final double penaltyAreaHeight = size.height * 0.15;
    final double goalAreaWidth = size.width * 0.25;
    final double goalAreaHeight = size.height * 0.05;

    // Top Penalty Area
    canvas.drawRect(
      Rect.fromLTWH((size.width - penaltyAreaWidth) / 2, 10, penaltyAreaWidth, penaltyAreaHeight),
      linePaint,
    );
    // Top Goal Area
    canvas.drawRect(
      Rect.fromLTWH((size.width - goalAreaWidth) / 2, 10, goalAreaWidth, goalAreaHeight),
      linePaint,
    );
    // Top Penalty Arc (semi-circle)
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, 10 + penaltyAreaHeight),
        width: size.width * 0.2,
        height: size.width * 0.2,
      ),
      0,
      3.14159,
      false,
      linePaint,
    );

    // Bottom Penalty Area
    canvas.drawRect(
      Rect.fromLTWH((size.width - penaltyAreaWidth) / 2, size.height - 10 - penaltyAreaHeight, penaltyAreaWidth, penaltyAreaHeight),
      linePaint,
    );
    // Bottom Goal Area
    canvas.drawRect(
      Rect.fromLTWH((size.width - goalAreaWidth) / 2, size.height - 10 - goalAreaHeight, goalAreaWidth, goalAreaHeight),
      linePaint,
    );
    // Bottom Penalty Arc
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 10 - penaltyAreaHeight),
        width: size.width * 0.2,
        height: size.width * 0.2,
      ),
      3.14159,
      3.14159,
      false,
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
