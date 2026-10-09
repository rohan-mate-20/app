import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          PopupMenuButton<ProductSortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort Products',
            onSelected: (opt) => catalogProvider.setSortOption(opt),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ProductSortOption.relevance,
                child: Text('Relevance'),
              ),
              const PopupMenuItem(
                value: ProductSortOption.priceLowToHigh,
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem(
                value: ProductSortOption.priceHighToLow,
                child: Text('Price: High to Low'),
              ),
              const PopupMenuItem(
                value: ProductSortOption.discount,
                child: Text('Discount: High to Low'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Pills Horizontal Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final slug = isAll ? 'all' : categories[index - 1].slug;
                  final name = isAll ? 'All' : categories[index - 1].name;
                  final isSelected = catalogProvider.selectedCategorySlug == slug;

                  return ChoiceChip(
                    label: Text(name),
                    selected: isSelected,
                    selectedColor: AppColors.primaryRed,
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryRed
                            : AppColors.cardBorder,
                      ),
                    ),
                    onSelected: (_) => catalogProvider.selectCategory(slug),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),

          // Product Grid
          Expanded(
            child: catalogProvider.isLoading
                ? GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.64,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: 6,
                    itemBuilder: (_, __) => const SkeletonLoader(
                      width: 160,
                      height: 240,
                      borderRadius: 16,
                    ),
                  )
                : products.isEmpty
                    ? EmptyStateView(
                        title: 'No products found',
                        message:
                            'No items available under this category currently.',
                        buttonText: 'View All Products',
                        onButtonPressed: () {
                          catalogProvider.selectCategory('all');
                        },
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.62,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return ProductCard(product: products[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
