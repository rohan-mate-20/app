import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import 'product_details_screen.dart';

/// Website-matching product card layout:
/// [Image] → [K MART • CATEGORY] → [Name] → [Weight • In stock] →
/// [₹Price  ₹MRP]  [X% OFF badge] → [ADD +]
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double? width;
  /// If true renders in list-row mode (used by search/list views)
  final bool listMode;

  const ProductCard({
    super.key,
    required this.product,
    this.width,
    this.listMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return listMode ? _buildListCard(context) : _buildGridCard(context);
  }

  // ─── Grid card (2-column grid, matches website product grid) ─────────────
  Widget _buildGridCard(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final catalogProvider = context.watch<CatalogProvider>();
    final currentQty = cartProvider.getQuantity(product.id);
    final isWishlisted = catalogProvider.isWishlisted(product.id);

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image block ──────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 36,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),

                // Wishlist heart
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => catalogProvider.toggleWishlist(product.id),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        isWishlisted
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 15,
                        color: isWishlisted
                            ? AppColors.primaryRed
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),

                // Out-of-stock overlay
                if (!product.inStock)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(8)),
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.7),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.textMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Info block ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // K MART • CATEGORY  (matches website label exactly)
                  Text(
                    'K MART • ${product.categoryName.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Product Name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Weight • In stock / Out of stock
                  Text(
                    '${product.weightUnit} • ${product.inStock ? "In stock" : "Out of stock"}',
                    style: TextStyle(
                      fontSize: 11,
                      color: product.inStock
                          ? const Color(0xFF6B7280)
                          : AppColors.primaryRed,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Price row: ₹125  ₹150 (strikethrough)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        CurrencyFormatter.format(product.sellingPrice),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      if (product.mrp > product.sellingPrice) ...[
                        const SizedBox(width: 5),
                        Text(
                          CurrencyFormatter.format(product.mrp),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Discount badge (green pill — matches website)
                  if (product.discountPercent > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.discountPercent}% OFF',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // ADD + / Stepper (right-aligned like website)
                  Align(
                    alignment: Alignment.centerRight,
                    child: currentQty == 0
                        ? _AddButton(
                            onTap: product.inStock
                                ? () => cartProvider.addToCart(product)
                                : null,
                          )
                        : _StepperWidget(
                            qty: currentQty,
                            onDecrement: () => cartProvider.updateQuantity(
                                product.id, currentQty - 1),
                            onIncrement: () => cartProvider.updateQuantity(
                                product.id, currentQty + 1),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── List/row card (for search results etc.) ─────────────────────────────
  Widget _buildListCard(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final currentQty = cartProvider.getQuantity(product.id);

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFFF3F4F6),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFFF3F4F6),
                  child: const Icon(Icons.shopping_bag_outlined,
                      color: AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'K MART • ${product.categoryName.toUpperCase()}',
                    style: const TextStyle(
                        fontSize: 9, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.weightUnit} • ${product.inStock ? "In stock" : "Out of stock"}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        CurrencyFormatter.format(product.sellingPrice),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      if (product.mrp > product.sellingPrice) ...[
                        const SizedBox(width: 5),
                        Text(
                          CurrencyFormatter.format(product.mrp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 5),
                        if (product.discountPercent > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${product.discountPercent}% OFF',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Add/Stepper
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(height: 36),
                currentQty == 0
                    ? _AddButton(
                        onTap: product.inStock
                            ? () => cartProvider.addToCart(product)
                            : null,
                      )
                    : _StepperWidget(
                        qty: currentQty,
                        onDecrement: () => cartProvider.updateQuantity(
                            product.id, currentQty - 1),
                        onIncrement: () => cartProvider.updateQuantity(
                            product.id, currentQty + 1),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: product)),
    );
  }
}

// ── ADD + button matching website exactly ─────────────────────────────────
class _AddButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _AddButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled ? AppColors.primaryRed : AppColors.textMuted,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ADD',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: enabled ? AppColors.primaryRed : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.add,
              size: 13,
              color: enabled ? AppColors.primaryRed : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quantity stepper ──────────────────────────────────────────────────────
class _StepperWidget extends StatelessWidget {
  final int qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _StepperWidget({
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(icon: Icons.remove, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$qty',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _Btn(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}