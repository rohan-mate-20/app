import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import 'supabase_service.dart';

class ProductService {
  final _supabase = SupabaseService.client;

  /// Fetch active products with optional pagination and category filtering
  Future<List<ProductModel>> fetchProducts({
    String? storeId,
    String? categoryId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('products')
          .select('''
            *,
            categories ( id, name ),
            inventory ( store_id, stock_quantity )
          ''')
          .eq('active', true);

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      final response = await query
          .order('name', ascending: true)
          .range(offset, offset + limit - 1);

      final list = response as List;
      return list
          .map((item) => ProductModel.fromJson(item, storeId: storeId))
          .where((product) => product.stockQuantity >= 5)
          .toList();
    } catch (e) {
      debugPrint('[ProductService] fetchProducts error: $e');
      return [];
    }
  }

  /// Fetch active top-level categories
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('name');

      final list = response as List;
      return list
          .where((item) => item['parent_id'] == null)
          .map((item) => CategoryModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('[ProductService] fetchCategories error: $e');
      return [];
    }
  }

  /// Search products across whole database with fallback
  Future<List<ProductModel>> searchProducts(String query, {String? storeId}) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];
    try {
      final response = await _supabase
          .from('products')
          .select('''
            *,
            categories ( id, name ),
            inventory ( store_id, stock_quantity )
          ''')
          .eq('active', true)
          .or('name.ilike.%$clean%,description.ilike.%$clean%,brand.ilike.%$clean%')
          .order('name', ascending: true)
          .limit(100);

      final list = response as List;
      return list
          .map((item) => ProductModel.fromJson(item, storeId: storeId))
          .where((product) => product.stockQuantity >= 5)
          .toList();
    } catch (e) {
      debugPrint('[ProductService] searchProducts or query error, attempting name fallback: $e');
      try {
        final fallback = await _supabase
            .from('products')
            .select('''
              *,
              categories ( id, name ),
              inventory ( store_id, stock_quantity )
            ''')
            .eq('active', true)
            .ilike('name', '%$clean%')
            .order('name', ascending: true)
            .limit(100);

        final list = fallback as List;
        return list
            .map((item) => ProductModel.fromJson(item, storeId: storeId))
            .where((product) => product.stockQuantity >= 5)
            .toList();
      } catch (e2) {
        debugPrint('[ProductService] searchProducts fallback error: $e2');
        return [];
      }
    }
  }
}