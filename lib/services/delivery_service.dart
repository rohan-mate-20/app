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
      var query = _supabase.from('delivery_slots').select();
      if (storeId != null && storeId.isNotEmpty) {
        query = query.eq('store_id', storeId);
      }

      final response = await query
          .order('slot_date', ascending: true)
          .order('start_time', ascending: true);

      final list = response as List;
      if (list.isNotEmpty) {
        return list.map((item) => DeliverySlotModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('[DeliveryService] fetchDeliverySlots error: $e');
    }

    return DeliverySlotModel.defaultSlots;
  }
}