import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/empty_state_view.dart';
import '../products/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Ensure search is fresh when entering search screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CatalogProvider>().clearSearch();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final clean = query.trim();
    if (clean.isEmpty) {
      context.read<CatalogProvider>().clearSearch();
      setState(() {});
      return;
    }
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        context.read<CatalogProvider>().setSearchQuery(clean);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogProvider = context.watch<CatalogProvider>();
    final results = catalogProvider.searchResults;
    final allProducts = catalogProvider.allProducts;
    final queryText = _searchController.text.trim();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _debounce?.cancel();
          context.read<CatalogProvider>().clearSearch();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              _debounce?.cancel();
              catalogProvider.clearSearch();
              Navigator.of(context).pop();
            },
          ),
          title: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search atta, milk, biscuits, soaps...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _debounce?.cancel();
                            _searchController.clear();
                            catalogProvider.clearSearch();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ),
        body: queryText.isEmpty
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Popular Searches',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Aashirvaad Atta',
                        'Amul Milk',
                        'Surf Excel',
                        'Colgate',
                        'Tomato',
                        'Banana',
                        'Parle-G',
                        'Oil',
                      ].map((term) {
                        return ActionChip(
                          label: Text(term),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.cardBorder),
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                          onPressed: () {
                            _searchController.text = term;
                            _onSearchChanged(term);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Browse Categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: catalogProvider.categories.map((cat) {
                        return ActionChip(
                          avatar: const Icon(
                            Icons.category_outlined,
                            size: 16,
                            color: AppColors.primaryRed,
                          ),
                          label: Text(cat.name),
                          backgroundColor: AppColors.navyLight,
                          side: BorderSide.none,
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navyDark,
                          ),
                          onPressed: () {
                            _searchController.text = cat.name;
                            _onSearchChanged(cat.name);
                          },
                        );
                      }).toList(),
                    ),
                    if (allProducts.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All Products',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyDark,
                            ),
                          ),
                          Text(
                            '${allProducts.length} items',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = (constraints.maxWidth - 12) / 2;
                          final childAspectRatio = cardWidth / 324;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: childAspectRatio,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: allProducts.length,
                            itemBuilder: (context, index) {
                              return ProductCard(product: allProducts[index]);
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
              )
            : results.isEmpty && !catalogProvider.isLoading
                ? EmptyStateView(
                    title: 'No results found',
                    message:
                        'We couldn\'t find any products matching "$queryText"',
                    icon: Icons.search_off_rounded,
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - 32 - 12) / 2;
                      final childAspectRatio = cardWidth / 324;
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          return ProductCard(product: results[index]);
                        },
                      );
                    },
                  ),
      ),
    );
  }
}