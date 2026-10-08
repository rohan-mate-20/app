import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../models/delivery_settings_model.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();

  List<CartItemModel> _items = [];
  String? _dbCartId;
  String? _appliedCoupon;
  double _couponDiscount = 0.0;
  bool _isLoading = false;

  List<CartItemModel> get items => _items;
  int get itemCount => _items.fold(0, (sum, it) => sum + it.quantity);
  bool get isEmpty => _items.isEmpty;
  String? get appliedCoupon => _appliedCoupon;
  double get couponDiscount => _couponDiscount;
  bool get isLoading => _isLoading;

  /// Subtotal (sum of selling prices)
  double get itemTotal => _items.fold(0.0, (sum, it) => sum + it.lineTotal);

  /// MRP Total
  double get mrpTotal => _items.fold(0.0, (sum, it) => sum + it.lineMrpTotal);

  /// Total discount saved
  double get totalSavings => (mrpTotal - itemTotal) + _couponDiscount;

  /// Calculate Delivery Fee dynamically
  double calculateDeliveryFee(DeliverySettingsModel settings, {int pastOrderCount = 0}) {
    if (isEmpty) return 0.0;
    if (itemTotal >= 2000) return 0.0;
    return settings.calculateFee(itemTotal, pastOrderCount);
  }

  /// Grand total
  double calculateGrandTotal(DeliverySettingsModel settings, {int pastOrderCount = 0}) {
    if (isEmpty) return 0.0;
    final delFee = calculateDeliveryFee(settings, pastOrderCount: pastOrderCount);
    final total = itemTotal + delFee - _couponDiscount;
    return total > 0 ? total : 0.0;
  }

  int getQuantity(String productId) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    return index >= 0 ? _items[index].quantity : 0;
  }

  Future<void> initForCustomer(String customerId) async {
    if (customerId.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      _dbCartId = await _cartService.getOrCreateCartId(customerId);
      if (_dbCartId != null) {
        final dbItems = await _cartService.loadCartItems(_dbCartId!);
        if (dbItems.isNotEmpty) {
          _items = dbItems;
        }
      }
    } catch (e) {
      debugPrint('[CartProvider] initForCustomer error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void addToCart(ProductModel product, {int quantity = 1}) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItemModel(product: product, quantity: quantity));
    }
    _syncDb(product.id, getQuantity(product.id));
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
      _syncDb(productId, newQuantity);
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    _syncDb(productId, 0);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _appliedCoupon = null;
    _couponDiscount = 0.0;
    if (_dbCartId != null) {
      _cartService.clearCart(_dbCartId!);
    }
    notifyListeners();
  }

  void _syncDb(String productId, int qty) {
    if (_dbCartId != null) {
      _cartService.syncCartItem(_dbCartId!, productId, qty);
    }
  }

  Map<String, dynamic> applyCoupon(String code) {
    final clean = code.trim().toUpperCase();
    if (clean == 'KMART50') {
      if (itemTotal < 250) {
        return {'success': false, 'message': 'Min. order value for KMART50 is ₹250'};
      }
      _appliedCoupon = 'KMART50';
      _couponDiscount = 50.0;
      notifyListeners();
      return {'success': true, 'message': 'Coupon KMART50 applied! ₹50 OFF'};
    } else if (clean == 'WELCOME10') {
      _appliedCoupon = 'WELCOME10';
      _couponDiscount = (itemTotal * 0.10).roundToDouble();
      notifyListeners();
      return {'success': true, 'message': 'Coupon WELCOME10 applied! 10% OFF'};
    } else if (clean == 'FREEDEL') {
      _appliedCoupon = 'FREEDEL';
      _couponDiscount = 40.0;
      notifyListeners();
      return {'success': true, 'message': 'Free Delivery Coupon Applied!'};
    }
    return {'success': false, 'message': 'Invalid coupon code'};
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _couponDiscount = 0.0;
    notifyListeners();
  }
}