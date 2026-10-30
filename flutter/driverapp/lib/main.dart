import 'package:flutter/material.dart';
import 'core/theme/driver_theme.dart';
import 'core/services/driver_api_service.dart';
import 'features/auth/screens/driver_welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DriverApiService().initializeFromStorage();
  runApp(const HamhaDriverApp());
}

class HamhaDriverApp extends StatelessWidget {
  const HamhaDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HAMHA Driver & Carrier Pilot',
      debugShowCheckedModeBanner: false,
      theme: DriverTheme.lightTheme,
      home: const DriverWelcomeScreen(),
    );
  }
}
