import 'package:flutter/foundation.dart';
import '../models/store_model.dart';
import 'supabase_service.dart';

class StoreService {
  final _supabase = SupabaseService.client;

  Future<List<StoreModel>> fetchStores() async {
    try {
      final response = await _supabase
          .from('stores')
          .select()
          .eq('active', true);

      final list = response as List;
      if (list.isNotEmpty) {
        return list.map((item) => StoreModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('[StoreService] fetchStores error: $e');
    }

    // Default Pune Store 1 fallback
    return [
      StoreModel(
        id: '458cbfde-68fd-4e71-86c7-a12a4cecad4d',
        name: 'Store 1',
        address: '123, Green Park, Pune 411001',
        latitude: 18.5204,
        longitude: 73.8567,
        serviceRadiusKm: 5.0,
        gofrugalAccountId: 'PENDING_STORE1',
        active: true,
      )
    ];
  }
}