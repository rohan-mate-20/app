import 'package:flutter/foundation.dart';
import '../models/address_model.dart';
import 'supabase_service.dart';

class AddressService {
  final _supabase = SupabaseService.client;

  Future<List<AddressModel>> fetchAddresses(String customerId) async {
    if (customerId.isEmpty) return [];
    try {
      final response = await _supabase
          .from('addresses')
          .select()
          .eq('customer_id', customerId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (response as List).map((item) => AddressModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('[AddressService] fetchAddresses error: $e');
    }
    return [];
  }

  Future<AddressModel?> addAddress(AddressModel address) async {
    try {
      if (address.isDefault && address.customerId.isNotEmpty) {
        await _supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('customer_id', address.customerId);
      }

      final response = await _supabase
          .from('addresses')
          .insert(address.toJson())
          .select()
          .single();

      return AddressModel.fromJson(response);
    } catch (e) {
      debugPrint('[AddressService] addAddress error: $e');
      return null;
    }
  }

  Future<bool> updateAddress(AddressModel address) async {
    try {
      if (address.isDefault && address.customerId.isNotEmpty) {
        await _supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('customer_id', address.customerId);
      }

      await _supabase
          .from('addresses')
          .update(address.toJson())
          .eq('id', address.id);
      return true;
    } catch (e) {
      debugPrint('[AddressService] updateAddress error: $e');
      return false;
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    try {
      await _supabase.from('addresses').delete().eq('id', addressId);
      return true;
    } catch (e) {
      debugPrint('[AddressService] deleteAddress error: $e');
      return false;
    }
  }

  Future<bool> setDefaultAddress(String addressId, String customerId) async {
    try {
      await _supabase
          .from('addresses')
          .update({'is_default': false})
          .eq('customer_id', customerId);

      await _supabase
          .from('addresses')
          .update({'is_default': true})
          .eq('id', addressId);
      return true;
    } catch (e) {
      debugPrint('[AddressService] setDefaultAddress error: $e');
      return false;
    }
  }
}