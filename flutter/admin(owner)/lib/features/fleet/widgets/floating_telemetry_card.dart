import 'package:flutter/material.dart';
import '../../../core/models/fleet_driver_model.dart';
import '../../../core/theme/admin_theme.dart';

class FloatingTelemetryCard extends StatelessWidget {
  final FleetDriverModel driver;
  final bool isRouteVisible;
  final VoidCallback onClose;
  final VoidCallback onToggleRoute;
  final VoidCallback onCenterMap;
  final VoidCallback onManualDispatch;

  const FloatingTelemetryCard({
    super.key,
    required this.driver,
    required this.isRouteVisible,
    required this.onClose,
    required this.onToggleRoute,
    required this.onCenterMap,
    required this.onManualDispatch,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = driver.statusColor;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          color: AdminTheme.crispWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AdminTheme.borderSubtle, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminTheme.borderSubtle)),
              ),
              child: Row(
                children: [
                  // Status Beacon
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: statusColor.withAlpha(140), blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AdminTheme.deepBlack,
                          ),
                        ),
                        Text(
                          '${driver.phone} • ${driver.district}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AdminTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AdminTheme.textMuted),
                    onPressed: onClose,
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Telemetry Highlights Grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Current Speed
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.speed,
                          iconColor: AdminTheme.crimsonRed,
                          label: 'LIVE SPEED',
                          value: '${driver.speedKmh.toStringAsFixed(0)} km/h',
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Battery Percent
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.battery_charging_full,
                          iconColor: driver.batteryPercent > 20 ? AdminTheme.statusOnline : AdminTheme.crimsonRed,
                          label: 'DEVICE BATTERY',
                          value: '${driver.batteryPercent}%',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Online Duration
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.access_time_filled,
                          iconColor: const Color(0xFF38BDF8),
                          label: 'SHIFT DURATION',
                          value: driver.onlineDuration,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Vehicle Plate
                      Expanded(
                        child: _buildMetricTile(
                          icon: driver.vehicleIcon,
                          iconColor: AdminTheme.deepBlack,
                          label: driver.vehicleType.toUpperCase(),
                          value: driver.plateNumber,
                        ),
                      ),
                    ],
                  ),

                  // Active Consignment / Task Section
                  if (driver.status == DriverFleetStatus.onTrip && driver.currentOrderCode != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminTheme.warmCream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminTheme.crimsonRed.withAlpha(60)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_shipping, size: 14, color: AdminTheme.crimsonRed),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'TASK: #${driver.currentOrderCode}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: AdminTheme.crimsonDark,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AdminTheme.crimsonRed.withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'IN TRANSIT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: AdminTheme.crimsonRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (driver.currentCargo != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              driver.currentCargo!,
                              style: const TextStyle(fontSize: 11, color: AdminTheme.textDark, fontWeight: FontWeight.w600),
                            ),
                          ],
                          if (driver.pickupAddress != null && driver.dropoffAddress != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, size: 12, color: AdminTheme.statusOnline),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    driver.pickupAddress!,
                                    style: const TextStyle(fontSize: 10, color: AdminTheme.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.flag, size: 12, color: AdminTheme.crimsonRed),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    driver.dropoffAddress!,
                                    style: const TextStyle(fontSize: 10, color: AdminTheme.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Interactive Action Control Bar
                  Row(
                    children: [
                      // Center Camera
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCenterMap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AdminTheme.deepBlack,
                            side: const BorderSide(color: AdminTheme.borderSubtle),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.my_location, size: 14),
                          label: const Text('Center', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Toggle Active Route
                      if (driver.activeRoute.isNotEmpty) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onToggleRoute,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isRouteVisible ? AdminTheme.crimsonRed : AdminTheme.warmCream,
                              foregroundColor: isRouteVisible ? AdminTheme.crispWhite : AdminTheme.deepBlack,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: isRouteVisible ? AdminTheme.crimsonRed : AdminTheme.borderSubtle),
                              ),
                            ),
                            icon: Icon(isRouteVisible ? Icons.alt_route : Icons.route, size: 14),
                            label: Text(
                              isRouteVisible ? 'Hide Route' : 'Draw Route',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Dispatch Override Action
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onManualDispatch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.crimsonRed,
                            foregroundColor: AdminTheme.crispWhite,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 14),
                          label: const Text('Dispatch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AdminTheme.warmCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: AdminTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AdminTheme.deepBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
