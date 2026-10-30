import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HamhaLogo extends StatelessWidget {
  final double size;
  final bool showSubtitle;

  const HamhaLogo({
    super.key,
    this.size = 110,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/hamha_logo.png',
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/hamha_logo.jpg',
            height: size,
            fit: BoxFit.contain,
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
