import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  CustomerModel? _currentCustomer;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String _phoneNumber = '';
  int _resendCountdown = 30;
  Timer? _countdownTimer;

  CustomerModel? get currentCustomer => _currentCustomer;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String get phoneNumber => _phoneNumber;
  int get resendCountdown => _resendCountdown;
  bool get canResend => _resendCountdown == 0;

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
    _resendCountdown = 30;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        _resendCountdown--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  Future<bool> sendOtp(String phone) async {
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

  Future<bool> verifyOtp(String otp, {String? name, String? email}) async {
    _isLoading = true;
    notifyListeners();

    final authRes = await _authService.verifyOtp(_phoneNumber, otp);
    final authUserId = authRes?.user?.id;

    final customer = await _authService.upsertCustomer(
      phone: _phoneNumber,
      name: name ?? _currentCustomer?.name ?? 'Customer',
      email: email ?? _currentCustomer?.email,
      authUserId: authUserId,
    );

    _currentCustomer = customer.copyWith(isVerified: true);
    _isLoggedIn = true;
    _isLoading = false;
    _countdownTimer?.cancel();
    notifyListeners();
    return true;
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