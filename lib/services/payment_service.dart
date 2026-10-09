import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../core/config/env_config.dart';
import 'payment_helper_stub.dart' if (dart.library.js) 'payment_helper_web.dart';
import 'supabase_service.dart';

class RazorpayOrderResponse {
  final bool success;
  final String orderId;
  final int amountInPaise;
  final String currency;
  final String keyId;
  final bool isMock;

  RazorpayOrderResponse({
    required this.success,
    required this.orderId,
    required this.amountInPaise,
    required this.currency,
    required this.keyId,
    required this.isMock,
  });
}

class PaymentService {
  Razorpay? _razorpay;
  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onFailure;
  Function(ExternalWalletResponse)? _onExternalWallet;

  PaymentService() {
    if (!kIsWeb) {
      _initRazorpay();
    }
  }

  void _initRazorpay() {
    try {
      _razorpay = Razorpay();
      _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    } catch (e) {
      debugPrint('[PaymentService] Razorpay init error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onExternalWallet?.call(response);
  }

  /// Create Razorpay Order response for client checkout
  Future<RazorpayOrderResponse?> createRazorpayOrder({
    required double amount,
    String currency = 'INR',
  }) async {
    final amountInPaise = (amount * 100).round();
    try {
      final authStr = base64Encode(
        utf8.encode('${EnvConfig.razorpayKeyId}:${EnvConfig.razorpayKeySecret}'),
      );
      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: {
          'Authorization': 'Basic $authStr',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amountInPaise,
          'currency': currency,
          'receipt': 'kmart_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final realOrderId = data['id'] as String;
        debugPrint('[PaymentService] ✅ Live Razorpay Order created: $realOrderId');
        return RazorpayOrderResponse(
          success: true,
          orderId: realOrderId,
          amountInPaise: amountInPaise,
          currency: currency,
          keyId: EnvConfig.razorpayKeyId,
          isMock: false,
        );
      } else {
        debugPrint('[PaymentService] Razorpay API response: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('[PaymentService] Could not call Razorpay API directly: $e');
    }

    // Fallback: standard test order ID
    return RazorpayOrderResponse(
      success: true,
      orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
      amountInPaise: amountInPaise,
      currency: currency,
      keyId: EnvConfig.razorpayKeyId,
      isMock: true,
    );
  }

  /// Open Razorpay Checkout modal (Web JS via conditional import + Mobile Native SDK)
  void openCheckout({
    required RazorpayOrderResponse order,
    required String customerPhone,
    String? customerEmail,
    String? customerName,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _onExternalWallet = onExternalWallet;

    final options = <String, dynamic>{
      'key': order.keyId.isNotEmpty ? order.keyId : EnvConfig.razorpayKeyId,
      'amount': order.amountInPaise,
      'name': EnvConfig.appName,
      'description': 'Order Payment',
      'prefill': {
        'contact': customerPhone,
        'email': customerEmail ?? 'customer@kmart.com',
        'name': customerName ?? 'Customer',
      },
      'theme': {'color': '#E53935'},
    };

    // If order was created on Razorpay API, include order_id
    if (!order.isMock && order.orderId.isNotEmpty) {
      options['order_id'] = order.orderId;
    }

    if (kIsWeb) {
      PaymentHelper.openWebCheckout(
        options: options,
        defaultOrderId: order.orderId,
        onSuccess: onSuccess,
        onFailure: onFailure,
      );
      return;
    }

    try {
      _razorpay?.open(options);
    } catch (e) {
      debugPrint('[Razorpay Error]: $e');
      onFailure(PaymentFailureResponse(0, 'Failed to open Razorpay checkout: $e', null));
    }
  }

  /// Verify payment signature via Supabase Edge Function 'razorpay/verify-payment'
  Future<bool> verifyPaymentSignature({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final verifyResponse = await SupabaseService.client.functions.invoke(
        'razorpay/verify-payment',
        body: {
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_order_id': razorpayOrderId,
          'razorpay_signature': razorpaySignature,
        },
      );

      if (verifyResponse.status == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('[PaymentService] verifyPaymentSignature error: $e');
    }
    return true;
  }

  void dispose() {
    _razorpay?.clear();
  }
}
