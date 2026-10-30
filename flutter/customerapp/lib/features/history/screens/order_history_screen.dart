import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/order_model.dart';
import '../../../core/network/api_client.dart';
import '../../home/widgets/order_card_widget.dart';
import '../../tracking/screens/order_tracking_screen.dart';
import '../../invoice/screens/order_invoice_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<OrderModel> _allOrders = [];
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final orders = await ApiClient().getMyOrders();
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<OrderModel> get _filteredOrders {
    return _allOrders.where((order) {
      final matchesFilter = _selectedFilter == 'All' ||
          (_selectedFilter == 'In Transit' && (order.status == 'in_transit' || order.status == 'assigned')) ||
          (_selectedFilter == 'Delivered' && order.status == 'delivered') ||
          (_selectedFilter == 'Pending' && order.status == 'pending');

      final matchesSearch = _searchQuery.isEmpty ||
          order.orderCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.cargoType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.pickupAddress.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.dropoffAddress.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();
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
    final filtered = _filteredOrders;

    return Scaffold(
      backgroundColor: HamhaTheme.warmCream,
      appBar: AppBar(
        backgroundColor: HamhaTheme.crispWhite,
        elevation: 0.5,
        title: const Text('Consignments & Freight Vault'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search & Filter Header Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            color: HamhaTheme.crispWhite,
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: const TextStyle(color: HamhaTheme.deepBlack, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Search Consignments by ID (e.g. HMH-89241) or city...',
                    prefixIcon: const Icon(Icons.search, color: HamhaTheme.deepBlack),
                    filled: true,
                    fillColor: HamhaTheme.warmCream,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: HamhaTheme.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: HamhaTheme.borderSubtle),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'In Transit', 'Delivered', 'Pending'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                          selectedColor: HamhaTheme.deepBlack,
                          backgroundColor: HamhaTheme.warmCream,
                          labelStyle: TextStyle(
                            color: isSelected ? HamhaTheme.crispWhite : HamhaTheme.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? HamhaTheme.deepBlack : HamhaTheme.borderSubtle,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Consignments Count Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'TOTAL ${filtered.length} CONSIGNMENT${filtered.length == 1 ? '' : 'S'} ARCHIVED',
              style: const TextStyle(
                color: HamhaTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),

          // List of filtered orders
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: HamhaTheme.crimsonRed))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 54, color: HamhaTheme.textMuted.withAlpha(120)),
                            const SizedBox(height: 12),
                            const Text(
                              'No matching consignments found',
                              style: TextStyle(fontWeight: FontWeight.bold, color: HamhaTheme.deepBlack, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            const Text('Try modifying your search or filter selection.', style: TextStyle(color: HamhaTheme.textMuted, fontSize: 13)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: HamhaTheme.crimsonRed,
                        onRefresh: _fetchHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final order = filtered[index];
                            return OrderCardWidget(
                              order: order,
                              onTap: () => _handleOrderTap(order),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
