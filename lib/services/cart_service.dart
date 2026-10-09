import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import 'supabase_service.dart';

class CartService {
  final _supabase = SupabaseService.client;

  Future<String?> getOrCreateCartId(String customerId) async {
    if (customerId.isEmpty) return null;
    try {
      final existing = await _supabase
          .from('carts')
          .select('id')
          .eq('customer_id', customerId)
          .maybeSingle();

      if (existing != null && existing['id'] != null) {
        return existing['id'] as String;
      }

      final created = await _supabase
          .from('carts')
          .insert({'customer_id': customerId})
          .select('id')
          .single();

      return created['id'] as String;
    } catch (e) {
      debugPrint('[CartService] getOrCreateCartId error: $e');
      return null;
    }
  }

  Future<List<CartItemModel>> loadCartItems(String cartId) async {
    if (cartId.isEmpty) return [];
    try {
      final response = await _supabase
          .from('cart_items')
          .select('''
            quantity,
            product_id,
            products (
              *,
              categories ( name )
            )
          ''')
          .eq('cart_id', cartId);

      final list = response as List;
      final List<CartItemModel> items = [];
      for (final item in list) {
        if (item['products'] != null) {
          items.add(
            CartItemModel(
              product: ProductModel.fromJson(item['products']),
              quantity: (item['quantity'] as num?)?.toInt() ?? 1,
            ),
          );
        }
      }
      return items;
    } catch (e) {
      debugPrint('[CartService] loadCartItems error: $e');
    }
    return [];
  }

  Future<void> syncCartItem(String cartId, String productId, int quantity) async {
    if (cartId.isEmpty || productId.isEmpty) return;
    try {
      if (quantity <= 0) {
        await _supabase
            .from('cart_items')
            .delete()
            .eq('cart_id', cartId)
            .eq('product_id', productId);
      } else {
        await _supabase.from('cart_items').upsert(
          {
            'cart_id': cartId,
            'product_id': productId,
            'quantity': quantity,
          },
          onConflict: 'cart_id,product_id',
        );
      }
    } catch (e) {
      debugPrint('[CartService] syncCartItem error: $e');
    }
  }

  Future<void> clearCart(String cartId) async {
    if (cartId.isEmpty) return;
    try {
      await _supabase.from('cart_items').delete().eq('cart_id', cartId);
    } catch (e) {
      debugPrint('[CartService] clearCart error: $e');
    }
  }

  /// Synchronize all local cart items to the database cart_items table
  Future<void> syncCartToDatabase({
    required String cartId,
    required List<Map<String, dynamic>> items,
  }) async {
    if (cartId.isEmpty) return;
    try {
      await _supabase.from('cart_items').delete().eq('cart_id', cartId);
      if (items.isEmpty) return;
      final rows = items
          .map((item) => {
                'cart_id': cartId,
                'product_id': item['productId'],
                'quantity': item['quantity'],
              })
          .toList();
      await _supabase.from('cart_items').insert(rows);
    } catch (e) {
      debugPrint('[CartService] syncCartToDatabase note: $e');
    }
  }
}