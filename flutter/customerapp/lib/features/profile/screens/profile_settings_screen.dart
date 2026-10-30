import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/widgets/terms_conditions_dialog.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final VoidCallback onProfileUpdated;
  const ProfileSettingsScreen({super.key, required this.onProfileUpdated});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _companyController;
  late TextEditingController _gstinController;
  late TextEditingController _addressController;
  late TextEditingController _upiController;
  bool _whatsappAlerts = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ApiClient().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _companyController = TextEditingController(text: user?.companyName ?? 'Apex Commercial Logistics');
    _gstinController = TextEditingController(text: user?.gstin ?? '27AAACA9876Q1Z5');
    _addressController = TextEditingController(
        text: user?.primaryAddress ?? 'Plot 42, Bhiwandi Logistics Corridor, Thane, Maharashtra');
    _upiController = TextEditingController(text: user?.upiId ?? 'ms@okaxis');
    _whatsappAlerts = user?.whatsappAlerts ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _gstinController.dispose();
    _addressController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ApiClient().updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        companyName: _companyController.text.trim(),
        gstin: _gstinController.text.trim(),
        primaryAddress: _addressController.text.trim(),
        upiId: _upiController.text.trim(),
        whatsappAlerts: _whatsappAlerts,
      );

      widget.onProfileUpdated();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: HamhaTheme.statusDelivered,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: HamhaTheme.crispWhite),
              SizedBox(width: 10),
              Text('Shipper profile & business settings updated!'),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: HamhaTheme.crimsonRed,
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiClient().currentUser;
    final initial = (user?.name.isNotEmpty == true ? user!.name[0] : 'S').toUpperCase();

    return Scaffold(
      backgroundColor: HamhaTheme.warmCream,
      appBar: AppBar(
        backgroundColor: HamhaTheme.crispWhite,
        elevation: 0.5,
        title: const Text('Shipper Profile & Business Hub'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Shipper Identification Header Card
                  Card(
                    color: HamhaTheme.crispWhite,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: const BorderSide(color: HamhaTheme.borderSubtle, width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22.0),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: HamhaTheme.deepBlack,
                              border: Border.all(color: HamhaTheme.crimsonRed, width: 2.5),
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: HamhaTheme.crispWhite,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'Shipper',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: HamhaTheme.deepBlack,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _companyController.text.isNotEmpty
                                      ? _companyController.text
                                      : 'Verified Business Account',
                                  style: const TextStyle(fontSize: 13, color: HamhaTheme.textMuted, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: HamhaTheme.deepBlack,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'GST VERIFIED SHIPPER • ACTIVE FLEET ACCESS',
                                    style: TextStyle(
                                      color: HamhaTheme.crispWhite,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
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
                  const SizedBox(height: 18),

                  // 2. Personal & Business Information
                  _buildSectionContainer(
                    title: '1. Personal & Company Information',
                    icon: Icons.business,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: HamhaTheme.textDark, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          labelText: 'Authorized Contact Name',
                          prefixIcon: Icon(Icons.person_outline, color: HamhaTheme.deepBlack),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter contact name' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _companyController,
                        style: const TextStyle(color: HamhaTheme.textDark, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          labelText: 'Registered Business / Entity Name',
                          prefixIcon: Icon(Icons.apartment, color: HamhaTheme.deepBlack),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _gstinController,
                        style: const TextStyle(color: HamhaTheme.textDark, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          labelText: 'GSTIN (Goods and Services Tax ID)',
                          prefixIcon: Icon(Icons.receipt_long, color: HamhaTheme.deepBlack),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: HamhaTheme.textDark, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                labelText: 'Mobile Phone',
                                prefixIcon: Icon(Icons.phone_outlined, color: HamhaTheme.deepBlack),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Enter phone' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: HamhaTheme.textDark, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                labelText: 'Corporate Email',
                                prefixIcon: Icon(Icons.email_outlined, color: HamhaTheme.deepBlack),
                              ),
                              validator: (val) => val == null || !val.contains('@') ? 'Enter email' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 3. Saved Address Book & Dispatch Corridors
                  _buildSectionContainer(
                    title: '2. Default Dispatch Hub & Warehouse Address',
                    icon: Icons.warehouse_outlined,
                    children: [
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        style: const TextStyle(color: HamhaTheme.textDark, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          labelText: 'Primary Pickup Warehouse / Dispatch Center',
                          prefixIcon: Icon(Icons.location_on_outlined, color: HamhaTheme.crimsonRed),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 4. Payment & Indian Freight Billing Preferences (INR & UPI)
                  _buildSectionContainer(
                    title: '3. Payments & Digital Invoicing (INR ₹)',
                    icon: Icons.account_balance_wallet_outlined,
                    children: [
                      TextFormField(
                        controller: _upiController,
                        style: const TextStyle(color: HamhaTheme.textDark, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          labelText: 'Primary Business UPI ID (for instant dispatch refunds)',
                          prefixIcon: Icon(Icons.qr_code, color: HamhaTheme.deepBlack),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        value: _whatsappAlerts,
                        activeColor: HamhaTheme.statusDelivered,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Live WhatsApp Transit Updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: HamhaTheme.deepBlack)),
                        subtitle: const Text('Receive live GPS link & driver details directly on WhatsApp when dispatched', style: TextStyle(fontSize: 12, color: HamhaTheme.textMuted)),
                        onChanged: (val) => setState(() => _whatsappAlerts = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Save Profile Changes Button
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _handleSaveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: HamhaTheme.crispWhite, strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, color: HamhaTheme.crispWhite),
                    label: const Text('SAVE SHIPPER & BUSINESS PREFERENCES'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HamhaTheme.crimsonRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 5. About HAMHA Logistics Platform & Support
                  _buildSectionContainer(
                    title: '4. About HAMHA Logistics & Compliance',
                    icon: Icons.info_outline,
                    children: [
                      _buildInfoRow('Engine Version', 'v2.4.0 (National Enterprise Freight Network)'),
                      _buildInfoRow('Geospatial Engine', 'Mapbox Vector + Neon PostGIS (SRID 4326)'),
                      _buildInfoRow('Currency Standard', 'Indian Rupee (INR ₹) with 18% Freight GST'),
                      _buildInfoRow('24/7 Operations Hotline', '+91 (800) 555-HAMHA'),
                      _buildInfoRow('Official Grievance Desk', 'support@hamhalogistics.in'),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => TermsConditionsDialog.show(context),
                        icon: const Icon(Icons.gavel_outlined, color: HamhaTheme.deepBlack, size: 18),
                        label: const Text(
                          'VIEW COMMERCIAL CARRIAGE TERMS & CARGO POLICY',
                          style: TextStyle(color: HamhaTheme.deepBlack, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: HamhaTheme.borderSubtle, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Sign Out Button
                  OutlinedButton.icon(
                    onPressed: () {
                      ApiClient().clearToken();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: HamhaTheme.crimsonRed),
                    label: const Text(
                      'SIGN OUT FROM ACCOUNT',
                      style: TextStyle(color: HamhaTheme.crimsonRed, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: HamhaTheme.crimsonRed, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      color: HamhaTheme.crispWhite,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: HamhaTheme.borderSubtle, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: HamhaTheme.deepBlack, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: HamhaTheme.deepBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: HamhaTheme.borderSubtle),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: HamhaTheme.textMuted, fontSize: 13)),
          Text(value, style: const TextStyle(color: HamhaTheme.deepBlack, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
