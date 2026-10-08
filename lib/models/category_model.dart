import '../core/constants/app_constants.dart';
import 'product_model.dart';

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String iconUrl;
  final String? parentId;
  final int itemCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconUrl,
    this.parentId,
    this.itemCount = 20,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] ?? 'Category';
    final slug = ProductModel.categoryNameToSlug(name);
    final icon = json['icon_url'] ??
        json['image_url'] ??
        AppConstants.categoryIcons[slug] ??
        AppConstants.genericProductImageFallback;

    return CategoryModel(
      id: json['id'] ?? '',
      name: name,
      slug: slug,
      iconUrl: icon,
      parentId: json['parent_id'],
      itemCount: (json['item_count'] as num?)?.toInt() ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon_url': iconUrl,
      'parent_id': parentId,
    };
  }
}