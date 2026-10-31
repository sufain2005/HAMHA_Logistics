import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../auth/screens/login_screen.dart';

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
  late TextEditingController _addressController;
  late TextEditingController _upiController;
  String _selectedPaymentMethod = 'Cash to Pickup Pilot (Cash on Dispatch)';
  bool _whatsappAlerts = true;
  bool _isSaving = false;
  String? _avatarUrl;

  final List<String> _avatarPresets = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80',
  ];

  @override
  void initState() {
    super.initState();
    final user = ApiClient().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(
        text: user?.primaryAddress ?? 'Plot 42, Bhiwandi Logistics Corridor, Thane, Maharashtra');
    _upiController = TextEditingController(text: user?.upiId ?? 'ms@okaxis');
    _whatsappAlerts = user?.whatsappAlerts ?? true;
    _avatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _showAvatarPickerSheet() {
    final customUrlController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: HamhaTheme.crispWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Profile Picture',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: HamhaTheme.deepBlack,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: HamhaTheme.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a profile avatar preset or paste an image URL. It will be saved securely to the database.',
                style: TextStyle(fontSize: 12, color: HamhaTheme.textMuted),
              ),
              const SizedBox(height: 16),

              // Avatar Presets Grid
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _avatarPresets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final url = _avatarPresets[i];
                    final isSelected = _avatarUrl == url;
                    return InkWell(
                      onTap: () {
                        setState(() => _avatarUrl = url);
                        Navigator.pop(ctx);
                        _persistAvatar(url);
                      },
                      borderRadius: BorderRadius.circular(36),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? HamhaTheme.crimsonRed : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(url),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Custom Image URL Input
              TextFormField(
                controller: customUrlController,
                decoration: InputDecoration(
                  labelText: 'Custom Photo URL (HTTPS)',
                  hintText: 'https://example.com/my-photo.jpg',
                  prefixIcon: const Icon(Icons.link, color: HamhaTheme.deepBlack),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_circle, color: HamhaTheme.crimsonRed),
                    onPressed: () {
                      final url = customUrlController.text.trim();
                      if (url.isNotEmpty && url.startsWith('http')) {
                        setState(() => _avatarUrl = url);
                        Navigator.pop(ctx);
                        _persistAvatar(url);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _persistAvatar(String url) async {
    try {
      await ApiClient().updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        avatarUrl: url,
        primaryAddress: _addressController.text.trim(),
        upiId: _upiController.text.trim(),
        whatsappAlerts: _whatsappAlerts,
      );
      widget.onProfileUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: HamhaTheme.statusDelivered,
            content: Text('Profile picture updated and saved to database!'),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ApiClient().updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        avatarUrl: _avatarUrl,
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
                  // 1. Shipper Identification Header Card with Avatar Editor
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
                          Stack(
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: HamhaTheme.deepBlack,
                                  border: Border.all(color: HamhaTheme.crimsonRed, width: 2.5),
                                  image: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(_avatarUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                                    ? Center(
                                        child: Text(
                                          initial,
                                          style: const TextStyle(
                                            color: HamhaTheme.crispWhite,
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: InkWell(
                                  onTap: _showAvatarPickerSheet,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: HamhaTheme.crimsonRed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.isNotEmpty ? _nameController.text : (user?.name ?? 'Shipper'),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: HamhaTheme.deepBlack,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Registered Customer Account • Priority Dispatch',
                                  style: TextStyle(fontSize: 12, color: HamhaTheme.textMuted, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: HamhaTheme.deepBlack,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'VERIFIED SHIPPER • ACTIVE FLEET ACCESS',
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

                  // 2. Personal Information (No GSTIN or Company Name required for customer)
                  _buildSectionContainer(
                    title: '1. Personal Information',
                    icon: Icons.person_outline,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: HamhaTheme.textDark, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'e.g. Alex Mercer',
                          prefixIcon: Icon(Icons.person_outline, color: HamhaTheme.deepBlack),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
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
                                labelText: 'Email Address',
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

                  // 4. Payment Preferences: Cash, Direct QR to Pilot, or Online
                  _buildSectionContainer(
                    title: '3. Payments & Digital Invoicing (INR ₹)',
                    icon: Icons.account_balance_wallet_outlined,
                    children: [
                      const Text(
                        'PREFERRED PAYMENT MODE AT DISPATCH',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: HamhaTheme.textMuted, letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 8),

                      // Option 1: Cash to Pickup Pilot
                      _buildPaymentOptionTile(
                        title: 'Cash to Pickup Pilot',
                        subtitle: 'Pay physical cash to the dispatch pilot upon consignment collection',
                        icon: Icons.payments_outlined,
                        value: 'Cash to Pickup Pilot (Cash on Dispatch)',
                      ),
                      const SizedBox(height: 8),

                      // Option 2: Direct QR Code to Pickup Pilot
                      _buildPaymentOptionTile(
                        title: 'Direct Driver UPI QR Code',
                        subtitle: 'Scan pilot\'s live UPI QR code directly on their mobile during pickup',
                        icon: Icons.qr_code_scanner,
                        value: 'Direct Driver UPI QR Code (Scan Pilot QR)',
                      ),
                      const SizedBox(height: 8),

                      // Option 3: Online UPI / Net Banking
                      _buildPaymentOptionTile(
                        title: 'Online UPI / Net Banking',
                        subtitle: 'Instant digital invoice settlement via verified payment gateway',
                        icon: Icons.account_balance,
                        value: 'Online UPI / Corporate Net Banking',
                      ),
                      const SizedBox(height: 16),

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

                  // 5. Clean About Company (Name & Version only as requested)
                  _buildSectionContainer(
                    title: '4. About HAMHA Logistics',
                    icon: Icons.info_outline,
                    children: [
                      _buildInfoRow('Company Name', 'HAMHA Logistics Pvt. Ltd.'),
                      _buildInfoRow('App Version', 'v2.4.0'),
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

  Widget _buildPaymentOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? HamhaTheme.crimsonRed.withAlpha(15) : HamhaTheme.warmCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? HamhaTheme.crimsonRed : HamhaTheme.borderSubtle,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? HamhaTheme.crimsonRed : HamhaTheme.deepBlack,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? HamhaTheme.crimsonRed : HamhaTheme.deepBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: HamhaTheme.textMuted),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              activeColor: HamhaTheme.crimsonRed,
              onChanged: (val) {
                if (val != null) setState(() => _selectedPaymentMethod = val);
              },
            ),
          ],
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
