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
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: HamhaTheme.borderGrey.withAlpha(120)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: HamhaTheme.crimsonRed.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_shipping, size: 16, color: HamhaTheme.crimsonRed),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.orderCode,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: HamhaTheme.textDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withAlpha(100)),
                    ),
                    child: Text(
                      _getStatusLabel(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Route representation (Origin -> Destination)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.trip_origin, size: 14, color: HamhaTheme.crimsonRed),
                      Container(width: 1.5, height: 24, color: HamhaTheme.borderGrey),
                      const Icon(Icons.location_on, size: 14, color: HamhaTheme.textDark),
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
                          style: const TextStyle(fontSize: 13, color: HamhaTheme.textDark, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          order.dropoffAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: HamhaTheme.textDark, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: HamhaTheme.borderGrey, height: 1),
              const SizedBox(height: 12),

              // Footer: Fare + Cargo info + Action Prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.cargoType} • ${order.weightKg} kg',
                        style: const TextStyle(fontSize: 12, color: HamhaTheme.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${order.fareAmount.toStringAsFixed(2)} USD',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: HamhaTheme.crimsonRed),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        order.status == 'delivered' ? 'View Invoice' : 'Track Live',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: order.status == 'delivered' ? HamhaTheme.textDark : HamhaTheme.crimsonRed,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 13,
                        color: order.status == 'delivered' ? HamhaTheme.textDark : HamhaTheme.crimsonRed,
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

