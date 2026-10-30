import 'package:flutter/material.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/services/driver_api_service.dart';
import '../../../core/services/driver_socket_service.dart';
import '../../auth/screens/driver_welcome_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  bool _voiceGuidance = true;
  bool _soundAlerts = true;
  bool _fastagExpressways = true;
  bool _dailyPayouts = true;

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DriverTheme.crispWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out of Carrier Account?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to end your shift and disconnect from HAMHA Logistics?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: DriverTheme.textMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverTheme.crimsonRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              DriverSocketService().toggleOnline(false);
              DriverSocketService().disconnect();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const DriverWelcomeScreen()),
                (route) => false,
              );
            },
            child: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDocumentViewer(String title, String docNumber, String status) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: DriverTheme.crispWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: DriverTheme.borderSubtle, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DriverTheme.statusOnline.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DriverTheme.statusOnline),
                  ),
                  child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: DriverTheme.statusOnline)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Credential Number: $docNumber', style: const TextStyle(fontWeight: FontWeight.w700, color: DriverTheme.textDark)),
            const SizedBox(height: 6),
            const Text('Audited & verified by HAMHA Fleet Compliance Bureau under Central Motor Vehicles Act.', style: TextStyle(fontSize: 12, color: DriverTheme.textMuted)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: DriverTheme.deepBlack,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = DriverApiService().currentDriver;

    return Scaffold(
      backgroundColor: DriverTheme.warmCream,
      appBar: AppBar(
        backgroundColor: DriverTheme.crispWhite,
        title: const Text('Driver Profile & Fleet Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: DriverTheme.crimsonRed),
            onPressed: _handleLogout,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. DRIVER HERO CARD
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: DriverTheme.crispWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: DriverTheme.borderSubtle, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: DriverTheme.deepBlack,
                            child: const Icon(Icons.person, color: DriverTheme.crispWhite, size: 40),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: DriverTheme.statusOnline,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified, color: DriverTheme.crispWhite, size: 14),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  driver?.name ?? 'Rajesh Kumar',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: DriverTheme.deepBlack,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'PILOT ID: HMH-DRV-4921',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: DriverTheme.textMuted,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: DriverTheme.warmCream,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: DriverTheme.borderSubtle),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${driver?.rating ?? 4.92}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                                      ),
                                      const Text(
                                        ' (428 reviews)',
                                        style: TextStyle(fontSize: 10, color: DriverTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: DriverTheme.crimsonTint,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: DriverTheme.crimsonRed.withAlpha(60)),
                                  ),
                                  child: const Text(
                                    'ELITE PILOT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: DriverTheme.crimsonRed,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: DriverTheme.borderSubtle, height: 1),
                  const SizedBox(height: 16),

                  // Lifetime stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLifetimeStat('LIFETIME EARNINGS', '₹1,48,650'),
                      Container(width: 1, height: 30, color: DriverTheme.borderSubtle),
                      _buildLifetimeStat('TOTAL DELIVERIES', '428 Trips'),
                      Container(width: 1, height: 30, color: DriverTheme.borderSubtle),
                      _buildLifetimeStat('SAFETY SCORE', '99/100'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. VEHICLE & FLEET ASSET SPECIFICATIONS
            _buildSectionHeader('Assigned Vehicle & Telematics', Icons.local_shipping),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DriverTheme.crispWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DriverTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  _buildProfileRow('Asset Category', '${driver?.vehicleType ?? 'Van'} (Light Commercial)'),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildProfileRow('Registration Plate', driver?.plateNumber ?? 'MH 12 AB 1234', isBold: true),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildProfileRow('Vehicle Make & Model', driver?.vehicleModel ?? 'Tata Ace Gold 1.5T'),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildProfileRow('Payload & Volume Capacity', '1,200 kg • 180 cu ft'),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildProfileRow('FASTag Electronic Toll', 'FAST-8839210-ICICI (Active)', badge: '₹1,450'),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildProfileRow('Pollution Clearance (PUC)', 'Valid till 15 Dec 2027', badge: 'PASSED'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. STATUTORY COMPLIANCE & KYC
            _buildSectionHeader('Statutory Compliance & Licenses', Icons.verified_user),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DriverTheme.crispWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DriverTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  _buildDocRow('Commercial Driver License (CDL)', 'MH-042019003841', 'VERIFIED'),
                  const Divider(color: DriverTheme.borderSubtle, height: 18),
                  _buildDocRow('Vehicle RC Smart Card', 'MH12AB1234', 'VERIFIED'),
                  const Divider(color: DriverTheme.borderSubtle, height: 18),
                  _buildDocRow('Cargo & Transit Insurance', 'ICICI Lombard Policy #8841-B', 'ACTIVE'),
                  const Divider(color: DriverTheme.borderSubtle, height: 18),
                  _buildDocRow('Police Background Verification', 'Thane City Police Bureau', 'CLEARED'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. BANK & INSTANT PAYOUT SETTINGS
            _buildSectionHeader('Bank & Instant Payout Settings', Icons.account_balance),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DriverTheme.crispWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DriverTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  _buildProfileRow('Primary UPI ID', '9823411209@okhdfcbank', badge: 'DEFAULT'),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildProfileRow('Direct Salary Bank Account', 'HDFC Bank •••• 4892'),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildProfileRow('Bank IFSC Code', 'HDFC0001242'),
                  const Divider(color: DriverTheme.borderSubtle, height: 20),
                  _buildSwitchRow(
                    'Daily Instant Auto-Settlement',
                    'Transfers cleared shift earnings automatically to UPI at 23:59',
                    _dailyPayouts,
                    (val) => setState(() => _dailyPayouts = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. OPERATING PREFERENCES
            _buildSectionHeader('Operating & Navigation Preferences', Icons.tune),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DriverTheme.crispWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DriverTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  _buildSwitchRow(
                    'Turn-by-Turn Voice Navigation',
                    'Audible route instructions in English & Hindi',
                    _voiceGuidance,
                    (val) => setState(() => _voiceGuidance = val),
                  ),
                  const Divider(color: DriverTheme.borderSubtle, height: 16),
                  _buildSwitchRow(
                    'Loud Dispatch Sirens & Haptic',
                    'High-priority audio alerts for incoming 15s dispatches',
                    _soundAlerts,
                    (val) => setState(() => _soundAlerts = val),
                  ),
                  const Divider(color: DriverTheme.borderSubtle, height: 16),
                  _buildSwitchRow(
                    'Allow Expressways & FASTag Tolls',
                    'Faster transit routing with automated toll reimbursement',
                    _fastagExpressways,
                    (val) => setState(() => _fastagExpressways = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6. EMERGENCY & DRIVER HELPLINE
            _buildSectionHeader('Safety & Emergency Helpline', Icons.health_and_safety),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DriverTheme.crimsonTint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DriverTheme.crimsonRed.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: DriverTheme.crimsonRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sos, color: DriverTheme.crispWhite, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '24x7 Carrier Pilot SOS Helpline',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: DriverTheme.deepBlack,
                              ),
                            ),
                            Text(
                              'Instant emergency dispatch and roadside assistance: 1800-HAMHA-PILOT',
                              style: TextStyle(fontSize: 11, color: DriverTheme.crimsonDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Connected to HAMHA Emergency Dispatch Desk.')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DriverTheme.crimsonDark,
                      side: const BorderSide(color: DriverTheme.crimsonRed),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.phone_in_talk, size: 16),
                    label: const Text('DIAL DRIVER HELPLINE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sign out
            ElevatedButton.icon(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: DriverTheme.deepBlack,
                foregroundColor: DriverTheme.crispWhite,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('END SHIFT & SIGN OUT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: DriverTheme.crimsonRed),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: DriverTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifetimeStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: DriverTheme.textMuted, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildProfileRow(String label, String value, {bool isBold = false, String? badge}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: const TextStyle(fontSize: 13, color: DriverTheme.textMuted, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                    color: DriverTheme.deepBlack,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DriverTheme.warmCream,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: DriverTheme.borderSubtle),
                  ),
                  child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: DriverTheme.crimsonRed)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: DriverTheme.deepBlack)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: DriverTheme.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          activeColor: DriverTheme.crimsonRed,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDocRow(String title, String docNumber, String status) {
    return InkWell(
      onTap: () => _showDocumentViewer(title, docNumber, status),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: DriverTheme.deepBlack)),
                  const SizedBox(height: 2),
                  Text(docNumber, style: const TextStyle(fontSize: 11, color: DriverTheme.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: DriverTheme.statusOnline.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DriverTheme.statusOnline),
              ),
              child: Text(
                status,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: DriverTheme.statusOnline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
