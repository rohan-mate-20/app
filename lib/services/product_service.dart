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

  /// Search products with filter
  Future<List<ProductModel>> searchProducts(String query, {String? storeId}) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _supabase
          .from('products')
          .select('''
            *,
            categories ( id, name ),
            inventory ( store_id, stock_quantity )
          ''')
          .eq('active', true)
          .ilike('name', '%${query.trim()}%');

      final list = response as List;
      return list
          .map((item) => ProductModel.fromJson(item, storeId: storeId))
          .toList();
    } catch (e) {
      debugPrint('[ProductService] searchProducts error: $e');
      return [];
    }
  }
}