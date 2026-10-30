import 'package:flutter/material.dart';
import '../../../core/theme/driver_theme.dart';

class DriverHamhaLogo extends StatelessWidget {
  final double size;
  const DriverHamhaLogo({super.key, this.size = 100});

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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: DriverTheme.deepBlack,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_shipping, color: DriverTheme.crimsonRed, size: 14),
              SizedBox(width: 8),
              Text(
                'DRIVER & CARRIER FLEET',
                style: TextStyle(
                  color: DriverTheme.crispWhite,
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
