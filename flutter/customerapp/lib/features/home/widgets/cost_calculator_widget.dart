import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/quote_model.dart';

class CostCalculatorWidget extends StatelessWidget {
  final QuoteModel? quote;
  final bool isLoading;
  final VoidCallback onCalculate;
  final VoidCallback? onProceed;

  const CostCalculatorWidget({
    super.key,
    required this.quote,
    required this.isLoading,
    required this.onCalculate,
    this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HamhaTheme.deepBlack,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calculate_outlined, color: HamhaTheme.crispWhite, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'HAMHA Cost Calculator',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: HamhaTheme.deepBlack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: HamhaTheme.borderSubtle, height: 1),
            const SizedBox(height: 16),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: HamhaTheme.crimsonRed),
                      SizedBox(height: 12),
                      Text('Calculating route & dynamic freight rates...', style: TextStyle(color: HamhaTheme.textMuted)),
                    ],
                  ),
                ),
              )
            else if (quote != null) ...[
              // Distance & Time summary pills
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: HamhaTheme.warmCream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: HamhaTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DISTANCE', style: TextStyle(color: HamhaTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${quote!.distanceKm} km', style: const TextStyle(color: HamhaTheme.deepBlack, fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: HamhaTheme.warmCream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: HamhaTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EST. DURATION', style: TextStyle(color: HamhaTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${quote!.estimatedDurationMin} mins', style: const TextStyle(color: HamhaTheme.deepBlack, fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Itemized Rates
              _buildCostRow('Base Freight Handling Fee', quote!.breakdown['baseFee'] ?? '₹650'),
              _buildCostRow('Interstate Distance Tariff', quote!.breakdown['distanceRate'] ?? '₹24 / km'),
              _buildCostRow('Cargo Weight Surcharge', quote!.breakdown['weightSurcharge'] ?? '₹0'),
              _buildCostRow('Goods & Services Tax (18% GST)', quote!.breakdown['gst'] ?? '₹0'),

              const SizedBox(height: 14),
              const Divider(color: HamhaTheme.borderSubtle),
              const SizedBox(height: 14),

              // Total Fare
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL FREIGHT QUOTE',
                    style: TextStyle(
                      color: HamhaTheme.deepBlack,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '₹${quote!.totalFare} INR',
                    style: const TextStyle(
                      color: HamhaTheme.crimsonRed,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // "Calculate & Proceed" prominent red button
              ElevatedButton.icon(
                onPressed: onProceed,
                icon: const Icon(Icons.arrow_forward, color: HamhaTheme.crispWhite),
                label: const Text('CALCULATE & PROCEED'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HamhaTheme.crimsonRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Fill in cargo weight and locations to compute exact freight fare.',
                    style: TextStyle(color: HamhaTheme.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onCalculate,
                icon: const Icon(Icons.refresh, color: HamhaTheme.crimsonRed),
                label: const Text('GET ESTIMATE', style: TextStyle(color: HamhaTheme.crimsonRed, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: HamhaTheme.crimsonRed, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: HamhaTheme.textMuted, fontSize: 13)),
          Text(value, style: const TextStyle(color: HamhaTheme.deepBlack, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
