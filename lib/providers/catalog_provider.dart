import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/product_service.dart';

enum ProductSortOption {
  relevance,
  priceLowToHigh,
  priceHighToLow,
  discount,
}

class CatalogProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _searchResults = [];
  List<CategoryModel> _categories = [];
  String _selectedCategorySlug = 'all';
  String _searchQuery = '';
  ProductSortOption _sortOption = ProductSortOption.relevance;
  final Set<String> _wishlistProductIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get allProducts => _allProducts;
  List<CategoryModel> get categories => _categories;
  String get selectedCategorySlug => _selectedCategorySlug;
  String get searchQuery => _searchQuery;
  ProductSortOption get sortOption => _sortOption;
  Set<String> get wishlistProductIds => _wishlistProductIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CatalogProvider() {
    loadCatalog();
  }

  Future<void> loadCatalog({String? storeId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _productService.fetchProducts(storeId: storeId, limit: 100),
        _productService.fetchCategories(),
      ]);

      _allProducts = results[0] as List<ProductModel>;
      _categories = results[1] as List<CategoryModel>;
      _isLoading = false;
    } catch (e) {
      _errorMessage = 'Failed to load products. Please check your connection.';
      _isLoading = false;
    }
    notifyListeners();
  }

  bool _isFetchingMore = false;
  bool get isFetchingMore => _isFetchingMore;

  Future<void> loadMoreProducts({String? storeId, String? categoryId}) async {
    if (_isFetchingMore || _isLoading) return;
    _isFetchingMore = true;
    notifyListeners();

    try {
      final moreProducts = await _productService.fetchProducts(
        storeId: storeId,
        categoryId: categoryId,
        limit: 100,
        offset: _allProducts.length,
      );

      if (moreProducts.isNotEmpty) {
        // Prevent duplicates
        final existingIds = _allProducts.map((p) => p.id).toSet();
        final newProducts = moreProducts.where((p) => !existingIds.contains(p.id)).toList();
        _allProducts.addAll(newProducts);
      }
    } catch (e) {
      debugPrint('[CatalogProvider] loadMoreProducts error: $e');
    }

    _isFetchingMore = false;
    notifyListeners();
  }

  List<ProductModel> get searchResults => _searchResults;

  void selectCategory(String slug) {
    _selectedCategorySlug = slug;
    _searchQuery = '';
    _searchResults.clear();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults.clear();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setSearchQuery(String query) async {
    final clean = query.trim();
    _searchQuery = clean;
    if (clean.isEmpty) {
      _searchResults.clear();
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    // 1. Sub-second instant search on in-memory catalog
    final q = clean.toLowerCase();
    _searchResults = _allProducts.where((p) =>
      p.name.toLowerCase().contains(q) ||
      (p.brand != null && p.brand!.toLowerCase().contains(q)) ||
      p.categoryName.toLowerCase().contains(q) ||
      (p.description != null && p.description!.toLowerCase().contains(q))
    ).toList();
    _isLoading = true;
    notifyListeners();

    // 2. Query whole database in Supabase
    try {
      final dbResults = await _productService.searchProducts(clean);
      if (_searchQuery == clean) {
        final existingIds = _searchResults.map((p) => p.id).toSet();
        for (final item in dbResults) {
          if (!existingIds.contains(item.id)) {
            _searchResults.add(item);
          }
        }
      }
    } catch (e) {
      debugPrint('[CatalogProvider] remote search error: $e');
    } finally {
      if (_searchQuery == clean) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void setSortOption(ProductSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void toggleWishlist(String productId) {
    if (_wishlistProductIds.contains(productId)) {
      _wishlistProductIds.remove(productId);
    } else {
      _wishlistProductIds.add(productId);
    }
    notifyListeners();
  }

  bool isWishlisted(String productId) => _wishlistProductIds.contains(productId);

  List<ProductModel> get filteredProducts {
    List<ProductModel> list = _searchQuery.trim().isNotEmpty 
        ? List.from(_searchResults) 
        : List.from(_allProducts);

    // Filter out products with less than 5 stock
    list = list.where((p) => p.stockQuantity >= 5).toList();

    // 1. Filter by category
    if (_selectedCategorySlug != 'all') {
      final categoryMatches = list.where((p) => p.categorySlug == _selectedCategorySlug).toList();
      // If the category has exact matches, show them; otherwise fallback to all products
      if (categoryMatches.isNotEmpty) {
        list = categoryMatches;
      }
    }

    // 2. Sort
    switch (_sortOption) {
      case ProductSortOption.priceLowToHigh:
        list.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
      case ProductSortOption.priceHighToLow:
        list.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
        break;
      case ProductSortOption.discount:
        list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
        break;
      case ProductSortOption.relevance:
        break;
    }

    return list;
  }

  List<ProductModel> get popularProducts {
    if (_allProducts.isEmpty) return [];
    final inStockList = _allProducts.where((p) => p.stockQuantity >= 5).toList();
    final sorted = List<ProductModel>.from(inStockList)
      ..sort((a, b) {
        final r = b.rating.compareTo(a.rating);
        if (r != 0) return r;
        return b.discountPercent.compareTo(a.discountPercent);
      });
    return sorted.take(8).toList();
  }

  List<ProductModel> get discountedProducts {
    return _allProducts.where((p) => p.stockQuantity >= 5 && p.discountPercent > 0).toList();
  }
}
