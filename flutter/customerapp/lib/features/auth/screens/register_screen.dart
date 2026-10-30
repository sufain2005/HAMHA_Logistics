import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../widgets/hamha_logo.dart';
import '../widgets/logistics_motion_background.dart';
import '../widgets/terms_conditions_dialog.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+1 ');
  final _passwordController = TextEditingController();
  bool _agreedToTerms = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      setState(() {
        _errorMessage = 'You must review and agree to the Terms of Service to create an account.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient().register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneNumber: _phoneController.text.trim(),
            mockOtp: res['otpVerification']?['mockCode'] ?? '889900',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: HamhaTheme.deepBlack, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LogisticsMotionBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: HamhaTheme.crispWhite,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: HamhaTheme.borderSubtle, width: 1.2),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: HamhaLogo(size: 72, showSubtitle: true)),
                        const SizedBox(height: 24),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: HamhaTheme.crimsonTint,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: HamhaTheme.crimsonLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: HamhaTheme.crimsonRed, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: HamhaTheme.crimsonDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Full Name
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: HamhaTheme.textDark, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            labelText: 'Full Legal Name',
                            prefixIcon: Icon(Icons.person_outline, color: HamhaTheme.deepBlack),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter your legal name' : null,
                        ),
                        const SizedBox(height: 16),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: HamhaTheme.textDark, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            labelText: 'Work Email Address',
                            prefixIcon: Icon(Icons.email_outlined, color: HamhaTheme.deepBlack),
                          ),
                          validator: (val) => val == null || !val.contains('@') ? 'Enter a valid corporate email' : null,
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: HamhaTheme.textDark, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            labelText: 'Mobile Phone (for live delivery SMS)',
                            prefixIcon: Icon(Icons.phone_outlined, color: HamhaTheme.deepBlack),
                          ),
                          validator: (val) => val == null || val.length < 8 ? 'Enter a valid mobile phone number' : null,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: HamhaTheme.textDark, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            labelText: 'Create Password',
                            prefixIcon: Icon(Icons.lock_outline, color: HamhaTheme.deepBlack),
                          ),
                          validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                        ),
                        const SizedBox(height: 18),

                        // Legal Terms Agreement Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreedToTerms,
                                activeColor: HamhaTheme.crimsonRed,
                                checkColor: HamhaTheme.crispWhite,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => TermsConditionsDialog.show(context),
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(fontSize: 12, color: HamhaTheme.textDark, height: 1.4),
                                    children: [
                                      TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: TextStyle(
                                          color: HamhaTheme.crimsonRed,
                                          fontWeight: FontWeight.w800,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      TextSpan(text: ', Cargo Liability Agreement, and '),
                                      TextSpan(
                                        text: 'GPS Telemetry Consent',
                                        style: TextStyle(
                                          color: HamhaTheme.crimsonRed,
                                          fontWeight: FontWeight.w800,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      TextSpan(text: '.'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HamhaTheme.crimsonRed,
                            foregroundColor: HamhaTheme.crispWhite,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: HamhaTheme.crispWhite, strokeWidth: 2),
                                )
                              : const Text('CONTINUE TO VERIFICATION'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
