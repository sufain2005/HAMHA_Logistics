import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/models/driver_completed_order_model.dart';
import '../../../core/services/driver_api_service.dart';
import '../../dashboard/widgets/driver_cash_out_modal.dart';
import 'driver_work_search_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  final VoidCallback onGoToTracking;

  const DriverHomeScreen({
    super.key,
    required this.onGoToTracking,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  List<DriverCompletedOrderModel> _completedOrders = DriverCompletedOrderModel.sampleCompletedOrders();
  String _selectedFilter = 'Today';
  double _todayEarnings = 3450.0;
  String _currentState = 'Maharashtra';
  Map<String, dynamic>? _activeOrder;

  @override
  void initState() {
    super.initState();
    final driver = DriverApiService().currentDriver;
    if (driver != null) {
      _todayEarnings = driver.todayEarnings;
    }
    _loadDeliveredOrders();
    _loadActiveOrder();
  }

  Future<void> _loadActiveOrder() async {
    final order = await DriverApiService().fetchCurrentActiveOrder();
    if (mounted) {
      setState(() {
        _activeOrder = order;
      });
    }
  }

  Future<void> _updateOrderStatus(String status) async {
    if (_activeOrder == null) return;
    final orderId = _activeOrder!['id'];
    await DriverApiService().updateOrderStatus(orderId: orderId, status: status);
    if (mounted) {
      if (status == 'delivered') {
        _loadDeliveredOrders();
        _loadActiveOrder();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Long delivery marked as DELIVERED! Net fare credited to driver wallet.'),
            backgroundColor: DriverTheme.statusOnline,
          ),
        );
      } else {
        setState(() {
          _activeOrder!['status'] = status;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${status.toUpperCase()}. In-transit telemetry broadcasted.'),
            backgroundColor: DriverTheme.deepBlack,
          ),
        );
      }
    }
  }

  Future<void> _loadDeliveredOrders() async {
    final orders = await DriverApiService().fetchDeliveredOrders();
    if (mounted) {
      setState(() {
        _completedOrders = orders;
      });
    }
  }

  void _openCashOutModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DriverCashOutModal(
        availableBalance: _todayEarnings,
        onCashOutSuccess: () {
          setState(() {
            _todayEarnings = 0.0;
          });
        },
      ),
    );
  }

  void _showOrderDetailsModal(DriverCompletedOrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                decoration: BoxDecoration(
                  color: DriverTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderCode,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack),
                    ),
                    const SizedBox(height: 2),
                    Text(order.completedAt, style: const TextStyle(fontSize: 12, color: DriverTheme.textMuted)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DriverTheme.statusOnline.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DriverTheme.statusOnline),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, size: 14, color: DriverTheme.statusOnline),
                      SizedBox(width: 4),
                      Text(
                        'DELIVERED',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: DriverTheme.statusOnline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Payout breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DriverTheme.warmCream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DriverTheme.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Net Fare Credited', style: TextStyle(fontWeight: FontWeight.w700, color: DriverTheme.textDark)),
                  Text(
                    '₹${order.fareEarned.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: DriverTheme.crimsonRed),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Route Points
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DriverTheme.crispWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DriverTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.trip_origin, size: 16, color: DriverTheme.crimsonRed),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PICKUP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: DriverTheme.textMuted)),
                            Text(order.pickupAddress, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: DriverTheme.borderSubtle),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 16, color: DriverTheme.deepBlack),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DROP-OFF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: DriverTheme.textMuted)),
                            Text(order.dropoffAddress, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Recipient & POD Proof
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DriverTheme.warmCream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DriverTheme.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_pin, color: DriverTheme.crimsonRed, size: 20),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SIGNATORY RECIPIENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: DriverTheme.textMuted)),
                          Text(order.recipientName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: DriverTheme.crispWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DriverTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 13),
                        const SizedBox(width: 3),
                        Text('${order.rating}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: DriverTheme.deepBlack,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('CLOSE RECEIPT', style: TextStyle(fontWeight: FontWeight.w800)),
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/hamha_logo.png',
              height: 34,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/hamha_logo.jpg',
                height: 34,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: DriverTheme.deepBlack,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'PILOT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: DriverTheme.crimsonRed,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Driver Greeting & Online Shortcut Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DriverTheme.deepBlack,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: DriverTheme.surfaceBlack,
                    child: const Icon(Icons.person, color: DriverTheme.crispWhite, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${driver?.name.split(' ').first ?? 'Rajesh'}!',
                          style: const TextStyle(
                            color: DriverTheme.crispWhite,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: DriverTheme.statusOnline,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${driver?.vehicleType ?? 'Van'} (${driver?.plateNumber ?? 'MH 12 AB 1234'})',
                              style: const TextStyle(color: DriverTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Real Driver ID Badge with 1-Tap Copy
                        InkWell(
                          onTap: () {
                            final dId = driver?.id ?? '2ff1fda4-bea5-4e97-bdf4-755a6fc4a2d3';
                            Clipboard.setData(ClipboardData(text: dId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Driver ID copied: $dId (Share with Owner)'),
                                backgroundColor: DriverTheme.statusOnline,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: DriverTheme.crimsonRed.withAlpha(90)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.badge, size: 11, color: DriverTheme.crimsonRed),
                                const SizedBox(width: 4),
                                Text(
                                  'DRIVER ID: ${(driver?.id != null && driver!.id.length > 12) ? "${driver.id.substring(0, 8)}..." : (driver?.id ?? "2ff1fda4")}',
                                  style: const TextStyle(
                                    color: DriverTheme.crispWhite,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.copy, size: 10, color: DriverTheme.textMuted),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: widget.onGoToTracking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DriverTheme.crimsonRed,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.navigation, size: 14, color: DriverTheme.crispWhite),
                        SizedBox(width: 6),
                        Text('GO LIVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // -------------------------------------------------------------
            // ACTIVE LONG DELIVERY ASSIGNMENT (Direct from Fleet Owner)
            // -------------------------------------------------------------
            _buildActiveLongDeliveryCard(),

            // Shift Performance Metrics Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DriverTheme.crispWhite,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: DriverTheme.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Shift Earnings",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: DriverTheme.deepBlack,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: DriverTheme.statusOnline.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: DriverTheme.statusOnline),
                        ),
                        child: const Text(
                          'IMPS ELIGIBLE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: DriverTheme.statusOnline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CLEARED BALANCE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: DriverTheme.textMuted, letterSpacing: 0.6),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${_todayEarnings.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: DriverTheme.crimsonRed,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _todayEarnings > 0 ? _openCashOutModal : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DriverTheme.crimsonRed,
                          foregroundColor: DriverTheme.crispWhite,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('CASH OUT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: DriverTheme.borderSubtle, height: 1),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem('TRIPS COMPLETED', '${driver?.todayTrips ?? 6}', Icons.task_alt),
                      ),
                      Container(width: 1, height: 32, color: DriverTheme.borderSubtle),
                      Expanded(
                        child: _buildMetricItem('HOURS ACTIVE', driver?.onlineHours ?? '5h 20m', Icons.timer_outlined),
                      ),
                      Container(width: 1, height: 32, color: DriverTheme.borderSubtle),
                      Expanded(
                        child: _buildMetricItem('ACCEPTANCE', '98.4%', Icons.speed),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // SEARCH FOR WORK IN STATE (OWNER LOAD BOARD)
            // ==========================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [DriverTheme.deepBlack, Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: DriverTheme.crimsonRed.withAlpha(40),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.travel_explore, color: DriverTheme.crimsonLight, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Search for Work',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: DriverTheme.crispWhite,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: DriverTheme.crimsonRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '3-DAY POSTINGS',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: DriverTheme.crispWhite,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Direct Fleet Owners are actively searching for trucks in your state with 3-day load broadcasts.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFFCBD5E1), height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: DriverTheme.crimsonRed),
                            const SizedBox(width: 4),
                            Text(
                              _currentState,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: DriverTheme.crispWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DriverWorkSearchScreen(initialSelectedState: _currentState),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DriverTheme.crimsonRed,
                            foregroundColor: DriverTheme.crispWhite,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.search, size: 16),
                          label: const Text('FIND WORK IN STATE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Delivered Shipments Section Header (Strictly Delivered Only)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Delivered Shipments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: DriverTheme.deepBlack,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: DriverTheme.statusOnline.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: DriverTheme.statusOnline),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check, size: 10, color: DriverTheme.statusOnline),
                          SizedBox(width: 3),
                          Text(
                            'DELIVERED ONLY',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: DriverTheme.statusOnline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: ['Today', 'All'].map((filter) {
                    final isSel = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedFilter = filter),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSel ? DriverTheme.crimsonRed : DriverTheme.crispWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? DriverTheme.crimsonRed : DriverTheme.borderSubtle),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSel ? DriverTheme.crispWhite : DriverTheme.textDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Completed Orders List
            ..._completedOrders.map((order) {
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                color: DriverTheme.crispWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: DriverTheme.borderSubtle, width: 1.2),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _showOrderDetailsModal(order),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: DriverTheme.deepBlack,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.check_circle_outline, color: DriverTheme.statusOnline, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  order.orderCode,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: DriverTheme.deepBlack,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '₹${order.fareEarned.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: DriverTheme.crimsonRed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Route
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.trip_origin, size: 14, color: DriverTheme.crimsonRed),
                                Container(width: 1.5, height: 20, color: DriverTheme.borderSubtle),
                                const Icon(Icons.location_on, size: 14, color: DriverTheme.deepBlack),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.pickupAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DriverTheme.textDark),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    order.dropoffAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DriverTheme.textDark),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: DriverTheme.borderSubtle, height: 1),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${order.cargoType} • ${order.weightKg} kg',
                              style: const TextStyle(fontSize: 11, color: DriverTheme.textMuted, fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  '${order.rating}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right, size: 16, color: DriverTheme.textMuted),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: DriverTheme.textMuted),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: DriverTheme.textMuted, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildActiveLongDeliveryCard() {
    if (_activeOrder == null) return const SizedBox.shrink();

    final order = _activeOrder!;
    final status = (order['status'] ?? 'in_transit').toString().toLowerCase();
    final isDelivered = status == 'delivered';
    if (isDelivered) return const SizedBox.shrink();

    final isInTransit = status == 'in_transit';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DriverTheme.crispWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DriverTheme.crimsonRed, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: DriverTheme.crimsonRed.withAlpha(25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: DriverTheme.crimsonRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_shipping, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'DIRECT LONG DELIVERY FROM OWNER',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: DriverTheme.crimsonRed,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isInTransit ? DriverTheme.statusOnline : const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isInTransit ? 'IN TRANSIT' : 'ASSIGNED TO YOU',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '#${order['order_code'] ?? 'HMH-LONG'} • ${order['cargo_type'] ?? 'Heavy Freight'} (${order['weight_kg'] ?? 450} kg)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DriverTheme.warmCream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DriverTheme.borderSubtle),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.trip_origin, size: 14, color: DriverTheme.crimsonRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pickup: ${order['pickup_address'] ?? 'Origin Depot'}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: DriverTheme.deepBlack),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drop-off: ${order['dropoff_address'] ?? 'Destination Zone'}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Corridor Fare: ₹${order['fare_amount'] ?? '28500'} INR',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: DriverTheme.crimsonRed),
              ),
              Row(
                children: [
                  if (!isInTransit)
                    ElevatedButton.icon(
                      onPressed: () => _updateOrderStatus('in_transit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DriverTheme.deepBlack,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.navigation, size: 12),
                      label: const Text('START TRANSIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _updateOrderStatus('delivered'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DriverTheme.statusOnline,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 12),
                    label: const Text('MARK DELIVERED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

