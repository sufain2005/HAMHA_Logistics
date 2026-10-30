import 'package:flutter/material.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/services/driver_api_service.dart';

class DriverCashOutModal extends StatefulWidget {
  final double availableBalance;
  final VoidCallback onCashOutSuccess;

  const DriverCashOutModal({
    super.key,
    required this.availableBalance,
    required this.onCashOutSuccess,
  });

  @override
  State<DriverCashOutModal> createState() => _DriverCashOutModalState();
}

class _DriverCashOutModalState extends State<DriverCashOutModal> {
  bool _isProcessing = false;
  bool _isCompleted = false;
  String _selectedMethod = 'UPI';

  Future<void> _handleConfirmCashOut() async {
    setState(() => _isProcessing = true);
    await DriverApiService().processCashOut(amount: widget.availableBalance);
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isCompleted = true;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    widget.onCashOutSuccess();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final driver = DriverApiService().currentDriver;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: DriverTheme.crispWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: _isCompleted
          ? _buildSuccessView()
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: DriverTheme.borderSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Instant Cash Out',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: DriverTheme.deepBlack,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: DriverTheme.statusOnline.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: DriverTheme.statusOnline),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt, size: 14, color: DriverTheme.statusOnline),
                          SizedBox(width: 4),
                          Text(
                            'IMPS Instant',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: DriverTheme.statusOnline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Amount Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DriverTheme.warmCream,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: DriverTheme.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'AVAILABLE FOR TRANSFER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: DriverTheme.textMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${widget.availableBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: DriverTheme.crimsonRed,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Includes 6 completed trips • Zero transfer fee',
                        style: TextStyle(
                          fontSize: 12,
                          color: DriverTheme.textDark.withAlpha(180),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Payout Destinations
                const Text(
                  'Select Payout Destination',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: DriverTheme.deepBlack,
                  ),
                ),
                const SizedBox(height: 12),

                _buildDestinationOption(
                  method: 'UPI',
                  title: 'Instant UPI VPA',
                  subtitle: '${driver?.phone.replaceAll(' ', '') ?? '9823411209'}@okhdfcbank',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(height: 10),
                _buildDestinationOption(
                  method: 'BANK',
                  title: 'HDFC Direct Salary Account',
                  subtitle: 'A/C •••• 4892 • IFSC: HDFC0001242',
                  icon: Icons.account_balance_outlined,
                ),
                const SizedBox(height: 24),

                // Action Button
                ElevatedButton(
                  onPressed: _isProcessing ? null : _handleConfirmCashOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverTheme.crimsonRed,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: DriverTheme.crispWhite, strokeWidth: 2.5),
                        )
                      : Text(
                          'CONFIRM TRANSFER (₹${widget.availableBalance.toStringAsFixed(0)})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDestinationOption({
    required String method,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == method;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? DriverTheme.crimsonTint : DriverTheme.crispWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? DriverTheme.crimsonRed : DriverTheme.borderSubtle,
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? DriverTheme.crimsonRed : DriverTheme.deepBlack,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: DriverTheme.crispWhite, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? DriverTheme.crimsonDark : DriverTheme.deepBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: DriverTheme.textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? DriverTheme.crimsonRed : DriverTheme.borderSubtle,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: DriverTheme.statusOnline,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: DriverTheme.crispWhite, size: 38),
          ),
          const SizedBox(height: 20),
          const Text(
            'Transfer Initiated!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${widget.availableBalance.toStringAsFixed(2)} has been credited via IMPS to your account.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: DriverTheme.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

