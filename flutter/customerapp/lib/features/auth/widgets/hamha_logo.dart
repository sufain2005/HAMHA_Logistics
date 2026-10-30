import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HamhaLogo extends StatelessWidget {
  final double size;
  final bool showSubtitle;

  const HamhaLogo({
    super.key,
    this.size = 90,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _HamhaLogoPainter(),
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              fontFamily: 'sans-serif',
            ),
            children: [
              TextSpan(text: 'HAMHA ', style: TextStyle(color: HamhaTheme.deepBlack)),
              TextSpan(text: 'LOGISTICS', style: TextStyle(color: HamhaTheme.crimsonRed)),
            ],
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: HamhaTheme.deepBlack,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'FAST • SECURE • NATIONWIDE FREIGHT',
              style: TextStyle(
                color: HamhaTheme.crispWhite,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HamhaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Deep Black circular shield
    final circlePaint = Paint()
      ..color = HamhaTheme.deepBlack
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.48, circlePaint);

    // Crimson Red accent outer ring
    final borderPaint = Paint()
      ..color = HamhaTheme.crimsonRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.48, borderPaint);

    // Dynamic Crimson Swoosh
    final swooshPaint = Paint()
      ..color = HamhaTheme.crimsonRed
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.085;

    final path = Path();
    path.moveTo(w * 0.16, h * 0.65);
    path.quadraticBezierTo(w * 0.35, h * 0.88, w * 0.82, h * 0.42);
    canvas.drawPath(path, swooshPaint);

    // Letter 'H' stylized in Crisp White
    final hPaint = Paint()
      ..color = HamhaTheme.crispWhite
      ..strokeWidth = w * 0.095
      ..strokeCap = StrokeCap.square;

    // Left vertical bar
    canvas.drawLine(Offset(w * 0.35, h * 0.28), Offset(w * 0.35, h * 0.72), hPaint);
    // Right vertical bar
    canvas.drawLine(Offset(w * 0.65, h * 0.28), Offset(w * 0.65, h * 0.72), hPaint);
    // Cross bar
    canvas.drawLine(Offset(w * 0.35, h * 0.50), Offset(w * 0.65, h * 0.50), hPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
