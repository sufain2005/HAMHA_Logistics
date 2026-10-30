import 'package:flutter/material.dart';
import 'core/theme/admin_theme.dart';
import 'core/services/admin_auth_service.dart';
import 'features/auth/screens/admin_login_screen.dart';
import 'features/dashboard/screens/admin_dashboard_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdminAuthService().initializeFromStorage();
  runApp(const HamhaAdminApp());
}

class HamhaAdminApp extends StatelessWidget {
  const HamhaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AdminAuthService();

    return MaterialApp(
      title: 'HAMHA Logistics — Owner Panel',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.theme,
      home: authService.isAuthenticated
          ? AdminDashboardShell(admin: authService.currentAdmin!)
          : const AdminLoginScreen(),
    );
  }
}
