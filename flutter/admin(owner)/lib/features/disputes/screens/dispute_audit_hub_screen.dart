import 'package:flutter/material.dart';
import '../../../core/models/dispute_model.dart';
import '../../../core/models/audit_log_model.dart';
import '../../../core/network/admin_api_client.dart';
import '../../../core/theme/admin_theme.dart';

class DisputeAuditHubScreen extends StatefulWidget {
  const DisputeAuditHubScreen({super.key});

  @override
  State<DisputeAuditHubScreen> createState() => _DisputeAuditHubScreenState();
}

class _DisputeAuditHubScreenState extends State<DisputeAuditHubScreen> {
  int _activeTab = 0; // 0: Disputes, 1: System Audit Logs

  List<DisputeModel> _disputes = [];
  List<AuditLogModel> _auditLogs = [];
  bool _isLoading = true;

  String _disputeFilter = 'All'; // 'All', 'Open / Investigating', 'Resolved'
  String _auditFilter = 'All'; // 'All', 'Overrides', 'KYC Approvals', 'Refunds', 'Security Alerts'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final disputesFuture = AdminApiClient().fetchDisputes();
    final logsFuture = AdminApiClient().fetchAuditLogs();

    final results = await Future.wait([disputesFuture, logsFuture]);

    if (mounted) {
      setState(() {
        _disputes = results[0] as List<DisputeModel>;
        _auditLogs = results[1] as List<AuditLogModel>;
        _isLoading = false;
      });
    }
  }

  List<DisputeModel> get _filteredDisputes {
    return _disputes.where((d) {
      if (_disputeFilter == 'Open / Investigating' && d.status == 'resolved') return false;
      if (_disputeFilter == 'Resolved' && d.status != 'resolved') return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return d.orderCode.toLowerCase().contains(q) ||
            d.customerName.toLowerCase().contains(q) ||
            d.driverName.toLowerCase().contains(q) ||
            d.customerComplaint.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  List<AuditLogModel> get _filteredAuditLogs {
    return _auditLogs.where((log) {
      if (_auditFilter == 'Overrides' && !log.actionType.contains('OVERRIDE')) return false;
      if (_auditFilter == 'KYC Approvals' && !log.actionType.contains('KYC')) return false;
      if (_auditFilter == 'Refunds' && !log.actionType.contains('REFUND')) return false;
      if (_auditFilter == 'Security Alerts' && !log.actionType.contains('ALERT') && !log.actionType.contains('BREACH')) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return log.actionType.toLowerCase().contains(q) ||
            log.adminUser.toLowerCase().contains(q) ||
            log.targetEntity.toLowerCase().contains(q) ||
            log.details.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  Future<void> _resolveDispute(DisputeModel dispute, String action, String notes) async {
    final success = await AdminApiClient().resolveDispute(dispute.id, action, notes);
    if (success && mounted) {
      setState(() {
        final index = _disputes.indexWhere((d) => d.id == dispute.id);
        if (index != -1) {
          _disputes[index] = dispute.copyWith(status: 'resolved');
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dispute ${dispute.id} (${dispute.orderCode}) resolved: $action'),
          backgroundColor: AdminTheme.statusOnline,
        ),
      );
    }
  }

  void _showRefundDialog(DisputeModel dispute) {
    final amountController = TextEditingController(text: dispute.refundAmount.toStringAsFixed(0));
    final notesController = TextEditingController(text: 'Approved concession credit for SLA transit delay.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.sidebarBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AdminTheme.borderBlack)),
        title: Row(
          children: [
            const Icon(Icons.currency_rupee, color: AdminTheme.statusOnline, size: 22),
            const SizedBox(width: 8),
            Text('Issue Refund: #${dispute.orderCode}', style: const TextStyle(color: AdminTheme.crispWhite, fontSize: 16, fontWeight: FontWeight.w900)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Client: ${dispute.customerName} • ${dispute.customerPhone}', style: const TextStyle(color: AdminTheme.textLight, fontSize: 12)),
              const SizedBox(height: 14),
              const Text('REFUND AMOUNT (INR)', style: TextStyle(color: AdminTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AdminTheme.crispWhite, fontWeight: FontWeight.w900, fontSize: 16),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(color: AdminTheme.crimsonRed, fontWeight: FontWeight.w900),
                  filled: true,
                  fillColor: AdminTheme.surfaceBlack,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderBlack)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('AUDITOR RESOLUTION NOTES', style: TextStyle(color: AdminTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              TextField(
                controller: notesController,
                maxLines: 2,
                style: const TextStyle(color: AdminTheme.crispWhite, fontSize: 12),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AdminTheme.surfaceBlack,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminTheme.borderBlack)),
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
              Navigator.pop(ctx);
              _resolveDispute(dispute, 'Refund Issued (₹${amountController.text} INR)', notesController.text);
            },
            child: const Text('PROCESS REFUND', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final openDisputesCount = _disputes.where((d) => d.status != 'resolved').length;

    return Container(
      color: AdminTheme.canvasBg,
      child: Column(
        children: [
          // Header Bar with Primary Module Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
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
                              'Dispute & System Audit Hub',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (openDisputesCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AdminTheme.crimsonTint,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AdminTheme.crimsonRed),
                              ),
                              child: Text(
                                '$openDisputesCount ACTIVE DISPUTES',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AdminTheme.crimsonRed),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Customer rating disputes, consignment damage claims, carrier defenses, and immutable system intervention logs.',
                        style: TextStyle(fontSize: 12, color: AdminTheme.textMuted),
                      ),
                    ],
                  ),
                ),

                // Primary Hub View Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AdminTheme.canvasBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AdminTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      _buildHubTabButton(0, 'Customer Disputes', Icons.gavel_outlined, Icons.gavel),
                      const SizedBox(width: 4),
                      _buildHubTabButton(1, 'System Audit Logs', Icons.history_edu_outlined, Icons.history_edu),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search & Secondary Filter Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: AdminTheme.crispWhite,
            child: Row(
              children: [
                // Secondary filter options based on active tab
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_activeTab == 0) ...[
                          ...['All', 'Open / Investigating', 'Resolved'].map((filter) {
                            final isSel = _disputeFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () => setState(() => _disputeFilter = filter),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                          }),
                        ] else ...[
                          ...['All', 'Overrides', 'KYC Approvals', 'Refunds', 'Security Alerts'].map((filter) {
                            final isSel = _auditFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () => setState(() => _auditFilter = filter),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                          }),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Search Bar
                SizedBox(
                  width: 280,
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: _activeTab == 0 ? 'Search dispute, order, customer...' : 'Search action, actor, target entity...',
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

          // Body View (Disputes vs Audit Logs)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.crimsonRed))
                : _activeTab == 0
                    ? _buildDisputesView()
                    : _buildAuditLogsView(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 0: CUSTOMER DISPUTES VIEW
  // ==========================================
  Widget _buildDisputesView() {
    final filtered = _filteredDisputes;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 48, color: AdminTheme.statusOnline),
            const SizedBox(height: 12),
            const Text('No customer disputes matching the current criteria.', style: TextStyle(fontWeight: FontWeight.w800, color: AdminTheme.textDark)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final d = filtered[index];
        return _buildDisputeCard(d);
      },
    );
  }

  Widget _buildDisputeCard(DisputeModel d) {
    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.crispWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dispute Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: AdminTheme.canvasBg,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: AdminTheme.borderSubtle)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AdminTheme.crimsonRed, size: 18),
                  const SizedBox(width: 8),
                  Text('DISPUTE #${d.id} • CONSIGNMENT #${d.orderCode}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AdminTheme.deepBlack)),
                  const SizedBox(width: 14),

                  // Severity Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: d.severityColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: d.severityColor),
                    ),
                    child: Text(
                      '${d.severity.toUpperCase()} PRIORITY',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: d.severityColor),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: d.statusColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: d.statusColor),
                    ),
                    child: Text(
                      d.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: d.statusColor),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating & Category
                      SizedBox(
                        width: 220,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < d.customerRating ? Icons.star : Icons.star_border,
                                  size: 18,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('Issue Type: ${d.typeLabel}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AdminTheme.deepBlack)),
                            const SizedBox(height: 2),
                            Text('Client: ${d.customerName} (${d.customerPhone})', style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted)),
                            Text('Carrier: ${d.driverName} (${d.driverPhone})', style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Customer Complaint Box
                      SizedBox(
                        width: 260,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.rate_review, size: 14, color: AdminTheme.crimsonRed),
                                  SizedBox(width: 6),
                                  Text('CUSTOMER COMPLAINT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AdminTheme.crimsonRed)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('"${d.customerComplaint}"', style: const TextStyle(fontSize: 11.5, color: AdminTheme.deepBlack, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Driver Defense Box
                      SizedBox(
                        width: 280,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AdminTheme.canvasBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AdminTheme.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.security, size: 14, color: AdminTheme.deepBlack),
                                  SizedBox(width: 6),
                                  Text('CARRIER STATEMENT / TELEMATICS DEFENSE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('"${d.driverExplanation}"', style: const TextStyle(fontSize: 11.5, color: AdminTheme.textDark)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AdminTheme.borderSubtle, height: 1),
                const SizedBox(height: 14),

                // Action Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'Filed on: ${d.filedAt.toLocal().toString().split('.').first} • Suggested Concession: ₹${d.refundAmount.toStringAsFixed(0)} INR',
                        style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 16),

                      if (d.status != 'resolved') ...[
                        Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _resolveDispute(d, 'Dismissed with auditor review', 'Customer complaint investigated; carrier GPS telematics vindicated delay.'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AdminTheme.textDark,
                              side: const BorderSide(color: AdminTheme.borderSubtle),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.block, size: 14),
                            label: const Text('Dismiss', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showRefundDialog(d),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminTheme.crimsonRed,
                              foregroundColor: AdminTheme.crispWhite,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.currency_rupee, size: 14),
                            label: const Text('Issue Refund', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: AdminTheme.statusOnline, size: 16),
                          SizedBox(width: 6),
                          Text('RESOLVED & CLOSED', style: TextStyle(color: AdminTheme.statusOnline, fontWeight: FontWeight.w900, fontSize: 11)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  // ==========================================
  // TAB 1: IMMUTABLE SYSTEM AUDIT LOG VIEWER
  // ==========================================
  Widget _buildAuditLogsView() {
    final filtered = _filteredAuditLogs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: AdminTheme.crispWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTheme.borderSubtle, width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 20,
            columnSpacing: 22,
            headingRowColor: MaterialStateProperty.all(AdminTheme.canvasBg),
            headingTextStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AdminTheme.textMuted,
              letterSpacing: 0.6,
            ),
            dataTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminTheme.deepBlack),
            columns: const [
              DataColumn(label: Text('TIMESTAMP & ID')),
              DataColumn(label: Text('ACTOR / USER')),
              DataColumn(label: Text('ACTION EVENT')),
              DataColumn(label: Text('TARGET ENTITY')),
              DataColumn(label: Text('INTERVENTION DETAILS')),
              DataColumn(label: Text('IP / ORIGIN')),
              DataColumn(label: Text('SHA256 AUDIT SEAL')),
            ],
            rows: filtered.map((log) {
              return DataRow(
                cells: [
                  // Timestamp & ID
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(log.id, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                        Text(log.timestamp.toLocal().toString().split('.').first, style: const TextStyle(fontSize: 10.5, color: AdminTheme.textMuted)),
                      ],
                    ),
                  ),

                  // Actor
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: log.adminUser.contains('admin') ? AdminTheme.crimsonRed.withAlpha(20) : AdminTheme.canvasBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: log.adminUser.contains('admin') ? AdminTheme.crimsonRed : AdminTheme.borderSubtle),
                      ),
                      child: Text(
                        log.adminUser,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: log.adminUser.contains('admin') ? AdminTheme.crimsonRed : AdminTheme.deepBlack,
                        ),
                      ),
                    ),
                  ),

                  // Action Event
                  DataCell(
                    Text(log.actionType, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: AdminTheme.deepBlack)),
                  ),

                  // Target Entity
                  DataCell(
                    Text(log.targetEntity, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF2563EB))),
                  ),

                  // Intervention Details
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        log.details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AdminTheme.textDark),
                      ),
                    ),
                  ),

                  // IP
                  DataCell(
                    Text(log.ipAddress, style: const TextStyle(fontSize: 10.5, color: AdminTheme.textMuted)),
                  ),

                  // Security Hash Seal
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 14, color: AdminTheme.statusOnline),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            log.securityHash,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9.5, color: AdminTheme.textMuted, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildHubTabButton(int index, String label, IconData icon, IconData activeIcon) {
    final isSel = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? AdminTheme.deepBlack : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(isSel ? activeIcon : icon, size: 16, color: isSel ? AdminTheme.crispWhite : AdminTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: isSel ? AdminTheme.crispWhite : AdminTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
