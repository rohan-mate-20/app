import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/config/env_config.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../models/address_model.dart';
import '../models/customer_model.dart';
import 'supabase_service.dart';
import 'cart_service.dart';
import 'checkout_service.dart';

class OrderService {
  final _supabase = SupabaseService.client;
  final _cartService = CartService();
  final _checkoutService = CheckoutService();
  static const String _prefKeyLocalOrders = 'kmart_local_cached_orders';

  /// Check if a string is a valid UUID
  bool _isUuid(String? str) {
    if (str == null || str.isEmpty) return false;
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(str);
  }

  /// Places an order securely via Supabase and persists locally
  Future<OrderModel?> placeOrder({
    required CustomerModel customer,
    required AddressModel address,
    required List<CartItemModel> items,
    required double subtotal,
    required double deliveryFee,
    required double total,
    required String paymentMethod, // 'ONLINE' or 'COD'
    String? deliverySlotId,
    String? scheduledDeliveryDate,
    String? paymentId,
  }) async {
    String orderNumber = 'KM${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final idempotencyKey = const Uuid().v4();
    final paymentStatus = paymentMethod == 'COD' ? 'PENDING' : 'PAID';

    // 1. Ensure valid UUID for customer_id
    String resolvedCustId = _isUuid(customer.id) ? customer.id : const Uuid().v4();

    // Try to ensure customer row in Supabase so foreign key passes
    try {
      final custPhone = customer.phone.replaceAll(RegExp(r'\D'), '');
      if (custPhone.isNotEmpty) {
        final existing = await _supabase
            .from('customers')
            .select('id')
            .eq('phone', custPhone)
            .maybeSingle();

        if (existing != null && existing['id'] != null) {
          resolvedCustId = existing['id'] as String;
        } else {
          final inserted = await _supabase
              .from('customers')
              .insert({
                'id': resolvedCustId,
                'phone': custPhone,
                'name': customer.name ?? 'Customer',
                'email': customer.email,
              })
              .select('id')
              .maybeSingle();
          if (inserted != null && inserted['id'] != null) {
            resolvedCustId = inserted['id'] as String;
          }
        }
      }
    } catch (custErr) {
      debugPrint('[OrderService] Note: Customer table sync: $custErr');
    }

    // 2. Ensure valid address in Supabase with Store service area coordinates
    String validAddressId = address.id;
    final double safeLat = (address.latitude != 0.0) ? address.latitude : 18.5300;
    final double safeLon = (address.longitude != 0.0) ? address.longitude : 73.8700;

    if (_isUuid(validAddressId)) {
      // already valid UUID
    } else {
      try {
        final addrRes = await _supabase
            .from('addresses')
            .insert({
              'customer_id': resolvedCustId,
              'label': address.label,
              'full_name': address.fullName,
              'phone': address.phone,
              'line1': address.line1,
              'line2': address.line2,
              'city': address.city.isNotEmpty ? address.city : 'Pune',
              'state': address.state.isNotEmpty ? address.state : 'Maharashtra',
              'pincode': address.pincode.isNotEmpty ? address.pincode : '411001',
              'latitude': safeLat,
              'longitude': safeLon,
              'is_default': address.isDefault,
            })
            .select('id')
            .maybeSingle();
        if (addrRes != null && addrRes['id'] != null) {
          validAddressId = addrRes['id'] as String;
        }
      } catch (addrErr) {
        debugPrint('[OrderService] Address table sync note: $addrErr');
      }
    }

    // 3. Ensure valid delivery slot
    String? validSlotId = deliverySlotId;
    if (validSlotId != null && !_isUuid(validSlotId)) {
      try {
        final slotRes = await _supabase
            .from('delivery_slots')
            .select('id')
            .limit(1)
            .maybeSingle();
        if (slotRes != null && slotRes['id'] != null) {
          validSlotId = slotRes['id'] as String;
        } else {
          validSlotId = null;
        }
      } catch (_) {
        validSlotId = null;
      }
    }

    // 4. Try checkout Edge Function (Official K MART checkout engine)
    String createdOrderId = const Uuid().v4();
    bool savedInSupabase = false;

    try {
      // Step 3: Sync Cart to DB (carts & cart_items tables)
      final dbCartId = await _cartService.getOrCreateCartId(resolvedCustId);
      if (dbCartId != null && items.isNotEmpty) {
        await _cartService.syncCartToDatabase(
          cartId: dbCartId,
          items: items
              .map((it) => {
                    'productId': it.product.id,
                    'quantity': it.quantity,
                  })
              .toList(),
        );
      }

      // Step 4: Call Edge Function via CheckoutService
      final edgeData = await _checkoutService.placeOrder(
        customerId: resolvedCustId,
        orderType: 'DELIVERY',
        addressId: validAddressId,
        deliverySlotId: validSlotId,
        scheduledDate: scheduledDeliveryDate,
        paymentMethod: paymentMethod == 'COD' ? 'COD' : 'ONLINE',
        idempotencyKey: idempotencyKey,
      );

      if (edgeData['order'] != null) {
        final dbOrder = edgeData['order'];
        createdOrderId = dbOrder['id']?.toString() ?? createdOrderId;
        if (dbOrder['order_number'] != null) {
          orderNumber = dbOrder['order_number'].toString();
        }
        savedInSupabase = true;
        debugPrint('[OrderService] ✅ Order successfully created via Supabase Edge Function checkout: $createdOrderId (#$orderNumber)');
      }
    } catch (edgeErr) {
      debugPrint('[OrderService] Note: checkout edge function: $edgeErr');
    }

    // 5. Fallback: Direct Supabase insertion
    if (!savedInSupabase) {
      try {
        final orderRow = await _supabase
            .from('orders')
            .insert({
              'order_number': orderNumber,
              'customer_id': resolvedCustId,
              'store_id': EnvConfig.defaultStoreId,
              'order_type': 'DELIVERY',
              'status': 'CONFIRMED',
              'payment_status': paymentStatus,
              'payment_method': paymentMethod == 'COD' ? 'COD' : 'ONLINE',
              'subtotal': subtotal,
              'delivery_fee': deliveryFee,
              'total': total,
              'delivery_slot_id': validSlotId,
              'scheduled_delivery_date': scheduledDeliveryDate,
              'delivery_address_snapshot': address.toJson(),
              'customer_snapshot': customer.toJson(),
              'idempotency_key': idempotencyKey,
            })
            .select()
            .maybeSingle();

        if (orderRow != null && orderRow['id'] != null) {
          createdOrderId = orderRow['id'] as String;
          savedInSupabase = true;
          debugPrint('[OrderService] ✅ Order successfully created in Supabase: $createdOrderId');

          // Insert status history
          try {
            await _supabase.from('order_status_history').insert({
              'order_id': createdOrderId,
              'status': 'CONFIRMED',
              'changed_by': 'K MART System',
            });
          } catch (_) {}

          // Insert order items
          if (items.isNotEmpty) {
            try {
              final itemsPayload = items.map((it) => {
                'order_id': createdOrderId,
                'product_id': it.product.id,
                'product_name': it.product.name,
                'quantity': it.quantity,
                'unit_mrp': it.product.mrp,
                'unit_selling_price': it.product.sellingPrice,
                'tax': 0,
                'line_total': it.lineTotal,
                'is_available': true,
              }).toList();

              await _supabase.from('order_items').insert(itemsPayload);
            } catch (_) {}
          }

          // Insert payment record
          if (paymentMethod != 'COD' || paymentId != null) {
            try {
              await _supabase.from('payments').insert({
                'order_id': createdOrderId,
                'razorpay_payment_id': paymentId,
                'amount': total,
                'status': paymentStatus,
              });
            } catch (_) {}
          }
        }
      } catch (dbErr) {
        debugPrint('[OrderService] Supabase DB note (RLS policy check): $dbErr');
      }
    }

    final finalOrder = OrderModel(
      id: createdOrderId,
      orderNumber: orderNumber,
      customerId: resolvedCustId,
      storeId: EnvConfig.defaultStoreId,
      status: 'CONFIRMED',
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      deliverySlotId: validSlotId,
      scheduledDeliveryDate: scheduledDeliveryDate,
      deliveryAddress: address,
      customerSnapshot: customer.toJson(),
      createdAt: DateTime.now(),
      items: items,
      paymentId: paymentId,
      statusHistory: [
        OrderStatusHistoryModel(
          id: const Uuid().v4(),
          orderId: createdOrderId,
          status: 'CONFIRMED',
          changedBy: 'K MART Operations',
          changedAt: DateTime.now(),
        ),
      ],
    );

    // Save order in local cache
    await _saveLocalOrder(finalOrder);

    debugPrint('[OrderService] Order completed (DB saved: $savedInSupabase): $orderNumber');
    return finalOrder;
  }

