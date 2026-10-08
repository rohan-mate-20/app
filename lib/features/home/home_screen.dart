import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/store_delivery_provider.dart';
import '../../widgets/skeleton_loader.dart';
import '../categories/categories_screen.dart';
import '../location/location_selector_sheet.dart';
import '../offers/offers_screen.dart';
import '../products/product_card.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bannerIndex = 0;

  static const _banners = [
    _BannerData(
      title: 'Up to 20% Off\nDaily Essentials',
      subtitle: 'Groceries, snacks & more\nat your doorstep',
      cta: 'Shop Now',
      bg: Color(0xFF0B1E48),
      accentColor: AppColors.primaryRed,
      imageUrl:
          'https://images.unsplash.com/photo-1542838132-92c53300491e?w=400&q=80',
    ),
    _BannerData(
      title: 'Fresh Vegetables\nEvery Morning',
      subtitle: 'Farm-fresh produce\ndelivered daily',
      cta: 'Explore',
      bg: Color(0xFF065F46),
      accentColor: Color(0xFF10B981),
      imageUrl:
          'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=400&q=80',
    ),
    _BannerData(
      title: 'Dairy & Eggs\nFresh Daily',
      subtitle: 'Quality guaranteed\nfrom trusted farms',
      cta: 'Order Now',
      bg: Color(0xFF92400E),
      accentColor: Color(0xFFF59E0B),
      imageUrl:
          'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final store = context.watch<StoreDeliveryProvider>();
    final auth = context.watch<AuthProvider>();
    final addr = store.selectedAddress;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      // ── Top header matching website ──────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          color: AppColors.navyDark,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Row 1: Logo | Delivery | Cart icon
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      // K MART Logo (matches website text logo)
                      _KMartTextLogo(),
                      const SizedBox(width: 10),

                      // Deliver to chip
                      Expanded(
                        child: GestureDetector(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => const LocationSelectorSheet(),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 12, color: AppColors.primaryRed),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Deliver to',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.white60,
                                        ),
                                      ),
                                      Text(
                                        addr != null
                                            ? '${addr.city} ${addr.pincode}'
                                            : 'Select address',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down,
                                    size: 14, color: Colors.white60),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Avatar
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.15),
                        child: Text(
                          (auth.currentCustomer?.name?.isNotEmpty == true)
                              ? auth.currentCustomer!.name!
                                  .substring(0, 1)
                                  .toUpperCase()
                              : 'G',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Row 2: Search bar (matches website search)
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          const Icon(Icons.search,
                              size: 18, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Search products, brands and more...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          // Search button (red, matches website)
                          Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryRed,
                              borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(6),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Search',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await catalog.loadCatalog();
          await store.loadInitialData();
        },
        color: AppColors.primaryRed,
        child: ListView(
          children: [
            // ── Category pills strip (matches website nav strip) ──────────
            _CategoryStrip(catalog: catalog),

            // ── Promotional banner carousel ──────────────────────────────
            _BannerCarousel(
              banners: _banners,
              currentIndex: _bannerIndex,
              onPageChanged: (i) => setState(() => _bannerIndex = i),
            ),

            const SizedBox(height: 16),

            // ── Popular Products ─────────────────────────────────────────
            _SectionHeader(
              title: 'Popular Products',
              onViewAll: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const CategoriesScreen()),
              ),
            ),
            const SizedBox(height: 8),

            if (catalog.isLoading)
              _HorizontalSkeletons()
            else
              _HorizontalProductList(products: catalog.popularProducts),

            const SizedBox(height: 16),

            // ── Deals banner ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OffersScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Great Deals Every Day',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Save more on daily essentials',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'View Offers',
                          style: TextStyle(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── All Products (compact grid preview) ──────────────────────
            _SectionHeader(
              title: 'Shop All Products',
              onViewAll: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              ),
            ),
            const SizedBox(height: 8),

            if (catalog.isLoading)
              _buildGridSkeleton()
            else
              _ProductGrid(products: catalog.filteredProducts.take(6).toList()),

            const SizedBox(height: 16),

            // ── Trust badges ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TrustBadge(
                      icon: Icons.local_shipping_outlined,
                      title: 'Fast Delivery',
                      subtitle: 'On-time, always',
                    ),
                    _TrustBadge(
                      icon: Icons.verified_outlined,
                      title: 'Quality Items',
                      subtitle: 'Trusted brands',
                    ),
                    _TrustBadge(
                      icon: Icons.support_agent_outlined,
                      title: 'Need Help?',
                      subtitle: 'Instant support',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => const SkeletonLoader(
          width: 160,
          height: 260,
          borderRadius: 8,
        ),
      ),
    );
  }
}

