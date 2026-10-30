import 'package:flutter/material.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/services/driver_api_service.dart';
import '../widgets/driver_hamha_logo.dart';
import 'driver_otp_screen.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _nameController = TextEditingController(text: 'Vikram Singh');
  final _emailController = TextEditingController(text: 'vikram.logistics@gmail.com');
  final _phoneController = TextEditingController(text: '+91 98451 22340');
  final _cityController = TextEditingController(text: 'Mumbai / Bhiwandi Freight Corridor');

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      setState(() => _errorMessage = 'Please complete all required fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await DriverApiService().registerDriver(
        name: name,
        email: email,
        phone: phone,
        city: city,
      );

      final mockCode = res['otpVerification']?['mockCode'] ?? '889900';

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverOtpScreen(
            phoneNumber: phone,
            mockCode: mockCode,
            isRegistration: true,
            registrationData: {
              'name': name,
              'email': email,
              'phone': phone,
              'city': city,
            },
          ),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
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
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: DriverHamhaLogo(size: 75)),
                  const SizedBox(height: 28),

                  // Registration Card
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
                          'Driver Partner Application',
                          style: TextStyle(
                            color: DriverTheme.deepBlack,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Step 1 of 3: Enter your details to create your fleet pilot account and verify your phone number.',
                          style: TextStyle(
                            color: DriverTheme.textMuted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

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

                        // Full Name
                        const Text(
                          'FULL LEGAL NAME',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DriverTheme.textMuted),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: DriverTheme.deepBlack),
                          decoration: const InputDecoration(
                            hintText: 'Enter your name as in Driving License',
                            prefixIcon: Icon(Icons.person_outline, color: DriverTheme.textDark),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email
                        const Text(
                          'EMAIL ADDRESS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DriverTheme.textMuted),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: DriverTheme.deepBlack),
                          decoration: const InputDecoration(
                            hintText: 'e.g. driver@express.in',
                            prefixIcon: Icon(Icons.email_outlined, color: DriverTheme.textDark),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Mobile Phone
                        const Text(
                          'MOBILE NUMBER (FOR SMS OTP)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DriverTheme.textMuted),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: DriverTheme.deepBlack),
                          decoration: const InputDecoration(
                            hintText: '+91 98765 43210',
                            prefixIcon: Icon(Icons.phone_outlined, color: DriverTheme.textDark),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Operating Hub
                        const Text(
                          'LOGISTICS HUB / PRIMARY CITY',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DriverTheme.textMuted),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _cityController,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: DriverTheme.deepBlack),
                          decoration: const InputDecoration(
                            hintText: 'e.g. Mumbai, Pune, Thane',
                            prefixIcon: Icon(Icons.location_city_outlined, color: DriverTheme.textDark),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
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
                              : const Text('PROCEED TO VERIFICATION'),
                        ),
                        const SizedBox(height: 20),

                        // Return to Login
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Already registered as a driver? ',
                              style: TextStyle(color: DriverTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Sign In',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
