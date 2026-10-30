import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HamhaCustomerApp());
}

class HamhaCustomerApp extends StatelessWidget {
  const HamhaCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HAMHA Logistics - Customer',
      debugShowCheckedModeBanner: false,
      theme: HamhaTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