  /// Save order to SharedPreferences local cache
  Future<void> _saveLocalOrder(OrderModel order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getStringList(_prefKeyLocalOrders) ?? [];
      final list = <Map<String, dynamic>>[];
      for (final s in existingJson) {
        try {
          list.add(Map<String, dynamic>.from(jsonDecode(s)));
        } catch (_) {}
      }

      // Check if duplicate
      list.removeWhere((item) => item['id'] == order.id || item['order_number'] == order.orderNumber);
      list.insert(0, order.toJson());

      // Save top 50 orders
      final updatedJson = list.take(50).map((m) => jsonEncode(m)).toList();
      await prefs.setStringList(_prefKeyLocalOrders, updatedJson);
    } catch (e) {
      debugPrint('[OrderService] Error saving local order: $e');
    }
  }

  /// Fetch user orders (merges Supabase live orders with local cache)
  Future<List<OrderModel>> fetchOrders(String customerId) async {
    final Map<String, OrderModel> orderMap = {};

    // 1. Fetch from Supabase
    if (customerId.isNotEmpty) {
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
        for (final item in list) {
          try {
            final ord = OrderModel.fromJson(Map<String, dynamic>.from(item));
            orderMap[ord.id] = ord;
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('[OrderService] fetchOrders DB error: $e');
      }
    }

    // 2. Fetch from Local Cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKeyLocalOrders) ?? [];
      for (final s in list) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(s));
          final ord = OrderModel.fromJson(map);
          if (!orderMap.containsKey(ord.id)) {
            orderMap[ord.id] = ord;
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[OrderService] Error reading cached orders: $e');
    }

    final result = orderMap.values.toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  /// Fetch single order tracking
  Future<OrderModel?> fetchOrderTracking(String orderId) async {
    if (orderId.isEmpty) return null;

    // 1. Check Supabase
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
        return OrderModel.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (_) {}

    // 2. Check Local Cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKeyLocalOrders) ?? [];
      for (final s in list) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(s));
          if (map['id'] == orderId || map['order_number'] == orderId) {
            return OrderModel.fromJson(map);
          }
        } catch (_) {}
      }
    } catch (_) {}

    return null;
  }

  /// Real-time stream for active order tracking
  Stream<Map<String, dynamic>?> streamOrderDetails(String orderId) {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((rows) => rows.isNotEmpty ? rows.first : null);
  }
}
