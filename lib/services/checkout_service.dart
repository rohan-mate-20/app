import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';

class CheckoutService {
  final SupabaseClient _supabase = SupabaseService.client;

  /// Invokes the official K MART Supabase checkout Edge Function
  Future<Map<String, dynamic>> placeOrder({
    required String customerId,
    required String orderType, // 'DELIVERY' or 'PICKUP'
    String? addressId, // Real UUID from 'addresses' table
    String? pickupStoreId, // Real UUID from 'stores' table
    String? deliverySlotId, // Real UUID from 'delivery_slots' table (or null)
    String? scheduledDate, // 'YYYY-MM-DD'
    required String paymentMethod, // 'COD' or 'ONLINE'
    String? idempotencyKey,
  }) async {
    try {
      final key = idempotencyKey ?? const Uuid().v4();

      final response = await _supabase.functions.invoke(
        'checkout',
        body: {
          'customerId': customerId,
          'addressId': orderType == 'DELIVERY' ? addressId : null,
          'orderType': orderType,
          'pickupStoreId': orderType == 'PICKUP' ? pickupStoreId : null,
          'deliverySlotId': orderType == 'DELIVERY' ? deliverySlotId : null,
          'scheduledDeliveryDate': orderType == 'DELIVERY' ? scheduledDate : null,
          'paymentMethod': paymentMethod, // 'COD' or 'ONLINE'
          'idempotencyKey': key,
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        final errorMsg = errorData is Map ? errorData['error'] : 'Checkout failed';
        throw Exception(errorMsg ?? 'Server error during checkout (${response.status})');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception(data['error']);
      }

      return data;
    } on FunctionException catch (fe) {
      final details = fe.details;
      if (details is Map && details['error'] != null) {
        throw Exception(details['error']);
      }
      throw Exception(fe.details?.toString() ?? fe.toString());
    } catch (e) {
      debugPrint('[CheckoutService] placeOrder error: $e');
      rethrow;
    }
  }
}
