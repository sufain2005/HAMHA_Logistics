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

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentTabIndex = 0;
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
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
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: HamhaTheme.crimsonRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                      children: [
                        TextSpan(text: 'HAMHA ', style: TextStyle(color: HamhaTheme.deepBlack)),
                        TextSpan(text: 'LOGISTICS', style: TextStyle(color: HamhaTheme.crimsonRed)),
                      ],
                    ),
                  ),
                ],
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

        // Welcome Header & "Book New Shipment" CTA
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
          decoration: BoxDecoration(
            color: HamhaTheme.crispWhite,
            border: Border(bottom: BorderSide(color: HamhaTheme.borderSubtle)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
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
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ApiClient().isDemoMode)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: HamhaTheme.warmCream,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: HamhaTheme.borderSubtle),
                          ),
                          child: const Text('DEMO MODE', style: TextStyle(color: HamhaTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: HamhaTheme.deepBlack,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield, color: HamhaTheme.crimsonRed, size: 14),
                            SizedBox(width: 4),
                            Text('VERIFIED', style: TextStyle(color: HamhaTheme.crispWhite, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Book New Shipment CTA Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateShipmentScreen()),
                  ).then((_) => _loadOrders());
                },
                icon: const Icon(Icons.add_location_alt_outlined, color: HamhaTheme.crispWhite, size: 20),
                label: const Text('BOOK NEW SHIPMENT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HamhaTheme.crimsonRed,
                  elevation: 3,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

    if (_orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_shipping_outlined, size: 64, color: HamhaTheme.textMuted.withAlpha(120)),
              const SizedBox(height: 16),
              const Text(
                'No Active Consignments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: HamhaTheme.deepBlack),
              ),
              const SizedBox(height: 8),
              const Text(
                'Book your first shipment to start real-time GPS tracking.',
                textAlign: TextAlign.center,
                style: TextStyle(color: HamhaTheme.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return OrderCardWidget(
          order: order,
          onTap: () => _handleOrderTap(order),
        );
      },
    );
  }
}
