import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/store_delivery_provider.dart';
import '../../widgets/kmart_logo.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/need_help_faq_sheet.dart';
import '../categories/categories_screen.dart';
import '../location/location_selector_sheet.dart';
import '../products/product_card.dart';
import '../search/search_screen.dart';
import '../auth/login_screen.dart';
import '../../providers/notification_provider.dart';
import '../navigation/main_navigation_shell.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _bannerController;
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  static const int _virtualPageMultiplier = 1000;
  late int _initialPage;

  static final List<Map<String, dynamic>> _bannerItems = [
    {
      'title': 'Everything you need,\nRight at your doorstep.',
      'subtitle': 'Daily essentials delivered fast.',
      'tag': 'Fresh Daily',
      'image': AppConstants.bannerFreshEssentials,
      'gradientColors': [
        AppColors.navyDark,
        AppColors.navyDark,
        AppColors.navyDark.withValues(alpha: 0.6),
        Colors.transparent,
      ],
    },
    {
      'title': 'Dasara Festive Offer\nSpecial Deals on Sweets & Pooja',
      'subtitle': 'Celebrate with festive grocery savings.',
      'tag': 'Dasara Special',
      'image': 'https://images.unsplash.com/photo-1549007994-cb92caebd54b?auto=format&fit=crop&w=800&q=80',
      'gradientColors': [
        const Color(0xFF2E1065),
        const Color(0xFF2E1065),
        const Color(0xFF2E1065).withValues(alpha: 0.65),
        Colors.transparent,
      ],
    },
    {
      'title': 'Diwali Grand Dhamaka\nUp to 50% Off on Essentials',
      'subtitle': 'Mega savings on dry fruits & family packs.',
      'tag': 'Diwali Dhamaka',
      'image': 'https://images.unsplash.com/photo-1508061252445-5350f3193a14?auto=format&fit=crop&w=800&q=80',
      'gradientColors': [
        const Color(0xFF1E1B4B),
        const Color(0xFF1E1B4B),
        const Color(0xFF1E1B4B).withValues(alpha: 0.65),
        Colors.transparent,
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    final count = _bannerItems.length;
    _initialPage = count > 1 ? (count * _virtualPageMultiplier) ~/ 2 : 0;
    if (count > 1 && _initialPage % count != 0) {
      _initialPage -= (_initialPage % count);
    }
    _currentBannerIndex = 0;
    _bannerController = PageController(initialPage: _initialPage);
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    if (_bannerItems.length <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_bannerController.hasClients) {
        _bannerController.nextPage(
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogProvider = context.watch<CatalogProvider>();
    final storeProvider = context.watch<StoreDeliveryProvider>();
    final authProvider = context.watch<AuthProvider>();

    // Hide Fruits and Vegetables categories from Home Page category section
    final homeCategories = catalogProvider.categories.where((cat) {
      final nameLower = cat.name.toLowerCase();
      final slugLower = cat.slug.toLowerCase();
      final isFruits = nameLower.contains('fruit') || slugLower.contains('fruit');
      final isVeg = nameLower.contains('veg') || slugLower.contains('veg');
      return !isFruits && !isVeg;
    }).toList();
    final currentAddress = storeProvider.selectedAddress;

    // Distinct product selection for All Products section:
    // When selectedCategorySlug is 'all' and there are enough products,
    // exclude the products displayed in Popular Products to avoid duplicates.
    final popularIds = catalogProvider.popularProducts.map((p) => p.id).toSet();
    final List<ProductModel> displayAllProducts;
    if (catalogProvider.selectedCategorySlug == 'all' &&
        catalogProvider.filteredProducts.length > catalogProvider.popularProducts.length) {
      final distinct = catalogProvider.filteredProducts.where((p) => !popularIds.contains(p.id)).toList();
      displayAllProducts = distinct.isNotEmpty ? distinct : catalogProvider.filteredProducts;
    } else {
      displayAllProducts = catalogProvider.filteredProducts;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const KMartLogo(fontSize: 26, showTagline: false),
            const SizedBox(height: 2),
            if (authProvider.isLoggedIn)
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const LocationSelectorSheet(),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.primaryRed,
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.52,
                      ),
                      child: Text(
                        currentAddress != null
                            ? '${currentAddress.label} - ${currentAddress.line1}, ${currentAddress.city}'
                            : 'Select Delivery Location',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.primaryRed,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Login to select address',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              final unread = notifProvider.unreadCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      unread > 0
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: unread > 0 ? AppColors.primaryRed : AppColors.navyDark,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (authProvider.isLoggedIn && unread > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryRed,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                MainNavigationShell.switchTab(context, 4);
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.navyLight,
                child: Text(
                  (authProvider.currentCustomer?.name?.isNotEmpty == true)
                      ? authProvider.currentCustomer!.name!.substring(0, 1).toUpperCase()
                      : 'K',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await catalogProvider.loadCatalog();
          await storeProvider.loadInitialData();
        },
        color: AppColors.primaryRed,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Sticky Search Bar Header (QR removed, pinned while scrolling)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchBarDelegate(
                child: Container(
                  color: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search for products, brands and more...',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Scrollable Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Automatic Scrolling Banner Carousel (Dasara & Diwali Offers)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final height = width > 500 ? 200.0 : (width * 0.45).clamp(145.0, 175.0);

                          return Column(
                            children: [
                              SizedBox(
                                height: height,
                                width: double.infinity,
                                child: NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    if (notification is ScrollStartNotification) {
                                      _bannerTimer?.cancel();
                                    } else if (notification is ScrollEndNotification) {
                                      _startBannerTimer();
                                    }
                                    return false;
                                  },
                                  child: PageView.builder(
                                    controller: _bannerController,
                                    itemCount: _bannerItems.length > 1
                                        ? _bannerItems.length * _virtualPageMultiplier
                                        : _bannerItems.length,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentBannerIndex = index % _bannerItems.length;
                                      });
                                    },
                                    itemBuilder: (context, index) {
                                      final item = _bannerItems[index % _bannerItems.length];
                                      final title = item['title'] as String;
                                      final subtitle = item['subtitle'] as String;
                                      final tag = item['tag'] as String;
                                      final imageUrl = item['image'] as String;
                                      final gradColors = item['gradientColors'] as List<Color>;

                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      decoration: BoxDecoration(
                                        color: gradColors.first,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Stack(
                                        children: [
                                          // Background Image on the right
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            bottom: 0,
                                            width: (width - 32) * 0.45,
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.horizontal(
                                                right: Radius.circular(20),
                                              ),
                                              child: CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                                errorWidget: (context, url, error) => Container(
                                                  color: AppColors.primaryRed.withValues(alpha: 0.3),
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Gradient Overlay
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(20),
                                                gradient: LinearGradient(
                                                  colors: gradColors,
                                                  stops: const [0.0, 0.48, 0.65, 1.0],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Text Content
                                          Positioned(
                                            left: 0,
                                            top: 0,
                                            bottom: 0,
                                            width: (width - 32) * 0.62,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                                vertical: 14.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      tag,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 0.4,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    title,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: width > 350 ? 15 : 13.5,
                                                      fontWeight: FontWeight.w900,
                                                      height: 1.15,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    subtitle,
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 10.5,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const Spacer(),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.of(context).push(
                                                        MaterialPageRoute(
                                                          builder: (_) => const CategoriesScreen(),
                                                        ),
                                                      );
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppColors.primaryRed,
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'Shop Now',
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        SizedBox(width: 4),
                                                        Icon(Icons.arrow_forward, size: 13),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                              const SizedBox(height: 8),
                              // Banner indicator dots
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_bannerItems.length, (dotIndex) {
                                  final isSelected = _currentBannerIndex == dotIndex;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: isSelected ? 18 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primaryRed : AppColors.cardBorder,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Shop by Category Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Shop by Category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyDark,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CategoriesScreen(),
                                ),
                              );
                            },
                            child: const Row(
                              children: [
                                Text(
                                  'View All',
                                  style: TextStyle(
                                    color: AppColors.primaryRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.primaryRed,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Categories — Horizontal Scrolling UI (Req 1)
                    SizedBox(
                      height: 110,
                      child: catalogProvider.isLoading
                          ? ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: 6,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (_, __) => const SizedBox(
                                width: 72,
                                child: Column(
                                  children: [
                                    SkeletonLoader(
                                      width: 58,
                                      height: 58,
                                      borderRadius: 29,
                                    ),
                                    SizedBox(height: 8),
                                    SkeletonLoader(
                                      width: 54,
                                      height: 12,
                                      borderRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: homeCategories.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final cat = homeCategories[index];
                                return GestureDetector(
                                  onTap: () {
                                    catalogProvider.selectCategory(cat.slug);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CategoriesScreen(
                                          initialCategorySlug: cat.slug,
                                        ),
                                      ),
                                    );
                                  },
                                  child: SizedBox(
                                    width: 74,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          height: 58,
                                          width: 58,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppColors.cardBorder),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.03),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: cat.iconUrl,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => const Icon(
                                                Icons.category_outlined,
                                                color: AppColors.primaryRed,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          cat.name,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                            height: 1.15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Popular Products Section (Req 4: View All removed)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Popular Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Popular Products Horizontal Carousel
                    if (catalogProvider.isLoading)
                      SizedBox(
                        height: 326,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: 4,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, __) => const SkeletonLoader(
                            width: 165,
                            height: 326,
                            borderRadius: 16,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 326,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: catalogProvider.popularProducts.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            return ProductCard(
                              product: catalogProvider.popularProducts[index],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),

                    // All Products Section Header (Req 3: Distinct Catalogue)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                catalogProvider.selectedCategorySlug == 'all'
                                    ? 'All Products'
                                    : catalogProvider.categories
                                        .firstWhere(
                                          (c) => c.slug == catalogProvider.selectedCategorySlug,
                                          orElse: () => catalogProvider.categories.first,
                                        )
                                        .name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Showing ${displayAllProducts.length} items',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CategoriesScreen(),
                                ),
                              );
                            },
                            child: const Row(
                              children: [
                                Text(
                                  'Explore All',
                                  style: TextStyle(
                                    color: AppColors.primaryRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.primaryRed,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Horizontal Category Chips
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: homeCategories.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final isAll = index == 0;
                          final slug = isAll ? 'all' : homeCategories[index - 1].slug;
                          final name = isAll ? 'All Items' : homeCategories[index - 1].name;
                          final isSelected = catalogProvider.selectedCategorySlug == slug;

                          return ChoiceChip(
                            label: Text(name),
                            selected: isSelected,
                            selectedColor: AppColors.primaryRed,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.primaryRed : AppColors.cardBorder,
                              ),
                            ),
                            onSelected: (_) => catalogProvider.selectCategory(slug),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Responsive Product Grid (Displaying distinct catalogue items)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: displayAllProducts.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(32),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'No products found in this category',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => catalogProvider.selectCategory('all'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryRed,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('View All Items'),
                                  ),
                                ],
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                final int columns = width > 900 ? 4 : (width > 550 ? 3 : 2);
                                final cardWidth = (width - ((columns - 1) * 12)) / columns;
                                final childAspectRatio = cardWidth / 324;

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    childAspectRatio: childAspectRatio,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 14,
                                  ),
                                  itemCount: displayAllProducts.length,
                                  itemBuilder: (context, index) {
                                    return ProductCard(product: displayAllProducts[index]);
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Trust Badges Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildTrustBadge(
                              Icons.local_shipping_outlined,
                              'Fast Delivery',
                              'On-time, always',
                            ),
                            _buildTrustBadge(
                              Icons.verified_outlined,
                              'Quality Items',
                              'Trusted brands',
                            ),
                            GestureDetector(
                              onTap: () => NeedHelpFaqSheet.show(context),
                              child: _buildTrustBadge(
                                Icons.headset_mic_outlined,
                                'Need Help?',
                                'Instant support',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryRed, size: 24),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _StickySearchBarDelegate({required this.child});

  @override
  double get minExtent => 62.0;
  @override
  double get maxExtent => 62.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: 62.0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchBarDelegate oldDelegate) => false;
}
