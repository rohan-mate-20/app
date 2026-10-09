import '../core/constants/app_constants.dart';

class ProductModel {
  final String id;
  final String? sku;
  final String? barcode;
  final String name;
  final String? brand;
  final String? categoryId;
  final String categoryName;
  final String categorySlug;
  final String? description;
  final double mrp;
  final double sellingPrice;
  final int discountPercent;
  final double taxPercent;
  final String weightUnit;
  final String imageUrl;
  final bool active;
  final int stockQuantity;
  final bool inStock;
  final double rating;
  final int reviewCount;
  final List<String> highlights;

  ProductModel({
    required this.id,
    this.sku,
    this.barcode,
    required this.name,
    this.brand,
    this.categoryId,
    required this.categoryName,
    required this.categorySlug,
    this.description,
    required this.mrp,
    required this.sellingPrice,
    required this.discountPercent,
    this.taxPercent = 0,
    required this.weightUnit,
    required this.imageUrl,
    this.active = true,
    this.stockQuantity = 50,
    required this.inStock,
    this.rating = 4.7,
    this.reviewCount = 124,
    this.highlights = const [
      '100% Genuine Branded Pack',
      'Quality Guaranteed',
      'Best Market Price',
    ],
  });

  static String resolveImage(String productName, String? rawUrl) {
    if (rawUrl != null && rawUrl.trim().isNotEmpty) {
      return rawUrl;
    }
    final lower = productName.toLowerCase();
    for (final entry in AppConstants.productImageFallbacks) {
      final keywords = (entry['keywords'] ?? '').split(',');
      if (keywords.any((kw) => lower.contains(kw.trim()))) {
        return entry['url'] ?? AppConstants.genericProductImageFallback;
      }
    }
    return AppConstants.genericProductImageFallback;
  }

  static String categoryNameToSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  factory ProductModel.fromJson(Map<String, dynamic> json, {String? storeId}) {
    final double rawMrp = (json['mrp'] as num?)?.toDouble() ?? 0.0;
    final double rawPrice = (json['selling_price'] as num?)?.toDouble() ?? rawMrp;
    final int discount = (rawMrp > rawPrice && rawMrp > 0)
        ? (((rawMrp - rawPrice) / rawMrp) * 100).round()
        : 0;

    String catName = 'Groceries';
    if (json['categories'] != null && json['categories'] is Map) {
      catName = json['categories']['name'] ?? 'Groceries';
    } else {
      // Intelligently infer category based on product title keywords
      final lowerName = (json['name'] ?? '').toString().toLowerCase();
      if (lowerName.contains('coca') ||
          lowerName.contains('cola') ||
          lowerName.contains('pepsi') ||
          lowerName.contains('drink') ||
          lowerName.contains('juice') ||
          lowerName.contains('tea') ||
          lowerName.contains('coffee') ||
          lowerName.contains('biscuit') ||
          lowerName.contains('cookie') ||
          lowerName.contains('toffee') ||
          lowerName.contains('choco') ||
          lowerName.contains('candy') ||
          lowerName.contains('cashew') ||
          lowerName.contains('wafer') ||
          lowerName.contains('chips') ||
          lowerName.contains('snack')) {
        catName = 'Snacks & Beverages';
      } else if (lowerName.contains('milk') ||
          lowerName.contains('cheese') ||
          lowerName.contains('butter') ||
          lowerName.contains('curd') ||
          lowerName.contains('paneer') ||
          lowerName.contains('ghee') ||
          lowerName.contains('egg') ||
          lowerName.contains('amul')) {
        catName = 'Dairy & Eggs';
      } else if (lowerName.contains('cream') ||
          lowerName.contains('soap') ||
          lowerName.contains('handwash') ||
          lowerName.contains('shampoo') ||
          lowerName.contains('paste') ||
          lowerName.contains('lotion') ||
          lowerName.contains('ponds') ||
          lowerName.contains('lifebuoy') ||
          lowerName.contains('face') ||
          lowerName.contains('beauty')) {
        catName = 'Personal Care';
      } else if (lowerName.contains('lizol') ||
          lowerName.contains('agarbatti') ||
          lowerName.contains('detergent') ||
          lowerName.contains('cleaner') ||
          lowerName.contains('harpic') ||
          lowerName.contains('surf') ||
          lowerName.contains('lock') ||
          lowerName.contains('snap') ||
          lowerName.contains('laser') ||
          lowerName.contains('pooja') ||
          lowerName.contains('dish')) {
        catName = 'Household';
      } else if (lowerName.contains('apple') ||
          lowerName.contains('banana') ||
          lowerName.contains('potato') ||
          lowerName.contains('tomato') ||
          lowerName.contains('onion') ||
          lowerName.contains('vegetable') ||
          lowerName.contains('fruit')) {
        catName = 'Fruits & Vegetables';
      } else {
        catName = 'Groceries';
      }
    }

    int stock = 50;
    if (json['inventory'] != null) {
      if (json['inventory'] is List) {
        final invList = json['inventory'] as List;
        if (storeId != null) {
          final match = invList.firstWhere(
            (inv) => inv is Map && inv['store_id'] == storeId,
            orElse: () => null,
          );
          if (match != null && match is Map) {
            final parsedStock = (match['stock_quantity'] as num?)?.toInt();
            if (parsedStock != null && parsedStock > 0) {
              stock = parsedStock;
            }
          }
        } else {
          final totalStock = invList.fold<int>(0, (sum, inv) {
            if (inv is Map) {
              return sum + ((inv['stock_quantity'] as num?)?.toInt() ?? 0);
            }
            return sum;
          });
          if (totalStock > 0) {
            stock = totalStock;
          }
        }
      } else if (json['inventory'] is Map) {
        final parsedStock = (json['inventory']['stock_quantity'] as num?)?.toInt();
        if (parsedStock != null && parsedStock > 0) {
          stock = parsedStock;
        }
      }
    }

    final prodName = json['name'] ?? 'Grocery Product';
    final img = resolveImage(prodName, json['image_url']);

    return ProductModel(
      id: json['id'] ?? '',
      sku: json['sku'],
      barcode: json['barcode'],
      name: prodName,
      brand: json['brand'] ?? 'K MART',
      categoryId: json['category_id'],
      categoryName: catName,
      categorySlug: categoryNameToSlug(catName),
      description: json['description'] ??
          '$prodName — fresh daily essential available for guaranteed on-time doorstep delivery from K MART.',
      mrp: rawMrp > 0 ? rawMrp : rawPrice,
      sellingPrice: rawPrice,
      discountPercent: discount,
      taxPercent: (json['tax_percent'] as num?)?.toDouble() ?? 0.0,
      weightUnit: json['weight_unit'] ?? '1 unit',
      imageUrl: img,
      active: json['active'] ?? true,
      stockQuantity: stock > 0 ? stock : 50,
      inStock: true,
      rating: 4.7,
      reviewCount: 124,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'category_id': categoryId,
      'description': description,
      'mrp': mrp,
      'selling_price': sellingPrice,
      'tax_percent': taxPercent,
      'weight_unit': weightUnit,
      'image_url': imageUrl,
      'active': active,
    };
  }
}