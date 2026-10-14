import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import 'product_details_screen.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double width;

  const ProductCard({
    super.key,
    required this.product,
    this.width = 165,
  });

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final catalogProvider = context.watch<CatalogProvider>();
    final currentQty = cartProvider.getQuantity(product.id);
    final isWishlisted = catalogProvider.isWishlisted(product.id);

    final rawBrand = product.brand?.trim() ?? '';
    final brandTag = (rawBrand.isNotEmpty && rawBrand.toLowerCase() != 'my store')
        ? rawBrand.toUpperCase()
        : 'K MART';
    final catTag = product.categoryName.trim().isNotEmpty
        ? product.categoryName.trim().toUpperCase()
        : 'GROCERIES';

    final int discount = product.discountPercent > 0
        ? product.discountPercent
        : (product.mrp > product.sellingPrice && product.mrp > 0
            ? (((product.mrp - product.sellingPrice) / product.mrp) * 100).round()
            : 0);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(product: product),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Product Image with Wishlist Heart (fixed 105px)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 105,
                        width: double.infinity,
                        color: AppColors.background,
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryRed.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.shopping_bag_outlined,
                            size: 36,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),

                    // Wishlist Heart Icon at top right
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          catalogProvider.toggleWishlist(product.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isWishlisted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: isWishlisted
                                ? AppColors.primaryRed
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 2. Category & Brand Tag (fixed height 14)
                SizedBox(
                  height: 14,
                  width: double.infinity,
                  child: Text(
                    '$brandTag | $catTag',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A92A6),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // 3. Product Name (fixed height 32, exactly 2 lines allocated)
                SizedBox(
                  height: 32,
                  width: double.infinity,
                  child: Text(
                    product.name.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // 4. Unit (fixed height 16)
                SizedBox(
                  height: 16,
                  width: double.infinity,
                  child: Text(
                    product.weightUnit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // 5. Rating & In Stock row (fixed height 18)
                SizedBox(
                  height: 18,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFEAB308),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          product.inStock ? 'In stock' : 'Out of stock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: product.inStock
                                ? const Color(0xFF16A34A)
                                : AppColors.primaryRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // 6. Price Row (fixed height 22)
                SizedBox(
                  height: 22,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '₹${product.sellingPrice.toStringAsFixed(product.sellingPrice.truncateToDouble() == product.sellingPrice ? 0 : 2)}',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryRed,
                          ),
                        ),
                        if (product.mrp > product.sellingPrice) ...[
                          const SizedBox(width: 4),
                          Text(
                            '₹${product.mrp.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          if (discount > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$discount% OFF',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // 7. Maximum purchase note (fixed height 16)
                const SizedBox(
                  height: 16,
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 12,
                        color: Color(0xFF64748B),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Maximum purchase • 24 units',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 8. Add Button (fixed height 34)
                SizedBox(
                  height: 34,
                  width: double.infinity,
                  child: currentQty == 0
                      ? OutlinedButton(
                          onPressed: () {
                            cartProvider.addToCart(product);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryRed,
                            backgroundColor: const Color(0xFFF8FAFC),
                            side: const BorderSide(
                              color: AppColors.primaryRed,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'ADD +',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                            )
                          : Container(
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  cartProvider.updateQuantity(
                                    product.id,
                                    currentQty - 1,
                                  );
                                },
                              ),
                              Text(
                                '$currentQty',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  cartProvider.updateQuantity(
                                    product.id,
                                    currentQty + 1,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
