import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/models/fleet_driver_model.dart';
import '../../../core/theme/admin_theme.dart';

class FleetDriverMarkerWidget extends StatelessWidget {
  final FleetDriverModel driver;
  final bool isSelected;
  final VoidCallback onTap;

  const FleetDriverMarkerWidget({
    super.key,
    required this.driver,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = driver.statusColor;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Selected Pulse Wave
          if (isSelected)
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withAlpha(35),
                border: Border.all(color: statusColor, width: 2),
              ),
            ),

          // Heading direction pointer
          if (driver.heading > 0 && driver.status != DriverFleetStatus.offline)
            Transform.rotate(
              angle: (driver.heading * math.pi) / 180,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: Icon(
                  Icons.navigation,
                  size: 13,
                  color: isSelected ? AdminTheme.crimsonRed : statusColor,
                ),
              ),
            ),

          // Central Driver Vehicle Shield
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected ? AdminTheme.deepBlack : AdminTheme.surfaceBlack,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AdminTheme.crimsonRed : statusColor,
                width: isSelected ? 2.5 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withAlpha(isSelected ? 160 : 90),
                  blurRadius: isSelected ? 14 : 8,
                  spreadRadius: isSelected ? 2 : 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              driver.vehicleIcon,
              color: isSelected ? AdminTheme.crispWhite : statusColor,
              size: 20,
            ),
          ),

          // Small Status Pip (Top Right)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: AdminTheme.deepBlack, width: 1.8),
              ),
            ),
          ),

          // Compact Label Tag Pill
          Positioned(
            bottom: -22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AdminTheme.deepBlack.withAlpha(230),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AdminTheme.crimsonRed : AdminTheme.borderBlack,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    driver.name.split(' ').first,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AdminTheme.crimsonLight : AdminTheme.crispWhite,
                    ),
                  ),
                  if (driver.speedKmh > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '${driver.speedKmh.toInt()}k',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

