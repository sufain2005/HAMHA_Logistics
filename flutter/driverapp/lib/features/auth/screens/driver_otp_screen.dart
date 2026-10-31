import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/services/driver_api_service.dart';
import '../widgets/driver_hamha_logo.dart';
import 'driver_vehicle_selection_screen.dart';
import '../../dashboard/screens/driver_main_shell.dart';

class DriverOtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String mockCode;
  final bool isRegistration;
  final Map<String, String>? registrationData;

  const DriverOtpScreen({
    super.key,
    required this.phoneNumber,
    this.mockCode = '123456',
    this.isRegistration = false,
    this.registrationData,
  });

  @override
  State<DriverOtpScreen> createState() => _DriverOtpScreenState();
}

class _DriverOtpScreenState extends State<DriverOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendTimer = 30;
  Timer? _timer;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus first digit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _resendTimer = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        if (mounted) setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    final otp = _currentOtp;
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the SMS code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await DriverApiService().verifyOtp(
        phone: widget.phoneNumber,
        otpCode: otp,
        isRegistration: widget.isRegistration,
        regData: widget.registrationData,
      );

      if (!mounted) return;

      if (widget.isRegistration) {
        // New driver registration flow -> proceed to Vehicle Setup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DriverVehicleSelectionScreen(),
          ),
        );
      } else {
        // Existing driver login flow -> directly proceed to Driver Shell (Home, Live Tracking, Profile)!
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const DriverMainShell(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fillMockOtp() {
    final code = widget.mockCode.padRight(6, '0');
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = code[i];
    }
    _handleVerify();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverTheme.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DriverTheme.deepBlack),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: DriverHamhaLogo(size: 70)),
                  const SizedBox(height: 28),

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
                        Text(
                          widget.isRegistration ? 'Verify Mobile Number' : 'Driver PIN Verification',
                          style: const TextStyle(
                            color: DriverTheme.deepBlack,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We sent a 6-digit one-time code to ${widget.phoneNumber}',
                          style: const TextStyle(
                            color: DriverTheme.textMuted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Fast Testing Pill
                        InkWell(
                          onTap: _fillMockOtp,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: DriverTheme.crimsonTint,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: DriverTheme.crimsonRed.withAlpha(60)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.touch_app, size: 16, color: DriverTheme.crimsonRed),
                                const SizedBox(width: 8),
                                Text(
                                  'Tap to Auto-Fill Code: ${widget.mockCode}',
                                  style: const TextStyle(
                                    color: DriverTheme.crimsonRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
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
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: DriverTheme.crimsonRed, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // 6-Digit Boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: 48,
                              height: 56,
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                style: const TextStyle(
                                  color: DriverTheme.deepBlack,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                  filled: true,
                                  fillColor: DriverTheme.warmCream,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: DriverTheme.borderSubtle),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: DriverTheme.crimsonRed, width: 2),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty && index < 5) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                  if (_currentOtp.length == 6) {
                                    _handleVerify();
                                  }
                                },
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 28),

                        // Action Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleVerify,
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
                              : Text(widget.isRegistration ? 'VERIFY & CONTINUE' : 'VERIFY & ENTER DASHBOARD'),
                        ),
                        const SizedBox(height: 20),

                        // Resend Section
                        Center(
                          child: _resendTimer > 0
                              ? Text(
                                  'Resend code in $_resendTimer seconds',
                                  style: const TextStyle(
                                    color: DriverTheme.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : TextButton(
                                  onPressed: () {
                                    _startTimer();
                                    DriverApiService().sendOtpForLogin(phone: widget.phoneNumber);
                                  },
                                  child: const Text(
                                    'RESEND CODE',
                                    style: TextStyle(
                                      color: DriverTheme.crimsonRed,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
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
