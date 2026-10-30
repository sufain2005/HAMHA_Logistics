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
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: HamhaTheme.borderGrey.withAlpha(150)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HamhaTheme.crimsonRed.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calculate_outlined, color: HamhaTheme.crimsonRed, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'HAMHA Cost Calculator',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: HamhaTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: HamhaTheme.borderGrey, height: 1),
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
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: HamhaTheme.lightGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DISTANCE', style: TextStyle(color: HamhaTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${quote!.distanceKm} km', style: const TextStyle(color: HamhaTheme.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: HamhaTheme.lightGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EST. DURATION', style: TextStyle(color: HamhaTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${quote!.estimatedDurationMin} mins', style: const TextStyle(color: HamhaTheme.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Itemized Rates
              _buildCostRow('Base Logistics Fee', '\$${quote!.breakdown['baseFee'] ?? '15.00'}'),
              _buildCostRow('Distance Rate (Road)', quote!.breakdown['distanceRate'] ?? ''),
              _buildCostRow('Weight Surcharge', quote!.breakdown['weightSurcharge'] ?? '\$0.00'),
              _buildCostRow('Tax & Transit Insurance (8%)', quote!.breakdown['tax'] ?? '\$0.00'),

              const SizedBox(height: 12),
              const Divider(color: HamhaTheme.borderGrey),
              const SizedBox(height: 12),

              // Total Fare
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL ESTIMATE',
                    style: TextStyle(
                      color: HamhaTheme.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '\$${quote!.totalFare} USD',
                    style: const TextStyle(
                      color: HamhaTheme.crimsonRed,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Fill in weight and locations to compute exact freight fare.',
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
          Text(value, style: const TextStyle(color: HamhaTheme.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

