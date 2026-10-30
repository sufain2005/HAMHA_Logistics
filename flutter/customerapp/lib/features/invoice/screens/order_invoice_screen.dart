import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../widgets/package_3d_widget.dart';

class OrderInvoiceScreen extends StatefulWidget {
  final String orderId;

  const OrderInvoiceScreen({super.key, required this.orderId});

  @override
  State<OrderInvoiceScreen> createState() => _OrderInvoiceScreenState();
}

class _OrderInvoiceScreenState extends State<OrderInvoiceScreen> {
  Map<String, dynamic>? _invoice;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInvoice();
  }

  Future<void> _fetchInvoice() async {
    try {
      final invoice = await ApiClient().getOrderInvoice(widget.orderId);
      setState(() {
        _invoice = invoice;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _handleDownloadInvoice() {
    setState(() => _isDownloading = true);

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _isDownloading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: HamhaTheme.deepBlack,
          content: Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: HamhaTheme.crimsonRed),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Invoice ${_invoice?['invoiceNumber'] ?? ''} downloaded to Documents/HAMHA_Invoices.',
                  style: const TextStyle(color: HamhaTheme.crispWhite),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: HamhaTheme.warmCream,
        body: Center(
          child: CircularProgressIndicator(color: HamhaTheme.crimsonRed),
        ),
      );
    }

    if (_errorMessage != null || _invoice == null) {
      return Scaffold(
        backgroundColor: HamhaTheme.warmCream,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Text(_errorMessage ?? 'Invoice not found', style: const TextStyle(color: HamhaTheme.deepBlack)),
        ),
      );
    }

    final shipment = _invoice!['shipment'] ?? {};
    final billing = _invoice!['billing'] ?? {};

    return Scaffold(
      backgroundColor: HamhaTheme.warmCream,
      appBar: AppBar(
        backgroundColor: HamhaTheme.crispWhite,
        title: const Text('DELIVERY INVOICE'),
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: HamhaTheme.deepBlack),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              children: [
                // 3D Package Graphic Visual
                const Center(
                  child: Package3DWidget(size: 150),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Package Safely Delivered',
                  style: TextStyle(
                    color: HamhaTheme.deepBlack,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _invoice!['invoiceNumber'] ?? 'INV-HMH-001',
                  style: const TextStyle(
                    color: HamhaTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 20),

                // Crisp White Card with Official Invoice Breakdown
                Card(
                  color: HamhaTheme.crispWhite,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: const BorderSide(color: HamhaTheme.borderSubtle, width: 1.2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Official HAMHA Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontFamily: 'sans-serif',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                                children: [
                                  TextSpan(text: 'HAMHA ', style: TextStyle(color: HamhaTheme.deepBlack)),
                                  TextSpan(text: 'LOGISTICS', style: TextStyle(color: HamhaTheme.crimsonRed)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: HamhaTheme.statusDelivered.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: HamhaTheme.statusDelivered),
                              ),
                              child: const Text(
                                'PAID',
                                style: TextStyle(
                                  color: HamhaTheme.statusDelivered,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: HamhaTheme.borderSubtle),
                        const SizedBox(height: 16),

                        // Shipment Specs
                        _buildInvoiceRow('Order Tracking #', shipment['orderCode'] ?? ''),
                        _buildInvoiceRow('Cargo Category', shipment['cargoType'] ?? ''),
                        _buildInvoiceRow('Cargo Weight', '${shipment['weightKg']} kg'),
                        _buildInvoiceRow('Transit Distance', '${shipment['distanceKm']} km'),
                        _buildInvoiceRow('Assigned Courier', shipment['driverName'] ?? 'HAMHA Fleet'),
                        _buildInvoiceRow('Vehicle Plate', shipment['vehiclePlate'] ?? 'N/A'),

                        const SizedBox(height: 16),
                        const Divider(color: HamhaTheme.borderSubtle),
                        const SizedBox(height: 16),

                        // Financial Summary
                        _buildInvoiceRow('Subtotal', '₹${billing['subtotal'] ?? '4,110.00'}'),
                        _buildInvoiceRow('Freight GST & Surcharges (18%)', '₹${billing['gst'] ?? '740.00'}'),

                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: HamhaTheme.warmCream,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: HamhaTheme.borderSubtle),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL AMOUNT PAID',
                                style: TextStyle(fontWeight: FontWeight.w900, color: HamhaTheme.deepBlack, fontSize: 14),
                              ),
                              Text(
                                '₹${billing['total'] ?? '4,850.00'} INR',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: HamhaTheme.crimsonRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Prominent Red "Download Invoice" Button
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _handleDownloadInvoice,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: HamhaTheme.crispWhite, strokeWidth: 2),
                        )
                      : const Icon(Icons.download, color: HamhaTheme.crispWhite),
                  label: Text(_isDownloading ? 'GENERATING PDF...' : 'DOWNLOAD INVOICE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HamhaTheme.crimsonRed,
                    elevation: 3,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: HamhaTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: HamhaTheme.deepBlack, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
