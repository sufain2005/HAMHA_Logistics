import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';
import '../../home/screens/customer_home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String mockOtp;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.mockOtp = '889900',
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _otpController.text = widget.mockOtp; // Convenience for testing
  }

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() => _errorMessage = 'Please enter a 6-digit verification code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiClient().verifyOtp(
        phone: widget.phoneNumber,
        otpCode: code,
      );

      // Connect real-time socket
      SocketService().connect('mock-customer-session');

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        (route) => false,
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
      backgroundColor: HamhaTheme.deepBlack,
      appBar: AppBar(
        title: const Text('Phone Verification'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.mark_email_read_outlined,
                size: 64,
                color: HamhaTheme.crimsonRed,
              ),
              const SizedBox(height: 20),
              const Text(
                'Enter Security Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: HamhaTheme.crispWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit confirmation code to\n${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: HamhaTheme.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 32),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HamhaTheme.crimsonDark.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: HamhaTheme.crimsonRed),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: HamhaTheme.crimsonLight, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // OTP Input
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  color: HamhaTheme.crispWhite,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: TextStyle(color: HamhaTheme.textMuted, letterSpacing: 10),
                ),
              ),
              const SizedBox(height: 16),

              // Mock Code Helper pill
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: HamhaTheme.cardBlack,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: HamhaTheme.crimsonRed.withAlpha(80)),
                  ),
                  child: Text(
                    'Demo OTP: ${widget.mockOtp}',
                    style: const TextStyle(color: HamhaTheme.crimsonLight, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const Spacer(),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: HamhaTheme.crispWhite, strokeWidth: 2),
                      )
                    : const Text('VERIFY & ENTER HAMHA'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

