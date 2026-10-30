import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/order_model.dart';

class OrderCardWidget extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const OrderCardWidget({
    super.key,
    required this.order,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (order.status) {
      case 'in_transit':
        return HamhaTheme.statusTransit;
      case 'delivered':
        return HamhaTheme.statusDelivered;
      case 'assigned':
      case 'picked_up':
        return HamhaTheme.crimsonRed;
      default:
        return HamhaTheme.statusPending;
    }
  }

  String _getStatusLabel() {
    return order.status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: HamhaTheme.crispWhite,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: HamhaTheme.borderSubtle, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order Code & Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: HamhaTheme.deepBlack,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_shipping, size: 16, color: HamhaTheme.crispWhite),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        order.orderCode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: HamhaTheme.deepBlack,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      _getStatusLabel(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Route representation (Origin -> Destination)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.trip_origin, size: 15, color: HamhaTheme.crimsonRed),
                      Container(width: 1.5, height: 26, color: HamhaTheme.borderSubtle),
                      const Icon(Icons.location_on, size: 16, color: HamhaTheme.deepBlack),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.pickupAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, color: HamhaTheme.textDark, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          order.dropoffAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, color: HamhaTheme.textDark, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: HamhaTheme.borderSubtle, height: 1),
              const SizedBox(height: 14),

              // Footer: Fare + Cargo info + Action Prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.cargoType} • ${order.weightKg} kg',
                        style: const TextStyle(fontSize: 12, color: HamhaTheme.textMuted, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${order.fareAmount.toStringAsFixed(0)} INR',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: HamhaTheme.crimsonRed),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        order.status == 'delivered' ? 'View Invoice' : 'Track Live',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: order.status == 'delivered' ? HamhaTheme.deepBlack : HamhaTheme.crimsonRed,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 13,
                        color: order.status == 'delivered' ? HamhaTheme.deepBlack : HamhaTheme.crimsonRed,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