// ── K MART text logo (matches website) ────────────────────────────────────
class _KMartTextLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'K',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryRed,
                  fontStyle: FontStyle.italic,
                ),
              ),
              TextSpan(
                text: 'MART',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Text(
          'Daily Essentials',
          style: TextStyle(
            fontSize: 8,
            color: Colors.white54,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Category strip (horizontal category nav like website top nav) ──────────
class _CategoryStrip extends StatelessWidget {
  final CatalogProvider catalog;
  const _CategoryStrip({required this.catalog});

  @override
  Widget build(BuildContext context) {
    if (catalog.categories.isEmpty) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: catalog.categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 0),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final name =
              isAll ? 'Home' : catalog.categories[index - 1].name;
          final slug =
              isAll ? 'all' : catalog.categories[index - 1].slug;
          final isSelected = catalog.selectedCategorySlug == slug;

          return GestureDetector(
            onTap: () {
              if (!isAll) {
                catalog.selectCategory(slug);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        CategoriesScreen(initialCategorySlug: slug),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? AppColors.primaryRed
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primaryRed
                      : const Color(0xFF374151),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Banner carousel ────────────────────────────────────────────────────────
class _BannerCarousel extends StatelessWidget {
  final List<_BannerData> banners;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _BannerCarousel({
    required this.banners,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            itemCount: banners.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final b = banners[index];
              return Container(
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                decoration: BoxDecoration(
                  color: b.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    // Background image
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 150,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(10)),
                        child: CachedNetworkImage(
                          imageUrl: b.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: b.accentColor.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                    // Dark gradient overlay on image
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 150,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(10)),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [b.bg, Colors.transparent],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Text content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            b.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            b.subtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              b.cta,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Dots
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (i) {
            return Container(
              width: i == currentIndex ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i == currentIndex
                    ? AppColors.primaryRed
                    : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: const Text(
              'View All →',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Horizontal product list ────────────────────────────────────────────────
class _HorizontalProductList extends StatelessWidget {
  final List<dynamic> products;
  const _HorizontalProductList({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: Text('No products available',
              style: TextStyle(color: Color(0xFF9CA3AF))),
        ),
      );
    }
    return SizedBox(
      height: 270,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) =>
            ProductCard(product: products[index], width: 158),
      ),
    );
  }
}

// ── Horizontal skeleton placeholders ──────────────────────────────────────
class _HorizontalSkeletons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 270,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) =>
            const SkeletonLoader(width: 158, height: 270, borderRadius: 8),
      ),
    );
  }
}

// ── Compact 2-column product grid (home page preview) ─────────────────────
class _ProductGrid extends StatelessWidget {
  final List<dynamic> products;
  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) =>
            ProductCard(product: products[index]),
      ),
    );
  }
}

// ── Trust badge ───────────────────────────────────────────────────────────
class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TrustBadge({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryRed, size: 22),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

// ── Banner data model ─────────────────────────────────────────────────────
class _BannerData {
  final String title;
  final String subtitle;
  final String cta;
  final Color bg;
  final Color accentColor;
  final String imageUrl;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.bg,
    required this.accentColor,
    required this.imageUrl,
  });
}