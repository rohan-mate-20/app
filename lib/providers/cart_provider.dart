import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

import '../services/cart_service.dart';
import '../services/delivery_service.dart';

class CartProvider with ChangeNotifier {
  static const String _localCartKey = 'kmart_local_cart_items_v1';
  final CartService _cartService = CartService();

  List<CartItemModel> _items = [];
  String? _dbCartId;
  bool _isLoading = false;
  int _completedDeliveriesCount = 0;

  CartProvider() {
    _loadLocalCart();
  }

  Future<void> _loadLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_localCartKey);
      if (savedJson != null && savedJson.trim().isNotEmpty) {
        final List decoded = jsonDecode(savedJson);
        final loaded = decoded
            .map((item) => CartItemModel.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.product.id.trim().isNotEmpty)
            .toList();
        if (loaded.isNotEmpty && _items.isEmpty) {
          _items = loaded;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[CartProvider] _loadLocalCart error: $e');
    }
  }

  Future<void> _saveLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _items.map((it) => it.toJson()).toList();
      await prefs.setString(_localCartKey, jsonEncode(list));
    } catch (e) {
      debugPrint('[CartProvider] _saveLocalCart error: $e');
    }
  }

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
    final cleanId = productId.trim();
    if (cleanId.isEmpty) return 0;
    final index = _items.indexWhere((i) => i.product.id.trim() == cleanId);
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
          // Merge db items into local cart if not already present
          for (final dbItem in dbItems) {
            final idx = _items.indexWhere(
              (it) => it.product.id.trim() == dbItem.product.id.trim(),
            );
            if (idx < 0) {
              _items.add(dbItem);
            }
          }
        }
        // Sync any items currently in local cart to DB
        for (final item in _items) {
          _syncDb(item.product.id, item.quantity);
        }
        await _saveLocalCart();
      }
    } catch (e) {
      debugPrint('[CartProvider] initForCustomer error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void addToCart(ProductModel product, {int quantity = 1}) {
    final cleanId = product.id.trim();
    final index = _items.indexWhere((i) => i.product.id.trim() == cleanId);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItemModel(product: product, quantity: quantity));
    }
    _syncDb(cleanId, getQuantity(cleanId));
    _saveLocalCart();
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    final cleanId = productId.trim();
    final index = _items.indexWhere((i) => i.product.id.trim() == cleanId);
    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
      _syncDb(cleanId, newQuantity);
      _saveLocalCart();
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    final cleanId = productId.trim();
    _items.removeWhere((i) => i.product.id.trim() == cleanId);
    _syncDb(cleanId, 0);
    _saveLocalCart();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _saveLocalCart();
    if (_dbCartId != null) {
      _cartService.clearCart(_dbCartId!);
    }
    notifyListeners();
  }

  void _syncDb(String productId, int qty) async {
    if (_dbCartId != null && productId.trim().isNotEmpty) {
      try {
        await _cartService.syncCartItem(_dbCartId!, productId.trim(), qty);
      } catch (e) {
        debugPrint('[CartProvider] _syncDb error: $e');
      }
    }
  }
}