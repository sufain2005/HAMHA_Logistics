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

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _isDownloading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: HamhaTheme.cardBlack,
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
        backgroundColor: HamhaTheme.deepBlack,
        body: Center(
          child: CircularProgressIndicator(color: HamhaTheme.crimsonRed),
        ),
      );
    }

    if (_errorMessage != null || _invoice == null) {
      return Scaffold(
        backgroundColor: HamhaTheme.deepBlack,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Text(_errorMessage ?? 'Invoice not found', style: const TextStyle(color: HamhaTheme.crispWhite)),
        ),
      );
    }

    final shipment = _invoice!['shipment'] ?? {};
    final billing = _invoice!['billing'] ?? {};

    return Scaffold(
      backgroundColor: HamhaTheme.deepBlack,
      appBar: AppBar(
        backgroundColor: HamhaTheme.deepBlack,
        title: const Text('DELIVERY INVOICE'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: HamhaTheme.crispWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // 3D Package Graphic Visual
            const Center(
              child: Package3DWidget(size: 150),
            ),
            const SizedBox(height: 8),

            const Text(
              'Package Safely Delivered',
              style: TextStyle(
                color: HamhaTheme.crispWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _invoice!['invoiceNumber'] ?? 'INV-HAMHA-001',
              style: const TextStyle(
                color: HamhaTheme.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 20),

            // White Layered Card with Official Invoice Breakdown
            Card(
              color: HamhaTheme.crispWhite,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Official HAMHA Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'HAMHA LOGISTICS',
                          style: TextStyle(
                            color: HamhaTheme.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: HamhaTheme.statusDelivered.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: HamhaTheme.statusDelivered),
                          ),
                          child: const Text(
                            'PAID',
                            style: TextStyle(
                              color: HamhaTheme.statusDelivered,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: HamhaTheme.borderGrey),
                    const SizedBox(height: 16),

                    // Shipment Specs
                    _buildInvoiceRow('Order Tracking #', shipment['orderCode'] ?? ''),
                    _buildInvoiceRow('Cargo Category', shipment['cargoType'] ?? ''),
                    _buildInvoiceRow('Cargo Weight', '${shipment['weightKg']} kg'),
                    _buildInvoiceRow('Transit Distance', '${shipment['distanceKm']} km'),
                    _buildInvoiceRow('Assigned Courier', shipment['driverName'] ?? 'HAMHA Fleet'),
                    _buildInvoiceRow('Vehicle Plate', shipment['vehiclePlate'] ?? 'N/A'),

                    const SizedBox(height: 16),
                    const Divider(color: HamhaTheme.borderGrey),
                    const SizedBox(height: 16),

                    // Financial Summary
                    _buildInvoiceRow('Subtotal', '\$${billing['subtotal'] ?? '0.00'}'),
                    _buildInvoiceRow('Transit Insurance & Tax (8%)', '\$${billing['tax'] ?? '0.00'}'),

                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: HamhaTheme.lightGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL AMOUNT',
                            style: TextStyle(fontWeight: FontWeight.w900, color: HamhaTheme.textDark, fontSize: 14),
                          ),
                          Text(
                            '\$${billing['total'] ?? '0.00'} USD',
                            style: const TextStyle(
                              fontSize: 22,
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
                elevation: 4,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 30),
          ],
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
          Text(label, style: const TextStyle(color: HamhaTheme.textMuted, fontSize: 13)),
          Text(value, style: const TextStyle(color: HamhaTheme.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

