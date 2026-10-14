import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.product,
    required this.quantity,
  });

  double get lineTotal => product.sellingPrice * quantity;
  double get lineMrpTotal => product.mrp * quantity;
  double get lineSavings => lineMrpTotal - lineTotal;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> prodMap;
    if (json['product'] is Map) {
      prodMap = Map<String, dynamic>.from(json['product'] as Map);
    } else if (json['products'] is Map) {
      prodMap = Map<String, dynamic>.from(json['products'] as Map);
    } else {
      prodMap = Map<String, dynamic>.from(json);
    }

    if (!prodMap.containsKey('id') && json.containsKey('product_id')) {
      prodMap['id'] = json['product_id'];
    }

    return CartItemModel(
      product: ProductModel.fromJson(prodMap),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': product.id,
      'product': product.toJson(),
      'quantity': quantity,
    };
  }
}