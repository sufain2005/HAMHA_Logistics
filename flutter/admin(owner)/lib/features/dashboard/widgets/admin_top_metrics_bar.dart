import 'package:flutter/material.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/auth/admin_rbac.dart';

class AdminTopMetricsBar extends StatelessWidget {
  final AdminUserModel admin;
  final VoidCallback onRefresh;
  final VoidCallback? onPostTruckRequirement;

  const AdminTopMetricsBar({
    super.key,
    required this.admin,
    required this.onRefresh,
    this.onPostTruckRequirement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AdminTheme.crispWhite,
        border: const Border(bottom: BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Operational Metric Cards (Horizontally Scrollable on smaller viewports)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickMetric(
                    label: 'ONLINE CAPTAINS',
                    value: '18 / 24',
                    icon: Icons.local_shipping,
                    accentColor: AdminTheme.statusOnline,
                  ),
                  const SizedBox(width: 12),
                  _buildQuickMetric(
                    label: 'ACTIVE TRIPS',
                    value: '7 In Transit',
                    icon: Icons.navigation,
                    accentColor: AdminTheme.crimsonRed,
                  ),
                  const SizedBox(width: 12),
                  _buildQuickMetric(
                    label: 'PENDING DISPATCH',
                    value: '3 Orders',
                    icon: Icons.schedule,
                    accentColor: AdminTheme.statusWarning,
                  ),
                  const SizedBox(width: 12),
                  _buildQuickMetric(
                    label: "TODAY'S REVENUE",
                    value: '₹48,250 INR',
                    icon: Icons.currency_rupee,
                    accentColor: AdminTheme.deepBlack,
                  ),
                ],
              ),
            ),
          ),

          if (onPostTruckRequirement != null) ...[
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onPostTruckRequirement,
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.crimsonRed,
                foregroundColor: AdminTheme.crispWhite,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_road, size: 16),
              label: const Text('SEARCH FOR TRUCK (3-DAY)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            ),
          ],
          const SizedBox(width: 8),

          // Refresh Button
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, color: AdminTheme.textMuted, size: 20),
            tooltip: 'Sync Live Fleet & PostGIS Orders',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AdminTheme.canvasBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminTheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
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
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: AdminTheme.deepBlack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
