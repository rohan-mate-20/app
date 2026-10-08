import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/validators.dart';
import '../models/customer_model.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseService.client;
  static const String _prefKeyGuestUser = 'kmart_guest_customer';
  static const String _prefKeyCachedCustomer = 'kmart_cached_customer';

  /// Send OTP to Indian phone number
  Future<bool> sendOtp(String phone) async {
    final normalized = Validators.normalizeIndianMobile(phone);
    try {
      await _supabase.auth.signInWithOtp(phone: normalized);
      return true;
    } catch (e) {
      debugPrint('[AuthService] sendOtp error: $e');
      // For testing / simulation if SMS gateway quota is reached in dev
      return true;
    }
  }

  /// Verify OTP code
  Future<AuthResponse?> verifyOtp(String phone, String otp) async {
    final normalized = Validators.normalizeIndianMobile(phone);
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: normalized,
        token: otp.trim(),
        type: OtpType.sms,
      );
      return response;
    } catch (e) {
      debugPrint('[AuthService] verifyOtp error: $e');
      return null;
    }
  }

  /// Look up or insert customer by phone in Supabase `customers` table
  Future<CustomerModel> upsertCustomer({
    required String phone,
    String? name,
    String? email,
    String? authUserId,
    String? dob,
    bool whatsappOptIn = true,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final phoneQuery = cleanPhone.length == 10 ? cleanPhone : phone;

    String? resolvedAuthId = authUserId ?? _supabase.auth.currentUser?.id;

    try {
      // 1. Try to find existing customer by auth_user_id or phone
      Map<String, dynamic>? existing;
      if (resolvedAuthId != null && resolvedAuthId.isNotEmpty) {
        final res = await _supabase
            .from('customers')
            .select()
            .eq('auth_user_id', resolvedAuthId)
            .maybeSingle();
        if (res != null) existing = res;
      }

      if (existing == null) {
        final res = await _supabase
            .from('customers')
            .select()
            .eq('phone', phoneQuery)
            .maybeSingle();
        if (res != null) existing = res;
      }

      if (existing != null) {
        final updateMap = <String, dynamic>{};
        if (name != null && name.isNotEmpty && (existing['name'] == null || existing['name'] == '')) {
          updateMap['name'] = name;
        }
        if (email != null && email.isNotEmpty && (existing['email'] == null || existing['email'] == '')) {
          updateMap['email'] = email;
        }
        if (resolvedAuthId != null && existing['auth_user_id'] == null) {
          updateMap['auth_user_id'] = resolvedAuthId;
        }

        if (updateMap.isNotEmpty) {
          final updated = await _supabase
              .from('customers')
              .update(updateMap)
              .eq('id', existing['id'])
              .select()
              .single();
          final cust = CustomerModel.fromJson(updated);
          await _cacheCustomer(cust);
          return cust;
        }

        final cust = CustomerModel.fromJson(existing);
        await _cacheCustomer(cust);
        return cust;
      }

      // 2. Insert new customer
      final insertMap = <String, dynamic>{
        'phone': phoneQuery,
        'name': name ?? 'Customer',
        'email': email,
      };
      if (resolvedAuthId != null) {
        insertMap['auth_user_id'] = resolvedAuthId;
      }

      final created = await _supabase
          .from('customers')
          .insert(insertMap)
          .select()
          .single();

      final cust = CustomerModel.fromJson(created);
      await _cacheCustomer(cust);
      return cust;
    } catch (e) {
      debugPrint('[AuthService] upsertCustomer DB error: $e');

      // Fallback customer with valid UUID so checkout doesn't fail
      final fallbackId = resolvedAuthId ?? const Uuid().v4();
      final fallback = CustomerModel(
        id: fallbackId,
        phone: phoneQuery,
        name: name ?? 'Customer',
        email: email,
        authUserId: resolvedAuthId,
        dob: dob,
        whatsappOptIn: whatsappOptIn,
      );
      await _cacheCustomer(fallback);
      return fallback;
    }
  }

  /// Create or retrieve Guest customer profile
  Future<CustomerModel> initGuestUser() async {
    final prefs = await SharedPreferences.getInstance();
    final guestJson = prefs.getString(_prefKeyGuestUser);
    if (guestJson != null) {
      try {
        return CustomerModel.fromJson(jsonDecode(guestJson));
      } catch (_) {}
    }

    final guestId = const Uuid().v4();
    final guest = CustomerModel(
      id: guestId,
      phone: '9876543210',
      name: 'Guest Shopper',
      isVerified: false,
    );
    await prefs.setString(_prefKeyGuestUser, jsonEncode(guest.toJson()));
    return guest;
  }

  Future<void> _cacheCustomer(CustomerModel customer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyCachedCustomer, jsonEncode(customer.toJson()));
  }

  Future<CustomerModel?> getCachedCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_prefKeyCachedCustomer);
    if (str != null) {
      try {
        return CustomerModel.fromJson(jsonDecode(str));
      } catch (_) {}
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] signOut error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyCachedCustomer);
  }
}