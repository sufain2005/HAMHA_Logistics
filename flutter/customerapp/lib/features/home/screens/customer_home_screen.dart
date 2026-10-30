import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/order_model.dart';
import '../../../core/network/api_client.dart';
import '../widgets/order_card_widget.dart';
import 'create_shipment_screen.dart';
import '../../tracking/screens/order_tracking_screen.dart';
import '../../invoice/screens/order_invoice_screen.dart';
import '../../auth/screens/login_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
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
    final user = ApiClient().currentUser;

    return Scaffold(
      backgroundColor: HamhaTheme.deepBlack,
      appBar: AppBar(
        backgroundColor: HamhaTheme.deepBlack,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: HamhaTheme.crimsonRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'HAMHA CUSTOMER',
              style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: HamhaTheme.textMuted, size: 20),
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
      body: Column(
        children: [
          // Top Customer Welcome Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            color: HamhaTheme.deepBlack,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome back,', style: TextStyle(color: HamhaTheme.textMuted, fontSize: 13)),
                        Text(
                          user?.name ?? 'Alex Mercer',
                          style: const TextStyle(
                            color: HamhaTheme.crispWhite,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: HamhaTheme.crimsonRed.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: HamhaTheme.crimsonRed.withAlpha(80)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield, color: HamhaTheme.crimsonRed, size: 14),
                          SizedBox(width: 4),
                          Text('VERIFIED', style: TextStyle(color: HamhaTheme.crimsonLight, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Book New Shipment CTA Button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateShipmentScreen()),
                    ).then((_) => _loadOrders());
                  },
                  icon: const Icon(Icons.add_location_alt_outlined, color: HamhaTheme.crispWhite),
                  label: const Text('BOOK NEW SHIPMENT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HamhaTheme.crimsonRed,
                    elevation: 5,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),

          // Lower Section: Shipments List (Light styled container)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6F8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: RefreshIndicator(
                  color: HamhaTheme.crimsonRed,
                  onRefresh: _loadOrders,
                  child: _buildShipmentContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: HamhaTheme.crimsonRed));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: HamhaTheme.textMuted),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: HamhaTheme.textDark)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrders,
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_shipping_outlined, size: 64, color: HamhaTheme.textMuted.withAlpha(100)),
              const SizedBox(height: 16),
              const Text(
                'No Active Shipments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: HamhaTheme.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your first shipment to start real-time tracking.',
                textAlign: TextAlign.center,
                style: TextStyle(color: HamhaTheme.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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

