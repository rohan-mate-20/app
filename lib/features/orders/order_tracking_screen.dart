import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';

class OrderTrackingScreen extends StatelessWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #${order.orderNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Status Highlight Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            order.displayStatus,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyDark,
                            ),
                          ),
                          if (order.isPickup) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.navyDark.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.storefront_outlined, size: 13, color: AppColors.navyDark),
                                  SizedBox(width: 4),
                                  Text(
                                    'Self Pickup',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.paymentStatus == 'PAID'
                              ? 'Paid via ${order.paymentMethod}'
                              : 'Pending (${order.paymentMethod})',
                          style: const TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  () {
                    String dateLabel = 'Today';
                    if (order.scheduledDeliveryDate != null && order.scheduledDeliveryDate!.isNotEmpty) {
                      final dt = DateTime.tryParse(order.scheduledDeliveryDate!);
                      if (dt != null) {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final slotDay = DateTime(dt.year, dt.month, dt.day);
                        final diffDays = slotDay.difference(today).inDays;
                        if (diffDays == 0) {
                          dateLabel = 'Today';
                        } else if (diffDays == 1) {
                          dateLabel = 'Tomorrow';
                        } else {
                          const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          dateLabel = '${weekdays[dt.weekday - 1]}, ${dt.day}/${dt.month}';
                        }
                      }
                    }
                    final slotText = order.deliverySlotTime.isNotEmpty
                        ? order.deliverySlotTime
                        : '11:00 AM - 2:00 PM';
                    return Text(
                      order.isPickup
                          ? 'Pickup Slot: $dateLabel, $slotText'
                          : 'Expected delivery: $dateLabel, $slotText',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    );
                  }(),
                  const SizedBox(height: 16),

                  // Interactive Stepper Timeline
                  if (order.isPickup) ...[
                    _buildTimelineItem(
                      title: 'Order Placed & Confirmed',
                      subtitle: 'Order received and verified',
                      isDone: order.trackingStepIndex >= 0,
                      isCurrent: order.trackingStepIndex == 0,
                    ),
                    _buildTimelineItem(
                      title: 'Packed & Ready for Store Pickup',
                      subtitle: 'Items securely packed and ready for you at K MART store',
                      isDone: order.trackingStepIndex >= 1,
                      isCurrent: order.trackingStepIndex == 1,
                      isLast: order.status.toUpperCase() != 'DELIVERED',
                    ),
                    if (order.status.toUpperCase() == 'DELIVERED')
                      _buildTimelineItem(
                        title: 'Collected from Store',
                        subtitle: 'Order successfully collected by customer',
                        isDone: true,
                        isCurrent: true,
                        isLast: true,
                      ),
                  ] else ...[
                    _buildTimelineItem(
                      title: 'Order Placed & Confirmed',
                      subtitle: 'Order received and verified',
                      isDone: order.trackingStepIndex >= 0,
                      isCurrent: order.trackingStepIndex == 0,
                    ),
                    _buildTimelineItem(
                      title: 'Packed at Store',
                      subtitle: 'Items picked and securely packed',
                      isDone: order.trackingStepIndex >= 1,
                      isCurrent: order.trackingStepIndex == 1,
                    ),
                    _buildTimelineItem(
                      title: 'Out for Delivery',
                      subtitle: 'Delivery executive is on the way',
                      isDone: order.trackingStepIndex >= 2,
                      isCurrent: order.trackingStepIndex == 2,
                    ),
                    _buildTimelineItem(
                      title: 'Delivered to Doorstep',
                      subtitle: 'Package handed over to customer',
                      isDone: order.trackingStepIndex >= 3,
                      isCurrent: order.trackingStepIndex == 3,
                      isLast: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Delivery / Store Pickup Address Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        order.isPickup ? Icons.storefront_outlined : Icons.location_on_outlined,
                        color: AppColors.primaryRed,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.isPickup ? 'Store Pickup Location' : 'Delivery Address',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.isPickup
                        ? 'K MART Baramati Central Store, Main Road, Baramati, Maharashtra'
                        : (order.deliveryAddress?.fullAddressString ?? 'Near K MART Store, Yashwant Nagar, Baramati'),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Items & Bill Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items in this Order',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...order.items.map((it) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${it.quantity}x ${it.product.name}',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(it.lineTotal),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(order.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDone ? AppColors.successGreen : AppColors.cardBorder,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isDone ? AppColors.successGreen : AppColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                  color: isDone ? AppColors.navyDark : AppColors.textMuted,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}