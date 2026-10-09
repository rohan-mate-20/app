import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentHelper {
  static void openWebCheckout({
    required Map<String, dynamic> options,
    required String defaultOrderId,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
  }) {
    // Stub for non-web platforms; native Razorpay plugin is used instead
  }
}
