import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  CustomerModel? _currentCustomer;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String _phoneNumber = '';

  static const int otpValiditySeconds = 300;
  int _otpRemainingSeconds = otpValiditySeconds;
  int _resendCooldown = 30;
  Timer? _countdownTimer;

  CustomerModel? get currentCustomer => _currentCustomer;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String get phoneNumber => _phoneNumber;
  int get resendCountdown => _otpRemainingSeconds;
  int get otpRemainingSeconds => _otpRemainingSeconds;
  int get resendCooldown => _resendCooldown;
  bool get isOtpExpired => _otpRemainingSeconds == 0;
  bool get canResend => (_resendCooldown == 0 || _otpRemainingSeconds == 0) && !_isLoading;

  String get formattedCountdown =>
      '${(_otpRemainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_otpRemainingSeconds % 60).toString().padLeft(2, '0')}';

  AuthProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _isLoading = true;

    final cached = await _authService.getCachedCustomer();
    if (cached != null && cached.isVerified) {
      _currentCustomer = cached;
      _isLoggedIn = true;
      _phoneNumber = cached.phone;
    } else {
      _currentCustomer = null;
      _isLoggedIn = false;
      _phoneNumber = '';
    }

    _isLoading = false;
    notifyListeners();
  }

  void startResendTimer() {
    _countdownTimer?.cancel();
    _otpRemainingSeconds = otpValiditySeconds;
    _resendCooldown = 30;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      bool changed = false;
      if (_otpRemainingSeconds > 0) {
        _otpRemainingSeconds--;
        changed = true;
      }
      if (_resendCooldown > 0) {
        _resendCooldown--;
        changed = true;
      }
      if (changed) {
        notifyListeners();
      }
      if (_otpRemainingSeconds == 0 && _resendCooldown == 0) {
        timer.cancel();
      }
    });
  }

  Future<bool> sendOtp(String phone) async {
    if (_isLoading) return false;
    _isLoading = true;
    _phoneNumber = phone;
    notifyListeners();

    final success = await _authService.sendOtp(phone);
    _isLoading = false;
    if (success) {
      startResendTimer();
    }
    notifyListeners();
    return success;
  }

  Future<bool> verifyOtp(String otp, {String? name, String? email, DateTime? customNow}) async {
    if (_isLoading) return false;

    // Authoritative expiration validation (300 seconds)
    if (_authService.isOtpExpired(customNow)) {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final authRes = await _authService.verifyOtp(_phoneNumber, otp, customNow);
      final authUser = authRes.user;

      if (authUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Requirement 2: customer_id must be customers.id, looked up with:
      // select id from customers where auth_user_id = <auth user id>.
      // Never use the auth user id itself as customer_id.
      // Requirement 3: Never insert into customers from the app.
      final customer = await _authService.lookupCustomerByAuthUserId(authUser.id, fallbackPhone: _phoneNumber);

      if (customer != null) {
        _currentCustomer = customer.copyWith(isVerified: true);
      } else {
        _currentCustomer = CustomerModel(
          id: authUser.id,
          phone: _phoneNumber,
          name: name ?? 'Customer',
          email: email,
          authUserId: authUser.id,
          isVerified: true,
        );
      }

      _isLoggedIn = true;
      _isLoading = false;
      _countdownTimer?.cancel();
      _otpRemainingSeconds = 0;
      notifyListeners();
      return true;
    } on AuthException catch (ae) {
      debugPrint('❌ [AuthProvider] verifyOtp AuthException: code=${ae.statusCode}, message=${ae.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ [AuthProvider] verifyOtp error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({
    required String name,
    String? email,
    String? dob,
    bool whatsappOptIn = true,
  }) async {
    if (_currentCustomer == null) return;
    _isLoading = true;
    notifyListeners();

    final updated = await _authService.upsertCustomer(
      phone: _currentCustomer!.phone,
      name: name,
      email: email,
      authUserId: _currentCustomer!.authUserId,
      dob: dob,
      whatsappOptIn: whatsappOptIn,
    );

    _currentCustomer = updated.copyWith(
      dob: dob,
      whatsappOptIn: whatsappOptIn,
      isVerified: true,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateCustomerName(String name) async {
    final clean = name.trim();
    if (clean.isEmpty || clean == 'Customer') return;
    if (_currentCustomer != null) {
      _currentCustomer = _currentCustomer!.copyWith(name: clean);
      notifyListeners();
      await _authService.updateCustomerName(
        phone: _currentCustomer!.phone,
        name: clean,
        customerId: _currentCustomer!.id,
      );
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentCustomer = null;
    _isLoggedIn = false;
    _phoneNumber = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}