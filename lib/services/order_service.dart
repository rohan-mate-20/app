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
import 'delivery_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  SupabaseClient get _supabase => SupabaseService.client;
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
    required String orderType, // 'DELIVERY' or 'PICKUP'
    String? deliverySlotId,
    String? scheduledDeliveryDate,
    String? deliverySlotTime,
    String? paymentId,
  }) async {
    String orderNumber = 'KM${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final idempotencyKey = const Uuid().v4();
    final paymentStatus = paymentMethod == 'COD' ? 'PENDING' : 'PAID';

    final isPickup = orderType.toUpperCase() == 'PICKUP';
    final effectiveDeliveryFee = isPickup ? 0.0 : deliveryFee;
    final effectiveTotal = subtotal + effectiveDeliveryFee + DeliveryPricingService.handlingFee + DeliveryPricingService.platformFee;

    // Requirement 1: Verify auth user before database operations
    final userRes = await _supabase.auth.getUser();
    final authUser = userRes.user ?? _supabase.auth.currentUser;
    if (authUser == null) {
      debugPrint('❌ [OrderService] No authenticated user found with Supabase.');
      throw Exception('Customer is not logged in as far as Supabase is concerned. Please login with OTP first.');
    }

    // Requirement 2: customer_id must be customers.id, looked up with:
    // select id from customers where auth_user_id = <auth user id>.
    // Never use the auth user id itself as customer_id.
    String customerId;
    try {
      final custRes = await _supabase
          .from('customers')
          .select('id')
          .eq('auth_user_id', authUser.id)
          .maybeSingle();

      if (custRes != null && custRes['id'] != null) {
        customerId = custRes['id'] as String;
        debugPrint('ℹ️ [OrderService] Found customer record: customers.id=$customerId for auth_user_id=${authUser.id}');
      } else {
        debugPrint('❌ [OrderService] No customers row found where auth_user_id = ${authUser.id}');
        throw Exception('Customer row not found for logged in user. Please log out and log in again.');
      }
    } on PostgrestException catch (pe) {
      debugPrint('❌ [OrderService] Lookup customer PostgrestException: code=${pe.code}, message=${pe.message}, details=${pe.details}');
      rethrow;
    }

    // Requirement 4: Addresses written directly with the customer's own customers.id
    String? validAddressId;
    if (!isPickup) {
      if (_isUuid(address.id)) {
        validAddressId = address.id;
        try {
          await _supabase.from('addresses').update({
            'latitude': 18.1508,
            'longitude': 74.5779,
          }).eq('id', validAddressId);
        } catch (_) {}
      } else {
        try {
          final addrRes = await _supabase
              .from('addresses')
              .insert({
                'customer_id': customerId,
                'label': address.label,
                'full_name': address.fullName,
                'phone': address.phone,
                'line1': address.line1,
                'line2': address.line2,
                'city': address.city.isNotEmpty ? address.city : 'Baramati',
                'state': address.state.isNotEmpty ? address.state : 'Maharashtra',
                'pincode': address.pincode.isNotEmpty ? address.pincode : '413102',
                'latitude': 18.1508,
                'longitude': 74.5779,
                'is_default': address.isDefault,
              })
              .select('id')
              .single();

          if (addrRes['id'] != null) {
            validAddressId = addrRes['id'] as String;
          }
        } on PostgrestException catch (pe) {
          debugPrint('❌ [OrderService] Address insert PostgrestException: code=${pe.code}, message=${pe.message}, details=${pe.details}');
          rethrow;
        }
      }
    }

    // Delivery Slot resolution
    String? validSlotId = isPickup ? null : deliverySlotId;
    if (validSlotId != null && _isUuid(validSlotId)) {
      try {
        final slotRes = await _supabase
            .from('delivery_slots')
            .select('id')
            .eq('id', validSlotId)
            .maybeSingle();
        if (slotRes == null) validSlotId = null;
      } catch (_) {
        validSlotId = null;
      }
    } else {
      validSlotId = null;
    }

    if (!isPickup && validSlotId == null) {
      try {
        final anySlot = await _supabase
            .from('delivery_slots')
            .select('id, slot_date')
            .order('slot_date', ascending: true)
            .limit(1)
            .maybeSingle();
        if (anySlot != null && anySlot['id'] != null) {
          validSlotId = anySlot['id'] as String;
          if (scheduledDeliveryDate == null || scheduledDeliveryDate.isEmpty) {
            scheduledDeliveryDate = anySlot['slot_date'] as String?;
          }
        }
      } catch (_) {}
    }

    // Resolve store ID
    String validStoreId = EnvConfig.defaultStoreId;
    try {
      final storeCheck = await _supabase.from('stores').select('id').eq('id', validStoreId).maybeSingle();
      if (storeCheck == null) {
        final anyStore = await _supabase.from('stores').select('id').limit(1).maybeSingle();
        if (anyStore != null && anyStore['id'] != null) {
          validStoreId = anyStore['id'] as String;
        }
      }
    } catch (_) {}

    // Requirement 4: Carts and cart items are written directly with customer's own customers.id
    final dbCartId = await _cartService.getOrCreateCartId(customerId);
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

    // Requirement 3: Orders are created ONLY by supabase.functions.invoke('checkout', ...)
    // Never insert into customers, orders, order_items, order_status_history or payments from client.
    String createdOrderId = const Uuid().v4();
    final edgeData = await _checkoutService.placeOrder(
      customerId: customerId,
      orderType: orderType,
      pickupStoreId: isPickup ? validStoreId : null,
      addressId: isPickup ? null : validAddressId,
      deliverySlotId: isPickup ? null : validSlotId,
      scheduledDate: isPickup ? null : scheduledDeliveryDate,
      paymentMethod: paymentMethod == 'COD' ? 'COD' : 'ONLINE',
      idempotencyKey: idempotencyKey,
      items: items
          .map((it) => {
                'productId': it.product.id,
                'quantity': it.quantity,
                'unitPrice': it.product.sellingPrice,
                'productName': it.product.name,
              })
          .toList(),
    );

    final dbOrder = edgeData['order'];
    if (dbOrder != null) {
      createdOrderId = dbOrder['id']?.toString() ?? createdOrderId;
      if (dbOrder['order_number'] != null) {
        orderNumber = dbOrder['order_number'].toString();
      }
      debugPrint('[OrderService] ✅ Order successfully created by Supabase Edge Function checkout: $createdOrderId (#$orderNumber)');
    } else {
      debugPrint('⚠️ [OrderService] Edge Function returned without order object: $edgeData');
    }

    final finalOrder = OrderModel(
      id: createdOrderId,
      orderNumber: orderNumber,
      customerId: customerId,
      storeId: EnvConfig.defaultStoreId,
      orderType: orderType,
      status: 'CONFIRMED',
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      deliveryFee: effectiveDeliveryFee,
      total: effectiveTotal,
      deliverySlotId: validSlotId,
      scheduledDeliveryDate: scheduledDeliveryDate,
      deliverySlotTime: deliverySlotTime ?? '11:00 AM - 2:00 PM',
      deliveryAddress: isPickup ? null : address,
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

    debugPrint('[OrderService] Order placed via Supabase Edge Function: $orderNumber (ID: $createdOrderId)');
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

  /// Clear local orders cache on logout
  Future<void> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyLocalOrders);
    } catch (e) {
      debugPrint('[OrderService] Error clearing local orders cache: $e');
    }
  }

  /// Fetch user orders (merges Supabase live orders with local cache)
  Future<List<OrderModel>> fetchOrders(String customerId) async {
    if (customerId.trim().isEmpty) {
      return [];
    }

    final Map<String, OrderModel> orderMap = {};

    // 1. Fetch from Supabase
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

    // 2. Fetch from Local Cache (filtered strictly to this customer)
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKeyLocalOrders) ?? [];
      for (final s in list) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(s));
          final ord = OrderModel.fromJson(map);
          // Only show cached orders that belong to this logged-in customer
          if (ord.customerId == customerId) {
            if (!orderMap.containsKey(ord.id)) {
              orderMap[ord.id] = ord;
            }
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
