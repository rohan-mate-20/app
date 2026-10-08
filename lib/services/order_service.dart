import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../models/address_model.dart';
import '../models/customer_model.dart';
import 'supabase_service.dart';

class OrderService {
  final _supabase = SupabaseService.client;

  /// Create and place an order
  Future<OrderModel?> placeOrder({
    required CustomerModel customer,
    required AddressModel address,
    required List<CartItemModel> items,
    required double subtotal,
    required double deliveryFee,
    required double total,
    required String paymentMethod, // 'COD' or 'ONLINE'
    String? deliverySlotId,
    String? scheduledDeliveryDate,
    String? paymentId,
  }) async {
    final orderNumber = 'KM${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // 1. Try Backend API first
    try {
      final url = Uri.parse('${EnvConfig.backendBaseUrl}/api/orders');
      final body = {
        'orderNumber': orderNumber,
        'customerId': customer.id,
        'storeId': EnvConfig.defaultStoreId,
        'items': items.map((i) => {
          'product': {
            'id': i.product.id,
            'name': i.product.name,
            'sellingPrice': i.product.sellingPrice,
            'mrp': i.product.mrp,
          },
          'quantity': i.quantity,
        }).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'deliverySlotId': deliverySlotId,
        'scheduledDeliveryDate': scheduledDeliveryDate,
        'deliveryAddressSnapshot': address.toJson(),
        'customerSnapshot': customer.toJson(),
        'paymentMethod': paymentMethod,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        if (resJson['success'] == true && resJson['orderId'] != null) {
          return OrderModel(
            id: resJson['orderId'],
            orderNumber: resJson['orderNumber'] ?? orderNumber,
            customerId: customer.id,
            storeId: EnvConfig.defaultStoreId,
            status: 'CONFIRMED',
            paymentStatus: paymentMethod == 'COD' ? 'PENDING' : 'PAID',
            paymentMethod: paymentMethod,
            subtotal: subtotal,
            deliveryFee: deliveryFee,
            total: total,
            deliverySlotId: deliverySlotId,
            scheduledDeliveryDate: scheduledDeliveryDate,
            deliveryAddress: address,
            customerSnapshot: customer.toJson(),
            createdAt: DateTime.now(),
            items: items,
            paymentId: paymentId,
          );
        }
      }
    } catch (apiErr) {
      debugPrint('[OrderService] Backend API /api/orders error: $apiErr, falling back to direct Supabase');
    }

    // 2. Direct Supabase fallback
    try {
      final paymentStatus = paymentMethod == 'COD' ? 'PENDING' : 'PAID';

      final orderRow = await _supabase
          .from('orders')
          .insert({
            'order_number': orderNumber,
            'customer_id': customer.id,
            'store_id': EnvConfig.defaultStoreId,
            'order_type': 'DELIVERY',
            'status': 'CONFIRMED',
            'payment_status': paymentStatus,
            'payment_method': paymentMethod,
            'subtotal': subtotal,
            'delivery_fee': deliveryFee,
            'total': total,
            'delivery_slot_id': (deliverySlotId != null && deliverySlotId.contains('-') && deliverySlotId.length == 36) ? deliverySlotId : null,
            'scheduled_delivery_date': scheduledDeliveryDate,
            'delivery_address_snapshot': address.toJson(),
            'customer_snapshot': customer.toJson(),
          })
          .select()
          .single();

      final orderId = orderRow['id'] as String;

      // Status history
      try {
        await _supabase.from('order_status_history').insert({
          'order_id': orderId,
          'status': 'CONFIRMED',
          'changed_by': 'K MART Operations',
        });
      } catch (_) {}

      // Order items
      if (items.isNotEmpty) {
        final itemsPayload = items.map((it) => {
          'order_id': orderId,
          'product_id': it.product.id,
          'product_name': it.product.name,
          'quantity': it.quantity,
          'unit_mrp': it.product.mrp,
          'unit_selling_price': it.product.sellingPrice,
          'tax': 0,
          'line_total': it.lineTotal,
          'is_available': true,
        }).toList();

        try {
          await _supabase.from('order_items').insert(itemsPayload);
        } catch (e) {
          debugPrint('[OrderService] Error inserting order_items: $e');
        }
      }

      // Payments table if online
      if (paymentMethod == 'ONLINE' || paymentId != null) {
        try {
          await _supabase.from('payments').insert({
            'order_id': orderId,
            'razorpay_payment_id': paymentId,
            'amount': total,
            'status': paymentStatus,
          });
        } catch (_) {}
      }

      return OrderModel(
        id: orderId,
        orderNumber: orderNumber,
        customerId: customer.id,
        storeId: EnvConfig.defaultStoreId,
        status: 'CONFIRMED',
        paymentStatus: paymentStatus,
        paymentMethod: paymentMethod,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        deliverySlotId: deliverySlotId,
        scheduledDeliveryDate: scheduledDeliveryDate,
        deliveryAddress: address,
        customerSnapshot: customer.toJson(),
        createdAt: DateTime.now(),
        items: items,
        paymentId: paymentId,
      );
    } catch (dbErr) {
      debugPrint('[OrderService] Supabase insert error: $dbErr');
      return null;
    }
  }

  /// Fetch user orders
  Future<List<OrderModel>> fetchOrders(String customerId) async {
    if (customerId.isEmpty) return [];
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items (
              *,
              products (
                *,
                categories ( name )
              )
            ),
            order_status_history (
              *
            )
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      final list = response as List;
      return list.map((item) => OrderModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('[OrderService] fetchOrders error: $e');
    }
    return [];
  }

  /// Fetch single order tracking
  Future<OrderModel?> fetchOrderTracking(String orderId) async {
    if (orderId.isEmpty) return null;
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items (
              *,
              products (
                *,
                categories ( name )
              )
            ),
            order_status_history (
              *
            )
          ''')
          .eq('id', orderId)
          .maybeSingle();

      if (response != null) {
        return OrderModel.fromJson(response);
      }
    } catch (e) {
      debugPrint('[OrderService] fetchOrderTracking error: $e');
    }
    return null;
  }
}
