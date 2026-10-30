import 'package:flutter/material.dart';
import '../../../core/theme/driver_theme.dart';
import '../../home/screens/driver_home_screen.dart';
import '../../tracking/screens/driver_live_tracking_screen.dart';
import '../../profile/screens/driver_profile_screen.dart';

class DriverMainShell extends StatefulWidget {
  final int initialTab;
  const DriverMainShell({super.key, this.initialTab = 0});

  @override
  State<DriverMainShell> createState() => _DriverMainShellState();
}

class _DriverMainShellState extends State<DriverMainShell> {
  late int _currentTabIndex;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTab;
  }

  void _switchTab(int index) {
    setState(() => _currentTabIndex = index);
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
      body: IndexedStack(
        index: _currentTabIndex,
        children: screens,
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
}

