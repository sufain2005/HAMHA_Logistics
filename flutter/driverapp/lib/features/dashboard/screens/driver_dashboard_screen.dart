import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/services/driver_api_service.dart';
import '../../../core/services/driver_socket_service.dart';
import '../../../core/models/dispatch_offer_model.dart';
import '../../dispatch/widgets/dispatch_offer_modal.dart';
import '../widgets/driver_cash_out_modal.dart';
import '../../auth/screens/driver_welcome_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LatLng _driverLocation = const LatLng(19.2813, 73.0483); // Bhiwandi Freight Corridor

  bool _isOnline = false;
  bool _isToggling = false;
  bool _isModalShowing = false;
  DispatchOfferModel? _activeAcceptedOffer;

  double _todayEarnings = 3450.0;
  int _tripsCompleted = 6;
  String _onlineHours = '5h 20m';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final driver = DriverApiService().currentDriver;
    if (driver != null) {
      _isOnline = driver.isOnline;
      _todayEarnings = driver.todayEarnings;
      _tripsCompleted = driver.todayTrips;
      _onlineHours = driver.onlineHours;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize socket connection for active driver
    _initSocket();
  }

  void _initSocket() {
    final driver = DriverApiService().currentDriver;
    if (driver == null) return;

    DriverSocketService().initialize(
      driverId: driver.id,
      onStatusChange: (connected) {
        if (mounted) setState(() {});
      },
      onDispatchOffer: (offerData) {
        if (mounted) {
          _handleIncomingOffer(offerData);
        }
      },
    );

    if (_isOnline) {
      DriverSocketService().toggleOnline(true);
      DriverSocketService().streamLocation(
        lon: _driverLocation.longitude,
        lat: _driverLocation.latitude,
        heading: 45.0,
        speedKmh: 0.0,
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleIncomingOffer(Map<String, dynamic> offerData) {
    if (!_isOnline || _isModalShowing || _activeAcceptedOffer != null) return;
    final offer = DispatchOfferModel.fromJson(offerData);
    _showDispatchOfferModal(offer);
  }

  void _showDispatchOfferModal(DispatchOfferModel offer) {
    setState(() => _isModalShowing = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => DispatchOfferModal(
        offer: offer,
        onAccept: (accepted) {
          Navigator.pop(context);
          setState(() {
            _isModalShowing = false;
            _activeAcceptedOffer = accepted;
            _todayEarnings += accepted.payoutAmount;
            _tripsCompleted += 1;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: DriverTheme.crispWhite),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dispatch ${accepted.orderCode} Accepted! (₹${accepted.payoutAmount.toStringAsFixed(0)})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              backgroundColor: DriverTheme.statusOnline,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        onDecline: () {
          Navigator.pop(context);
          setState(() => _isModalShowing = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Offer declined. Still searching nearby cargo for your vehicle...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: DriverTheme.deepBlack,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    ).then((_) {
      if (mounted) setState(() => _isModalShowing = false);
    });
  }

  Future<void> _handleToggleDuty(bool value) async {
    setState(() => _isToggling = true);

    try {
      await DriverApiService().toggleOnlineStatus(isOnline: value);
      DriverSocketService().toggleOnline(value);

      if (value) {
        DriverSocketService().streamLocation(
          lon: _driverLocation.longitude,
          lat: _driverLocation.latitude,
          heading: 45.0,
          speedKmh: 0.0,
        );
      }

      setState(() {
        _isOnline = value;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                value ? Icons.check_circle : Icons.pause_circle_filled,
                color: DriverTheme.crispWhite,
              ),
              const SizedBox(width: 10),
              Text(
                value
                    ? '🟢 You are ONLINE • Ready to receive dispatches'
                    : '⚫ You are OFFLINE • Duty paused',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          backgroundColor: value ? DriverTheme.statusOnline : DriverTheme.deepBlack,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      debugPrint('Duty toggle error: $e');
    } finally {
      if (mounted) setState(() => _isToggling = false);
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

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DriverTheme.crispWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Duty & Sign Out?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to go offline and sign out of HAMHA Logistics?'),
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

  @override
  Widget build(BuildContext context) {
    final driver = DriverApiService().currentDriver;

    return Scaffold(
      backgroundColor: DriverTheme.warmCream,
      body: Stack(
        children: [
          // 1. MAP VIEW
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _driverLocation,
                initialZoom: 14.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.hamha.driver',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _driverLocation,
                      width: 70,
                      height: 70,
                      child: _buildDriverLocationMarker(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. TOP FLOATING APP BAR & STATUS TOGGLE
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: DriverTheme.crispWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DriverTheme.borderSubtle, width: 1.2),
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
                      // HAMHA LOGO & DRIVER BADGE
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: DriverTheme.crispWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: DriverTheme.borderSubtle),
                        ),
                        child: Image.asset(
                          'assets/images/hamha_logo.png',
                          height: 26,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/hamha_logo.jpg',
                            height: 26,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  driver?.name ?? 'Rajesh Kumar',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: DriverTheme.deepBlack,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: DriverTheme.warmCream,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: DriverTheme.borderSubtle),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 12),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${driver?.rating ?? 4.9}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${driver?.vehicleType ?? 'Van'} • ${driver?.plateNumber ?? 'MH 12 AB 1234'}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: DriverTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // PROMINENT ONLINE / OFFLINE TOGGLE SWITCH
                      _buildOnlineToggleSwitch(),

                      const SizedBox(width: 8),
                      // Sign out button
                      IconButton(
                        icon: const Icon(Icons.logout, color: DriverTheme.textMuted, size: 20),
                        onPressed: _handleLogout,
                        tooltip: 'Sign Out',
                      ),
                    ],
                  ),
                ),

                // GPS Telemetry Strip
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: DriverTheme.deepBlack.withAlpha(220),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isOnline ? Icons.gps_fixed : Icons.gps_not_fixed,
                        color: _isOnline ? DriverTheme.statusOnline : DriverTheme.textMuted,
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isOnline
                            ? (_activeAcceptedOffer != null
                                ? 'Dispatch Assigned • Heading to Pickup'
                                : 'Bhiwandi Hub • GPS Active • Ready for Dispatch')
                            : 'Standby Mode • Turn Online to Receive Cargo',
                        style: const TextStyle(
                          color: DriverTheme.crispWhite,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. FLOATING ACTION PILLS: TEST DISPATCH & RE-CENTER MAP
          Positioned(
            right: 18,
            bottom: _activeAcceptedOffer != null ? 360 : 270,
            child: Column(
              children: [
                if (_isOnline && _activeAcceptedOffer == null) ...[
                  FloatingActionButton.extended(
                    heroTag: 'simulate_dispatch',
                    backgroundColor: DriverTheme.crimsonRed,
                    foregroundColor: DriverTheme.crispWhite,
                    elevation: 5,
                    icon: const Icon(Icons.bolt, size: 18),
                    label: const Text(
                      'TEST DISPATCH',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                    onPressed: () {
                      _showDispatchOfferModal(DispatchOfferModel.sampleBhiwandiMumbaiOffer());
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                FloatingActionButton.small(
                  heroTag: 'recenter_gps',
                  backgroundColor: DriverTheme.crispWhite,
                  foregroundColor: DriverTheme.deepBlack,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: DriverTheme.borderSubtle, width: 1.2),
                  ),
                  onPressed: () {
                    _mapController.move(_driverLocation, 15.0);
                  },
                  child: const Icon(Icons.my_location, size: 20),
                ),
              ],
            ),
          ),

          // 4. ACTIVE ACCEPTED CONSIGNMENT CARD (IF ACCEPTED)
          if (_activeAcceptedOffer != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 240,
              child: _buildActiveAcceptedOrderCard(),
            ),

          // 5. PULL-UP BOTTOM SHEET (TODAY'S EARNINGS & CASH OUT)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: _buildPullUpSummaryCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isOnline)
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DriverTheme.crimsonRed.withAlpha(50),
              ),
            ),
          ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _isOnline ? DriverTheme.crimsonRed : DriverTheme.deepBlack,
            shape: BoxShape.circle,
            border: Border.all(color: DriverTheme.crispWhite, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.navigation,
            color: DriverTheme.crispWhite,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineToggleSwitch() {
    return InkWell(
      onTap: _isToggling ? null : () => _handleToggleDuty(!_isOnline),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isOnline ? DriverTheme.statusOnline : DriverTheme.warmCream,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _isOnline ? DriverTheme.statusOnline : DriverTheme.borderSubtle,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _isOnline ? DriverTheme.crispWhite : DriverTheme.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _isOnline ? 'ONLINE' : 'OFFLINE',
              style: TextStyle(
                color: _isOnline ? DriverTheme.crispWhite : DriverTheme.deepBlack,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAcceptedOrderCard() {
    final offer = _activeAcceptedOffer!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DriverTheme.crispWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DriverTheme.crimsonRed, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: DriverTheme.crimsonRed.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DriverTheme.crimsonRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      offer.orderCode,
                      style: const TextStyle(
                        color: DriverTheme.crispWhite,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ASSIGNED • PROCEED TO PICKUP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: DriverTheme.deepBlack,
                    ),
                  ),
                ],
              ),
              Text(
                '₹${offer.payoutAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: DriverTheme.crimsonRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pickup: ${offer.pickupAddress}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DriverTheme.textDark),
          ),
          Text(
            'Drop-off: ${offer.dropoffAddress}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: DriverTheme.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() => _activeAcceptedOffer = null);
                },
                child: const Text('DISMISS', style: TextStyle(color: DriverTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: DriverTheme.deepBlack,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'READY FOR PHASE 4 NAVIGATION ➔',
                  style: TextStyle(color: DriverTheme.crispWhite, fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPullUpSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DriverTheme.crispWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DriverTheme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: DriverTheme.borderSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Shift Summary",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: DriverTheme.deepBlack,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DriverTheme.crimsonTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DriverTheme.crimsonRed.withAlpha(60)),
                ),
                child: const Text(
                  'PAYOUT DIRECT TO UPI',
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
          const SizedBox(height: 16),

          // 3 Metric Cards Row
          Row(
            children: [
              // Earnings (INR)
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  decoration: BoxDecoration(
                    color: DriverTheme.warmCream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DriverTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TODAY'S EARNINGS",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: DriverTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_todayEarnings.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: DriverTheme.crimsonRed,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Trips
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: DriverTheme.warmCream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DriverTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TRIPS DONE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: DriverTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_tripsCompleted',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: DriverTheme.deepBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Online Hours
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: DriverTheme.warmCream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DriverTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HOURS ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: DriverTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _onlineHours,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: DriverTheme.deepBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cash Out Button
          ElevatedButton(
            onPressed: _todayEarnings > 0 ? _openCashOutModal : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverTheme.crimsonRed,
              foregroundColor: DriverTheme.crispWhite,
              minimumSize: const Size.fromHeight(56),
              elevation: 4,
              shadowColor: DriverTheme.crimsonRed.withAlpha(90),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_wallet, size: 20),
                const SizedBox(width: 10),
                Text(
                  _todayEarnings > 0
                      ? 'CASH OUT (₹${_todayEarnings.toStringAsFixed(0)})'
                      : 'ALL EARNINGS TRANSFERRED',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
