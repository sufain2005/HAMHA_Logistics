import 'package:flutter/material.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/services/driver_api_service.dart';
import '../widgets/driver_hamha_logo.dart';
import 'driver_otp_screen.dart';
import 'driver_register_screen.dart';

class DriverWelcomeScreen extends StatefulWidget {
  const DriverWelcomeScreen({super.key});

  @override
  State<DriverWelcomeScreen> createState() => _DriverWelcomeScreenState();
}

class _DriverWelcomeScreenState extends State<DriverWelcomeScreen> {
  final _phoneController = TextEditingController(text: '+91 98234 11209');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 8) {
      setState(() => _errorMessage = 'Please enter a valid mobile number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await DriverApiService().sendOtpForLogin(phone: phone);
      final mockCode = res['mockCode'] ?? res['otpVerification']?['mockCode'] ?? res['otp'] ?? '123456';

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverOtpScreen(
            phoneNumber: phone,
            mockCode: mockCode,
            isRegistration: false, // Existing driver sign in
          ),
        ),
      );
    } catch (_) {
      // Seamless dummy OTP fallback — driver is never blocked
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverOtpScreen(
            phoneNumber: phone,
            mockCode: '123456',
            isRegistration: false,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverTheme.warmCream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: DriverHamhaLogo(size: 80)),
                  const SizedBox(height: 32),

                  // High-contrast clean card
                  Container(
                    padding: const EdgeInsets.all(28.0),
                    decoration: BoxDecoration(
                      color: DriverTheme.crispWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: DriverTheme.borderSubtle, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Driver Partner Sign In',
                          style: TextStyle(
                            color: DriverTheme.deepBlack,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter your registered phone number to log in and start receiving shipment dispatches.',
                          style: TextStyle(
                            color: DriverTheme.textMuted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: DriverTheme.crimsonTint,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: DriverTheme.crimsonRed.withAlpha(80)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: DriverTheme.crimsonRed, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: DriverTheme.crimsonRed,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Phone Field
                        const Text(
                          'REGISTERED MOBILE NUMBER',
                          style: TextStyle(
                            color: DriverTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            color: DriverTheme.deepBlack,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: InputDecoration(
                            hintText: '+91 98765 43210',
                            prefixIcon: const Icon(Icons.phone_android, color: DriverTheme.textDark),
                            suffixIcon: _phoneController.text.isNotEmpty
                                ? const Icon(Icons.verified, color: DriverTheme.statusOnline, size: 20)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Large action button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DriverTheme.crimsonRed,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: DriverTheme.crispWhite, strokeWidth: 2.5),
                                )
                              : const Text('CONTINUE WITH PHONE'),
                        ),
                        const SizedBox(height: 16),

                        // Demo Pilot quick login shortcut
                        OutlinedButton(
                          onPressed: () {
                            _phoneController.text = '+91 98234 11209';
                            _handleContinue();
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: DriverTheme.borderSubtle),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bolt, color: DriverTheme.crimsonRed, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'DEMO DRIVER (RAJESH KUMAR)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: DriverTheme.deepBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Apply / Register link
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'New Driver Partner? ',
                              style: TextStyle(color: DriverTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const DriverRegisterScreen()),
                                );
                              },
                              child: const Text(
                                'Apply & Register',
                                style: TextStyle(
                                  color: DriverTheme.crimsonRed,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'HAMHA FLEET TELEMATICS • ISO 9001 LOGISTICS CLOUD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: DriverTheme.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
