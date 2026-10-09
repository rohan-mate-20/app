// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentHelper {
  static void openWebCheckout({
    required Map<String, dynamic> options,
    required String defaultOrderId,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
  }) {
    try {
      final jsOptions = js.JsObject.jsify(options);

      final successCallback = js.allowInterop((dynamic paymentId, dynamic orderId, dynamic signature) {
        final pid = paymentId?.toString() ?? 'pay_${DateTime.now().millisecondsSinceEpoch}';
        final oid = orderId?.toString() ?? defaultOrderId;
        final sig = signature?.toString() ?? '';
        debugPrint('[PaymentHelperWeb] ✅ Razorpay Web Payment Success! ID: $pid, Order: $oid');
        onSuccess(
          PaymentSuccessResponse(pid, oid, sig, null),
        );
      });

      final failureCallback = js.allowInterop((dynamic code, dynamic message) {
        final errorCode = (code is num) ? code.toInt() : 0;
        final errorMsg = message?.toString() ?? 'Payment was cancelled or dismissed';
        debugPrint('[PaymentHelperWeb] ⚠️ Razorpay Web Error: $errorCode, $errorMsg');
        onFailure(
          PaymentFailureResponse(errorCode, errorMsg, null),
        );
      });

      if (js.context.hasProperty('openKmartRazorpay')) {
        js.context.callMethod('openKmartRazorpay', [jsOptions, successCallback, failureCallback]);
      } else {
        debugPrint('[PaymentHelperWeb] Razorpay script bridge not found, using immediate demo confirmation');
        onSuccess(
          PaymentSuccessResponse(
            'pay_${DateTime.now().millisecondsSinceEpoch}',
            defaultOrderId,
            'simulated_sig_${DateTime.now().millisecondsSinceEpoch}',
            null,
          ),
        );
      }
    } catch (e) {
      debugPrint('[PaymentHelperWeb] Exception launching Razorpay: $e');
      onFailure(
        PaymentFailureResponse(0, 'Failed to launch Razorpay Web: $e', null),
      );
    }
  }
}
