import 'cart_item_model.dart';
import 'address_model.dart';
import 'product_model.dart';

class OrderStatusHistoryModel {
  final String id;
  final String orderId;
  final String status;
  final String? changedBy;
  final DateTime changedAt;

  OrderStatusHistoryModel({
    required this.id,
    required this.orderId,
    required this.status,
    this.changedBy,
    required this.changedAt,
  });

  factory OrderStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryModel(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      status: json['status'] ?? 'CONFIRMED',
      changedBy: json['changed_by'],
      changedAt: DateTime.tryParse(json['changed_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String customerId;
  final String storeId;
  final String orderType;
  final String status; // 'CONFIRMED', 'PACKED', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED'
  final String paymentStatus; // 'PENDING', 'PAID', 'FAILED'
  final String paymentMethod; // 'COD', 'ONLINE', 'Razorpay', 'Cash on Delivery'
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String? deliverySlotId;
  final String? scheduledDeliveryDate;
  final String deliverySlotTime;
  final AddressModel? deliveryAddress;
  final Map<String, dynamic>? customerSnapshot;
  final DateTime createdAt;
  final List<CartItemModel> items;
  final List<OrderStatusHistoryModel> statusHistory;
  final String? paymentId;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    this.storeId = '458cbfde-68fd-4e71-86c7-a12a4cecad4d',
    this.orderType = 'DELIVERY',
    this.status = 'CONFIRMED',
    this.paymentStatus = 'PAID',
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.deliverySlotId,
    this.scheduledDeliveryDate,
    this.deliverySlotTime = '8:00 AM - 12:00 PM',
    this.deliveryAddress,
    this.customerSnapshot,
    required this.createdAt,
    required this.items,
    this.statusHistory = const [],
    this.paymentId,
  });

  String get displayStatus {
    switch (status.toUpperCase()) {
      case 'CREATED':
      case 'CONFIRMED':
        return 'Order Confirmed';
      case 'PREPARING':
      case 'PACKED':
        return 'Packed';
      case 'OUT_FOR_DELIVERY':
      case 'DELIVERY_ASSIGNED':
        return 'Out for Delivery';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  int get trackingStepIndex {
    switch (status.toUpperCase()) {
      case 'CREATED':
      case 'CONFIRMED':
        return 0;
      case 'PREPARING':
      case 'PACKED':
        return 1;
      case 'DELIVERY_ASSIGNED':
      case 'OUT_FOR_DELIVERY':
        return 2;
      case 'DELIVERED':
        return 3;
      default:
        return 0;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<CartItemModel> orderItems = [];
    if (json['order_items'] != null && json['order_items'] is List) {
      for (final it in json['order_items']) {
        if (it is Map<String, dynamic>) {
          final pMap = it['products'] is Map<String, dynamic>
              ? it['products'] as Map<String, dynamic>
              : {
                  'id': it['product_id'] ?? '',
                  'name': it['product_name'] ?? 'Grocery Item',
                  'selling_price': it['unit_selling_price'] ?? it['price'] ?? 0,
                  'mrp': it['unit_mrp'] ?? it['unit_selling_price'] ?? 0,
                };
          final product = ProductModel.fromJson(pMap);
          orderItems.add(
            CartItemModel(
              product: product,
              quantity: (it['quantity'] as num?)?.toInt() ?? 1,
            ),
          );
        }
      }
    }

    AddressModel? address;
    if (json['delivery_address_snapshot'] != null &&
        json['delivery_address_snapshot'] is Map) {
      address = AddressModel.fromJson(
        Map<String, dynamic>.from(json['delivery_address_snapshot']),
      );
    }

    List<OrderStatusHistoryModel> history = [];
    if (json['order_status_history'] != null &&
        json['order_status_history'] is List) {
      history = (json['order_status_history'] as List)
          .map((h) => OrderStatusHistoryModel.fromJson(h))
          .toList();
    }

    final double sub = (json['subtotal'] as num?)?.toDouble() ??
        (json['total_amount'] as num?)?.toDouble() ??
        0.0;
    final double del = (json['delivery_fee'] as num?)?.toDouble() ?? 0.0;
    final double tot = (json['total'] as num?)?.toDouble() ??
        (json['total_amount'] as num?)?.toDouble() ??
        (sub + del);

    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: json['order_number'] ?? 'KM-${json['id']?.toString().substring(0, 6).toUpperCase() ?? '0000'}',
      customerId: json['customer_id'] ?? '',
      storeId: json['store_id'] ?? '458cbfde-68fd-4e71-86c7-a12a4cecad4d',
      orderType: json['order_type'] ?? 'DELIVERY',
      status: json['status'] ?? 'CONFIRMED',
      paymentStatus: json['payment_status'] ?? 'PAID',
      paymentMethod: json['payment_method'] ?? 'ONLINE',
      subtotal: sub,
      deliveryFee: del,
      total: tot,
      deliverySlotId: json['delivery_slot_id'],
      scheduledDeliveryDate: json['scheduled_delivery_date'],
      deliveryAddress: address,
      customerSnapshot: json['customer_snapshot'] is Map
          ? Map<String, dynamic>.from(json['customer_snapshot'])
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      items: orderItems,
      statusHistory: history,
      paymentId: json['payment_id'],
    );
  }
}