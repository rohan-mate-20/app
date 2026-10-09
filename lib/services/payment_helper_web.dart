import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentHelper {
  static void openWebCheckout({
    required Map<String, dynamic> options,
    required String defaultOrderId,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
  }) {
    // Web Razorpay checkout simulation / callback handling
    debugPrint('[PaymentHelperWeb] Simulating online checkout for Web demo');
    Future.delayed(const Duration(milliseconds: 1200), () {
      onSuccess(
        PaymentSuccessResponse(
          'pay_${DateTime.now().millisecondsSinceEpoch}',
          defaultOrderId,
          'simulated_sig_${DateTime.now().millisecondsSinceEpoch}',
          null,
        ),
      );
    });
  }
}
