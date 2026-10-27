import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import 'supabase_service.dart';

class ProductService {
  final _supabase = SupabaseService.client;

  // High-concurrency caching layer to protect database under 10k+ concurrent users
  static List<CategoryModel>? _cachedCategories;
  static DateTime? _categoriesCacheTime;
  static const Duration _categoriesTtl = Duration(minutes: 15);

  static final Map<String, List<ProductModel>> _cachedProducts = {};
  static final Map<String, DateTime> _productsCacheTime = {};
  static const Duration _productsTtl = Duration(minutes: 5);

  /// Fetch active products with optional pagination, category filtering, and caching
  Future<List<ProductModel>> fetchProducts({
    String? storeId,
    String? categoryId,
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${storeId ?? "all"}_${categoryId ?? "all"}_${limit}_$offset';

    // Serve from cache if fresh and not force-refreshing
    if (!forceRefresh && _cachedProducts.containsKey(cacheKey)) {
      final cachedAt = _productsCacheTime[cacheKey];
      if (cachedAt != null && DateTime.now().difference(cachedAt) < _productsTtl) {
        return _cachedProducts[cacheKey]!;
      }
    }

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
          .range(offset, offset + limit - 1)
          .timeout(const Duration(seconds: 10));

      final list = response as List;
      final products = list
          .map((item) => ProductModel.fromJson(item, storeId: storeId))
          .where((product) => product.stockQuantity >= 5)
          .toList();

      if (products.isNotEmpty) {
        _cachedProducts[cacheKey] = products;
        _productsCacheTime[cacheKey] = DateTime.now();
      }

      return products;
    } catch (e) {
      debugPrint('[ProductService] fetchProducts error: $e');
      // If error or timeout, return stale cache if available
      if (_cachedProducts.containsKey(cacheKey)) {
        return _cachedProducts[cacheKey]!;
      }
      return [];
    }
  }

  /// Fetch active top-level categories with TTL caching
  Future<List<CategoryModel>> fetchCategories({bool forceRefresh = false}) async {
    // Check in-memory cache
    if (!forceRefresh && _cachedCategories != null && _categoriesCacheTime != null) {
      if (DateTime.now().difference(_categoriesCacheTime!) < _categoriesTtl) {
        return _cachedCategories!;
      }
    }

    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('name')
          .timeout(const Duration(seconds: 10));

      final list = response as List;
      final categories = list
          .where((item) => item['parent_id'] == null)
          .map((item) => CategoryModel.fromJson(item))
          .toList();

      if (categories.isNotEmpty) {
        _cachedCategories = categories;
        _categoriesCacheTime = DateTime.now();
      }

      return categories;
    } catch (e) {
      debugPrint('[ProductService] fetchCategories error: $e');
      // Fallback to cached categories during connection spikes
      if (_cachedCategories != null && _cachedCategories!.isNotEmpty) {
        return _cachedCategories!;
      }
      return [];
    }
  }

  /// Invalidate all memory caches (called upon pull-to-refresh)
  static void clearCache() {
    _cachedCategories = null;
    _categoriesCacheTime = null;
    _cachedProducts.clear();
    _productsCacheTime.clear();
  }

  /// Search products across whole database with fallback and timeout
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
          .limit(100)
          .timeout(const Duration(seconds: 8));

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
            .limit(100)
            .timeout(const Duration(seconds: 8));

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