import 'package:flutter/foundation.dart';
import '../models/delivery_settings_model.dart';
import '../models/delivery_slot_model.dart';
import 'supabase_service.dart';

class DeliveryService {
  final _supabase = SupabaseService.client;

  Future<DeliverySettingsModel> fetchDeliverySettings() async {
    try {
      final response = await _supabase
          .from('delivery_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (response != null) {
        return DeliverySettingsModel.fromJson(response);
      }
    } catch (e) {
      debugPrint('[DeliveryService] fetchDeliverySettings error: $e');
    }
    return DeliverySettingsModel();
  }

  Future<List<DeliverySlotModel>> fetchDeliverySlots({String? storeId}) async {
    try {
      var filter = _supabase
          .from('delivery_slots')
          .select();

      if (storeId != null && storeId.isNotEmpty) {
        filter = filter.eq('store_id', storeId);
      }

      final response = await filter
          .order('slot_date', ascending: true)
          .order('start_time', ascending: true);

      final list = response as List;
      if (list.isNotEmpty) {
        return list
            .map((item) => DeliverySlotModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('[DeliveryService] fetchDeliverySlots DB error: $e');
    }
    return DeliverySlotModel.getUpcomingSlots();
  }
}

/// Centralized delivery and fee calculation service for K MART
class DeliveryPricingService {
  // Configurable fees (initial values are 0.0)
  static const double handlingFee = 0.0;
  static const double platformFee = 0.0;

  /// Centralized calculation function:
  /// - Pickup orders: 0.0
  /// - Eligible for first 3 deliveries: 0.0
  /// - Below ₹500: 40.0
  /// - ₹500 to ₹999.99: 40.0
  /// - ₹1,000 and above: 30.0
  /// Charges are alternatives, never cumulative (never 40 + 30).
  static double calculateDeliveryFee({
    required double subtotal,
    bool isPickup = false,
    int pastEligibleDeliveries = 0,
    int freeDeliveryOrderCount = 0,
  }) {
    if (isPickup) return 0.0;
    if (freeDeliveryOrderCount > 0 && pastEligibleDeliveries < freeDeliveryOrderCount) {
      return 0.0;
    }
    if (subtotal >= 1000.0) {
      return 30.0;
    }
    return 40.0;
  }

  /// Final payable calculation:
  /// Subtotal - product discounts + delivery fee + handling fee + platform fee
  static double calculatePayableTotal({
    required double subtotal,
    required double deliveryFee,
    double productDiscounts = 0.0,
    double handling = handlingFee,
    double platform = platformFee,
  }) {
    final netSubtotal = (subtotal - productDiscounts).clamp(0.0, double.infinity);
    return netSubtotal + deliveryFee + handling + platform;
  }
}