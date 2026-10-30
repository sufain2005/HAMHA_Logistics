import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/order_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';
import '../widgets/floating_driver_card.dart';
import '../../invoice/screens/order_invoice_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final MapController _mapController = MapController();
  OrderModel? _order;
  bool _isLoading = true;
  String? _errorMessage;

  // Live Driver Position & Heading via Socket.io
  LatLng? _driverPosition;
  double _driverHeading = 0.0;
  String? _liveEta;

  StreamSubscription? _locationSub;
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    _fetchTrackingData();
    _setupSocketListeners();
  }

  Future<void> _fetchTrackingData() async {
    try {
      final order = await ApiClient().getOrderTracking(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
        if (order.driverLat != null && order.driverLon != null) {
          _driverPosition = LatLng(order.driverLat!, order.driverLon!);
          _driverHeading = order.driverHeading ?? 0.0;
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerMap();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _setupSocketListeners() {
    final socket = SocketService();
    socket.joinOrderRoom(widget.orderId);

    _locationSub = socket.driverLocationStream.listen((data) {
      if (!mounted) return;
      final lat = (data['lat'] as num?)?.toDouble();
      final lon = (data['lon'] as num?)?.toDouble();
      final heading = (data['heading'] as num?)?.toDouble() ?? 0.0;
      final speed = (data['speedKmh'] as num?)?.toDouble() ?? 0.0;

      if (lat != null && lon != null) {
        setState(() {
          _driverPosition = LatLng(lat, lon);
          _driverHeading = heading;
          if (speed > 5) {
            _liveEta = '${(12 * (30 / (speed > 0 ? speed : 30))).round()} MIN';
          }
        });
      }
    });

    _statusSub = socket.orderStatusStream.listen((data) {
      if (!mounted) return;
      final status = data['status'];
      if (status != null && _order != null) {
        setState(() {
          _order = OrderModel(
            id: _order!.id,
            orderCode: _order!.orderCode,
            status: status,
            cargoType: _order!.cargoType,
            weightKg: _order!.weightKg,
            pickupAddress: _order!.pickupAddress,
            pickupLon: _order!.pickupLon,
            pickupLat: _order!.pickupLat,
            dropoffAddress: _order!.dropoffAddress,
            dropoffLon: _order!.dropoffLon,
            dropoffLat: _order!.dropoffLat,
            fareAmount: _order!.fareAmount,
            distanceKm: _order!.distanceKm,
            paymentStatus: _order!.paymentStatus,
            driverId: _order!.driverId,
            driverName: _order!.driverName,
            driverPhone: _order!.driverPhone,
            vehiclePlate: _order!.vehiclePlate,
            vehicleModel: _order!.vehicleModel,
            createdAt: _order!.createdAt,
          );
        });

        if (status == 'delivered') {
          _showDeliveredDialog();
        }
      }
    });
  }

  void _centerMap() {
    if (_order == null) return;
    final pickup = LatLng(_order!.pickupLat, _order!.pickupLon);
    final dropoff = LatLng(_order!.dropoffLat, _order!.dropoffLon);

    final bounds = LatLngBounds(pickup, dropoff);
    if (_driverPosition != null) {
      bounds.extend(_driverPosition!);
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 120),
      ),
    );
  }

  void _showDeliveredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: HamhaTheme.crispWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: HamhaTheme.statusDelivered, size: 28),
            SizedBox(width: 10),
            Text('Shipment Delivered!', style: TextStyle(color: HamhaTheme.deepBlack, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Your package has been safely delivered to its destination. Your invoice is now ready.',
          style: TextStyle(color: HamhaTheme.textMuted),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: HamhaTheme.crimsonRed),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => OrderInvoiceScreen(orderId: widget.orderId)),
              );
            },
            child: const Text('VIEW INVOICE'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    SocketService().leaveOrderRoom(widget.orderId);
    _locationSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: HamhaTheme.warmCream,
        body: Center(
          child: CircularProgressIndicator(color: HamhaTheme.crimsonRed),
        ),
      );
    }

    if (_errorMessage != null || _order == null) {
      return Scaffold(
        backgroundColor: HamhaTheme.warmCream,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Text(_errorMessage ?? 'Failed to load tracking', style: const TextStyle(color: HamhaTheme.deepBlack)),
        ),
      );
    }

    final pickupLatLng = LatLng(_order!.pickupLat, _order!.pickupLon);
    final dropoffLatLng = LatLng(_order!.dropoffLat, _order!.dropoffLon);

    final driverLatLng = _driverPosition ??
        LatLng(
          (pickupLatLng.latitude + dropoffLatLng.latitude) / 2,
          (pickupLatLng.longitude + dropoffLatLng.longitude) / 2,
        );

    final routePoints = [pickupLatLng, driverLatLng, dropoffLatLng];

    return Scaffold(
      backgroundColor: HamhaTheme.warmCream,
      body: Stack(
        children: [
          // 1. Clean Map Tile Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: driverLatLng,
              initialZoom: 13.5,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.mapboxDarkTileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.hamha.customer',
              ),

              // Bold Crimson Red Route Line
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 5.5,
                    color: HamhaTheme.crimsonRed,
                    borderColor: HamhaTheme.crimsonDark,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // Pick-up Pin
                  Marker(
                    point: pickupLatLng,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: HamhaTheme.crispWhite,
                        shape: BoxShape.circle,
                        border: Border.all(color: HamhaTheme.deepBlack, width: 2.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 8),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.inventory_2, color: HamhaTheme.crimsonRed, size: 20),
                      ),
                    ),
                  ),

                  // Destination Pin
                  Marker(
                    point: dropoffLatLng,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: HamhaTheme.crimsonRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: HamhaTheme.crimsonRed.withAlpha(140), blurRadius: 10),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.flag, color: HamhaTheme.crispWhite, size: 24),
                      ),
                    ),
                  ),

                  // Live Moving Driver Marker
                  Marker(
                    point: driverLatLng,
                    width: 52,
                    height: 52,
                    child: Transform.rotate(
                      angle: (_driverHeading * 3.14159) / 180,
                      child: Container(
                        decoration: BoxDecoration(
                          color: HamhaTheme.deepBlack,
                          shape: BoxShape.circle,
                          border: Border.all(color: HamhaTheme.crimsonRed, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(80),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.navigation,
                            color: HamhaTheme.crispWhite,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Top Navigation Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: HamhaTheme.crispWhite,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8)],
                      border: Border.all(color: HamhaTheme.borderSubtle),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: HamhaTheme.deepBlack, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: HamhaTheme.crispWhite,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8)],
                      border: Border.all(color: HamhaTheme.crimsonRed.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: HamhaTheme.statusDelivered,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'LIVE GPS FEED',
                          style: TextStyle(
                            color: HamhaTheme.deepBlack,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: HamhaTheme.crispWhite,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8)],
                      border: Border.all(color: HamhaTheme.borderSubtle),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.my_location, color: HamhaTheme.deepBlack, size: 18),
                      onPressed: _centerMap,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Driver Contact Card at the Bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingDriverCard(
              order: _order!,
              liveEta: _liveEta,
              onCallDriver: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: HamhaTheme.deepBlack,
                    content: Text('Calling Driver: ${_order!.driverPhone ?? "+1 415 555 0192"}'),
                  ),
                );
              },
              onViewInvoice: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OrderInvoiceScreen(orderId: widget.orderId)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
