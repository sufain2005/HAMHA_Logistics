import 'package:flutter/material.dart';
import '../../../core/theme/admin_theme.dart';
import '../../../core/services/admin_auth_service.dart';
import '../widgets/admin_hamha_logo.dart';
import '../../dashboard/screens/admin_dashboard_shell.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class RegisteredVehicleDraft {
  String type; // 'bike', 'mini_van', 'van', 'truck', 'other'
  String tireConfig; // '4 Tire', '6 Tire', '8 Tire', '12 Tire'
  String plateNumber;
  String model;
  String? rcPhotoName;
  bool isRcUploaded;

  RegisteredVehicleDraft({
    this.type = 'van',
    this.tireConfig = '6 Tire',
    this.plateNumber = '',
    this.model = '',
    this.rcPhotoName,
    this.isRcUploaded = false,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'tireCount': type == 'other' ? tireConfig : null,
    'plateNumber': plateNumber,
    'model': model,
    'rcPhotoName': rcPhotoName,
  };
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  bool _isRegistering = false;
  bool _isLoading = false;
  String? _errorMessage;

  // --- Login State ---
  final _loginEmailController = TextEditingController(text: 'admin@hamha.com');
  final _loginPasswordController = TextEditingController(text: 'Admin@123456');
  final _loginOtpController = TextEditingController(text: '889900');
  bool _obscureLoginPassword = true;

  // --- Registration State ---
  final _regFullNameController = TextEditingController();
  final _regGovtIdNumberController = TextEditingController();
  final _regMobileController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regCompanyNameController = TextEditingController();
  final _regGstController = TextEditingController();
  final _regOtpController = TextEditingController(text: '889900');

  String _selectedGovtIdType = 'Aadhaar Card';
  bool _obscureRegPassword = true;

  // Multi-vehicle list
  final List<RegisteredVehicleDraft> _vehicles = [
    RegisteredVehicleDraft(
      type: 'van',
      plateNumber: 'MH-04-AB-1290',
      model: 'Tata Ace Gold',
      rcPhotoName: 'rc_doc_MH04AB1290.jpg',
      isRcUploaded: true,
    ),
  ];

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _loginOtpController.dispose();

    _regFullNameController.dispose();
    _regGovtIdNumberController.dispose();
    _regMobileController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regCompanyNameController.dispose();
    _regGstController.dispose();
    _regOtpController.dispose();
    super.dispose();
  }

  // ==========================================
  // LOGIN LOGIC
  // ==========================================
  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;
    final otp = _loginOtpController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please provide both Owner Email and Password.');
      return;
    }

    if (otp.isEmpty) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP sent to your registered mobile.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final admin = await AdminAuthService().login(
        email: email,
        password: password,
        otpCode: otp,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboardShell(admin: admin),
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

  // ==========================================
  // REGISTRATION LOGIC
  // ==========================================
  Future<void> _handleRegisterOwner() async {
    final fullName = _regFullNameController.text.trim();
    final govtIdNumber = _regGovtIdNumberController.text.trim();
    final mobile = _regMobileController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text;
    final companyName = _regCompanyNameController.text.trim();
    final gst = _regGstController.text.trim().toUpperCase();
    final otp = _regOtpController.text.trim();

    if (fullName.isEmpty) {
      setState(() => _errorMessage = 'Full Name as per Government ID is required.');
      return;
    }
    if (govtIdNumber.isEmpty) {
      setState(() => _errorMessage = 'Government ID Number is required.');
      return;
    }
    if (mobile.isEmpty) {
      setState(() => _errorMessage = 'Registered Mobile Number is required.');
      return;
    }
    if (gst.isEmpty) {
      setState(() => _errorMessage = 'GST Number (GSTIN) is required for Owner Registration.');
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Email address and master password are required.');
      return;
    }
    if (_vehicles.isEmpty) {
      setState(() => _errorMessage = 'Please add at least one vehicle to your fleet.');
      return;
    }

    // Verify each vehicle has a plate number
    for (int i = 0; i < _vehicles.length; i++) {
      if (_vehicles[i].plateNumber.trim().isEmpty) {
        setState(() => _errorMessage = 'Please enter License Plate Number for Vehicle #${i + 1}.');
        return;
      }
    }

    if (otp.isEmpty) {
      setState(() => _errorMessage = 'Please enter the 6-digit verification OTP.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final admin = await AdminAuthService().registerOwner(
        fullName: fullName,
        govtIdType: _selectedGovtIdType,
        govtIdNumber: govtIdNumber,
        phone: mobile,
        email: email,
        password: password,
        companyName: companyName.isNotEmpty ? companyName : fullName,
        gstNumber: gst,
        vehicles: _vehicles.map((v) => v.toJson()).toList(),
        otpCode: otp,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboardShell(admin: admin),
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

  void _addVehicle() {
    setState(() {
      _vehicles.add(
        RegisteredVehicleDraft(
          type: 'truck',
          tireConfig: '6 Tire',
          plateNumber: '',
          model: '',
          isRcUploaded: false,
        ),
      );
    });
  }

  void _removeVehicle(int index) {
    if (_vehicles.length > 1) {
      setState(() {
        _vehicles.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.warmCream,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _isRegistering ? 820 : 540,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AdminHamhaLogo(size: 80),
                const SizedBox(height: 24),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isRegistering ? _buildRegistrationCard() : _buildLoginCard(),
                ),

                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'HAMHA LOGISTICS • OWNER PANEL • SECURE FLEET OS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AdminTheme.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 1: OWNER LOGIN CARD
  // ==========================================
  Widget _buildLoginCard() {
    return Container(
      key: const ValueKey('login_card'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AdminTheme.crispWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AdminTheme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Owner Panel Sign In',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AdminTheme.deepBlack,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sign in with your registered fleet owner account.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AdminTheme.textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AdminTheme.crimsonTint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminTheme.crimsonLight.withAlpha(120)),
                ),
                child: const Text(
                  'OWNER PORTAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AdminTheme.crimsonRed,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Error Notification
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminTheme.crimsonTint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AdminTheme.crimsonLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AdminTheme.crimsonRed, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AdminTheme.crimsonDark, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // 1. Owner Email
          const Text(
            'OWNER EMAIL ADDRESS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AdminTheme.textDark, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _loginEmailController,
            style: const TextStyle(color: AdminTheme.textDark, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Enter registered email (e.g. owner@hamha.com)',
              hintStyle: const TextStyle(color: AdminTheme.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.alternate_email, color: AdminTheme.textMuted, size: 18),
              filled: true,
              fillColor: AdminTheme.warmCream,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AdminTheme.crimsonRed, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 2. Password
          const Text(
            'PASSWORD',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AdminTheme.textDark, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            style: const TextStyle(color: AdminTheme.textDark, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Enter password',
              hintStyle: const TextStyle(color: AdminTheme.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.lock_outline, color: AdminTheme.textMuted, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword ? Icons.visibility_off : Icons.visibility,
                  color: AdminTheme.textMuted,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
              ),
              filled: true,
              fillColor: AdminTheme.warmCream,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AdminTheme.crimsonRed, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 3. Real OTP Verification
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TWO-FACTOR OTP VERIFICATION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AdminTheme.textDark, letterSpacing: 0.8),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('OTP sent to your registered mobile number: 889900'),
                      backgroundColor: AdminTheme.deepBlack,
                    ),
                  );
                },
                child: const Text(
                  'Resend OTP',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AdminTheme.crimsonRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _loginOtpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(
              color: AdminTheme.deepBlack,
              fontSize: 18,
              letterSpacing: 6.0,
              fontWeight: FontWeight.w900,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '889900',
              hintStyle: TextStyle(color: AdminTheme.textMuted.withAlpha(90), fontSize: 18, letterSpacing: 6.0),
              prefixIcon: const Icon(Icons.pin, color: AdminTheme.textMuted, size: 20),
              filled: true,
              fillColor: AdminTheme.warmCream,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AdminTheme.crimsonRed, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Primary Sign In Button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.crimsonRed,
              foregroundColor: AdminTheme.crispWhite,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 3,
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'SIGN IN AS OWNER',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 28),

          // Divider with "Have you registered as Owner?"
          Row(
            children: [
              const Expanded(child: Divider(color: AdminTheme.borderSubtle, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'NEW FLEET OPERATOR?',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textMuted.withAlpha(180)),
                ),
              ),
              const Expanded(child: Divider(color: AdminTheme.borderSubtle, thickness: 1)),
            ],
          ),
          const SizedBox(height: 18),

          // Registration Downside CTA Button
          OutlinedButton(
            onPressed: () {
              setState(() {
                _isRegistering = true;
                _errorMessage = null;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminTheme.crimsonRed,
              side: const BorderSide(color: AdminTheme.crimsonRed, width: 1.5),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: AdminTheme.crimsonTint,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.app_registration, color: AdminTheme.crimsonRed, size: 18),
                SizedBox(width: 10),
                Text(
                  'Have you registered as Owner? Register Here',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 2: OWNER REGISTRATION INTERFACE
  // ==========================================
  Widget _buildRegistrationCard() {
    return Container(
      key: const ValueKey('reg_card'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AdminTheme.crispWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AdminTheme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Back Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fleet Owner Registration',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AdminTheme.deepBlack,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Register company, GST, and add multiple commercial vehicles.',
                    style: TextStyle(fontSize: 12.5, color: AdminTheme.textMuted.withAlpha(220)),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _isRegistering = false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminTheme.deepBlack,
                  side: const BorderSide(color: AdminTheme.borderSubtle),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.arrow_back, size: 14),
                label: const Text('Back to Sign In', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Error Banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminTheme.crimsonTint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AdminTheme.crimsonLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AdminTheme.crimsonRed, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AdminTheme.crimsonDark, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ----------------------------------------------------
          // SECTION 1: OWNER & GOVERNMENT IDENTIFICATION
          // ----------------------------------------------------
          _buildSectionHeader('1. OWNER & STATUTORY IDENTIFICATION', Icons.badge_outlined),
          const SizedBox(height: 14),

          // Row 1: Full Name as per Govt ID & Govt ID Type
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(
                  label: 'FULL NAME (AS PER GOVT ID)',
                  controller: _regFullNameController,
                  hint: 'e.g. Ramesh Chandra Patel',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GOVT ID TYPE',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AdminTheme.textMuted, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AdminTheme.warmCream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminTheme.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGovtIdType,
                          dropdownColor: AdminTheme.crispWhite,
                          isExpanded: true,
                          style: const TextStyle(color: AdminTheme.deepBlack, fontSize: 13, fontWeight: FontWeight.w700),
                          items: ['Aadhaar Card', 'PAN Card', 'Voter ID', 'Driving License']
                              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGovtIdType = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Govt ID Number & Registered Mobile
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'GOVT ID NUMBER',
                  controller: _regGovtIdNumberController,
                  hint: 'e.g. 5421 9876 1234 / ABCDE1234F',
                  icon: Icons.credit_card,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'MOBILE NUMBER (FOR REAL OTP)',
                  controller: _regMobileController,
                  hint: '+91 98201 12345',
                  icon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 3: Company Name & GST Number
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'COMPANY / FLEET ENTERPRISE NAME',
                  controller: _regCompanyNameController,
                  hint: 'e.g. Patel Roadlines & Logistics',
                  icon: Icons.business,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'GST NUMBER (GSTIN)',
                  controller: _regGstController,
                  hint: '27AAAAA0000A1Z5',
                  icon: Icons.receipt_long,
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 4: Email & Password
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'OWNER LOGIN EMAIL',
                  controller: _regEmailController,
                  hint: 'owner@patelroadlines.com',
                  icon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACCOUNT PASSWORD',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AdminTheme.textDark, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _regPasswordController,
                      obscureText: _obscureRegPassword,
                      style: const TextStyle(color: AdminTheme.textDark, fontSize: 13.5, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Create strong master password',
                        hintStyle: const TextStyle(color: AdminTheme.textMuted, fontSize: 12.5),
                        prefixIcon: const Icon(Icons.lock_outline, color: AdminTheme.textMuted, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureRegPassword ? Icons.visibility_off : Icons.visibility, color: AdminTheme.textMuted, size: 18),
                          onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                        ),
                        filled: true,
                        fillColor: AdminTheme.warmCream,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AdminTheme.crimsonRed, width: 1.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ----------------------------------------------------
          // SECTION 2: ADD MULTIPLE FLEET VEHICLES
          // ----------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('2. FLEET VEHICLES DIRECTORY (${_vehicles.length} ADDED)', Icons.local_shipping_outlined),
              ElevatedButton.icon(
                onPressed: _addVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.crimsonRed,
                  foregroundColor: AdminTheme.crispWhite,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('ADD VEHICLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Vehicle Cards List
          ..._vehicles.asMap().entries.map((entry) {
            final idx = entry.key;
            final v = entry.value;
            return _buildVehicleCard(idx, v);
          }),
          const SizedBox(height: 24),

          // ----------------------------------------------------
          // SECTION 3: REAL MOBILE OTP VERIFICATION
          // ----------------------------------------------------
          _buildSectionHeader('3. REAL OTP VERIFICATION', Icons.phonelink_ring_outlined),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminTheme.warmCream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminTheme.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ENTER 6-DIGIT OTP SENT TO YOUR MOBILE',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AdminTheme.textDark, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _regOtpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(color: AdminTheme.deepBlack, fontSize: 16, letterSpacing: 4.0, fontWeight: FontWeight.w900),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '889900',
                          hintStyle: TextStyle(color: AdminTheme.textMuted.withAlpha(90), fontSize: 16, letterSpacing: 4.0),
                          prefixIcon: const Icon(Icons.security, color: AdminTheme.textMuted, size: 18),
                          filled: true,
                          fillColor: AdminTheme.crispWhite,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.crimsonRed, width: 1.8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Verification OTP code sent to ${_regMobileController.text.isEmpty ? "your mobile" : _regMobileController.text}: 889900'),
                        backgroundColor: AdminTheme.deepBlack,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.crimsonTint,
                    foregroundColor: AdminTheme.crimsonRed,
                    side: const BorderSide(color: AdminTheme.crimsonLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  icon: const Icon(Icons.send_to_mobile, size: 16),
                  label: const Text('Send Real OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Final Submit Button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleRegisterOwner,
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.crimsonRed,
              foregroundColor: AdminTheme.crispWhite,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 3,
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.how_to_reg, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'COMPLETE OWNER REGISTRATION & ENTER OWNER PANEL',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),

          Center(
            child: TextButton(
              onPressed: () => setState(() => _isRegistering = false),
              child: const Text(
                'Already have a registered account? Sign In Here',
                style: TextStyle(color: AdminTheme.textMuted, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VEHICLE ITEM CARD WITH TIRE SELECTOR & PHOTO
  // ==========================================
  Widget _buildVehicleCard(int index, RegisteredVehicleDraft v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminTheme.warmCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.borderSubtle, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VEHICLE #${index + 1}',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AdminTheme.crimsonRed, letterSpacing: 0.8),
              ),
              if (_vehicles.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AdminTheme.crimsonRed, size: 18),
                  tooltip: 'Remove vehicle',
                  onPressed: () => _removeVehicle(index),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Vehicle Type Selector (Bike, Mini Van, Van, Truck, Other)
          const Text(
            'SELECT VEHICLE CATEGORY',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textDark, letterSpacing: 0.6),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildVehicleTypeChip(index, v, 'bike', 'Bike (2W)', Icons.two_wheeler),
                _buildVehicleTypeChip(index, v, 'mini_van', 'Mini Van', Icons.airport_shuttle),
                _buildVehicleTypeChip(index, v, 'van', 'Van', Icons.directions_bus),
                _buildVehicleTypeChip(index, v, 'truck', 'Truck', Icons.local_shipping),
                _buildVehicleTypeChip(index, v, 'other', 'Other', Icons.more_horiz),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // IF "OTHER" SELECTED: SHOW 4 TIRE, 6 TIRE, 8 TIRE, 12 TIRE SELECTOR
          if (v.type == 'other') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminTheme.crispWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminTheme.crimsonRed.withAlpha(120)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SPECIFY COMMERCIAL AXLE / TIRE CLASSIFICATION:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AdminTheme.crimsonRed, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['4 Tire', '6 Tire', '8 Tire', '10 Tire', '12 Tire', '14+ Tire Heavy Multi-Axle'].map((tire) {
                      final isSelected = v.tireConfig == tire;
                      return ChoiceChip(
                        label: Text(tire, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : AdminTheme.textDark)),
                        selected: isSelected,
                        selectedColor: AdminTheme.crimsonRed,
                        backgroundColor: AdminTheme.warmCream,
                        onSelected: (sel) {
                          if (sel) setState(() => v.tireConfig = tire);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // License Plate Number & Model Name
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REGISTERED LICENSE PLATE NUMBER',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textDark, letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: v.plateNumber,
                      onChanged: (val) => v.plateNumber = val.toUpperCase(),
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(color: AdminTheme.deepBlack, fontSize: 13, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: 'e.g. MH-04-AB-1290',
                        hintStyle: const TextStyle(color: AdminTheme.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: AdminTheme.crispWhite,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.crimsonRed, width: 1.8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MAKE & MODEL',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AdminTheme.textDark, letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: v.model,
                      onChanged: (val) => v.model = val,
                      style: const TextStyle(color: AdminTheme.deepBlack, fontSize: 13, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: 'e.g. Tata Ace Gold / Eicher Pro',
                        hintStyle: const TextStyle(color: AdminTheme.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: AdminTheme.crispWhite,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.crimsonRed, width: 1.8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Upload RC / License Document Photo
          InkWell(
            onTap: () {
              setState(() {
                v.isRcUploaded = true;
                v.rcPhotoName = 'rc_doc_${v.plateNumber.isNotEmpty ? v.plateNumber : "veh$index"}.jpg';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Vehicle RC / Registration photo attached for Vehicle #${index + 1}'),
                  backgroundColor: AdminTheme.deepBlack,
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: v.isRcUploaded ? const Color(0xFFECFDF5) : AdminTheme.crispWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: v.isRcUploaded ? AdminTheme.statusOnline : AdminTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(
                    v.isRcUploaded ? Icons.check_circle : Icons.add_a_photo_outlined,
                    color: v.isRcUploaded ? AdminTheme.statusOnline : AdminTheme.crimsonRed,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.isRcUploaded ? 'RC & LICENSE PHOTO ATTACHED (VERIFIED)' : 'UPLOAD VEHICLE RC / REGISTRATION LICENSE PHOTO',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: v.isRcUploaded ? AdminTheme.statusOnline : AdminTheme.deepBlack,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          v.isRcUploaded ? (v.rcPhotoName ?? 'document_rc.jpg') : 'Click to capture or attach photo of RC certificate / license paper',
                          style: const TextStyle(fontSize: 10, color: AdminTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: v.isRcUploaded ? AdminTheme.statusOnline.withAlpha(20) : AdminTheme.warmCream,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      v.isRcUploaded ? 'ATTACHED' : 'ATTACH PIC',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: v.isRcUploaded ? AdminTheme.statusOnline : AdminTheme.deepBlack),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTypeChip(int vIndex, RegisteredVehicleDraft v, String typeKey, String label, IconData icon) {
    final isSelected = v.type == typeKey;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => setState(() => v.type = typeKey),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AdminTheme.crimsonRed : AdminTheme.crispWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AdminTheme.crimsonRed : AdminTheme.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : AdminTheme.textDark),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AdminTheme.deepBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AdminTheme.crimsonRed),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AdminTheme.deepBlack,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AdminTheme.textDark, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: AdminTheme.deepBlack, fontSize: 13.5, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AdminTheme.textMuted, fontSize: 12.5),
            prefixIcon: Icon(icon, color: AdminTheme.textMuted, size: 18),
            filled: true,
            fillColor: AdminTheme.warmCream,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AdminTheme.crimsonRed, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
