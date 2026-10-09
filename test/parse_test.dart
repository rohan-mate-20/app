import 'dart:convert';
import 'package:kmart_customer/models/product_model.dart';

void main() {
  final jsonStr = '''
  {
    "id": "41e366a7-7955-412b-b221-a91528874734",
    "sku": "5945",
    "barcode": null,
    "name": "LASER ULTRA SNAP & LOCK",
    "brand": "My Store",
    "category_id": null,
    "description": null,
    "mrp": 20,
    "selling_price": 20,
    "tax_percent": 0,
    "weight_unit": null,
    "image_url": null,
    "shopify_product_id": "15265602109803",
    "shopify_variant_id": "53974725296491",
    "active": true,
    "created_at": "2026-10-08T13:01:43.090828+00:00",
    "updated_at": "2026-10-08T13:01:43.023+00:00",
    "last_synced_run": "51f677ec-f05d-4766-b48b-3c7e3349ae8c",
    "categories": null,
    "inventory": [{"store_id": "458cbfde-68fd-4e71-86c7-a12a4cecad4d", "stock_quantity": 0}]
  }
  ''';

  try {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final p = ProductModel.fromJson(map);
    print('Product successfully parsed: ${p.name}, mrp: ${p.mrp}, price: ${p.sellingPrice}, inStock: ${p.inStock}');
  } catch (e, st) {
    print('Error parsing product: $e');
    print(st);
  }
}
