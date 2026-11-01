import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/models/dispatch_offer_model.dart';
import '../../../core/services/driver_api_service.dart';
import '../../../core/services/driver_socket_service.dart';
import '../../home/screens/driver_home_screen.dart';
import '../../tracking/screens/driver_live_tracking_screen.dart';
import '../../profile/screens/driver_profile_screen.dart';
import '../../dispatch/widgets/dispatch_offer_modal.dart';

class DriverMainShell extends StatefulWidget {
  final int initialTab;
  const DriverMainShell({super.key, this.initialTab = 0});

  @override
  State<DriverMainShell> createState() => _DriverMainShellState();
}

class _DriverMainShellState extends State<DriverMainShell> {
  late int _currentTabIndex;
  StreamSubscription<Map<String, dynamic>>? _offerSubscription;
  DispatchOfferModel? _activeIncomingOffer;
  final List<DispatchOfferModel> _notificationHistory = [];
  bool _showNotificationBanner = false;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTab;
    _initDriverSocket();
  }

  void _initDriverSocket() {
    final driver = DriverApiService().currentDriver;
    final driverId = driver?.id ?? 'vikram-driver-id-2026';

    DriverSocketService().initialize(
      driverId: driverId,
      onDispatchOffer: (offerData) {
        _handleIncomingDispatch(offerData);
      },
    );

    // Also listen to the broadcast stream for redundant safety
    _offerSubscription = DriverSocketService().dispatchOfferStream.listen((offerData) {
      _handleIncomingDispatch(offerData);
    });
  }

  void _handleIncomingDispatch(Map<String, dynamic> offerData) {
    if (!mounted) return;
    try {
      final offer = DispatchOfferModel.fromJson(offerData);

      setState(() {
        _activeIncomingOffer = offer;
        _showNotificationBanner = true;
        _notificationHistory.removeWhere((item) => item.id == offer.id);
        _notificationHistory.insert(0, offer);
      });

      // Sound / Haptic Alert
      HapticFeedback.heavyImpact();

      // Automatically present dispatch offer modal
      _showDispatchModal(offer);
    } catch (e) {
      debugPrint('Error parsing incoming dispatch offer: $e');
    }
  }

  void _showDispatchModal(DispatchOfferModel offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DispatchOfferModal(
        offer: offer,
        onAccept: (acceptedOffer) {
          Navigator.pop(ctx);
          setState(() {
            _showNotificationBanner = false;
            _currentTabIndex = 1; // Switch to Live Tracking tab
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Consignment #${acceptedOffer.orderCode} Accepted! Heading to pickup at ${acceptedOffer.pickupAddress}.'),
              backgroundColor: DriverTheme.statusOnline,
              duration: const Duration(seconds: 4),
            ),
          );
        },
        onDecline: () {
          Navigator.pop(ctx);
          setState(() {
            _showNotificationBanner = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip offer declined. You remain available for other corridors.'),
              backgroundColor: DriverTheme.deepBlack,
            ),
          );
        },
      ),
    );
  }

  void _switchTab(int index) {
    setState(() => _currentTabIndex = index);
  }

  @override
  void dispose() {
    _offerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DriverHomeScreen(
        onGoToTracking: () => _switchTab(1),
      ),
      const DriverLiveTrackingScreen(),
      const DriverProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: DriverTheme.warmCream,
      body: SafeArea(
        child: Column(
          children: [
            // In-App Real-Time Notification Bar for Captain
            if (_showNotificationBanner && _activeIncomingOffer != null)
              _buildNotificationBar(),

            Expanded(
              child: IndexedStack(
                index: _currentTabIndex,
                children: screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: DriverTheme.crispWhite,
          border: const Border(top: BorderSide(color: DriverTheme.borderSubtle, width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: _switchTab,
          backgroundColor: DriverTheme.crispWhite,
          selectedItemColor: DriverTheme.crimsonRed,
          unselectedItemColor: DriverTheme.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
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
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBar() {
    final offer = _activeIncomingOffer!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DriverTheme.crimsonRed,
        boxShadow: [
          BoxShadow(
            color: DriverTheme.crimsonRed.withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active, color: DriverTheme.crimsonRed, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _showDispatchModal(offer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        '🚨 NEW OWNER DISPATCH REQUEST',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${offer.payoutAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${offer.cargoType} • ${offer.weightTons.toStringAsFixed(1)} Tons | Tap to review & accept',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _showDispatchModal(offer),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: DriverTheme.crimsonRed,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('VIEW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            tooltip: 'Dismiss alert',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _showNotificationBanner = false),
          ),
        ],
      ),
    );
  }
}
