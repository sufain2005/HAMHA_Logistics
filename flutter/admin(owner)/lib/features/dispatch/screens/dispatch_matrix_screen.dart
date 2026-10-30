import 'package:flutter/material.dart';
import '../../../core/models/admin_order_model.dart';
import '../../../core/models/fleet_driver_model.dart';
import '../../../core/network/admin_api_client.dart';
import '../../../core/theme/admin_theme.dart';

class DispatchMatrixScreen extends StatefulWidget {
  const DispatchMatrixScreen({super.key});

  @override
  State<DispatchMatrixScreen> createState() => _DispatchMatrixScreenState();
}

class _DispatchMatrixScreenState extends State<DispatchMatrixScreen> {
  List<AdminOrderModel> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // 'All', 'Pending', 'In Transit', 'Delivered'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  AdminOrderModel? _quickViewOrder;
  AdminOrderModel? _dispatchOverrideOrder;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final data = await AdminApiClient().fetchAllOrders();
    if (mounted) {
      setState(() {
        _orders = data;
        _isLoading = false;
      });
    }
  }

  List<AdminOrderModel> get _filteredOrders {
    return _orders.where((order) {
      if (_selectedFilter == 'Pending' && order.status != 'pending') return false;
      if (_selectedFilter == 'In Transit' && order.status != 'in_transit' && order.status != 'assigned') return false;
      if (_selectedFilter == 'Delivered' && order.status != 'delivered') return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesCode = order.orderCode.toLowerCase().contains(q);
        final matchesCustomer = order.customerName.toLowerCase().contains(q);
        final matchesCargo = order.cargoType.toLowerCase().contains(q);
        final matchesPickup = order.pickupAddress.toLowerCase().contains(q);
        final matchesDropoff = order.dropoffAddress.toLowerCase().contains(q);
        return matchesCode || matchesCustomer || matchesCargo || matchesPickup || matchesDropoff;
      }

      return true;
    }).toList();
  }

  Future<void> _executeManualDispatch(AdminOrderModel order, FleetDriverModel driver) async {
    final success = await AdminApiClient().manualDispatch(order.id, driver.id);
    if (success && mounted) {
      setState(() {
        final index = _orders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          _orders[index] = order.copyWith(
            status: 'assigned',
            driverId: driver.id,
            driverName: driver.name,
            driverPhone: driver.phone,
            plateNumber: driver.plateNumber,
            vehicleModel: driver.vehicleModel,
            assignedAt: DateTime.now(),
          );
        }
        _dispatchOverrideOrder = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dispatched #${order.orderCode} to ${driver.name} (${driver.plateNumber}).'),
          backgroundColor: AdminTheme.statusOnline,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;
    final pendingCount = _orders.where((o) => o.status == 'pending').length;

    return Stack(
      children: [
        Container(
          color: AdminTheme.canvasBg,
          child: Column(
            children: [
              // Top Action & Title Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  color: AdminTheme.crispWhite,
                  border: Border(bottom: BorderSide(color: AdminTheme.borderSubtle)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Flexible(
                                child: Text(
                                  'Active Dispatch Matrix',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack),
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (pendingCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFF59E0B)),
                                  ),
                                  child: Text(
                                    '$pendingCount READY FOR DISPATCH',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Centralized freight ledger with real-time PostGIS driver allocation, status transitions, and force overrides.',
                            style: TextStyle(fontSize: 12, color: AdminTheme.textMuted),
                          ),
                        ],
                      ),
                    ),

                    // Reload Button
                    OutlinedButton.icon(
                      onPressed: _loadOrders,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminTheme.deepBlack,
                        side: const BorderSide(color: AdminTheme.borderSubtle),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh Matrix', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // Filter & Search Controls Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: AdminTheme.crispWhite,
                child: Row(
                  children: [
                    // Status Filter Tabs
                    Row(
                      children: ['All', 'Pending', 'In Transit', 'Delivered'].map((filter) {
                        final isSel = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () => setState(() => _selectedFilter = filter),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? AdminTheme.deepBlack : AdminTheme.canvasBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSel ? AdminTheme.deepBlack : AdminTheme.borderSubtle),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSel ? AdminTheme.crispWhite : AdminTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const Spacer(),

                    // Search Field
                    SizedBox(
                      width: 320,
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Search order code, customer, cargo...',
                          hintStyle: const TextStyle(fontSize: 11.5, color: AdminTheme.textMuted),
                          prefixIcon: const Icon(Icons.search, size: 16, color: AdminTheme.textMuted),
                          filled: true,
                          fillColor: AdminTheme.canvasBg,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AdminTheme.borderSubtle),

              // Responsive Data Table
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AdminTheme.crimsonRed))
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 48, color: AdminTheme.textMuted),
                                const SizedBox(height: 12),
                                const Text('No shipments match the current filters.', style: TextStyle(fontWeight: FontWeight.w800, color: AdminTheme.textDark)),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AdminTheme.crispWhite,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AdminTheme.borderSubtle, width: 1.2),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  horizontalMargin: 20,
                                  columnSpacing: 24,
                                headingRowColor: MaterialStateProperty.all(AdminTheme.canvasBg),
                                headingTextStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AdminTheme.textMuted,
                                  letterSpacing: 0.6,
                                ),
                                dataTextStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminTheme.deepBlack),
                                columns: const [
                                  DataColumn(label: Text('CONSIGNMENT CODE')),
                                  DataColumn(label: Text('STATUS')),
                                  DataColumn(label: Text('CUSTOMER')),
                                  DataColumn(label: Text('CARGO & WEIGHT')),
                                  DataColumn(label: Text('ROUTE (PICKUP → DROPOFF)')),
                                  DataColumn(label: Text('TARIFF (INR)')),
                                  DataColumn(label: Text('CARRIER / DRIVER')),
                                  DataColumn(label: Text('ACTIONS')),
                                ],
                                rows: filtered.map((order) {
                                  return DataRow(
                                    cells: [
                                      // Code
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.qr_code, size: 16, color: AdminTheme.crimsonRed),
                                            const SizedBox(width: 6),
                                            Text(
                                              '#${order.orderCode}',
                                              style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.deepBlack),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Status Pill
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: order.statusColor.withAlpha(25),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: order.statusColor),
                                          ),
                                          child: Text(
                                            order.statusLabel,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: order.statusColor),
                                          ),
                                        ),
                                      ),

                                      // Customer
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                            Text(order.customerPhone, style: const TextStyle(color: AdminTheme.textMuted, fontSize: 10.5)),
                                          ],
                                        ),
                                      ),

                                      // Cargo
                                      DataCell(
                                        Text('${order.cargoType}\n(${order.weightKg.toInt()} kg)', style: const TextStyle(fontSize: 11.5)),
                                      ),

                                      // Route
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 240),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'From: ${order.pickupAddress}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 11, color: AdminTheme.textDark),
                                              ),
                                              Text(
                                                'To: ${order.dropoffAddress}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Fare
                                      DataCell(
                                        Text(
                                          '₹${order.fareAmount.toStringAsFixed(0)} INR',
                                          style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.crimsonRed, fontSize: 13),
                                        ),
                                      ),

                                      // Driver
                                      DataCell(
                                        order.driverName != null
                                            ? Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(order.driverName!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                                  Text(order.plateNumber ?? 'Vehicle Assigned', style: const TextStyle(color: AdminTheme.textMuted, fontSize: 10.5)),
                                                ],
                                              )
                                            : const Text(
                                                'UNASSIGNED',
                                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B)),
                                              ),
                                      ),

                                      // Actions
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Quick View Button
                                            IconButton(
                                              icon: const Icon(Icons.visibility_outlined, size: 18),
                                              tooltip: 'Quick View Consignment',
                                              onPressed: () => setState(() => _quickViewOrder = order),
                                            ),

                                            // Manual Dispatch / PostGIS Radius Override Button
                                            if (order.status == 'pending') ...[
                                              const SizedBox(width: 4),
                                              ElevatedButton.icon(
                                                onPressed: () => setState(() => _dispatchOverrideOrder = order),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AdminTheme.crimsonRed,
                                                  foregroundColor: AdminTheme.crispWhite,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                icon: const Icon(Icons.send_rounded, size: 13),
                                                label: const Text('Dispatch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),

        // Slide-out Quick View Drawer (Right Overlay)
        if (_quickViewOrder != null)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: _buildQuickViewDrawer(_quickViewOrder!),
          ),

        // PostGIS ST_DWithin Radius Manual Dispatch Modal
        if (_dispatchOverrideOrder != null)
          _buildPostGisDispatchModal(_dispatchOverrideOrder!),
      ],
    );
  }

  // ==========================================
  // QUICK VIEW SLIDE-OUT DRAWER
  // ==========================================
  Widget _buildQuickViewDrawer(AdminOrderModel order) {
    return Container(
      width: 420,
      decoration: BoxDecoration(
        color: AdminTheme.sidebarBlack,
        border: const Border(left: BorderSide(color: AdminTheme.borderBlack, width: 1.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(160), blurRadius: 28, offset: const Offset(-5, 0)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminTheme.borderBlack)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping, color: AdminTheme.crimsonRed, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Consignment #${order.orderCode}',
                    style: const TextStyle(color: AdminTheme.crispWhite, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AdminTheme.textMuted, size: 18),
                  onPressed: () => setState(() => _quickViewOrder = null),
                ),
              ],
            ),
          ),

          // Drawer Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: order.statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: order.statusColor),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: TextStyle(color: order.statusColor, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 18),

                  _buildDrawerSectionTitle('CLIENT & CARGO SPECIFICATION'),
                  _buildDrawerInfoTile('Client Entity', order.customerName),
                  _buildDrawerInfoTile('Client Phone', order.customerPhone),
                  _buildDrawerInfoTile('Cargo Classification', order.cargoType),
                  _buildDrawerInfoTile('Billable Weight', '${order.weightKg} kg'),
                  _buildDrawerInfoTile('Freight Fare', '₹${order.fareAmount.toStringAsFixed(0)} INR (${order.paymentStatus.toUpperCase()})'),
                  const SizedBox(height: 18),

                  _buildDrawerSectionTitle('LOGISTICS ROUTE ITINERARY'),
                  _buildDrawerInfoTile('Pickup Facility', order.pickupAddress),
                  _buildDrawerInfoTile('Pickup Supervisor', '${order.pickupContactName} (${order.pickupContactPhone})'),
                  _buildDrawerInfoTile('Drop-off Facility', order.dropoffAddress),
                  _buildDrawerInfoTile('Recipient Supervisor', '${order.dropoffContactName} (${order.dropoffContactPhone})'),
                  _buildDrawerInfoTile('Transit Distance', '${order.distanceKm} km (~${order.estimatedDurationMin} mins)'),
                  const SizedBox(height: 18),

                  _buildDrawerSectionTitle('ASSIGNED FLEET CARRIER'),
                  if (order.driverName != null) ...[
                    _buildDrawerInfoTile('Carrier Driver', order.driverName!),
                    _buildDrawerInfoTile('Carrier Phone', order.driverPhone ?? 'N/A'),
                    _buildDrawerInfoTile('Vehicle Spec', '${order.vehicleModel} (${order.plateNumber})'),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminTheme.surfaceBlack,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminTheme.borderBlack),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Consignment unassigned. Ready for PostGIS proximity dispatch.',
                              style: TextStyle(color: AdminTheme.textLight, fontSize: 11),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _quickViewOrder = null;
                                _dispatchOverrideOrder = order;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminTheme.crimsonRed,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Dispatch', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // POSTGIS ST_DWITHIN RADIUS DISPATCH MODAL
  // ==========================================
  Widget _buildPostGisDispatchModal(AdminOrderModel order) {
    return _PostGisRadiusDispatchModal(
      order: order,
      onClose: () => setState(() => _dispatchOverrideOrder = null),
      onAssign: (driver) => _executeManualDispatch(order, driver),
    );
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AdminTheme.textMuted, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildDrawerInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: AdminTheme.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 1),
          Text(value, style: const TextStyle(fontSize: 12.5, color: AdminTheme.crispWhite, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ==========================================
// POSTGIS RADIUS SEARCH COMPONENT (5km - 20km)
// ==========================================
class _PostGisRadiusDispatchModal extends StatefulWidget {
  final AdminOrderModel order;
  final VoidCallback onClose;
  final Function(FleetDriverModel driver) onAssign;

  const _PostGisRadiusDispatchModal({
    required this.order,
    required this.onClose,
    required this.onAssign,
  });

  @override
  State<_PostGisRadiusDispatchModal> createState() => _PostGisRadiusDispatchModalState();
}

class _PostGisRadiusDispatchModalState extends State<_PostGisRadiusDispatchModal> {
  double _radiusKm = 10.0; // Default 10km radius
  List<FleetDriverModel> _nearbyDrivers = [];
  bool _isSearching = true;

  @override
  void initState() {
    super.initState();
    _searchNearby();
  }

  Future<void> _searchNearby() async {
    setState(() => _isSearching = true);
    final drivers = await AdminApiClient().fetchNearbyDrivers(
      widget.order.pickupLocation.latitude,
      widget.order.pickupLocation.longitude,
      _radiusKm,
    );
    if (mounted) {
      setState(() {
        _nearbyDrivers = drivers;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Center(
      child: Container(
        width: 640,
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AdminTheme.sidebarBlack,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AdminTheme.borderBlack, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(180), blurRadius: 36, offset: const Offset(0, 12)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AdminTheme.borderBlack)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.radar, color: AdminTheme.crimsonRed, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PostGIS Proximity Dispatch Matrix',
                            style: const TextStyle(color: AdminTheme.crispWhite, fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'Target Consignment #${order.orderCode} • Pickup: ${order.pickupAddress}',
                            style: const TextStyle(color: AdminTheme.textMuted, fontSize: 11.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AdminTheme.textMuted),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),

              // Radius Selector Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                color: AdminTheme.surfaceBlack,
                child: Row(
                  children: [
                    const Text(
                      'NEON POSTGIS RADIUS:',
                      style: TextStyle(color: AdminTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                    ),
                    const SizedBox(width: 12),
                    ...[5.0, 10.0, 20.0].map((r) {
                      final isSel = _radiusKm == r;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() => _radiusKm = r);
                            _searchNearby();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? AdminTheme.crimsonRed : AdminTheme.sidebarBlack,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSel ? AdminTheme.crimsonRed : AdminTheme.borderBlack),
                            ),
                            child: Text(
                              '${r.toInt()} km',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isSel ? AdminTheme.crispWhite : AdminTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              // Nearby Drivers List
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: _isSearching
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: AdminTheme.crimsonRed),
                        ),
                      )
                    : _nearbyDrivers.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(36.0),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.location_off, color: AdminTheme.textMuted, size: 36),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No online carriers within ${_radiusKm.toInt()} km radius.',
                                    style: const TextStyle(color: AdminTheme.textMuted, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text('Expand radius to 20 km to broadcast to regional carriers.', style: TextStyle(color: AdminTheme.textDark, fontSize: 11)),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(18),
                            shrinkWrap: true,
                            itemCount: _nearbyDrivers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final driver = _nearbyDrivers[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AdminTheme.surfaceBlack,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AdminTheme.borderBlack),
                                ),
                                child: Row(
                                  children: [
                                    Icon(driver.vehicleIcon, color: AdminTheme.statusOnline, size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            driver.name,
                                            style: const TextStyle(color: AdminTheme.crispWhite, fontSize: 13, fontWeight: FontWeight.w900),
                                          ),
                                          Text(
                                            '${driver.vehicleModel} (${driver.plateNumber}) • ${driver.district}',
                                            style: const TextStyle(color: AdminTheme.textMuted, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AdminTheme.statusOnline.withAlpha(20),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'BATTERY ${driver.batteryPercent}%',
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AdminTheme.statusOnline),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),
                                    ElevatedButton(
                                      onPressed: () => widget.onAssign(driver),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AdminTheme.crimsonRed,
                                        foregroundColor: AdminTheme.crispWhite,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('FORCE ASSIGN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // Footer Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AdminTheme.borderBlack)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'ST_DWITHIN POSTGIS HIGHWAY INDEX • AUTOMATED DRIVER SIREN TRIGGER',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AdminTheme.textMuted, fontSize: 9.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: widget.onClose,
                      child: const Text('CANCEL', style: TextStyle(color: AdminTheme.textMuted, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
