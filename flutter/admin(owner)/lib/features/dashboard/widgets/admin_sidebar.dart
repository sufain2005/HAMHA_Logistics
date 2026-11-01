import 'package:flutter/material.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/auth/admin_rbac.dart';

class AdminSidebar extends StatelessWidget {
  final AdminUserModel admin;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;
  final VoidCallback? onPostTruckRequirement;

  const AdminSidebar({
    super.key,
    required this.admin,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    this.onPostTruckRequirement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AdminTheme.crispWhite,
        border: Border(right: BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Branding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminTheme.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/hamha_logo.png',
                  height: 38,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/hamha_logo.jpg',
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AdminTheme.deepBlack,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, color: AdminTheme.crimsonRed, size: 11),
                      SizedBox(width: 5),
                      Text(
                        'OWNER PANEL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AdminTheme.crispWhite,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Administrator Profile Badge
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdminTheme.warmCream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminTheme.borderSubtle),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: admin.scopeColor.withAlpha(30),
                  child: Icon(Icons.security, color: admin.scopeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AdminTheme.deepBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: admin.scopeColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: admin.scopeColor, width: 0.8),
                        ),
                        child: Text(
                          admin.scopeTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: admin.scopeColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.radar,
                  title: 'Fleet Control Tower',
                  subtitle: 'Live Mapbox & Active Drivers',
                  permission: AdminPermission.viewFleet,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.alt_route,
                  title: 'Dispatch Matrix',
                  subtitle: 'PostGIS Radius Manual Dispatch',
                  permission: AdminPermission.manualDispatch,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.verified_user_outlined,
                  title: 'Onboarding Approvals',
                  subtitle: 'Driver KYC & CDL Verifications',
                  permission: AdminPermission.approveDrivers,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.price_change_outlined,
                  title: 'Tariffs & Pricing Engine',
                  subtitle: 'KM Cost, Weight Price & Fleets',
                  permission: AdminPermission.viewFinancialLedgers,
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.receipt_long_outlined,
                  title: 'Financial Ledgers',
                  subtitle: 'Platform Tariffs & Invoices',
                  permission: AdminPermission.viewFinancialLedgers,
                ),
                _buildNavItem(
                  index: 5,
                  icon: Icons.support_agent_outlined,
                  title: 'Dispute & Audit Hub',
                  subtitle: 'Customer Issues & Action Logs',
                  permission: AdminPermission.resolveDisputes,
                ),
                _buildNavItem(
                  index: 6,
                  icon: Icons.account_circle_outlined,
                  title: 'Owner Profile & Fleet HQ',
                  subtitle: 'Profile, Vehicles & Request Driver',
                  permission: AdminPermission.viewFleet,
                ),
                _buildNavItem(
                  index: 7,
                  icon: Icons.insights_outlined,
                  title: 'Analytics & Reports',
                  subtitle: 'Revenue & Performance Metrics',
                  permission: AdminPermission.viewAnalytics,
                ),
              ],
            ),
          ),

          if (onPostTruckRequirement != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminTheme.crimsonTint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminTheme.crimsonRed.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.travel_explore, size: 16, color: AdminTheme.crimsonRed),
                      SizedBox(width: 6),
                      Text('Search for Truck', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AdminTheme.crimsonDark)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Post 3-day load broadcasts to state drivers.', style: TextStyle(fontSize: 10, color: AdminTheme.textMuted)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: onPostTruckRequirement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.crimsonRed,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('POST 3-DAY LOAD', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),

          // Footer Sign Out
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AdminTheme.borderSubtle)),
            ),
            child: InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AdminTheme.warmCream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminTheme.borderSubtle),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: AdminTheme.crimsonRed, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Lock Session & Exit',
                        style: TextStyle(
                          color: AdminTheme.deepBlack,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required AdminPermission permission,
  }) {
    final hasPerm = admin.hasPermission(permission);
    final isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasPerm ? () => onItemSelected(index) : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? AdminTheme.crimsonRed : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: !hasPerm
                      ? AdminTheme.borderGrey
                      : isSelected
                          ? AdminTheme.crispWhite
                          : AdminTheme.deepBlack,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: !hasPerm
                              ? AdminTheme.textMuted.withAlpha(100)
                              : isSelected
                                  ? AdminTheme.crispWhite
                                  : AdminTheme.deepBlack,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AdminTheme.crispWhite.withAlpha(190)
                              : AdminTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!hasPerm)
                  const Icon(Icons.lock_outline, size: 14, color: AdminTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
