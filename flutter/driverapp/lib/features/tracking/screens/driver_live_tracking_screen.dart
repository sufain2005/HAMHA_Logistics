import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/services/driver_api_service.dart';
import '../../../core/services/driver_socket_service.dart';
import '../../../core/models/dispatch_offer_model.dart';
import '../../dispatch/widgets/dispatch_offer_modal.dart';
import '../../completion/screens/driver_pod_screen.dart';

enum ActiveTripStage {
  headingToPickup,
  arrivedAtPickup,
  packageCollected,
  inTransitToDropoff,
  arrivedAtDestination,
}

class DriverLiveTrackingScreen extends StatefulWidget {
  const DriverLiveTrackingScreen({super.key});

  @override
  State<DriverLiveTrackingScreen> createState() => _DriverLiveTrackingScreenState();
}

class _DriverLiveTrackingScreenState extends State<DriverLiveTrackingScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Location coordinates (Bhiwandi to BKC Mumbai route)
  LatLng _driverLocation = const LatLng(19.2813, 73.0483);
  final LatLng _pickupLocation = const LatLng(19.2813, 73.0483); // Bhiwandi
  final LatLng _dropoffLocation = const LatLng(19.0657, 72.8679); // BKC Mumbai

  // Simulated GPS route waypoints
  final List<LatLng> _routePoints = const [
    LatLng(19.2813, 73.0483), // Bhiwandi Godown
    LatLng(19.2550, 73.0120), // Majiwada Junction
    LatLng(19.2183, 72.9781), // Thane Toll Plaza (EE Highway)
    LatLng(19.1620, 72.9420), // Mulund Check Naka
    LatLng(19.0880, 72.9100), // Ghatkopar Link
    LatLng(19.0657, 72.8679), // BKC Commercial Hub
  ];

  bool _isOnline = true;
  bool _isToggling = false;
  bool _isModalShowing = false;
  Timer? _gpsStreamTimer;

  // Active Trip State
  DispatchOfferModel? _activeTripOffer;
  ActiveTripStage _tripStage = ActiveTripStage.headingToPickup;
  double _currentSpeedKmh = 46.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final driver = DriverApiService().currentDriver;
    if (driver != null) {
      _isOnline = driver.isOnline;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initSocket();
    _startGpsStreaming();
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
        if (mounted && _isOnline && _activeTripOffer == null && !_isModalShowing) {
          _showDispatchOfferModal(DispatchOfferModel.fromJson(offerData));
        }
      },
    );
  }

  void _startGpsStreaming() {
    _gpsStreamTimer?.cancel();
    _gpsStreamTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_isOnline && mounted) {
        DriverSocketService().streamLocation(
          orderId: _activeTripOffer?.id,
          lon: _driverLocation.longitude,
          lat: _driverLocation.latitude,
          heading: 42.0,
          speedKmh: _activeTripOffer != null ? _currentSpeedKmh : 0.0,
        );
      }
    });
  }

  @override
  void dispose() {
    _gpsStreamTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
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
          _startTrip(accepted);
        },
        onDecline: () {
          Navigator.pop(context);
          setState(() => _isModalShowing = false);
        },
      ),
    ).then((_) {
      if (mounted) setState(() => _isModalShowing = false);
    });
  }

  void _startTrip(DispatchOfferModel offer) {
    setState(() {
      _isModalShowing = false;
      _activeTripOffer = offer;
      _tripStage = ActiveTripStage.headingToPickup;
      _currentSpeedKmh = 48.0;
    });

    _mapController.move(_driverLocation, 14.0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.navigation, color: DriverTheme.crispWhite),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'TRIP STARTED • Route plotted to ${offer.pickupAddress}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: DriverTheme.crimsonRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _advanceTripMilestone() {
    setState(() {
      switch (_tripStage) {
        case ActiveTripStage.headingToPickup:
          _tripStage = ActiveTripStage.arrivedAtPickup;
          _currentSpeedKmh = 0.0;
          break;
        case ActiveTripStage.arrivedAtPickup:
          _tripStage = ActiveTripStage.packageCollected;
          _currentSpeedKmh = 42.0;
          break;
        case ActiveTripStage.packageCollected:
          _tripStage = ActiveTripStage.inTransitToDropoff;
          _currentSpeedKmh = 54.0;
          // Move driver marker along highway
          _driverLocation = const LatLng(19.1620, 72.9420);
          _mapController.move(_driverLocation, 14.0);
          break;
        case ActiveTripStage.inTransitToDropoff:
          _tripStage = ActiveTripStage.arrivedAtDestination;
          _currentSpeedKmh = 0.0;
          _driverLocation = _dropoffLocation;
          _mapController.move(_driverLocation, 15.0);
          break;
        case ActiveTripStage.arrivedAtDestination:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DriverPodScreen(offer: _activeTripOffer!),
            ),
          );
          break;
      }
    });
  }

  void _completeTrip() {
    final fare = _activeTripOffer?.payoutAmount ?? 1850.0;
    final code = _activeTripOffer?.orderCode ?? 'HMH-89241';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: DriverTheme.crispWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: DriverTheme.statusOnline,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: DriverTheme.crispWhite, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Trip Completed!', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Consignment $code has been successfully delivered and signed by customer recipient.'),
            const SizedBox(height: 16),
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
                  const Text('Fare Credited to Wallet', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '₹${fare.toStringAsFixed(0)} INR',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: DriverTheme.crimsonRed),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverTheme.crimsonRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _activeTripOffer = null;
                _driverLocation = const LatLng(19.2813, 73.0483);
                _currentSpeedKmh = 0.0;
              });
              _mapController.move(_driverLocation, 14.5);
            },
            child: const Text('BACK TO LIVE RADAR', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggleDuty(bool value) async {
    setState(() => _isToggling = true);
    try {
      await DriverApiService().toggleOnlineStatus(isOnline: value);
      DriverSocketService().toggleOnline(value);
      setState(() => _isOnline = value);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  String get _milestoneActionText {
    switch (_tripStage) {
      case ActiveTripStage.headingToPickup:
        return 'ARRIVED AT PICKUP';
      case ActiveTripStage.arrivedAtPickup:
        return 'PACKAGE COLLECTED';
      case ActiveTripStage.packageCollected:
        return 'IN TRANSIT TO DROPOFF';
      case ActiveTripStage.inTransitToDropoff:
        return 'ARRIVED AT DESTINATION';
      case ActiveTripStage.arrivedAtDestination:
        return 'CAPTURE PROOF OF DELIVERY (POD)';
    }
  }

  String get _milestoneStatusLabel {
    switch (_tripStage) {
      case ActiveTripStage.headingToPickup:
        return 'STAGE 1/4: HEADING TO PICKUP WAREHOUSE';
      case ActiveTripStage.arrivedAtPickup:
        return 'STAGE 2/4: AT PICKUP WAREHOUSE (LOADING)';
      case ActiveTripStage.packageCollected:
        return 'STAGE 3/4: PACKAGE COLLECTED & MANIFEST VERIFIED';
      case ActiveTripStage.inTransitToDropoff:
        return 'STAGE 4/4: IN TRANSIT ON EXPRESSWAY TO DESTINATION';
      case ActiveTripStage.arrivedAtDestination:
        return 'DESTINATION REACHED: COLLECT PROOF OF DELIVERY';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverTheme.warmCream,
      body: Stack(
        children: [
          // 1. LIVE MAPBOX / TILE MAP
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _driverLocation,
                initialZoom: 14.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.hamha.driver',
                ),

                // Crimson Red Route Polyline when trip is active
                if (_activeTripOffer != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: DriverTheme.crimsonRed,
                        strokeWidth: 4.5,
                      ),
                    ],
                  ),

                // Map Markers
                MarkerLayer(
                  markers: [
                    // Moving Driver Marker
                    Marker(
                      point: _driverLocation,
                      width: 60,
                      height: 60,
                      child: _buildDriverBeaconMarker(),
                    ),

                    // Pickup Marker (if active trip)
                    if (_activeTripOffer != null)
                      Marker(
                        point: _pickupLocation,
                        width: 44,
                        height: 44,
                        child: _buildLocationPin(
                          color: DriverTheme.crimsonRed,
                          icon: Icons.inventory_2,
                          label: 'PICKUP',
                        ),
                      ),

                    // Dropoff Marker (if active trip)
                    if (_activeTripOffer != null)
                      Marker(
                        point: _dropoffLocation,
                        width: 44,
                        height: 44,
                        child: _buildLocationPin(
                          color: DriverTheme.deepBlack,
                          icon: Icons.flag,
                          label: 'DROP-OFF',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 2. TOP FLOATING TELEMETRY & DUTY BAR
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
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
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: DriverTheme.deepBlack,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.radar, color: DriverTheme.crimsonRed, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LIVE FLEET TELEMATICS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: DriverTheme.deepBlack,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Where is now: Thane District • ${_activeTripOffer != null ? "${_currentSpeedKmh.toInt()} km/h" : "Idle GPS Locked"}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: DriverTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Duty switch
                      InkWell(
                        onTap: _isToggling ? null : () => _handleToggleDuty(!_isOnline),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isOnline ? DriverTheme.statusOnline : DriverTheme.warmCream,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isOnline ? DriverTheme.statusOnline : DriverTheme.borderSubtle,
                            ),
                          ),
                          child: Text(
                            _isOnline ? 'ONLINE' : 'OFFLINE',
                            style: TextStyle(
                              color: _isOnline ? DriverTheme.crispWhite : DriverTheme.deepBlack,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Turn-by-Turn Instruction Banner (when trip active)
                if (_activeTripOffer != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: DriverTheme.deepBlack,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.turn_right, color: DriverTheme.crimsonRed, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'In 350m, take exit onto Mumbai-Nashik Expressway',
                                style: TextStyle(
                                  color: DriverTheme.crispWhite,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Next waypoint: Majiwada Flyover • Speed: ${_currentSpeedKmh.toInt()} km/h',
                                style: const TextStyle(color: DriverTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 3. RE-CENTER FAB & TEST DISPATCH BUTTON
          Positioned(
            right: 18,
            bottom: _activeTripOffer != null ? 230 : 120,
            child: Column(
              children: [
                if (_isOnline && _activeTripOffer == null) ...[
                  FloatingActionButton.extended(
                    heroTag: 'tracking_test_dispatch',
                    backgroundColor: DriverTheme.crimsonRed,
                    foregroundColor: DriverTheme.crispWhite,
                    elevation: 5,
                    icon: const Icon(Icons.bolt, size: 18),
                    label: const Text(
                      'START TRIP (DEMO)',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                    onPressed: () {
                      _showDispatchOfferModal(DispatchOfferModel.sampleBhiwandiMumbaiOffer());
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                FloatingActionButton.small(
                  heroTag: 'tracking_recenter',
                  backgroundColor: DriverTheme.crispWhite,
                  foregroundColor: DriverTheme.deepBlack,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: DriverTheme.borderSubtle, width: 1.2),
                  ),
                  onPressed: () => _mapController.move(_driverLocation, 14.5),
                  child: const Icon(Icons.my_location, size: 20),
                ),
              ],
            ),
          ),

          // 4. ACTIVE TRIP SYSTEM CONTROLLER CARD (BOTTOM DOCK)
          if (_activeTripOffer != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: _buildActiveTripCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverBeaconMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isOnline)
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DriverTheme.crimsonRed.withAlpha(50),
              ),
            ),
          ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _isOnline ? DriverTheme.crimsonRed : DriverTheme.deepBlack,
            shape: BoxShape.circle,
            border: Border.all(color: DriverTheme.crispWhite, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.navigation, color: DriverTheme.crispWhite, size: 18),
        ),
      ],
    );
  }

  Widget _buildLocationPin({required Color color, required IconData icon, required String label}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DriverTheme.crispWhite, width: 1.5),
          ),
          child: Icon(icon, color: DriverTheme.crispWhite, size: 16),
        ),
      ],
    );
  }

  Widget _buildActiveTripCard() {
    final offer = _activeTripOffer!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DriverTheme.crispWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DriverTheme.crimsonRed, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 18,
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
          const SizedBox(height: 12),

          // Header
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
                  Text(
                    '₹${offer.payoutAmount.toStringAsFixed(0)} INR',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: DriverTheme.deepBlack,
                    ),
                  ),
                ],
              ),
              Text(
                '${offer.distanceKm} km • ~${offer.estimatedDurationMin}m',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: DriverTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Milestone Status Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: DriverTheme.warmCream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DriverTheme.borderSubtle),
            ),
            child: Text(
              _milestoneStatusLabel,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: DriverTheme.crimsonRed,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Milestone Action Button
          ElevatedButton(
            onPressed: _advanceTripMilestone,
            style: ElevatedButton.styleFrom(
              backgroundColor: _tripStage == ActiveTripStage.arrivedAtDestination
                  ? DriverTheme.statusOnline
                  : DriverTheme.crimsonRed,
              foregroundColor: DriverTheme.crispWhite,
              minimumSize: const Size.fromHeight(54),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _tripStage == ActiveTripStage.arrivedAtDestination ? Icons.task_alt : Icons.arrow_forward,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _milestoneActionText,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

