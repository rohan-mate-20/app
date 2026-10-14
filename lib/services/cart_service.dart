import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class CartService {
  SupabaseClient get _supabase => SupabaseService.client;

  /// Requirement 1: Right before a cart write, log: await supabase.auth.getUser().
  /// If there is no user, the customer is not logged in as far as Supabase is concerned.
  Future<User?> _verifyAuthUserBeforeWrite(String operation) async {
    try {
      final userRes = await _supabase.auth.getUser();
      final user = userRes.user ?? _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ [CartService] $operation: No user logged in! Supabase auth session is missing.');
        return null;
      }
      debugPrint('ℹ️ [CartService] $operation: Authenticated user id: ${user.id}');
      return user;
    } on AuthException catch (ae) {
      debugPrint('❌ [CartService] $operation AuthException: code=${ae.statusCode}, message=${ae.message}');
      return null;
    } catch (e) {
      debugPrint('❌ [CartService] $operation auth error: $e');
      return null;
    }
  }

  /// Look up or create a cart for the customer in Supabase `carts` table
  /// Requirement 4: Uses customer's own customers.id
  Future<String?> getOrCreateCartId(String customerId) async {
    if (customerId.isEmpty) return null;

    final user = await _verifyAuthUserBeforeWrite('getOrCreateCartId');
    if (user == null) {
      debugPrint('❌ [CartService] Cannot write cart: customer is not logged in with Supabase.');
      throw Exception('Customer is not logged in as far as Supabase is concerned.');
    }

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
    } on PostgrestException catch (pe) {
      debugPrint('❌ [CartService] getOrCreateCartId PostgrestException: code=${pe.code}, message=${pe.message}, details=${pe.details}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [CartService] getOrCreateCartId error: $e');
      rethrow;
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
    } on PostgrestException catch (pe) {
      debugPrint('❌ [CartService] loadCartItems PostgrestException: code=${pe.code}, message=${pe.message}, details=${pe.details}');
      return [];
    } catch (e) {
      debugPrint('❌ [CartService] loadCartItems error: $e');
      return [];
    }
  }

  Future<void> syncCartItem(String cartId, String productId, int quantity) async {
    if (cartId.isEmpty || productId.isEmpty) return;

    await _verifyAuthUserBeforeWrite('syncCartItem');

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
    } on PostgrestException catch (pe) {
      debugPrint('❌ [CartService] syncCartItem PostgrestException: code=${pe.code}, message=${pe.message}, details=${pe.details}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [CartService] syncCartItem error: $e');
      rethrow;
    }
  }

  Future<void> clearCart(String cartId) async {
    if (cartId.isEmpty) return;

    await _verifyAuthUserBeforeWrite('clearCart');

    try {
      await _supabase.from('cart_items').delete().eq('cart_id', cartId);
    } on PostgrestException catch (pe) {
      debugPrint('❌ [CartService] clearCart PostgrestException: code=${pe.code}, message=${pe.message}, details=${pe.details}');
    } catch (e) {
      debugPrint('❌ [CartService] clearCart error: $e');
    }
  }

  /// Synchronize local cart items directly to the database cart_items table
  Future<void> syncCartToDatabase({
    required String cartId,
    required List<Map<String, dynamic>> items,
  }) async {
    if (cartId.isEmpty) return;

    final user = await _verifyAuthUserBeforeWrite('syncCartToDatabase');
    if (user == null) {
      throw Exception('Customer is not logged in as far as Supabase is concerned.');
    }

    try {
      await _supabase.from('cart_items').delete().eq('cart_id', cartId);
      if (items.isEmpty) return;
      final rows = items
          .map((item) => {
                'cart_id': cartId,
                'product_id': (item['productId'] ?? item['product_id'] ?? item['id'] ?? '').toString().trim(),
                'quantity': item['quantity'] ?? 1,
              })
          .where((r) => (r['product_id'] as String).isNotEmpty)
          .toList();
      if (rows.isNotEmpty) {
        await _supabase.from('cart_items').insert(rows);
      }
    } on PostgrestException catch (pe) {
      debugPrint('❌ [CartService] syncCartToDatabase PostgrestException: code=${pe.code}, message=${pe.message}, details=${pe.details}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [CartService] syncCartToDatabase error: $e');
      rethrow;
    }
  }
}