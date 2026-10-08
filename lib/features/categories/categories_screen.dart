import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/skeleton_loader.dart';
import '../products/product_card.dart';

class CategoriesScreen extends StatefulWidget {
  final String? initialCategorySlug;

  const CategoriesScreen({super.key, this.initialCategorySlug});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialCategorySlug != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .read<CatalogProvider>()
            .selectCategory(widget.initialCategorySlug!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogProvider = context.watch<CatalogProvider>();
    final categories = catalogProvider.categories;
    final products = catalogProvider.filteredProducts;
    final selectedSlug = catalogProvider.selectedCategorySlug;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Categories',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<ProductSortOption>(
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            tooltip: 'Sort',
            onSelected: (opt) => catalogProvider.setSortOption(opt),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: ProductSortOption.relevance,
                child: Text('Popular'),
              ),
              PopupMenuItem(
                value: ProductSortOption.priceLowToHigh,
                child: Text('Price: Low to High'),
              ),
              PopupMenuItem(
                value: ProductSortOption.priceHighToLow,
                child: Text('Price: High to Low'),
              ),
              PopupMenuItem(
                value: ProductSortOption.discount,
                child: Text('Discount: High to Low'),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── LEFT SIDEBAR: Category list (matches website left panel) ──
          _CategorySidebar(
            categories: categories,
            selectedSlug: selectedSlug,
            onSelect: (slug) => catalogProvider.selectCategory(slug),
          ),

          // ── RIGHT PANEL: Subcategory pills + product grid ─────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // K MART COLLECTION label + section header
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'K MART COLLECTION',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryRed,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _sectionTitle(selectedSlug, categories),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            '${products.length} items',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Subcategory filter pills (horizontal scroll)
                if (categories.isNotEmpty) ...[
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: SizedBox(
                      height: 34,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final isAll = index == 0;
                          final slug = isAll ? 'all' : categories[index - 1].slug;
                          final name = isAll ? 'All Products' : categories[index - 1].name;
                          final isSelected = selectedSlug == slug;

                          return GestureDetector(
                            onTap: () => catalogProvider.selectCategory(slug),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryRed
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryRed
                                      : const Color(0xFFD1D5DB),
                                ),
                              ),
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                // Product Grid
                Expanded(
                  child: catalogProvider.isLoading
                      ? _buildSkeletonGrid()
                      : products.isEmpty
                          ? EmptyStateView(
                              title: 'No products found',
                              message: 'No items available in this category.',
                              buttonText: 'View All Products',
                              onButtonPressed: () =>
                                  catalogProvider.selectCategory('all'),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(10),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.60,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) =>
                                  ProductCard(product: products[index]),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _sectionTitle(String slug, List<CategoryModel> cats) {
    if (slug == 'all') return 'Products';
    try {
      return cats.firstWhere((c) => c.slug == slug).name;
    } catch (_) {
      return 'Products';
    }
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.60,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const SkeletonLoader(
        width: 160,
        height: 260,
        borderRadius: 8,
      ),
    );
  }
}

// ── Left category sidebar ──────────────────────────────────────────────────
class _CategorySidebar extends StatelessWidget {
  final List<CategoryModel> categories;
  final String selectedSlug;
  final void Function(String slug) onSelect;

  const _CategorySidebar({
    required this.categories,
    required this.selectedSlug,
    required this.onSelect,
  });

  static const _icons = <String, IconData>{
    'groceries': Icons.shopping_basket_outlined,
    'dairy': Icons.egg_outlined,
    'dairy-and-eggs': Icons.egg_outlined,
    'snacks': Icons.fastfood_outlined,
    'snacks-and-beverages': Icons.fastfood_outlined,
    'beverages': Icons.local_drink_outlined,
    'fruits': Icons.nature_outlined,
    'fruits-and-vegetables': Icons.eco_outlined,
    'personal-care': Icons.face_outlined,
    'household': Icons.home_outlined,
    'baby-care': Icons.child_care_outlined,
    'pet-care': Icons.pets_outlined,
    'offers': Icons.local_offer_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final items = [
      const _SidebarItem(slug: 'all', name: 'All', icon: Icons.apps_rounded),
      ...categories.map((c) => _SidebarItem(
            slug: c.slug,
            name: c.name,
            icon: _icons[c.slug] ?? Icons.category_outlined,
          )),
    ];

    return Container(
      width: 76,
      color: Colors.white,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selectedSlug == item.slug;

          return GestureDetector(
            onTap: () => onSelect(item.slug),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryRed.withValues(alpha: 0.08)
                    : Colors.white,
                border: Border(
                  left: BorderSide(
                    color: isSelected
                        ? AppColors.primaryRed
                        : Colors.transparent,
                    width: 3,
                  ),
                  bottom: const BorderSide(
                    color: Color(0xFFF3F4F6),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Column(
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: isSelected
                        ? AppColors.primaryRed
                        : const Color(0xFF6B7280),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primaryRed
                          : const Color(0xFF374151),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SidebarItem {
  final String slug;
  final String name;
  final IconData icon;
  const _SidebarItem(
      {required this.slug, required this.name, required this.icon});
}