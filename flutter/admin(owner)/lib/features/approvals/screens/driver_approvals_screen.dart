import 'package:flutter/material.dart';
import '../../../core/models/driver_applicant_model.dart';
import '../../../core/network/admin_api_client.dart';
import '../../../core/theme/admin_theme.dart';

class DriverApprovalsScreen extends StatefulWidget {
  const DriverApprovalsScreen({super.key});

  @override
  State<DriverApprovalsScreen> createState() => _DriverApprovalsScreenState();
}

class _DriverApprovalsScreenState extends State<DriverApprovalsScreen> {
  List<DriverApplicantModel> _applications = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // 'All', 'Pending Review', 'Verified', 'Rejected'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    final data = await AdminApiClient().fetchDriverApplications();
    if (mounted) {
      setState(() {
        _applications = data;
        _isLoading = false;
      });
    }
  }

  List<DriverApplicantModel> get _filteredApplications {
    return _applications.where((app) {
      if (_selectedFilter == 'Pending Review' && app.status != ApplicantStatus.pending) return false;
      if (_selectedFilter == 'Verified' && app.status != ApplicantStatus.approved) return false;
      if (_selectedFilter == 'Rejected' && app.status != ApplicantStatus.rejected) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = app.name.toLowerCase().contains(q);
        final matchesPhone = app.phone.toLowerCase().contains(q);
        final matchesLicense = app.licenseNumber.toLowerCase().contains(q);
        final matchesPlate = app.plateNumber.toLowerCase().contains(q);
        return matchesName || matchesPhone || matchesLicense || matchesPlate;
      }

      return true;
    }).toList();
  }

  Future<void> _handleApprove(DriverApplicantModel app) async {
    final success = await AdminApiClient().approveDriverApplication(app.id);
    if (success && mounted) {
      setState(() {
        final index = _applications.indexWhere((a) => a.id == app.id);
        if (index != -1) {
          _applications[index] = app.copyWith(isVerified: true, rejectionReason: null);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Carrier verified! ${app.name} has been officially approved.'),
          backgroundColor: AdminTheme.statusOnline,
        ),
      );
    }
  }

  Future<void> _handleReject(DriverApplicantModel app, String reason) async {
    final success = await AdminApiClient().rejectDriverApplication(app.id, reason);
    if (success && mounted) {
      setState(() {
        final index = _applications.indexWhere((a) => a.id == app.id);
        if (index != -1) {
          _applications[index] = app.copyWith(isVerified: false, rejectionReason: reason);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application rejected for ${app.name}. Reason: $reason'),
          backgroundColor: AdminTheme.crimsonRed,
        ),
      );
    }
  }

  void _showDocumentViewer(DriverApplicantModel app) {
    showDialog(
      context: context,
      builder: (ctx) => _DriverDocumentModalViewer(
        applicant: app,
        onApprove: () {
          Navigator.pop(ctx);
          _handleApprove(app);
        },
        onReject: (reason) {
          Navigator.pop(ctx);
          _handleReject(app, reason);
        },
      ),
    );
  }

  void _showRejectDialog(DriverApplicantModel app) {
    final reasonController = TextEditingController();
    String selectedPreset = 'Expired Commercial Driver License (CDL)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AdminTheme.crispWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AdminTheme.borderSubtle)),
          title: Row(
            children: [
              const Icon(Icons.gpp_bad, color: AdminTheme.crimsonRed, size: 22),
              const SizedBox(width: 8),
              const Text('Reject Driver Application', style: TextStyle(color: AdminTheme.deepBlack, fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Specify the statutory reason for rejecting ${app.name}\'s application (${app.licenseNumber}):',
                  style: const TextStyle(color: AdminTheme.textDark, fontSize: 12),
                ),
                const SizedBox(height: 14),
                const Text('SELECT REJECTION REASON', style: TextStyle(color: AdminTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedPreset,
                  dropdownColor: AdminTheme.crispWhite,
                  style: const TextStyle(color: AdminTheme.deepBlack, fontSize: 12, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AdminTheme.warmCream,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Expired Commercial Driver License (CDL)', child: Text('Expired Commercial Driver License (CDL)')),
                    DropdownMenuItem(value: 'Blurred or Unreadable RC Document Photo', child: Text('Blurred or Unreadable RC Document Photo')),
                    DropdownMenuItem(value: 'Commercial Goods Insurance Expired', child: Text('Commercial Goods Insurance Expired')),
                    DropdownMenuItem(value: 'Vehicle Fitness Certificate Non-Compliant', child: Text('Vehicle Fitness Certificate Non-Compliant')),
                    DropdownMenuItem(value: 'Name on Identity Card does not match Vehicle RC', child: Text('Name on ID does not match RC')),
                    DropdownMenuItem(value: 'Other Reason (Specify Below)', child: Text('Other Reason (Specify Below)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedPreset = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  style: const TextStyle(color: AdminTheme.deepBlack, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Additional auditor notes or specific missing document details...',
                    hintStyle: const TextStyle(color: AdminTheme.textMuted, fontSize: 11),
                    filled: true,
                    fillColor: AdminTheme.warmCream,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: AdminTheme.textMuted, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.crimsonRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final reason = reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : selectedPreset;
                Navigator.pop(ctx);
                _handleReject(app, reason);
              },
              child: const Text('CONFIRM REJECTION', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredApplications;
    final pendingCount = _applications.where((a) => a.status == ApplicantStatus.pending).length;

    return Container(
      color: AdminTheme.canvasBg,
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: AdminTheme.crispWhite,
              border: Border(bottom: BorderSide(color: AdminTheme.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Carrier Onboarding Approval Desk',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (pendingCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF59E0B)),
                              ),
                              child: Text(
                                '$pendingCount PENDING REVIEW',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Statutory verification for CDL licenses, vehicle registrations (RC), and commercial carriage policies.',
                        style: TextStyle(fontSize: 12, color: AdminTheme.textMuted),
                      ),
                    ],
                  ),
                ),

                // Refresh Button
                OutlinedButton.icon(
                  onPressed: _loadApplications,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.deepBlack,
                    side: const BorderSide(color: AdminTheme.borderSubtle),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Filters & Search Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            color: AdminTheme.crispWhite,
            child: Row(
              children: [
                // Filter Tabs
                Row(
                  children: ['All', 'Pending Review', 'Verified', 'Rejected'].map((filter) {
                    final isSel = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedFilter = filter),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AdminTheme.deepBlack : AdminTheme.canvasBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSel ? AdminTheme.deepBlack : AdminTheme.borderSubtle),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: isSel ? AdminTheme.crispWhite : AdminTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const Spacer(),

                // Search Bar
                SizedBox(
                  width: 320,
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Search applicant, license, phone...',
                      hintStyle: const TextStyle(fontSize: 11.5, color: AdminTheme.textMuted),
                      prefixIcon: const Icon(Icons.search, size: 16, color: AdminTheme.textMuted),
                      filled: true,
                      fillColor: AdminTheme.canvasBg,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderSubtle)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AdminTheme.borderSubtle),

          // Applications Grid / Table View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.crimsonRed))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_shared_outlined, size: 48, color: AdminTheme.textMuted),
                            const SizedBox(height: 12),
                            const Text('No driver applications match the criteria.', style: TextStyle(fontWeight: FontWeight.w800, color: AdminTheme.textDark)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final app = filtered[index];
                          return _buildApplicantCard(app);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantCard(DriverApplicantModel app) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminTheme.crispWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Applicant Avatar & Status Pip
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AdminTheme.warmCream,
                shape: BoxShape.circle,
                border: Border.all(color: app.statusColor, width: 2),
              ),
              child: Center(
                child: Text(
                  app.name.split(' ').map((n) => n[0]).take(2).join(),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.deepBlack, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Driver Primary Details
            SizedBox(
              width: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          app.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: app.statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: app.statusColor),
                        ),
                        child: Text(
                          app.statusLabel,
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: app.statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${app.phone} • ${app.email}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AdminTheme.textMuted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 13, color: AdminTheme.textDark),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'CDL: ${app.licenseNumber}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AdminTheme.textDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Vehicle Specs
            SizedBox(
              width: 240,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${app.vehicleModel} (${app.vehicleType.toUpperCase()})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AdminTheme.deepBlack),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Plate: ${app.plateNumber} • Payload: ${app.maxWeightKg.toInt()} kg',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: AdminTheme.textMuted, fontWeight: FontWeight.w600),
                  ),
                  if (app.rejectionReason != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Rejection: ${app.rejectionReason}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: AdminTheme.crimsonRed, fontWeight: FontWeight.w800),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Action Buttons: View Docs, Approve, Reject
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showDocumentViewer(app),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.deepBlack,
                    side: const BorderSide(color: AdminTheme.borderSubtle, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.document_scanner, size: 16),
                  label: const Text('Inspect Docs', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),

                if (app.status == ApplicantStatus.pending) ...[
                  ElevatedButton(
                    onPressed: () => _handleApprove(app),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.statusOnline,
                      foregroundColor: AdminTheme.crispWhite,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Approve', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _showRejectDialog(app),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.crimsonRed,
                      foregroundColor: AdminTheme.crispWhite,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PHOTO MODAL VIEWER FOR CDL, RC & INSURANCE
// ==========================================
class _DriverDocumentModalViewer extends StatefulWidget {
  final DriverApplicantModel applicant;
  final VoidCallback onApprove;
  final Function(String reason) onReject;

  const _DriverDocumentModalViewer({
    required this.applicant,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_DriverDocumentModalViewer> createState() => _DriverDocumentModalViewerState();
}

class _DriverDocumentModalViewerState extends State<_DriverDocumentModalViewer> {
  int _activeDocTab = 0; // 0: License, 1: Registration, 2: Insurance

  @override
  Widget build(BuildContext context) {
    final app = widget.applicant;
    final docTitles = ['Driver License (CDL)', 'Vehicle Registration (RC)', 'Commercial Insurance'];
    final docNumbers = [app.licenseNumber, app.plateNumber, 'POL-COMM-2024-883'];

    return Dialog(
      backgroundColor: AdminTheme.crispWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AdminTheme.borderSubtle)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminTheme.borderSubtle)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: AdminTheme.crimsonRed, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KYC Document Verification: ${app.name}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack),
                        ),
                        Text(
                          '${app.phone} • Vehicle: ${app.vehicleModel} (${app.plateNumber})',
                          style: const TextStyle(fontSize: 12, color: AdminTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AdminTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Document Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: AdminTheme.warmCream,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDocTab(0, '1. Driver License (CDL)'),
                    const SizedBox(width: 8),
                    _buildDocTab(1, '2. Registration (RC)'),
                    const SizedBox(width: 8),
                    _buildDocTab(2, '3. Insurance Policy'),
                  ],
                ),
              ),
            ),

            // Document Viewer Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left: High-Resolution Photo Preview Canvas
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AdminTheme.warmCream,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AdminTheme.borderSubtle),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Simulated Document Canvas
                            Container(
                              color: AdminTheme.deepBlack,
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _activeDocTab == 0
                                        ? Icons.badge
                                        : _activeDocTab == 1
                                            ? Icons.directions_car
                                            : Icons.security,
                                    size: 64,
                                    color: AdminTheme.crimsonRed,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    docTitles[_activeDocTab].toUpperCase(),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AdminTheme.crispWhite),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'CERTIFICATE REF: ${docNumbers[_activeDocTab]}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminTheme.crimsonLight),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AdminTheme.statusOnline.withAlpha(30),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'ORIGINAL OCR SCANNED & CRYPTOGRAPHICALLY HASHED',
                                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AdminTheme.statusOnline),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Watermark Overlay
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(200),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'HAMHA SECURITY AUDIT',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AdminTheme.textMuted),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Right: Statutory Verification Checklist
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AdminTheme.warmCream,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AdminTheme.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STATUTORY COMPLIANCE AUDIT',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AdminTheme.textMuted, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 14),
                            _buildChecklistRow('Full Legal Name Match', 'Applicant name matches CDL and Aadhaar/PAN records.'),
                            _buildChecklistRow('Active Commercial Endorsement', 'Valid heavy transport/goods commercial badge active.'),
                            _buildChecklistRow('Vehicle Fitness Valid', 'Emission, fitness and chassis verification cleared.'),
                            _buildChecklistRow('Third-Party Goods Transit Cover', 'Active insurance cover up to ₹10,00,000 INR.'),
                            const Spacer(),

                            // Quick Reject / Approve from viewer
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => widget.onReject('Document failed compliance review'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AdminTheme.crimsonRed,
                                      side: const BorderSide(color: AdminTheme.crimsonRed),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: widget.onApprove,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AdminTheme.statusOnline,
                                      foregroundColor: AdminTheme.crispWhite,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocTab(int index, String label) {
    final isSel = _activeDocTab == index;
    return InkWell(
      onTap: () => setState(() => _activeDocTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AdminTheme.crimsonRed : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: isSel ? AdminTheme.crispWhite : AdminTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistRow(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: AdminTheme.statusOnline),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AdminTheme.deepBlack)),
                Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AdminTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
