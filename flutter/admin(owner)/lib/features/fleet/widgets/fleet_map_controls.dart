import 'package:flutter/material.dart';
import '../../../core/theme/admin_theme.dart';

class FleetMapControls extends StatelessWidget {
  final bool showGeofences;
  final bool showAllRoutes;
  final bool isDarkMap;
  final int livePacketCount;
  final bool isSocketConnected;
  final VoidCallback onToggleGeofences;
  final VoidCallback onToggleAllRoutes;
  final VoidCallback onToggleMapStyle;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetCentroid;

  const FleetMapControls({
    super.key,
    required this.showGeofences,
    required this.showAllRoutes,
    required this.isDarkMap,
    required this.livePacketCount,
    required this.isSocketConnected,
    required this.onToggleGeofences,
    required this.onToggleAllRoutes,
    required this.onToggleMapStyle,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetCentroid,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Live Socket Telemetry Indicator Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AdminTheme.sidebarBlack.withAlpha(240),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSocketConnected ? AdminTheme.statusOnline.withAlpha(120) : AdminTheme.crimsonRed.withAlpha(120),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(80),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSocketConnected ? AdminTheme.statusOnline : AdminTheme.crimsonRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isSocketConnected ? AdminTheme.statusOnline.withAlpha(150) : AdminTheme.crimsonRed.withAlpha(150),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isSocketConnected ? 'SOCKET.IO LIVE ($livePacketCount PKTS)' : 'SOCKET RECONNECTING...',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSocketConnected ? AdminTheme.statusOnline : AdminTheme.crimsonRed,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Action Overlay Buttons (Geofences & Routes)
        Container(
          decoration: BoxDecoration(
            color: AdminTheme.sidebarBlack.withAlpha(240),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminTheme.borderBlack),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(80),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Geofences Toggle
              _buildControlButton(
                icon: Icons.fence_outlined,
                activeIcon: Icons.fence,
                isActive: showGeofences,
                tooltip: 'Toggle PostGIS Geofence Zones',
                onTap: onToggleGeofences,
                activeColor: const Color(0xFFF59E0B),
              ),
              const Divider(color: AdminTheme.borderBlack, height: 1),

              // All Routes Toggle
              _buildControlButton(
                icon: Icons.alt_route_outlined,
                activeIcon: Icons.alt_route,
                isActive: showAllRoutes,
                tooltip: 'Toggle All Active Polylines',
                onTap: onToggleAllRoutes,
                activeColor: AdminTheme.crimsonRed,
              ),
              const Divider(color: AdminTheme.borderBlack, height: 1),

              // Map Dark/Street Style Toggle
              _buildControlButton(
                icon: Icons.layers_outlined,
                activeIcon: Icons.layers,
                isActive: isDarkMap,
                tooltip: 'Switch Map View (Dark / Street)',
                onTap: onToggleMapStyle,
                activeColor: const Color(0xFF38BDF8),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Zoom & Pan Centroid Stack
        Container(
          decoration: BoxDecoration(
            color: AdminTheme.sidebarBlack.withAlpha(240),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminTheme.borderBlack),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(80),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.add, size: 18, color: AdminTheme.crispWhite),
                onPressed: onZoomIn,
                tooltip: 'Zoom In',
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(),
              ),
              const Divider(color: AdminTheme.borderBlack, height: 1),
              IconButton(
                icon: const Icon(Icons.remove, size: 18, color: AdminTheme.crispWhite),
                onPressed: onZoomOut,
                tooltip: 'Zoom Out',
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(),
              ),
              const Divider(color: AdminTheme.borderBlack, height: 1),
              IconButton(
                icon: const Icon(Icons.center_focus_strong, size: 18, color: AdminTheme.crimsonLight),
                onPressed: onResetCentroid,
                tooltip: 'Center Fleet Hub',
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withAlpha(40) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isActive ? activeIcon : icon,
            size: 20,
            color: isActive ? activeColor : AdminTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

