import 'package:flutter/material.dart';
import '../../../core/theme/admin_theme.dart';

class AdminHamhaLogo extends StatelessWidget {
  final double size;
  const AdminHamhaLogo({super.key, this.size = 110});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/hamha_logo_dark.png',
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(
              'assets/images/hamha_logo.jpg',
              height: size * 0.8,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AdminTheme.surfaceBlack,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AdminTheme.borderBlack, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, color: AdminTheme.crimsonRed, size: 14),
              SizedBox(width: 8),
              Text(
                'OWNER PANEL • FLEET OPERATIONS',
                style: TextStyle(
                  color: AdminTheme.crispWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
