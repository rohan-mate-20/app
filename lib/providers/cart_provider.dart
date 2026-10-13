import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

import '../services/cart_service.dart';
import '../services/delivery_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();

  List<CartItemModel> _items = [];
  String? _dbCartId;
  bool _isLoading = false;
  int _completedDeliveriesCount = 0;

  List<CartItemModel> get items => _items;
  int get itemCount => _items.fold(0, (sum, it) => sum + it.quantity);
  bool get isEmpty => _items.isEmpty;
  bool get isLoading => _isLoading;

  /// Handling Fee and Platform Fee (both default to 0.0)
  double get handlingFee => DeliveryPricingService.handlingFee;
  double get platformFee => DeliveryPricingService.platformFee;

  /// Number of completed deliveries for promotion tracking
  int get completedDeliveriesCount => _completedDeliveriesCount;

  void setCompletedDeliveriesCount(int count) {
    _completedDeliveriesCount = count;
    notifyListeners();
  }

  /// Whether customer qualifies for the first 3 free deliveries
  bool isEligibleForFreeDelivery([int? count]) {
    final effective = count ?? _completedDeliveriesCount;
    return effective < 3;
  }

  /// Subtotal (sum of selling prices)
  double get itemTotal => _items.fold(0.0, (sum, it) => sum + it.lineTotal);

  /// MRP Total
  double get mrpTotal => _items.fold(0.0, (sum, it) => sum + it.lineMrpTotal);

  /// Total product discount saved
  double get totalSavings => (mrpTotal - itemTotal) > 0 ? (mrpTotal - itemTotal) : 0.0;

  /// Calculate Delivery Fee using centralized DeliveryPricingService
  double calculateDeliveryFee({bool isPickup = false, int? pastDeliveries}) {
    if (isEmpty) return 0.0;
    return DeliveryPricingService.calculateDeliveryFee(
      subtotal: itemTotal,
      isPickup: isPickup,
      pastEligibleDeliveries: pastDeliveries ?? _completedDeliveriesCount,
    );
  }

  /// Grand total: Subtotal + Delivery + Handling + Platform (Coupons removed)
  double calculateGrandTotal({bool isPickup = false, int? pastDeliveries}) {
    if (isEmpty) return 0.0;
    final delFee = calculateDeliveryFee(
      isPickup: isPickup,
      pastDeliveries: pastDeliveries,
    );
    return DeliveryPricingService.calculatePayableTotal(
      subtotal: itemTotal,
      deliveryFee: delFee,
      productDiscounts: 0.0,
      handling: handlingFee,
      platform: platformFee,
    );
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
}