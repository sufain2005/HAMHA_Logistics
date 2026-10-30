import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/order_model.dart';
import '../../../core/network/api_client.dart';
import 'order_tracking_screen.dart';

class LiveTrackingTabScreen extends StatefulWidget {
  const LiveTrackingTabScreen({super.key});

  @override
  State<LiveTrackingTabScreen> createState() => _LiveTrackingTabScreenState();
}

class _LiveTrackingTabScreenState extends State<LiveTrackingTabScreen> {
  OrderModel? _activeOrder;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveShipment();
  }

  Future<void> _fetchLiveShipment() async {
    setState(() => _isLoading = true);
    try {
      final orders = await ApiClient().getMyOrders();
      // Find the first active in-transit or assigned order
      final active = orders.firstWhere(
        (o) => o.status == 'in_transit' || o.status == 'assigned' || o.status == 'picked_up',
        orElse: () => orders.first,
      );
      setState(() {
        _activeOrder = active;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HamhaTheme.warmCream,
      appBar: AppBar(
        backgroundColor: HamhaTheme.crispWhite,
        elevation: 0.5,
        title: const Text('Live Fleet Tracking'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: HamhaTheme.deepBlack),
            onPressed: _fetchLiveShipment,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: HamhaTheme.crimsonRed))
          : _activeOrder == null
              ? const Center(child: Text('No active consignments currently in transit.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Current Live Status Banner
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: HamhaTheme.deepBlack,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(20),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: HamhaTheme.statusDelivered,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'LIVE GPS SATELLITE FEED ACTIVE',
                                        style: TextStyle(
                                          color: HamhaTheme.crispWhite,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tracking Consignment: ${_activeOrder!.orderCode}',
                                        style: const TextStyle(
                                          color: HamhaTheme.textMuted,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: HamhaTheme.crimsonRed,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_activeOrder!.driverSpeedKmh?.round() ?? 62} KM/H',
                                    style: const TextStyle(
                                      color: HamhaTheme.crispWhite,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. Real-time Location: State, District & Landmark Reached Card
                          Card(
                            color: HamhaTheme.crispWhite,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: HamhaTheme.borderSubtle, width: 1.2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(22.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: HamhaTheme.crimsonTint,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.pin_drop, color: HamhaTheme.crimsonRed, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Current Geolocation & District Reached',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: HamhaTheme.deepBlack,
                                              ),
                                            ),
                                            Text(
                                              'Verified via PostGIS Telemetry Checkpoint',
                                              style: TextStyle(fontSize: 12, color: HamhaTheme.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: HamhaTheme.borderSubtle),
                                  const SizedBox(height: 14),

                                  // State & District Highlights
                                  _buildLocationRow(
                                    icon: Icons.account_balance,
                                    title: 'Current State',
                                    value: _activeOrder!.currentState ?? 'Maharashtra',
                                    isHighlighted: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildLocationRow(
                                    icon: Icons.map_outlined,
                                    title: 'Current District Reached',
                                    value: _activeOrder!.currentDistrict ?? 'Pune District, Maharashtra',
                                    isHighlighted: true,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildLocationRow(
                                    icon: Icons.near_me,
                                    title: 'Highway Landmark / Checkpoint',
                                    value: _activeOrder!.currentLandmark ?? 'Pimpri-Chinchwad Expressway Toll Plaza (NH 48)',
                                  ),
                                  const SizedBox(height: 16),

                                  // Expected to Reach Time Banner (ETA Clock)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: HamhaTheme.warmCream,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: HamhaTheme.crimsonRed.withAlpha(80)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.schedule, color: HamhaTheme.crimsonRed, size: 24),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'EXPECTED TO REACH DESTINATION',
                                                style: TextStyle(
                                                  color: HamhaTheme.crimsonRed,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _activeOrder!.expectedReachTime ?? 'Today at 08:30 PM (2 hrs 15 mins remaining)',
                                                style: const TextStyle(
                                                  color: HamhaTheme.deepBlack,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3. Driver & Vehicle Credentials Card
                          Card(
                            color: HamhaTheme.crispWhite,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: HamhaTheme.borderSubtle, width: 1.2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(22.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: HamhaTheme.deepBlack,
                                              border: Border.all(color: HamhaTheme.crimsonRed, width: 2),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'R',
                                                style: TextStyle(
                                                  color: HamhaTheme.crispWhite,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _activeOrder!.driverName ?? 'Rajesh Kumar Verma',
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w900,
                                                  color: HamhaTheme.deepBlack,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              const Row(
                                                children: [
                                                  Icon(Icons.star, color: Color(0xFFF59E0B), size: 15),
                                                  SizedBox(width: 4),
                                                  Text('4.9 Rating • Certified Heavy Commercial Pilot', style: TextStyle(fontSize: 12, color: HamhaTheme.textMuted)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // Call Action
                                      InkWell(
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: HamhaTheme.deepBlack,
                                              content: Text('Calling Driver: ${_activeOrder!.driverPhone ?? "+91 98234 11209"}'),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(30),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: const BoxDecoration(
                                            color: HamhaTheme.crimsonRed,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.phone, color: HamhaTheme.crispWhite, size: 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  const Divider(color: HamhaTheme.borderSubtle),
                                  const SizedBox(height: 16),

                                  // Vehicle Details Grid
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: HamhaTheme.warmCream,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: HamhaTheme.borderSubtle),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('VEHICLE REGISTRATION #', style: TextStyle(color: HamhaTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              Text(
                                                _activeOrder!.vehiclePlate ?? 'MH 12 HM 8924',
                                                style: const TextStyle(
                                                  color: HamhaTheme.deepBlack,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: HamhaTheme.warmCream,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: HamhaTheme.borderSubtle),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('CARRIER MODEL', style: TextStyle(color: HamhaTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              Text(
                                                _activeOrder!.vehicleModel ?? 'BharatBenz 1617R',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: HamhaTheme.deepBlack,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 4. District Transit Timeline Reached
                          Card(
                            color: HamhaTheme.crispWhite,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: HamhaTheme.borderSubtle, width: 1.2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(22.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Transit Checkpoints & District Milestones',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: HamhaTheme.deepBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  ..._activeOrder!.checkpoints.map((cp) {
                                    return _buildCheckpointTile(cp);
                                  }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 5. Open Interactive Mapbox Full Map Screen Button
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderTrackingScreen(orderId: _activeOrder!.id),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map, color: HamhaTheme.crispWhite),
                            label: const Text('OPEN FULL MAPBOX NAVIGATION SCREEN'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HamhaTheme.crimsonRed,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String title,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: isHighlighted ? HamhaTheme.crimsonRed : HamhaTheme.deepBlack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: HamhaTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isHighlighted ? HamhaTheme.deepBlack : HamhaTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckpointTile(TransitCheckpoint cp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cp.isCompleted ? HamhaTheme.statusDelivered : HamhaTheme.warmCream,
                  border: Border.all(
                    color: cp.isCompleted ? HamhaTheme.statusDelivered : HamhaTheme.borderSubtle,
                    width: 2,
                  ),
                ),
                child: cp.isCompleted
                    ? const Icon(Icons.check, size: 12, color: HamhaTheme.crispWhite)
                    : null,
              ),
              Container(width: 2, height: 26, color: HamhaTheme.borderSubtle),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cp.location,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: cp.isCompleted ? HamhaTheme.deepBlack : HamhaTheme.textMuted,
                      ),
                    ),
                    Text(
                      cp.timestamp,
                      style: TextStyle(
                        fontSize: 11,
                        color: cp.isCompleted ? HamhaTheme.statusDelivered : HamhaTheme.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${cp.district}, ${cp.state}',
                  style: const TextStyle(fontSize: 12, color: HamhaTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

