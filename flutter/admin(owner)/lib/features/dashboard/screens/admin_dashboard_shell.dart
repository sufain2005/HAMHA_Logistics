import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/constants/admin_constants.dart';
import '../../../core/auth/admin_rbac.dart';
import '../../../core/models/fleet_driver_model.dart';
import '../../../core/models/geofence_zone_model.dart';
import '../../../core/network/admin_api_client.dart';
import '../../../core/network/admin_socket_service.dart';
import '../../../core/services/admin_auth_service.dart';
import '../../fleet/widgets/fleet_driver_marker.dart';
import '../../fleet/widgets/floating_telemetry_card.dart';
import '../../fleet/widgets/fleet_map_controls.dart';
import '../../approvals/screens/driver_approvals_screen.dart';
import '../../dispatch/screens/dispatch_matrix_screen.dart';
import '../../pricing/screens/tariffs_pricing_screen.dart';
import '../../finance/screens/financial_ledgers_screen.dart';
import '../../disputes/screens/dispute_audit_hub_screen.dart';
import '../../fleet/widgets/owner_post_truck_requirement_modal.dart';
import '../../profile/screens/owner_profile_screen.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_top_metrics_bar.dart';
import '../../auth/screens/admin_login_screen.dart';

class AdminDashboardShell extends StatefulWidget {
  final AdminUserModel admin;
  final bool enableLiveSocket;

  const AdminDashboardShell({
    super.key,
    required this.admin,
    this.enableLiveSocket = true,
  });

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  int _selectedNavIndex = 0;
  String _driverFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final MapController _mapController = MapController();
  final LatLng _fleetCentroid = const LatLng(19.1620, 72.9781); // MMR Command Center Centroid

  List<FleetDriverModel> _drivers = [];
  FleetDriverModel? _selectedDriver;
  bool _isLoading = true;

  // Map & Location Controls State
  bool _showMapTileView = false;
  bool _showGeofences = true;
  bool _showAllRoutes = true;
  bool _isDarkMap = true;
  bool _isRouteVisibleForSelected = true;

  final List<GeofenceZoneModel> _geofenceZones = GeofenceZoneModel.getDefaultZones();

