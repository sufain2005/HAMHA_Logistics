import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Interactive Ambient Motion Background
/// Renders moving animated transit routes, pulsing GPS waypoints,
/// and smooth floating logistics nodes over the warm cream canvas.
class LogisticsMotionBackground extends StatefulWidget {
  final Widget child;
  const LogisticsMotionBackground({super.key, required this.child});

  @override
  State<LogisticsMotionBackground> createState() => _LogisticsMotionBackgroundState();
}

class _LogisticsMotionBackgroundState extends State<LogisticsMotionBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Cream Scaffold
        Container(color: HamhaTheme.warmCream),

        // Animated Logistics Vector Network Canvas
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _LogisticsNetworkPainter(progress: _controller.value),
              );
            },
          ),
        ),

        // Child Content (Cards / Forms / Screens)
        widget.child,
      ],
    );
  }
}

class _LogisticsNetworkPainter extends CustomPainter {
  final double progress;
  _LogisticsNetworkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Route Waypoints across the screen
    final points = [
      Offset(w * 0.10, h * 0.18 + math.sin(progress * 2 * math.pi) * 12),
      Offset(w * 0.32, h * 0.30 + math.cos(progress * 2 * math.pi) * 16),
      Offset(w * 0.75, h * 0.15 + math.sin((progress + 0.3) * 2 * math.pi) * 14),
      Offset(w * 0.88, h * 0.45 + math.cos((progress + 0.5) * 2 * math.pi) * 18),
      Offset(w * 0.65, h * 0.78 + math.sin((progress + 0.7) * 2 * math.pi) * 15),
      Offset(w * 0.22, h * 0.82 + math.cos((progress + 0.2) * 2 * math.pi) * 12),
    ];

    // 1. Draw connecting courier route lines with subtle dashed effect
    final linePaint = Paint()
      ..color = HamhaTheme.crimsonRed.withAlpha(22)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      final midY = (prev.dy + curr.dy) / 2;
      path.quadraticBezierTo(prev.dx, prev.dy, midX, midY);
    }
    path.close();
    canvas.drawPath(path, linePaint);

    // 2. Secondary Deep Black Network Lines
    final darkLinePaint = Paint()
      ..color = HamhaTheme.deepBlack.withAlpha(14)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(points[1], points[4], darkLinePaint);
    canvas.drawLine(points[0], points[5], darkLinePaint);
    canvas.drawLine(points[2], points[3], darkLinePaint);

    // 3. Draw pulsing GPS transit nodes (Crimson & Black)
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final pulse = (math.sin((progress + (i * 0.2)) * 2 * math.pi) + 1) / 2;

      // Outer ripple
      final ripplePaint = Paint()
        ..color = (i % 2 == 0 ? HamhaTheme.crimsonRed : HamhaTheme.deepBlack)
            .withAlpha((20 + (pulse * 30)).toInt())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(p, 10 + (pulse * 8), ripplePaint);

      // Inner solid core node
      final nodePaint = Paint()
        ..color = (i % 2 == 0 ? HamhaTheme.crimsonRed : HamhaTheme.deepBlack)
            .withAlpha(120)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 4.0, nodePaint);
    }

    // 4. Moving package packet along the route
    final movingIndex = (progress * (points.length - 1)).floor();
    final nextIndex = (movingIndex + 1) % points.length;
    final subProgress = (progress * (points.length - 1)) - movingIndex;

    final p1 = points[movingIndex];
    final p2 = points[nextIndex];
    final movingX = p1.dx + (p2.dx - p1.dx) * subProgress;
    final movingY = p1.dy + (p2.dy - p1.dy) * subProgress;

    // Glowing Crimson transit pulse
    final glowPaint = Paint()
      ..color = HamhaTheme.crimsonRed.withAlpha(90)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(movingX, movingY), 7, glowPaint);

    final corePaint = Paint()
      ..color = HamhaTheme.crimsonRed
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(movingX, movingY), 4, corePaint);
  }

  @override
  bool shouldRepaint(covariant _LogisticsNetworkPainter oldDelegate) => true;
}

