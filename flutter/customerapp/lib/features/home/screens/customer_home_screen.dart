import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/order_model.dart';
import '../../../core/network/api_client.dart';
import '../widgets/order_card_widget.dart';
import 'create_shipment_screen.dart';
import '../../tracking/screens/live_tracking_tab_screen.dart';
import '../../history/screens/order_history_screen.dart';
import '../../profile/screens/profile_settings_screen.dart';
import '../../tracking/screens/order_tracking_screen.dart';
import '../../invoice/screens/order_invoice_screen.dart';
import '../../auth/screens/login_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> with SingleTickerProviderStateMixin {
  int _currentTabIndex = 0;
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _movingTruckController;

  @override
  void initState() {
    super.initState();
    _movingTruckController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _loadOrders();
  }

  @override
  void dispose() {
    _movingTruckController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await ApiClient().getMyOrders();
      setState(() {
        _orders = orders;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleOrderTap(OrderModel order) {
    if (order.status == 'delivered') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderInvoiceScreen(orderId: order.id)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeView(),
      const LiveTrackingTabScreen(),
      const OrderHistoryScreen(),
      ProfileSettingsScreen(
        onProfileUpdated: () {
          setState(() {});
        },
      ),
    ];

    return Scaffold(
      backgroundColor: HamhaTheme.warmCream,
      body: IndexedStack(
        index: _currentTabIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: HamhaTheme.crispWhite,
          border: Border(top: BorderSide(color: HamhaTheme.borderSubtle, width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) => setState(() => _currentTabIndex = index),
          backgroundColor: HamhaTheme.crispWhite,
          selectedItemColor: HamhaTheme.crimsonRed,
          unselectedItemColor: HamhaTheme.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.radar_outlined),
              activeIcon: Icon(Icons.radar),
              label: 'Live Tracking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping),
              label: 'Consignments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // TAB 0: Main Home View
  Widget _buildHomeView() {
    final user = ApiClient().currentUser;

    return Column(
      children: [
        // Top App Bar
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 12,
            left: 20,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: HamhaTheme.crispWhite,
            border: Border(bottom: BorderSide(color: HamhaTheme.borderSubtle)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/images/hamha_logo.png',
                height: 38,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/hamha_logo.jpg',
                  height: 38,
                  fit: BoxFit.contain,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: HamhaTheme.deepBlack, size: 20),
                tooltip: 'Sign Out',
                onPressed: () {
                  ApiClient().clearToken();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),

        // Welcome Header & Single Attractive "Book New Shipment" CTA
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: HamhaTheme.crispWhite,
            border: Border(bottom: BorderSide(color: HamhaTheme.borderSubtle)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome,',
                          style: TextStyle(color: HamhaTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.name.isNotEmpty == true ? user!.name : 'Shipper',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: HamhaTheme.deepBlack,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Single Attractive "Book New Shipment" CTA
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateShipmentScreen()),
                  ).then((_) => _loadOrders());
                },
                icon: const Icon(Icons.add_location_alt_rounded, color: HamhaTheme.crispWhite, size: 18),
                label: const Text(
                  'BOOK NEW SHIPMENT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HamhaTheme.crimsonRed,
                  foregroundColor: HamhaTheme.crispWhite,
                  elevation: 4,
                  shadowColor: HamhaTheme.crimsonRed.withAlpha(140),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),

        // Live Shipments Feed
        Expanded(
          child: RefreshIndicator(
            color: HamhaTheme.crimsonRed,
            backgroundColor: HamhaTheme.crispWhite,
            onRefresh: _loadOrders,
            child: _buildShipmentContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildShipmentContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: HamhaTheme.crimsonRed));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // 1. Moving Logistics Radar & Animated Delivery Truck
        _buildMovingLogisticsBanner(),
        const SizedBox(height: 18),

        // 2. Active Promotional Offers Carousel from Admin
        _buildAdminPromotionsCarousel(),
        const SizedBox(height: 20),

        // 3. Orders Section or Clean No-Orders Motivational State
        if (_orders.isEmpty) ...[
          _buildEmptyOrdersState(),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVE CONSIGNMENTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: HamhaTheme.deepBlack,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: HamhaTheme.crimsonRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_orders.length} In Transit',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: HamhaTheme.crimsonRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._orders.map((order) {
            return OrderCardWidget(
              order: order,
              onTap: () => _handleOrderTap(order),
            );
          }),
        ],

        const SizedBox(height: 24),
        // Motivational Trust Highlights
        _buildMotivationHighlights(),
        const SizedBox(height: 16),
      ],
    );
  }

  // Moving Animated Highway Truck Banner
  Widget _buildMovingLogisticsBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HamhaTheme.deepBlack,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Pulsing live radar beacon
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE FLEET CORRIDOR TELEMATICS ACTIVE',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              const Text(
                'PostGIS GPS V4',
                style: TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Highway Track with static HAMHA 24/7 indicator (Stationary, non-moving)
          SizedBox(
            height: 38,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Dotted road dashes
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  child: Row(
                    children: List.generate(
                      20,
                      (i) => Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          color: (i % 2 == 0) ? Colors.white30 : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),

                // Stationary Transport Van / Truck Badge
                Positioned(
                  left: 16,
                  bottom: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: HamhaTheme.crimsonRed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.local_shipping, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('HAMHA 24/7', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.flash_on, color: Color(0xFFF59E0B), size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '10,400+ Verified Carriers running across Indian National Highways with automated dispatch.',
            style: TextStyle(color: Colors.white70, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  // Promotional Offers Carousel from Admin
  Widget _buildAdminPromotionsCarousel() {
    final offers = [
      {
        'tag': 'FESTIVE FREIGHT SPECIAL',
        'title': 'Flat 20% OFF on Interstate Full-Truck Loads',
        'code': 'HAMHA20',
        'desc': 'Valid on bookings between Maharashtra, Karnataka, Gujarat & Telangana.',
        'color': HamhaTheme.crimsonRed,
        'icon': Icons.local_offer,
      },
      {
        'tag': 'SAME-DAY EXPRESS',
        'title': '4-Hour Dedicated Corridor: Mumbai ⇄ Pune',
        'code': 'EXPRESS4',
        'desc': 'Book mini-vans or vans for guaranteed same-day industrial express dispatch.',
        'color': const Color(0xFF2563EB),
        'icon': Icons.bolt,
      },
      {
        'tag': 'SAFE CARGO PROMISE',
        'title': 'Free In-Transit Cargo Cover up to ₹50,000',
        'code': 'SAFE50',
        'desc': 'Zero-cost insurance cover automatically applied to shipments over 30 kg.',
        'color': const Color(0xFF059669),
        'icon': Icons.verified_user,
      },
      {
        'tag': 'NEW FLEET EXPANSION',
        'title': '6-Tire, 8-Tire & 12-Tire Multi-Axles Now Live',
        'code': 'HEAVYTIRE',
        'desc': 'Heavy machinery and bulk industrial transport with live axle weight monitoring.',
        'color': const Color(0xFFD97706),
        'icon': Icons.fire_truck,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SPECIAL OFFERS & FLEET DISCOUNTS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: HamhaTheme.deepBlack, letterSpacing: 0.8),
            ),
            Text(
              'Verified Rates',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: HamhaTheme.crimsonRed),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final o = offers[idx];
              final color = o['color'] as Color;

              return Container(
                width: 280,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: HamhaTheme.crispWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withAlpha(60), width: 1.2),
                  boxShadow: [
                    BoxShadow(color: color.withAlpha(12), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            o['tag'] as String,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: HamhaTheme.warmCream,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: HamhaTheme.borderSubtle),
                          ),
                          child: Text(
                            o['code'] as String,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: HamhaTheme.deepBlack),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      o['title'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: HamhaTheme.deepBlack),
                    ),
                    const Spacer(),
                    Text(
                      o['desc'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: HamhaTheme.textMuted),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Clean Empty Orders Motivational Card (Clickable)
  Widget _buildEmptyOrdersState() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateShipmentScreen()),
        ).then((_) => _loadOrders());
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: HamhaTheme.crispWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HamhaTheme.borderSubtle, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: HamhaTheme.warmCream,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 48, color: HamhaTheme.crimsonRed),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ready for Your Next Consignment',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: HamhaTheme.deepBlack),
            ),
            const SizedBox(height: 6),
            const Text(
              'You currently have no active orders in transit.\nEnter your Pickup and Drop-off locations to book verified commercial fleets with transparent per-KM & per-KG tariffs.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: HamhaTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: HamhaTheme.warmCream,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HamhaTheme.borderSubtle),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_outlined, size: 14, color: HamhaTheme.crimsonRed),
                  SizedBox(width: 6),
                  Text(
                    'Click here or use top button to start new dispatch',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: HamhaTheme.deepBlack),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Trust & Motivation Highlights
  Widget _buildMotivationHighlights() {
    return Row(
      children: [
        _buildHighlightChip(Icons.speed, '99.4% On-Time SLA'),
        const SizedBox(width: 8),
        _buildHighlightChip(Icons.gps_fixed, 'Live GPS Telematics'),
        const SizedBox(width: 8),
        _buildHighlightChip(Icons.receipt_long, 'Instant GST Invoices'),
      ],
    );
  }

  Widget _buildHighlightChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: HamhaTheme.crispWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HamhaTheme.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, color: HamhaTheme.crimsonRed, size: 18),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: HamhaTheme.deepBlack),
            ),
          ],
        ),
      ),
    );
  }
}