  // Socket & Simulation
  final AdminSocketService _socketService = AdminSocketService();
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _loadFleetData();
    if (widget.enableLiveSocket) {
      _initSocketTelematics();
    }
    _startDemoMovementSimulation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _simulationTimer?.cancel();
    _socketService.disconnect();
    super.dispose();
  }

  Future<void> _loadFleetData() async {
    setState(() => _isLoading = true);
    final fleet = await AdminApiClient().fetchLiveFleet();
    if (mounted) {
      setState(() {
        _drivers = fleet;
        _isLoading = false;
        if (_drivers.isNotEmpty && _selectedDriver == null) {
          // Select first active on-trip driver as default focus
          _selectedDriver = _drivers.firstWhere(
            (d) => d.status == DriverFleetStatus.onTrip,
            orElse: () => _drivers.first,
          );
        }
      });
    }
  }

  void _initSocketTelematics() {
    _socketService.connect();

    // Listen to real-time driver GPS updates from Node.js backend
    _socketService.onDriverLocation = (data) {
      if (!mounted) return;
      final driverId = data['driverId']?.toString();
      if (driverId == null) return;

      final loc = data['location'] as Map<String, dynamic>?;
      final double? lat = (loc?['latitude'] ?? loc?['lat'] ?? data['latitude'])?.toDouble();
      final double? lon = (loc?['longitude'] ?? loc?['lng'] ?? data['longitude'])?.toDouble();

      if (lat != null && lon != null) {
        setState(() {
          final index = _drivers.indexWhere((d) => d.id == driverId);
          if (index != -1) {
            final existing = _drivers[index];
            final updated = existing.copyWith(
              location: LatLng(lat, lon),
              speedKmh: ((data['speed'] ?? existing.speedKmh) as num).toDouble(),
              heading: ((data['heading'] ?? existing.heading) as num).toDouble(),
              batteryPercent: ((data['battery'] ?? existing.batteryPercent) as num).toInt(),
              lastSeen: DateTime.now(),
            );
            _drivers[index] = updated;
            if (_selectedDriver?.id == driverId) {
              _selectedDriver = updated;
            }
          }
        });
      }
    };

    // Listen to driver online/offline status changes
    _socketService.onDriverStatus = (data) {
      if (!mounted) return;
      final driverId = data['driverId']?.toString();
      final bool? isOnline = data['isOnline'] as bool?;
      if (driverId != null && isOnline != null) {
        setState(() {
          final index = _drivers.indexWhere((d) => d.id == driverId);
          if (index != -1) {
            final existing = _drivers[index];
            final newStatus = isOnline
                ? (existing.currentOrderCode != null ? DriverFleetStatus.onTrip : DriverFleetStatus.available)
                : DriverFleetStatus.offline;
            _drivers[index] = existing.copyWith(status: newStatus);
            if (_selectedDriver?.id == driverId) {
              _selectedDriver = _drivers[index];
            }
          }
        });
      }
    };
  }

  // Smooth micro-movement simulation for demo/test mode to show live moving vehicles
  void _startDemoMovementSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _drivers.isEmpty) return;

      setState(() {
        for (int i = 0; i < _drivers.length; i++) {
          final d = _drivers[i];
          if (d.status == DriverFleetStatus.onTrip) {
            // Jitter/advance coordinates by small delta along heading
            final double deltaLat = ((i % 2 == 0 ? 1 : -1) * 0.0004);
            final double deltaLon = ((i % 3 == 0 ? 1 : -1) * 0.0004);
            final newLoc = LatLng(d.location.latitude + deltaLat, d.location.longitude + deltaLon);
            final newSpeed = 35.0 + (i * 4) + ((DateTime.now().second % 10) - 5);

            final updated = d.copyWith(
              location: newLoc,
              speedKmh: newSpeed.clamp(15.0, 75.0),
              heading: (d.heading + 10) % 360,
              lastSeen: DateTime.now(),
            );
            _drivers[i] = updated;
            if (_selectedDriver?.id == d.id) {
              _selectedDriver = updated;
            }
          }
        }
      });
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.crispWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out of Owner Panel?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to end your active Owner session? Real-time fleet telemetry listeners will be paused.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AdminTheme.textMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.crimsonRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminAuthService().logout();
              _socketService.disconnect();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
              );
            },
            child: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<FleetDriverModel> get _filteredRoster {
    return _drivers.where((driver) {
      // 1. Status Filter
      if (_driverFilter == 'Available' && driver.status != DriverFleetStatus.available) return false;
      if (_driverFilter == 'On-Trip' && driver.status != DriverFleetStatus.onTrip) return false;
      if (_driverFilter == 'Offline' && driver.status != DriverFleetStatus.offline) return false;

      // 2. Search Query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = driver.name.toLowerCase().contains(q);
        final matchesPlate = driver.plateNumber.toLowerCase().contains(q);
        final matchesOrder = driver.currentOrderCode?.toLowerCase().contains(q) ?? false;
        final matchesDistrict = driver.district.toLowerCase().contains(q);
        return matchesName || matchesPlate || matchesOrder || matchesDistrict;
      }

      return true;
    }).toList();
  }

  void _selectAndCenterDriver(FleetDriverModel driver) {
    setState(() {
      _selectedDriver = driver;
      _isRouteVisibleForSelected = true;
    });
    try {
      if (_showMapTileView) {
        _mapController.move(driver.location, 14.5);
      }
    } catch (_) {}
  }

  void _openPostTruckRequirementModal() {
    showDialog(
      context: context,
      builder: (_) => OwnerPostTruckRequirementModal(
        onRequirementPosted: () {
          _loadFleetData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.canvasBg,
      body: Row(
        children: [
          // 1. PERSISTENT SIDE NAVIGATION DRAWER (260px)
          AdminSidebar(
            admin: widget.admin,
            selectedIndex: _selectedNavIndex,
            onItemSelected: (index) {
              setState(() => _selectedNavIndex = index);
            },
            onLogout: _handleLogout,
            onPostTruckRequirement: _openPostTruckRequirementModal,
          ),

          // 2. MAIN OPERATIONS AREA
          Expanded(
            child: Column(
              children: [
                // Top Metrics Bar with live PostGIS / Sockets count
                AdminTopMetricsBar(
                  admin: widget.admin,
                  onRefresh: () {
                    _loadFleetData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fleet telemetry synchronized with Neon PostGIS.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  onPostTruckRequirement: _openPostTruckRequirementModal,
                ),

                // Active Workspace (Phase 2 Live Fleet Split View)
                Expanded(
                  child: _buildCurrentModuleView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentModuleView() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildFleetSplitView();
      case 1:
        return const DispatchMatrixScreen();
      case 2:
        return const DriverApprovalsScreen();
      case 3:
        return const TariffsPricingScreen();
      case 4:
        return const FinancialLedgersScreen();
      case 5:
        return const DisputeAuditHubScreen();
      case 6:
        return const OwnerProfileScreen();
      case 7:
        return _buildPlaceholderModule('Analytics & Reports', 'Multi-Chart Revenue Patterns & System Busy Hours (Phase 5)');
      default:
        return _buildFleetSplitView();
    }
  }

  // ==========================================
  // PHASE 2: RESPONSIVE SPLIT-VIEW WORKSPACE
  // Left: Searchable Fleet Roster | Right: Fullscreen Mapbox
  // ==========================================
  Widget _buildFleetSplitView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 950;

        if (!isDesktop) {
          return _buildRosterPane();
        }

        return Row(
          children: [
            // Left Pane: Searchable Active Drivers Roster (380px)
            SizedBox(
              width: 380,
              child: _buildRosterPane(),
            ),

            // Vertical Accent Divider
            const VerticalDivider(width: 1, color: AdminTheme.borderSubtle),

            // Right Pane: Sprawling Mapbox / Tile Map (Expanded)
            Expanded(
              child: _buildMapPane(),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // LEFT PANE: ACTIVE DRIVERS ROSTER & SEARCH
  // ==========================================
  Widget _buildRosterPane() {
    final filtered = _filteredRoster;

    return Container(
      color: AdminTheme.crispWhite,
      child: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminTheme.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'Active Fleet Roster',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AdminTheme.deepBlack,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AdminTheme.canvasBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminTheme.borderSubtle),
                      ),
                      child: Text(
                        '${filtered.length} Drivers',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Bar Field
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Search driver, plate, order, district...',
                    hintStyle: const TextStyle(fontSize: 11.5, color: AdminTheme.textMuted),
                    prefixIcon: const Icon(Icons.search, size: 18, color: AdminTheme.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AdminTheme.canvasBg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Tabs (All, Available, On-Trip, Offline)
                Row(
                  children: ['All', 'Available', 'On-Trip', 'Offline'].map((filter) {
                    final isSel = _driverFilter == filter;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: InkWell(
                          onTap: () => setState(() => _driverFilter = filter),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? AdminTheme.deepBlack : AdminTheme.canvasBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel ? AdminTheme.deepBlack : AdminTheme.borderSubtle,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSel ? AdminTheme.crispWhite : AdminTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Drivers Roster List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.crimsonRed))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_shipping_outlined, size: 36, color: AdminTheme.textMuted),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty ? 'No drivers match "$_searchQuery"' : 'No drivers in this category',
                              style: const TextStyle(fontSize: 12, color: AdminTheme.textMuted, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final driver = filtered[index];
                          final isSelected = _selectedDriver?.id == driver.id;

                          return InkWell(
                            onTap: () => _selectAndCenterDriver(driver),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected ? AdminTheme.crimsonTint : AdminTheme.crispWhite,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AdminTheme.crimsonRed : AdminTheme.borderSubtle,
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Status Indicator Beacon
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: driver.statusColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AdminTheme.crispWhite, width: 2),
                                      boxShadow: [
                                        BoxShadow(color: driver.statusColor.withAlpha(100), blurRadius: 6),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Driver Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                driver.name,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w900,
                                                  color: AdminTheme.deepBlack,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${driver.speedKmh.toInt()} km/h',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: driver.statusColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${driver.vehicleModel} (${driver.plateNumber})',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                driver.district,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 10, color: AdminTheme.textDark, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                            if (driver.currentOrderCode != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: AdminTheme.crimsonRed.withAlpha(20),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '#${driver.currentOrderCode}',
                                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AdminTheme.crimsonRed),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RIGHT PANE: DRIVER REGIONAL LOCATION & TELEMATICS (WITH OPTIONAL TILE MAP)
  // ==========================================
  Widget _buildMapPane() {
    if (_showMapTileView) {
      return _buildMapTileEnginePane();
    }
    return _buildDriverLocationAndDistrictPane();
  }

  Widget _buildDriverLocationAndDistrictPane() {
    final driver = _selectedDriver;

    return Container(
      color: const Color(0xFF0F172A), // Slate 900 High-Tech Radar Theme
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pane Top Bar with status & toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(bottom: BorderSide(color: Color(0xFF334155))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AdminTheme.crimsonRed.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.explore_rounded, color: AdminTheme.crimsonLight, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Driver Live Location & Regional Status',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          driver != null
                              ? '${driver.name} • ${driver.state} (${driver.presentDistrict})'
                              : 'Select any driver from the roster to inspect live State & Present District',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Socket Live Indicator
                    ValueListenableBuilder<bool>(
                      valueListenable: _socketService.isConnected,
                      builder: (context, connected, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: connected ? AdminTheme.statusOnline : const Color(0xFF475569)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: connected ? AdminTheme.statusOnline : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                connected ? 'SOCKET.IO LIVE' : 'SYNCING',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: connected ? AdminTheme.statusOnline : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    // Button to toggle Map View if needed
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showMapTileView = true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFCBD5E1),
                        side: const BorderSide(color: Color(0xFF475569)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.map_outlined, size: 14),
                      label: const Text('TILE MAP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Pane Content
          Expanded(
            child: driver != null
                ? _buildSelectedDriverDetailView(driver)
                : _buildNoDriverSelectedOverview(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDriverDetailView(FleetDriverModel driver) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. PRIMARY HIGHLIGHT: STATE & PRESENT DISTRICT HERO CARD
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AdminTheme.crimsonRed.withAlpha(120), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
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
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AdminTheme.crimsonRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DRIVER CURRENT LOCATION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AdminTheme.crimsonLight,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              driver.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: driver.statusColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: driver.statusColor, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: driver.statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(
                            driver.statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: driver.statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFF334155), height: 1),
                const SizedBox(height: 20),

                // STATE AND PRESENT DISTRICT IN TWO HIGH CONTRAST BOXES
                Row(
                  children: [
                    // STATE BOX
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.public, color: Color(0xFF38BDF8), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'CURRENT STATE',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              driver.state,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'India • Western Logistics Corridor',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // PRESENT DISTRICT BOX
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AdminTheme.crimsonRed.withAlpha(120)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.location_city_rounded, color: AdminTheme.crimsonLight, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'PRESENT DISTRICT',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AdminTheme.crimsonLight, letterSpacing: 0.8),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              driver.presentDistrict,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Verified Operational Hub • ${driver.vehicleModel}',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // GPS TELEMETRY & COORDINATES
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withAlpha(150),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.gps_fixed, size: 14, color: AdminTheme.statusOnline),
                          const SizedBox(width: 8),
                          Text(
                            'GPS: ${driver.location.latitude.toStringAsFixed(5)}° N, ${driver.location.longitude.toStringAsFixed(5)}° E',
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: '${driver.location.latitude},${driver.location.longitude}'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Coordinates copied for ${driver.name}'),
                              backgroundColor: AdminTheme.statusOnline,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.copy, size: 12, color: Color(0xFF94A3B8)),
                            SizedBox(width: 4),
                            Text('Copy Pin', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. TELEMETRICS 4-METRIC GRID
          Row(
            children: [
              Expanded(
                child: _buildTelemetryStatTile(
                  icon: Icons.speed,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'LIVE SPEED',
                  value: '${driver.speedKmh.toInt()} km/h',
                  subtitle: 'Real-time telemetry',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTelemetryStatTile(
                  icon: Icons.battery_charging_full,
                  iconColor: AdminTheme.statusOnline,
                  title: 'DEVICE BATTERY',
                  value: '${driver.batteryPercent}%',
                  subtitle: 'Healthy transceiver',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTelemetryStatTile(
                  icon: Icons.timer_outlined,
                  iconColor: const Color(0xFF38BDF8),
                  title: 'SHIFT DURATION',
                  value: driver.onlineDuration,
                  subtitle: 'Active since check-in',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTelemetryStatTile(
                  icon: driver.vehicleIcon,
                  iconColor: AdminTheme.crimsonLight,
                  title: 'VEHICLE CLASS',
                  value: driver.vehicleType.toUpperCase(),
                  subtitle: driver.plateNumber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3. ACTIVE TASK OR TRANSIT CORRIDOR
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assignment_outlined, color: AdminTheme.crimsonLight, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'ACTIVE CONSIGNMENT & CORRIDOR',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    if (driver.currentOrderCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AdminTheme.crimsonRed.withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminTheme.crimsonRed),
                        ),
                        child: Text(
                          '#${driver.currentOrderCode}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AdminTheme.crimsonLight),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (driver.currentOrderCode != null) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFCBD5E1), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CARGO CLASSIFICATION', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            Text(
                              driver.currentCargo ?? 'Packaged Goods & Industrial Electronics',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.circle, size: 10, color: AdminTheme.statusOnline),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'PICKUP: ${driver.pickupAddress ?? "Bhiwandi Warehousing Hub, Gate 4, Thane"}',
                                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(width: 2, height: 16, color: const Color(0xFF334155)),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: AdminTheme.crimsonRed),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'DROP-OFF: ${driver.dropoffAddress ?? "Ghodbunder Tech Park, Thane West"}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AdminTheme.statusOnline, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Driver is currently available for dispatch in ${driver.presentDistrict}, ${driver.state}. Tap "Manual Dispatch" below to allocate a priority order.',
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. ACTION CONTROLS
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showManualDispatchModal(driver),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.crimsonRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('MANUAL DISPATCH OVERRIDE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 14),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling driver ${driver.name} at ${driver.phone}...'),
                      backgroundColor: AdminTheme.deepBlack,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF475569)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.phone, size: 16, color: AdminTheme.statusOnline),
                label: Text(driver.phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryStatTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDriverSelectedOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AdminTheme.crimsonRed.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.touch_app_rounded, color: AdminTheme.crimsonLight, size: 30),
                ),
                const SizedBox(width: 18),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select a Driver to Inspect Regional Location',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap any driver on the left roster to view their live State, Present District, telematics, and active delivery route.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ACTIVE FLEET REGIONAL DISTRIBUTION',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _drivers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final d = _drivers[index];
              return InkWell(
                onTap: () => _selectAndCenterDriver(d),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: d.statusColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 12),
                          Text(d.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 8),
                          Text('(${d.vehicleModel})', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                            child: Text(d.state, style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                            child: Text(d.presentDistrict, style: const TextStyle(color: AdminTheme.crimsonLight, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Preserve Fullscreen Mapbox tile engine (toggleable via TILE MAP button)
  Widget _buildMapTileEnginePane() {
    final tileUrl = _isDarkMap ? AdminConstants.mapboxNavDarkTiles : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    // 1. Polylines to render
    final List<Polyline> polylines = [];

    if (_showAllRoutes) {
      for (final driver in _drivers) {
        if (driver.activeRoute.isNotEmpty) {
          polylines.add(
            Polyline(
              points: driver.activeRoute,
              strokeWidth: 3.5,
              color: AdminTheme.crimsonRed.withAlpha(160),
            ),
          );
        }
      }
    }

    if (_selectedDriver != null && _isRouteVisibleForSelected && _selectedDriver!.activeRoute.isNotEmpty) {
      polylines.add(
        Polyline(
          points: _selectedDriver!.activeRoute,
          strokeWidth: 5.0,
          color: AdminTheme.crimsonRed,
        ),
      );
    }

    // 2. Geofence Polygons
    final List<Polygon> polygons = [];
    if (_showGeofences) {
      for (final zone in _geofenceZones) {
        polygons.add(
          Polygon(
            points: zone.polygonPoints,
            color: zone.color.withAlpha(25),
            borderColor: zone.color.withAlpha(200),
            borderStrokeWidth: 2.0,
          ),
        );
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _fleetCentroid,
            initialZoom: 11.5,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.hamha.admin',
            ),
            if (polygons.isNotEmpty)
              PolygonLayer(polygons: polygons),
            if (polylines.isNotEmpty)
              PolylineLayer(polylines: polylines),
            MarkerLayer(
              markers: _drivers.map((driver) {
                final isSelected = _selectedDriver?.id == driver.id;
                return Marker(
                  point: driver.location,
                  width: isSelected ? 60 : 44,
                  height: isSelected ? 60 : 44,
                  child: FleetDriverMarkerWidget(
                    driver: driver,
                    isSelected: isSelected,
                    onTap: () => _selectAndCenterDriver(driver),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Back to Driver Location & District view toggle
        Positioned(
          left: 20,
          bottom: 20,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _showMapTileView = false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.deepBlack,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('BACK TO DRIVER LOCATION VIEW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
          ),
        ),

        // Floating Driver Telemetry Card (Positioned Top-Left over Map)
        if (_selectedDriver != null)
          Positioned(
            left: 20,
            top: 20,
            child: FloatingTelemetryCard(
              driver: _selectedDriver!,
              isRouteVisible: _isRouteVisibleForSelected,
              onClose: () => setState(() => _selectedDriver = null),
              onToggleRoute: () {
                setState(() => _isRouteVisibleForSelected = !_isRouteVisibleForSelected);
              },
              onCenterMap: () {
                _mapController.move(_selectedDriver!.location, 14.5);
              },
              onManualDispatch: () {
                _showManualDispatchModal(_selectedDriver!);
              },
            ),
          ),

        // Map Control Tower Controls (Positioned Top-Right)
        Positioned(
          right: 20,
          top: 20,
          child: ValueListenableBuilder<bool>(
            valueListenable: _socketService.isConnected,
            builder: (context, connected, _) {
              return ValueListenableBuilder<int>(
                valueListenable: _socketService.livePacketCount,
                builder: (context, pktCount, _) {
                  return FleetMapControls(
                    showGeofences: _showGeofences,
                    showAllRoutes: _showAllRoutes,
                    isDarkMap: _isDarkMap,
                    livePacketCount: pktCount,
                    isSocketConnected: connected,
                    onToggleGeofences: () => setState(() => _showGeofences = !_showGeofences),
                    onToggleAllRoutes: () => setState(() => _showAllRoutes = !_showAllRoutes),
                    onToggleMapStyle: () => setState(() => _isDarkMap = !_isDarkMap),
                    onZoomIn: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, currentZoom + 1.0);
                    },
                    onZoomOut: () {
                      final currentZoom = _mapController.camera.zoom;
                      _mapController.move(_mapController.camera.center, currentZoom - 1.0);
                    },
                    onResetCentroid: () {
                      _mapController.move(_fleetCentroid, 11.5);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showManualDispatchModal(FleetDriverModel driver) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.crispWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AdminTheme.borderSubtle)),
        title: Row(
          children: [
            const Icon(Icons.send_rounded, color: AdminTheme.crimsonRed, size: 20),
            const SizedBox(width: 8),
            Text('Manual Dispatch: ${driver.name}', style: const TextStyle(color: AdminTheme.deepBlack, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle: ${driver.vehicleModel} • ${driver.plateNumber}', style: const TextStyle(color: AdminTheme.textDark, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Location: ${driver.district} (${driver.location.latitude.toStringAsFixed(4)}, ${driver.location.longitude.toStringAsFixed(4)})', style: const TextStyle(color: AdminTheme.textMuted, fontSize: 11)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AdminTheme.warmCream, borderRadius: BorderRadius.circular(10), border: Border.all(color: AdminTheme.borderSubtle)),
              child: const Text(
                'Full PostGIS ST_DWithin radius matrix and shipment queue will be managed in Phase 3 Dispatch Matrix.',
                style: TextStyle(color: AdminTheme.textDark, fontSize: 11, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DISMISS', style: TextStyle(color: AdminTheme.textMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.crimsonRed,
              foregroundColor: AdminTheme.crispWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dispatched high-priority override packet to ${driver.name} via Socket.io.', style: const TextStyle(color: AdminTheme.crispWhite)),
                  backgroundColor: AdminTheme.deepBlack,
                ),
              );
            },
            child: const Text('CONFIRM OVERRIDE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderModule(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 48, color: AdminTheme.textMuted.withAlpha(120)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: AdminTheme.textMuted)),
        ],
      ),
    );
  }
}
