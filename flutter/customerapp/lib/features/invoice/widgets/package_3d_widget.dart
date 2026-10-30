import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class Package3DWidget extends StatefulWidget {
  final double size;
  const Package3DWidget({super.key, this.size = 140});

  @override
  State<Package3DWidget> createState() => _Package3DWidgetState();
}

class _Package3DWidgetState extends State<Package3DWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Subtle floating altitude translation
        final floatOffset = math.sin(_controller.value * math.pi * 2) * 6;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _IsometricBoxPainter(),
            ),
          ),
        );
      },
    );
  }
}

class _IsometricBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 - 10;

    // Ground soft shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 55), width: w * 0.75, height: 26), shadowPaint);

    // Box dimensions in isometric projection
    const double boxW = 46.0;
    const double boxH = 46.0;

    // Points
    final topCenter = Offset(cx, cy - 25);
    final topVertex = Offset(cx, cy - 25 - (boxH * 0.5));
    final leftTop = Offset(cx - boxW, cy - 25);
    final rightTop = Offset(cx + boxW, cy - 25);

    final leftBottom = Offset(cx - boxW, cy + boxH - 20);
    final centerBottom = Offset(cx, cy + boxH);
    final rightBottom = Offset(cx + boxW, cy + boxH - 20);

    // 1. TOP FACE (Cardboard Light Ochre)
    final topFace = Path()
      ..moveTo(cx, cy - 48)
      ..lineTo(rightTop.dx, rightTop.dy)
      ..lineTo(cx, cy - 2)
      ..lineTo(leftTop.dx, leftTop.dy)
      ..close();

    final topPaint = Paint()..color = const Color(0xFFE2C498);
    canvas.drawPath(topFace, topPaint);

    // 2. LEFT FACE (Cardboard Medium Ochre)
    final leftFace = Path()
      ..moveTo(leftTop.dx, leftTop.dy)
      ..lineTo(cx, cy - 2)
      ..lineTo(centerBottom.dx, centerBottom.dy)
      ..lineTo(leftBottom.dx, leftBottom.dy)
      ..close();

    final leftPaint = Paint()..color = const Color(0xFFC9A676);
    canvas.drawPath(leftFace, leftPaint);

    // 3. RIGHT FACE (Cardboard Dark Ochre / Shadowed)
    final rightFace = Path()
      ..moveTo(cx, cy - 2)
      ..lineTo(rightTop.dx, rightTop.dy)
      ..lineTo(rightBottom.dx, rightBottom.dy)
      ..lineTo(centerBottom.dx, centerBottom.dy)
      ..close();

    final rightPaint = Paint()..color = const Color(0xFFB08C5D);
    canvas.drawPath(rightFace, rightPaint);

    // 4. CRIMSON RED SECURITY TAPE (Brand Detail)
    final tapePaint = Paint()
      ..color = HamhaTheme.crimsonRed
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    // Tape crossing top
    canvas.drawLine(Offset(cx - 23, cy - 25), Offset(cx + 23, cy - 25), tapePaint);

    // Tape going down the center
    final centerTapePaint = Paint()
      ..color = HamhaTheme.crimsonDark
      ..strokeWidth = 9;
    canvas.drawLine(Offset(cx, cy - 2), Offset(cx, cy + boxH), centerTapePaint);

    // 5. White Barcode Shipping Label
    final labelPath = Path()
      ..moveTo(cx - 36, cy + 2)
      ..lineTo(cx - 14, cy + 12)
      ..lineTo(cx - 14, cy + 28)
      ..lineTo(cx - 36, cy + 18)
      ..close();

    final labelPaint = Paint()..color = HamhaTheme.crispWhite;
    canvas.drawPath(labelPath, labelPaint);

    // Tiny Barcode lines on label
    final barcodePaint = Paint()
      ..color = HamhaTheme.deepBlack
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(cx - 32, cy + 8), Offset(cx - 32, cy + 18), barcodePaint);
    canvas.drawLine(Offset(cx - 28, cy + 10), Offset(cx - 28, cy + 20), barcodePaint);
    canvas.drawLine(Offset(cx - 24, cy + 12), Offset(cx - 24, cy + 22), barcodePaint);
    canvas.drawLine(Offset(cx - 20, cy + 14), Offset(cx - 20, cy + 24), barcodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

