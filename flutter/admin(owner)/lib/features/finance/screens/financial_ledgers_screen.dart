import 'package:flutter/material.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/network/admin_api_client.dart';
import '../../../core/theme/admin_theme.dart';

class FinancialLedgersScreen extends StatefulWidget {
  const FinancialLedgersScreen({super.key});

  @override
  State<FinancialLedgersScreen> createState() => _FinancialLedgersScreenState();
}

class _FinancialLedgersScreenState extends State<FinancialLedgersScreen> {
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // 'All', 'Paid', 'Pending', 'Refunded'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final data = await AdminApiClient().fetchTransactions();
    if (mounted) {
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    }
  }

  List<TransactionModel> get _filteredTransactions {
    return _transactions.where((t) {
      if (_selectedFilter == 'Paid' && t.paymentStatus.toLowerCase() != 'paid') return false;
      if (_selectedFilter == 'Pending' && t.paymentStatus.toLowerCase() != 'pending') return false;
      if (_selectedFilter == 'Refunded' && t.paymentStatus.toLowerCase() != 'refunded') return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesInv = t.invoiceNumber.toLowerCase().contains(q);
        final matchesTxn = t.id.toLowerCase().contains(q);
        final matchesOrder = t.orderCode.toLowerCase().contains(q);
        final matchesCustomer = t.customerName.toLowerCase().contains(q);
        final matchesCarrier = t.carrierName.toLowerCase().contains(q);
        return matchesInv || matchesTxn || matchesOrder || matchesCustomer || matchesCarrier;
      }

      return true;
    }).toList();
  }

  void _showPdfInvoiceModal(TransactionModel txn) {
    showDialog(
      context: context,
      builder: (ctx) => _CustomPdfInvoiceModal(transaction: txn),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;
    final totalGross = _transactions.fold<double>(0.0, (sum, t) => sum + t.grossAmount);
    final totalCommissions = _transactions.fold<double>(0.0, (sum, t) => sum + t.platformCommission);
    final totalPayouts = _transactions.fold<double>(0.0, (sum, t) => sum + t.carrierPayout);
    final totalGst = _transactions.fold<double>(0.0, (sum, t) => sum + t.gstTax);

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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Financial Transactions & Invoices Ledger',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Statutory GST accounting, 15% platform commissions, carrier settlements, and automated invoice generation.',
                        style: TextStyle(fontSize: 12, color: AdminTheme.textMuted),
                      ),
                    ],
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: _loadTransactions,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminTheme.deepBlack,
                    side: const BorderSide(color: AdminTheme.borderSubtle),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh Ledger', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Operational Financial KPI Metrics Cards
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: AdminTheme.crispWhite,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildKpiCard('GROSS FREIGHT REVENUE', '₹${totalGross.toStringAsFixed(0)} INR', Icons.account_balance_wallet, AdminTheme.deepBlack),
                  const SizedBox(width: 14),
                  _buildKpiCard('PLATFORM COMMISSION (15%)', '₹${totalCommissions.toStringAsFixed(0)} INR', Icons.pie_chart, AdminTheme.crimsonRed),
                  const SizedBox(width: 14),
                  _buildKpiCard('CARRIER PAYOUTS (85%)', '₹${totalPayouts.toStringAsFixed(0)} INR', Icons.local_shipping, AdminTheme.statusOnline),
                  const SizedBox(width: 14),
                  _buildKpiCard('STATUTORY GST COLLECTED (18%)', '₹${totalGst.toStringAsFixed(1)} INR', Icons.receipt_long, const Color(0xFF2563EB)),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: AdminTheme.borderSubtle),

          // Filter & Search Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: AdminTheme.crispWhite,
            child: Row(
              children: [
                Row(
                  children: ['All', 'Paid', 'Pending', 'Refunded'].map((filter) {
                    final isSel = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedFilter = filter),
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
                  }).toList(),
                ),

                const Spacer(),

                SizedBox(
                  width: 320,
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Search invoice, txn, customer, order...',
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

          // Transactions Ledger Data Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.crimsonRed))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_outlined, size: 48, color: AdminTheme.textMuted),
                            const SizedBox(height: 12),
                            const Text('No transactions match the criteria.', style: TextStyle(fontWeight: FontWeight.w800, color: AdminTheme.textDark)),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AdminTheme.crispWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AdminTheme.borderSubtle, width: 1.2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4)),
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
                              dataTextStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminTheme.deepBlack),
                              columns: const [
                                DataColumn(label: Text('INVOICE & TXN')),
                                DataColumn(label: Text('CONSIGNMENT')),
                                DataColumn(label: Text('CLIENT / CUSTOMER')),
                                DataColumn(label: Text('GROSS FARE (INR)')),
                                DataColumn(label: Text('PLATFORM FEE (15%)')),
                                DataColumn(label: Text('CARRIER PAYOUT (85%)')),
                                DataColumn(label: Text('STATUS')),
                                DataColumn(label: Text('PAYMENT METHOD')),
                                DataColumn(label: Text('ACTIONS')),
                              ],
                              rows: filtered.map((txn) {
                                return DataRow(
                                  cells: [
                                    // Invoice & Txn
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(txn.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                                          Text(txn.id, style: const TextStyle(fontSize: 10.5, color: AdminTheme.textMuted)),
                                        ],
                                      ),
                                    ),

                                    // Consignment
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.qr_code, size: 14, color: AdminTheme.crimsonRed),
                                          const SizedBox(width: 6),
                                          Text('#${txn.orderCode}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    ),

                                    // Client
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(txn.customerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                          Text(txn.customerEmail, style: const TextStyle(color: AdminTheme.textMuted, fontSize: 10.5)),
                                        ],
                                      ),
                                    ),

                                    // Gross
                                    DataCell(
                                      Text(
                                        '₹${txn.grossAmount.toStringAsFixed(0)} INR',
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.deepBlack, fontSize: 13),
                                      ),
                                    ),

                                    // Commission 15%
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('₹${txn.platformCommission.toStringAsFixed(0)} INR', style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.crimsonRed)),
                                          Text('+ GST: ₹${txn.gstTax.toStringAsFixed(1)}', style: const TextStyle(fontSize: 9.5, color: AdminTheme.textMuted)),
                                        ],
                                      ),
                                    ),

                                    // Carrier Payout 85%
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('₹${txn.carrierPayout.toStringAsFixed(0)} INR', style: const TextStyle(fontWeight: FontWeight.w900, color: AdminTheme.statusOnline)),
                                          Text('To: ${txn.carrierName}', style: const TextStyle(fontSize: 9.5, color: AdminTheme.textMuted)),
                                        ],
                                      ),
                                    ),

                                    // Status Pill
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: txn.statusColor.withAlpha(25),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: txn.statusColor),
                                        ),
                                        child: Text(
                                          txn.paymentStatus.toUpperCase(),
                                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: txn.statusColor),
                                        ),
                                      ),
                                    ),

                                    // Payment Method
                                    DataCell(
                                      Text(txn.paymentMethod, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),

                                    // Action: Download PDF Invoice
                                    DataCell(
                                      ElevatedButton.icon(
                                        onPressed: () => _showPdfInvoiceModal(txn),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AdminTheme.crimsonRed,
                                          foregroundColor: AdminTheme.crispWhite,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.picture_as_pdf, size: 14),
                                        label: const Text('Download Invoice', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.canvasBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminTheme.borderSubtle, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: AdminTheme.textMuted, letterSpacing: 0.6),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CUSTOM PDF INVOICE GENERATOR MODAL
// ==========================================
class _CustomPdfInvoiceModal extends StatelessWidget {
  final TransactionModel transaction;

  const _CustomPdfInvoiceModal({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final txn = transaction;

    return Dialog(
      backgroundColor: AdminTheme.crispWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AdminTheme.deepBlack,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_shipping, color: AdminTheme.crimsonRed, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HAMHA LOGISTICS INDIA PVT LTD',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack),
                              ),
                              Text(
                                'GSTIN: 27AAACH2024H1Z4 • SAC: 996511',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: AdminTheme.textMuted),
                              ),
                            ],
                          ),
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
              const SizedBox(height: 20),
              const Divider(color: AdminTheme.borderSubtle, height: 1),
              const SizedBox(height: 20),

              // Invoice Reference Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BILLED TO (CONSIGNOR):', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AdminTheme.textMuted)),
                        const SizedBox(height: 4),
                        Text(txn.customerName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack)),
                        Text(txn.customerEmail, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AdminTheme.textDark)),
                        const Text('Corporate Accounts Logistics Division', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AdminTheme.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('TAX INVOICE: ${txn.invoiceNumber}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AdminTheme.crimsonRed)),
                        Text('Txn Ref: ${txn.id}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted)),
                        Text('Date: ${txn.createdAt.toLocal().toString().split('.').first}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AdminTheme.textMuted)),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminTheme.statusOnline.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AdminTheme.statusOnline),
                          ),
                          child: const Text('PAYMENT COMPLETED', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AdminTheme.statusOnline)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Freight Line Items Table
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminTheme.borderSubtle),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AdminTheme.canvasBg,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 5, child: Text('DESCRIPTION / SAC', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AdminTheme.textMuted))),
                          Expanded(flex: 2, child: Text('CONSIGNMENT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AdminTheme.textMuted))),
                          Expanded(flex: 2, child: Text('METHOD', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AdminTheme.textMuted))),
                          Expanded(flex: 2, child: Text('AMOUNT (INR)', textAlign: TextAlign.right, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AdminTheme.textMuted))),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(txn.cargoType, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                                const Text('SAC 996511: Inter-district dedicated goods transit', style: TextStyle(fontSize: 10.5, color: AdminTheme.textMuted)),
                              ],
                            ),
                          ),
                          Expanded(flex: 2, child: Text('#${txn.orderCode}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                          Expanded(flex: 2, child: Text(txn.paymentMethod, style: const TextStyle(fontSize: 11, color: AdminTheme.textDark))),
                          Expanded(flex: 2, child: Text('₹${txn.grossAmount.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Commission & GST Breakdown Box
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  // Verification Stamp
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AdminTheme.canvasBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminTheme.borderSubtle),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: AdminTheme.statusOnline, size: 28),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CRYPTOGRAPHICALLY SEALED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AdminTheme.deepBlack)),
                            Text('Authorized Signatory: HAMHA SaaS Gateway', style: TextStyle(fontSize: 9.5, color: AdminTheme.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Financial Totals
                  SizedBox(
                    width: 260,
                    child: Column(
                      children: [
                        _buildTotalRow('Gross Consignment Fare:', '₹${txn.grossAmount.toStringAsFixed(2)}'),
                        _buildTotalRow('Platform Commission (15%):', '₹${txn.platformCommission.toStringAsFixed(2)}'),
                        _buildTotalRow('Statutory GST (18% on Comm):', '₹${txn.gstTax.toStringAsFixed(2)}'),
                        const Divider(color: AdminTheme.borderSubtle, height: 16),
                        _buildTotalRow('Total Paid by Client:', '₹${txn.grossAmount.toStringAsFixed(2)} INR', isBold: true, color: AdminTheme.crimsonRed),
                        _buildTotalRow('Carrier Net Payout (85%):', '₹${txn.carrierPayout.toStringAsFixed(2)} INR', color: AdminTheme.statusOnline),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Print / Download CTA Action
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invoice ${txn.invoiceNumber}.pdf generated and downloaded successfully.'),
                      backgroundColor: AdminTheme.deepBlack,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.crimsonRed,
                  foregroundColor: AdminTheme.crispWhite,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('PRINT / SAVE PDF INVOICE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: AdminTheme.textMuted)),
          Text(value, style: TextStyle(fontSize: isBold ? 13 : 11.5, fontWeight: FontWeight.w900, color: color ?? AdminTheme.deepBlack)),
        ],
      ),
    );
  }
}
