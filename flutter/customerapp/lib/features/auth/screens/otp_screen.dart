import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';
import '../widgets/logistics_motion_background.dart';
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
    _otpController.text = widget.mockOtp;
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
      appBar: AppBar(
        title: const Text('Security Verification'),
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: HamhaTheme.crimsonTint,
                          shape: BoxShape.circle,
                          border: Border.all(color: HamhaTheme.crimsonRed.withAlpha(60)),
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          size: 44,
                          color: HamhaTheme.crimsonRed,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Enter 6-Digit Code',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: HamhaTheme.deepBlack,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A security verification code was sent to\n${widget.phoneNumber}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: HamhaTheme.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 28),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: HamhaTheme.crimsonTint,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: HamhaTheme.crimsonLight),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: HamhaTheme.crimsonDark, fontSize: 13),
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
                          color: HamhaTheme.deepBlack,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 12,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: HamhaTheme.warmCream,
                          hintText: '••••••',
                          hintStyle: const TextStyle(color: HamhaTheme.textMuted, letterSpacing: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: HamhaTheme.borderSubtle, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Demo Helper
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: HamhaTheme.deepBlack,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Demo Code: ${widget.mockOtp}',
                            style: const TextStyle(color: HamhaTheme.crispWhite, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HamhaTheme.crimsonRed,
                          foregroundColor: HamhaTheme.crispWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: HamhaTheme.crispWhite, strokeWidth: 2),
                              )
                            : const Text('VERIFY & ENTER HAMHA'),
                      ),
                    ],
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
