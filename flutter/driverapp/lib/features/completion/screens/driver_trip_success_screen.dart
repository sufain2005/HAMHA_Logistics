import 'package:flutter/material.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/models/dispatch_offer_model.dart';
import '../../dashboard/screens/driver_main_shell.dart';

class DriverTripSuccessScreen extends StatefulWidget {
  final DispatchOfferModel offer;

  const DriverTripSuccessScreen({
    super.key,
    required this.offer,
  });

  @override
  State<DriverTripSuccessScreen> createState() => _DriverTripSuccessScreenState();
}

class _DriverTripSuccessScreenState extends State<DriverTripSuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _checkAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _returnToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DriverMainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const double fuelBonus = 150.0;
    final double netTotal = widget.offer.payoutAmount + fuelBonus;

    return Scaffold(
      backgroundColor: DriverTheme.warmCream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Animated Checkmark
                  Center(
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: DriverTheme.statusOnline,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: DriverTheme.statusOnline.withAlpha(90),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ScaleTransition(
                          scale: _checkAnimation,
                          child: const Icon(
                            Icons.check_rounded,
                            color: DriverTheme.crispWhite,
                            size: 58,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Center(
                    child: Text(
                      'Delivery Complete!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: DriverTheme.deepBlack,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Consignment ${widget.offer.orderCode} successfully signed & delivered.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: DriverTheme.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Earnings Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: DriverTheme.crispWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: DriverTheme.borderSubtle, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL FARE CREDITED TO DRIVER WALLET',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: DriverTheme.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${netTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: DriverTheme.crimsonRed,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: DriverTheme.statusOnline.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: DriverTheme.statusOnline),
                          ),
                          child: const Text(
                            'CLEARED FOR INSTANT WITHDRAWAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: DriverTheme.statusOnline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: DriverTheme.borderSubtle, height: 1),
                        const SizedBox(height: 16),

                        // Breakdown lines
                        _buildFareLine('Base Freight Contract', '₹${widget.offer.payoutAmount.toStringAsFixed(2)}'),
                        const SizedBox(height: 10),
                        _buildFareLine('Toll & Express Highway Allowance', '+₹${fuelBonus.toStringAsFixed(2)}', isBonus: true),
                        const SizedBox(height: 10),
                        _buildFareLine('HAMHA Platform Fee (Elite Tier)', '₹0.00 (Waived)'),
                        const SizedBox(height: 10),
                        _buildFareLine('GST & TDS Compliance Deductions', '₹0.00'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Trip Telematics Summary Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: DriverTheme.crispWhite,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: DriverTheme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatPill(Icons.route, '${widget.offer.distanceKm} km', 'Distance'),
                        Container(width: 1, height: 28, color: DriverTheme.borderSubtle),
                        _buildStatPill(Icons.timer, '${widget.offer.estimatedDurationMin} mins', 'Drive Time'),
                        Container(width: 1, height: 28, color: DriverTheme.borderSubtle),
                        _buildStatPill(Icons.star, '5.0', 'Recipient Rating'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Return to Dashboard Action Button
                  ElevatedButton(
                    onPressed: _returnToDashboard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DriverTheme.crimsonRed,
                      foregroundColor: DriverTheme.crispWhite,
                      minimumSize: const Size.fromHeight(56),
                      elevation: 4,
                      shadowColor: DriverTheme.crimsonRed.withAlpha(90),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'RETURN TO DRIVER DASHBOARD',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
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

  Widget _buildFareLine(String label, String value, {bool isBonus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: DriverTheme.textMuted, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isBonus ? DriverTheme.statusOnline : DriverTheme.deepBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: icon == Icons.star ? Colors.amber : DriverTheme.crimsonRed),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: DriverTheme.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
