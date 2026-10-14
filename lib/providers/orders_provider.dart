import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../models/address_model.dart';
import '../models/customer_model.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';

class OrdersProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();

  List<OrderModel> _orders = [];
  OrderModel? _activeOrder;
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  OrderModel? get activeOrder => _activeOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Count of qualifying completed deliveries (excludes cancelled and pickup orders)
  int get completedDeliveriesCount {
    return _orders.where((o) {
      final isDelivery = (o.orderType.toUpperCase() != 'PICKUP');
      final notCancelled = o.status.toUpperCase() != 'CANCELLED' && o.status.toUpperCase() != 'FAILED';
      return isDelivery && notCancelled;
    }).length;
  }

  /// Clear all orders and local cache on logout
  Future<void> clearOrders() async {
    _orders = [];
    _activeOrder = null;
    _isLoading = false;
    _errorMessage = null;
    await _orderService.clearLocalCache();
    notifyListeners();
  }

  Future<void> loadOrders(String customerId) async {
    if (customerId.trim().isEmpty) {
      _orders = [];
      _activeOrder = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _orderService.fetchOrders(customerId);
    } catch (e) {
      _errorMessage = 'Failed to load orders.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Place COD Order
  Future<OrderModel?> placeCodOrder({
    required CustomerModel customer,
    required AddressModel address,
    required List<CartItemModel> items,
    required double subtotal,
    required double deliveryFee,
    required double total,
    required String orderType,
    String? deliverySlotId,
    String? scheduledDeliveryDate,
    String? deliverySlotTime,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final order = await _orderService.placeOrder(
        customer: customer,
        address: address,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        paymentMethod: 'COD',
        orderType: orderType,
        deliverySlotId: deliverySlotId,
        scheduledDeliveryDate: scheduledDeliveryDate,
        deliverySlotTime: deliverySlotTime,
      );

      _isLoading = false;
      if (order != null) {
        _activeOrder = order;
        _orders.insert(0, order);
      } else {
        _errorMessage = 'Failed to place order. Please try again.';
      }

      notifyListeners();
      return order;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Place Online Razorpay Order
  Future<void> placeRazorpayOrder({
    required CustomerModel customer,
    required AddressModel address,
    required List<CartItemModel> items,
    required double subtotal,
    required double deliveryFee,
    required double total,
    required String orderType,
    String? deliverySlotId,
    String? scheduledDeliveryDate,
    String? deliverySlotTime,
    required Function(OrderModel order) onSuccess,
    required Function(String error) onFailure,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Create Razorpay order on server
    final razorpayOrder = await _paymentService.createRazorpayOrder(amount: total);
    if (razorpayOrder == null) {
      _isLoading = false;
      _errorMessage = 'Unable to initiate payment gateway';
      notifyListeners();
      onFailure(_errorMessage!);
      return;
    }

    // 2. Open Razorpay Checkout modal
    _paymentService.openCheckout(
      order: razorpayOrder,
      customerPhone: customer.phone,
      customerEmail: customer.email,
      customerName: customer.name,
      onSuccess: (PaymentSuccessResponse res) async {
        // 3. Verify Razorpay signature server-side
        final verified = await _paymentService.verifyPaymentSignature(
          razorpayOrderId: res.orderId ?? razorpayOrder.orderId,
          razorpayPaymentId: res.paymentId ?? 'pay_dummy',
          razorpaySignature: res.signature ?? 'sig_dummy',
        );

        if (!verified) {
          _isLoading = false;
          _errorMessage = 'Payment signature verification failed';
          notifyListeners();
          onFailure(_errorMessage!);
          return;
        }

        // 4. Record order in Supabase
        final order = await _orderService.placeOrder(
          customer: customer,
          address: address,
          items: items,
          subtotal: subtotal,
          deliveryFee: deliveryFee,
          total: total,
          paymentMethod: 'ONLINE',
          orderType: orderType,
          deliverySlotId: deliverySlotId,
          scheduledDeliveryDate: scheduledDeliveryDate,
          deliverySlotTime: deliverySlotTime,
          paymentId: res.paymentId,
        );

        _isLoading = false;
        if (order != null) {
          _activeOrder = order;
          _orders.insert(0, order);
          notifyListeners();
          onSuccess(order);
        } else {
          _errorMessage = 'Payment captured but failed to record order.';
          notifyListeners();
          onFailure(_errorMessage!);
        }
      },
      onFailure: (PaymentFailureResponse res) {
        _isLoading = false;
        _errorMessage = res.message ?? 'Payment cancelled or failed';
        notifyListeners();
        onFailure(_errorMessage!);
      },
    );
  }

  Future<OrderModel?> trackOrder(String orderId) async {
    return _orderService.fetchOrderTracking(orderId);
  }

  void setActiveOrder(OrderModel? order) {
    _activeOrder = order;
    notifyListeners();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }
}