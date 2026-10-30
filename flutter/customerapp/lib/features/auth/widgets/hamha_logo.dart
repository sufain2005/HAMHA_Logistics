import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HamhaLogo extends StatelessWidget {
  final double size;
  final bool showSubtitle;

  const HamhaLogo({
    super.key,
    this.size = 100,
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
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              fontFamily: 'sans-serif',
            ),
            children: [
              TextSpan(text: 'HAMHA ', style: TextStyle(color: HamhaTheme.crispWhite)),
              TextSpan(text: 'LOGISTICS', style: TextStyle(color: HamhaTheme.crimsonRed)),
            ],
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 6),
          const Text(
            'FAST • SECURE • NATIONWIDE FREIGHT',
            style: TextStyle(
              color: HamhaTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
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

    // Background shield/circle ring
    final circlePaint = Paint()
      ..color = HamhaTheme.cardBlack
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.48, circlePaint);

    final borderPaint = Paint()
      ..color = HamhaTheme.crimsonRed.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.48, borderPaint);

    // Dynamic Crimson Swoosh
    final swooshPaint = Paint()
      ..color = HamhaTheme.crimsonRed
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.08;

    final path = Path();
    path.moveTo(w * 0.18, h * 0.65);
    path.quadraticBezierTo(w * 0.35, h * 0.88, w * 0.78, h * 0.45);
    canvas.drawPath(path, swooshPaint);

    // Letter 'H' stylized in crisp white
    final hPaint = Paint()
      ..color = HamhaTheme.crispWhite
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.square;

    // Left bar
    canvas.drawLine(Offset(w * 0.34, h * 0.28), Offset(w * 0.34, h * 0.72), hPaint);
    // Right bar
    canvas.drawLine(Offset(w * 0.66, h * 0.28), Offset(w * 0.66, h * 0.72), hPaint);
    // Cross bar
    canvas.drawLine(Offset(w * 0.34, h * 0.50), Offset(w * 0.66, h * 0.50), hPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

