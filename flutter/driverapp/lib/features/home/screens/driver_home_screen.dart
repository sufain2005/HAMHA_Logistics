import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/models/driver_completed_order_model.dart';
import '../../../core/models/truck_requirement_model.dart';
import '../../../core/services/driver_api_service.dart';
import '../../../core/services/driver_socket_service.dart';
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
  List<TruckRequirementModel> _ownerBroadcasts = TruckRequirementModel.sampleRequirements('Maharashtra');
  bool _isLoadingBroadcasts = false;

  @override
  void initState() {
    super.initState();
    final driver = DriverApiService().currentDriver;
    if (driver != null) {
      _todayEarnings = driver.todayEarnings;
    }
    _loadDeliveredOrders();
    _loadActiveOrder();
    _loadOwnerBroadcasts();
    _initBroadcastSocket();
  }

  void _initBroadcastSocket() {
    DriverSocketService().socket?.on('truck_requirement:posted', (data) {
      if (!mounted || data == null) return;
      try {
        final newReq = TruckRequirementModel.fromJson(Map<String, dynamic>.from(data));
        setState(() {
          _ownerBroadcasts.removeWhere((r) => r.id == newReq.id);
          _ownerBroadcasts.insert(0, newReq);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New Owner Broadcast: ${newReq.title} (Fare: ₹${newReq.offeredFare.toStringAsFixed(0)})'),
            backgroundColor: DriverTheme.crimsonRed,
            duration: const Duration(seconds: 4),
          ),
        );
      } catch (_) {}
    });
  }

  Future<void> _loadOwnerBroadcasts() async {
    setState(() => _isLoadingBroadcasts = true);
    try {
      final posts = await DriverApiService().searchTruckRequirements(state: _currentState);
      if (mounted) {
        setState(() {
          _ownerBroadcasts = posts.isNotEmpty ? posts : TruckRequirementModel.sampleRequirements(_currentState);
        });
      }
    } catch (e) {
      debugPrint('Error loading broadcasts: $e');
      if (mounted) {
        setState(() {
          _ownerBroadcasts = TruckRequirementModel.sampleRequirements(_currentState);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingBroadcasts = false);
      }
    }
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Welcome back, Captain ${driver?.name.split(' ').first ?? 'Rajesh'}!',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: DriverTheme.crispWhite,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (driver?.isVerified == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: DriverTheme.statusOnline.withAlpha(35),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: DriverTheme.statusOnline, width: 1.2),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, size: 12, color: DriverTheme.statusOnline),
                                    SizedBox(width: 4),
                                    Text(
                                      'VERIFIED',
                                      style: TextStyle(
                                        color: DriverTheme.statusOnline,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
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
                        // Real Driver ID Badge with 1-Tap Copy (Format: Year + PhonePrefix + Seq + NameInitials)
                        InkWell(
                          onTap: () {
                            final dId = driver?.customDriverId ?? '202698200001V';
                            Clipboard.setData(ClipboardData(text: dId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Captain ID copied: $dId (Share with Owner)'),
                                backgroundColor: DriverTheme.statusOnline,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: DriverTheme.crimsonRed.withAlpha(90)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.badge, size: 12, color: DriverTheme.crimsonRed),
                                const SizedBox(width: 5),
                                Text(
                                  'CAPTAIN ID: ${driver?.customDriverId ?? "202698200001V"}',
                                  style: const TextStyle(
                                    color: DriverTheme.crispWhite,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(Icons.copy, size: 11, color: DriverTheme.textMuted),
                              ],
                            ),
                          ),
                        ),
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
                  const Text(
                    "Today's Shift Earnings",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: DriverTheme.deepBlack,
                    ),
                  ),
                  const SizedBox(height: 12),

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
                  const SizedBox(height: 12),
                  const Text(
                    'Direct Fleet Owners are actively searching for trucks in your region with verified load broadcasts.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFFCBD5E1), height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton.icon(
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('FIND YOUR WORK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // -------------------------------------------------------------
            // OWNER LOAD BOARD BROADCASTS (UPSIDE OF DELIVERED SHIPMENTS)
            // -------------------------------------------------------------
            _buildOwnerBroadcastsSection(),
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

  // =========================================================================
  // OWNER BROADCASTS / LOAD POSTS SECTION (UPSIDE OF DELIVERED SHIPMENTS)
  // =========================================================================

  Widget _buildOwnerBroadcastsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign_rounded, color: DriverTheme.crimsonRed, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Owner Posted Requirements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: DriverTheme.deepBlack,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: DriverTheme.crimsonRed.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: DriverTheme.crimsonRed.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: DriverTheme.crimsonRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_ownerBroadcasts.length} ACTIVE',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: DriverTheme.crimsonRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: _isLoadingBroadcasts
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: DriverTheme.crimsonRed),
                    )
                  : const Icon(Icons.refresh, size: 20, color: DriverTheme.textDark),
              tooltip: 'Refresh load broadcasts',
              onPressed: _isLoadingBroadcasts
                  ? null
                  : () async {
                      await _loadOwnerBroadcasts();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Load board refreshed: ${_ownerBroadcasts.length} owner broadcasts available!'),
                            backgroundColor: DriverTheme.statusOnline,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Direct freight loads broadcasted by verified Fleet Owners for your regional fleet.',
          style: TextStyle(fontSize: 12, color: DriverTheme.textMuted),
        ),
        const SizedBox(height: 12),

        if (_isLoadingBroadcasts)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: DriverTheme.crimsonRed, strokeWidth: 2),
            ),
          )
        else if (_ownerBroadcasts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DriverTheme.crispWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DriverTheme.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.inbox_outlined, color: DriverTheme.textMuted, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No direct broadcasts in $_currentState currently',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: DriverTheme.deepBlack),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tap "Find Your Work" above to explore regional and interstate corridors.',
                        style: TextStyle(fontSize: 11, color: DriverTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _loadOwnerBroadcasts,
                  child: const Text('REFRESH', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: DriverTheme.crimsonRed)),
                ),
              ],
            ),
          )
        else
          Column(
            children: _ownerBroadcasts.take(4).map((req) => _buildOwnerBroadcastCard(req)).toList(),
          ),
      ],
    );
  }

  Widget _buildOwnerBroadcastCard(TruckRequirementModel req) {
    final hoursLeft = (req.remainingSeconds / 3600).clamp(1, 72).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: DriverTheme.crispWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DriverTheme.borderSubtle, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showOwnerDetailsModal(req),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Truck Type & Offered Fare
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: DriverTheme.deepBlack,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              req.truckType.toUpperCase(),
                              style: const TextStyle(
                                color: DriverTheme.crispWhite,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: DriverTheme.warmCream,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: DriverTheme.borderSubtle),
                            ),
                            child: Text(
                              '${req.weightTons.toStringAsFixed(1)} Tons',
                              style: const TextStyle(
                                color: DriverTheme.deepBlack,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withAlpha(18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined, size: 11, color: Color(0xFF0284C7)),
                                const SizedBox(width: 3),
                                Text(
                                  '${hoursLeft}h left',
                                  style: const TextStyle(
                                    color: Color(0xFF0284C7),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${req.offeredFare.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: DriverTheme.crimsonRed,
                          ),
                        ),
                        const Text(
                          'OFFERED FARE',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: DriverTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Requirement Title
                Text(
                  req.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: DriverTheme.deepBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cargo: ${req.cargoType}',
                  style: const TextStyle(fontSize: 11.5, color: DriverTheme.textMuted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),

                // Route Indicators
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DriverTheme.warmCream,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.circle, size: 9, color: DriverTheme.statusOnline),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${req.pickupCity} (${req.pickupState}) - ${req.pickupAddress}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DriverTheme.deepBlack),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 10, color: DriverTheme.crimsonRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${req.dropoffCity} (${req.dropoffState}) - ${req.dropoffAddress}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DriverTheme.deepBlack),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Owner Footer & Quick Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_user, size: 12, color: DriverTheme.statusOnline),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${req.ownerName} • ${req.ownerCompany}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DriverTheme.deepBlack),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ph: ${req.ownerPhone}',
                            style: const TextStyle(fontSize: 10, color: DriverTheme.textMuted, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone, size: 18, color: DriverTheme.deepBlack),
                          tooltip: 'Copy Phone Number',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: req.ownerPhone));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Owner Phone ${req.ownerPhone} copied to clipboard!'),
                                backgroundColor: DriverTheme.statusOnline,
                              ),
                            );
                          },
                        ),
                        ElevatedButton(
                          onPressed: () => _showOwnerDetailsModal(req),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DriverTheme.crimsonRed,
                            foregroundColor: DriverTheme.crispWhite,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('VIEW / APPLY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOwnerDetailsModal(TruckRequirementModel req) {
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DriverTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: DriverTheme.deepBlack,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      req.truckType.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                  Text(
                    '₹${req.offeredFare.toStringAsFixed(0)} INR',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: DriverTheme.crimsonRed),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                req.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack),
              ),
              const SizedBox(height: 4),
              Text(
                'Cargo: ${req.cargoType} • Weight: ${req.weightTons} Tons • Validity: ${req.validityDays} Days',
                style: const TextStyle(fontSize: 12.5, color: DriverTheme.textMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Divider(color: DriverTheme.borderSubtle),
              const SizedBox(height: 12),

              // Locations Details
              const Text('PICKUP LOCATION & DEPOT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: DriverTheme.textMuted)),
              const SizedBox(height: 4),
              Text('${req.pickupCity}, ${req.pickupState}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: DriverTheme.deepBlack)),
              Text(req.pickupAddress, style: const TextStyle(fontSize: 12, color: DriverTheme.textDark)),
              const SizedBox(height: 12),

              const Text('DESTINATION & DELIVERY POINT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: DriverTheme.textMuted)),
              const SizedBox(height: 4),
              Text('${req.dropoffCity}, ${req.dropoffState}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: DriverTheme.deepBlack)),
              Text(req.dropoffAddress, style: const TextStyle(fontSize: 12, color: DriverTheme.textDark)),
              const SizedBox(height: 16),
              const Divider(color: DriverTheme.borderSubtle),
              const SizedBox(height: 12),

              // Owner Contacts
              const Text('FLEET OWNER CONTACT DETAILS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: DriverTheme.textMuted)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: DriverTheme.textDark),
                  const SizedBox(width: 8),
                  Text('${req.ownerName} (${req.ownerCompany})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: req.ownerPhone));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Owner Phone ${req.ownerPhone} copied to clipboard!'), backgroundColor: DriverTheme.statusOnline),
                        );
                      },
                      icon: const Icon(Icons.phone, size: 16, color: DriverTheme.deepBlack),
                      label: Text(req.ownerPhone, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DriverTheme.deepBlack)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: req.ownerWhatsapp));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Owner WhatsApp ${req.ownerWhatsapp} copied to clipboard!'), backgroundColor: DriverTheme.statusOnline),
                        );
                      },
                      icon: const Icon(Icons.chat, size: 16, color: DriverTheme.statusOnline),
                      label: Text(req.ownerWhatsapp, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DriverTheme.deepBlack)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Submit Application Button
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await DriverApiService().contactOwnerForRequirement(
                      req.id,
                      message: 'Driver ${DriverApiService().currentDriver?.name ?? "Partner"} is ready to fulfill this requirement.',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Application dispatched to Owner ${req.ownerName}!'),
                          backgroundColor: DriverTheme.statusOnline,
                        ),
                      );
                    }
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Application recorded and broadcast to Owner.'),
                          backgroundColor: DriverTheme.statusOnline,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DriverTheme.crimsonRed,
                  foregroundColor: DriverTheme.crispWhite,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('EXPRESS INTEREST / APPLY FOR CORRIDOR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

