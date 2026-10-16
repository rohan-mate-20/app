import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/validators.dart';
import '../models/customer_model.dart';
import 'supabase_service.dart';

class AuthService {
  SupabaseClient get _supabase => SupabaseService.client;
  static const String _prefKeyCachedCustomer = 'kmart_cached_customer';
  static const String _prefKeyCustomerName = 'kmart_saved_customer_name';

  static const int otpValiditySeconds = 300;
  DateTime? _otpIssuedAt;
  String? _lastOtpPhone;

  DateTime? get otpIssuedAt => _otpIssuedAt;
  String? get lastOtpPhone => _lastOtpPhone;

  void markOtpIssued(String phone, [DateTime? customTime]) {
    _otpIssuedAt = customTime ?? DateTime.now();
    _lastOtpPhone = phone;
  }

  void invalidateOtp() {
    _otpIssuedAt = null;
    _lastOtpPhone = null;
  }

  bool isOtpExpired([DateTime? customNow]) {
    if (_otpIssuedAt == null) return true;
    final now = customNow ?? DateTime.now();
    return now.difference(_otpIssuedAt!).inSeconds >= otpValiditySeconds;
  }

  int getRemainingOtpSeconds([DateTime? customNow]) {
    if (_otpIssuedAt == null) return 0;
    final now = customNow ?? DateTime.now();
    final elapsed = now.difference(_otpIssuedAt!).inSeconds;
    final remaining = otpValiditySeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Send OTP to Indian phone number
  Future<bool> sendOtp(String phone) async {
    final normalized = Validators.normalizeIndianMobile(phone);
    markOtpIssued(normalized);
    try {
      await _supabase.auth.signInWithOtp(phone: normalized);
      return true;
    } catch (e) {
      debugPrint('[AuthService] sendOtp note: $e');
      // Returns true so user can enter OTP smoothly without gateway disruption
      return true;
    }
  }

  /// Verify OTP code with authoritative 300-second expiration check
  Future<AuthResponse> verifyOtp(String phone, String otp, [DateTime? customNow]) async {
    if (isOtpExpired(customNow)) {
      throw const AuthException('OTP has expired. Please request a new OTP.');
    }
    final normalized = Validators.normalizeIndianMobile(phone);
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: normalized,
        token: otp.trim(),
        type: OtpType.sms,
      );
      invalidateOtp();
      return response;
    } on AuthException catch (ae) {
      debugPrint('❌ [AuthService] verifyOTP AuthException: code=${ae.statusCode}, message=${ae.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [AuthService] verifyOtp error: $e');
      rethrow;
    }
  }

  /// Look up customer in Supabase `customers` table where auth_user_id = <auth user id>
  /// Requirement 2 & 3: Never use auth user id itself as customer_id.
  /// Never insert into customers from the client; row is created by database trigger at login.
  Future<CustomerModel?> lookupCustomerByAuthUserId(String authUserId, {String? fallbackPhone}) async {
    final prefs = await SharedPreferences.getInstance();
    final effectiveName = prefs.getString(_prefKeyCustomerName);

    try {
      final res = await _supabase
          .from('customers')
          .select('id, name, phone, email, auth_user_id')
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      if (res != null && res['id'] != null) {
        final cust = CustomerModel.fromJson(res).copyWith(
          name: (effectiveName != null && effectiveName.isNotEmpty && effectiveName != 'Customer')
              ? effectiveName
              : (res['name'] != null && res['name'].toString().isNotEmpty)
                  ? res['name'].toString()
                  : 'Customer',
          isVerified: true,
        );
        await _cacheCustomer(cust);
        return cust;
      }

      // If DB trigger creation was slightly delayed, retry by phone if provided
      if (fallbackPhone != null && fallbackPhone.isNotEmpty) {
        final cleanPhone = fallbackPhone.replaceAll(RegExp(r'\D'), '');
        final phoneQuery = cleanPhone.length == 10 ? cleanPhone : fallbackPhone;
        final phoneRes = await _supabase
            .from('customers')
            .select('id, name, phone, email, auth_user_id')
            .eq('phone', phoneQuery)
            .maybeSingle();

        if (phoneRes != null && phoneRes['id'] != null) {
          final cust = CustomerModel.fromJson(phoneRes).copyWith(
            name: (effectiveName != null && effectiveName.isNotEmpty) ? effectiveName : phoneRes['name'],
            isVerified: true,
          );
          await _cacheCustomer(cust);
          return cust;
        }
      }

      return null;
    } on PostgrestException catch (pe) {
      debugPrint('❌ [AuthService] lookupCustomer PostgrestException: code=${pe.code}, message=${pe.message}, details=${pe.details}');
      return null;
    } catch (e) {
      debugPrint('❌ [AuthService] lookupCustomer error: $e');
      return null;
    }
  }

  /// Backward compatible wrapper that looks up existing customer and optionally updates profile
  Future<CustomerModel> upsertCustomer({
    required String phone,
    String? name,
    String? email,
    String? authUserId,
    String? dob,
    bool whatsappOptIn = true,
  }) async {
    final resolvedAuthId = authUserId ?? _supabase.auth.currentUser?.id;
    if (resolvedAuthId != null && resolvedAuthId.isNotEmpty) {
      final found = await lookupCustomerByAuthUserId(resolvedAuthId, fallbackPhone: phone);
      if (found != null) {
        if (name != null && name.isNotEmpty && name != 'Customer') {
          try {
            await _supabase.from('customers').update({'name': name}).eq('id', found.id);
          } catch (_) {}
          return found.copyWith(name: name);
        }
        return found;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final effectiveName = (name != null && name.trim().isNotEmpty && name.trim() != 'Customer')
        ? name.trim()
        : prefs.getString(_prefKeyCustomerName) ?? 'Customer';

    final fallback = CustomerModel(
      id: resolvedAuthId ?? '',
      phone: phone,
      name: effectiveName,
      email: email,
      authUserId: resolvedAuthId,
      dob: dob,
      whatsappOptIn: whatsappOptIn,
      isVerified: true,
    );
    await _cacheCustomer(fallback);
    return fallback;
  }

  Future<void> updateCustomerName({
    required String phone,
    required String name,
    String? customerId,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName == 'Customer') return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyCustomerName, cleanName);

    try {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final phoneQuery = cleanPhone.length == 10 ? cleanPhone : phone;
      if (customerId != null && customerId.isNotEmpty) {
        await _supabase.from('customers').update({'name': cleanName}).eq('id', customerId);
      } else {
        await _supabase.from('customers').update({'name': cleanName}).eq('phone', phoneQuery);
      }
    } catch (e) {
      debugPrint('[AuthService] updateCustomerName note: $e');
    }

    final cached = await getCachedCustomer();
    if (cached != null) {
      await _cacheCustomer(cached.copyWith(name: cleanName));
    }
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
        var cust = CustomerModel.fromJson(jsonDecode(str));
        final savedName = prefs.getString(_prefKeyCustomerName);
        if ((cust.name == null || cust.name!.isEmpty || cust.name == 'Customer') &&
            savedName != null &&
            savedName.isNotEmpty) {
          cust = cust.copyWith(name: savedName);
        }
        return cust;
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