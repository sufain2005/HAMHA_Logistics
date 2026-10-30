import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/order_model.dart';

class FloatingDriverCard extends StatelessWidget {
  final OrderModel order;
  final String? liveEta;
  final VoidCallback onCallDriver;
  final VoidCallback onViewInvoice;

  const FloatingDriverCard({
    super.key,
    required this.order,
    this.liveEta,
    required this.onCallDriver,
    required this.onViewInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final hasDriver = order.driverName != null && order.driverName!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HamhaTheme.crispWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: HamhaTheme.borderGrey.withAlpha(120)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Header with ETA & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderCode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: HamhaTheme.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.status == 'in_transit' ? 'In Transit to Destination' : 'Driver Assigned',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: HamhaTheme.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: HamhaTheme.crimsonRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: HamhaTheme.crimsonRed),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: HamhaTheme.crimsonRed),
                    const SizedBox(width: 4),
                    Text(
                      liveEta ?? '${order.estimatedDurationMin ?? 18} MIN ETA',
                      style: const TextStyle(
                        color: HamhaTheme.crimsonRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: HamhaTheme.borderGrey, height: 1),
          const SizedBox(height: 16),

          // Driver & Vehicle Identity Block
          if (hasDriver)
            Row(
              children: [
                // Driver Avatar with red border
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: HamhaTheme.deepBlack,
                    border: Border.all(color: HamhaTheme.crimsonRed, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      order.driverName!.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: HamhaTheme.crispWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Driver Name & Plate
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.driverName!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: HamhaTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order.vehicleModel ?? 'Freight Van'} • ${order.vehiclePlate ?? 'HAMHA-PRO'}',
                        style: const TextStyle(fontSize: 13, color: HamhaTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                // Call Driver Crimson Button
                InkWell(
                  onTap: onCallDriver,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: HamhaTheme.crimsonRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone, color: HamhaTheme.crispWhite, size: 20),
                  ),
                ),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: HamhaTheme.crimsonRed),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Matching nearest available HAMHA driver...',
                    style: TextStyle(color: HamhaTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),

          if (order.status == 'delivered') ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onViewInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: HamhaTheme.crimsonRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('VIEW DELIVERY INVOICE'),
            ),
          ],
        ],
      ),
    );
  }
}

