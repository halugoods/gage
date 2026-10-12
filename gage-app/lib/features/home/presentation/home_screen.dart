import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/features/home/presentation/widgets/jogja_header.dart';
import 'package:gage_app/features/home/presentation/widgets/floating_wallet_card.dart';
import 'package:gage_app/features/home/presentation/widgets/service_grid_clay.dart';
import 'package:gage_app/features/home/presentation/widgets/promo_carousel.dart';
import 'package:gage_app/features/home/presentation/widgets/hemat_resto_list.dart';
import 'package:gage_app/features/home/presentation/widgets/smart_search_sheet.dart';
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const HomeScreen({
    super.key,
    this.onProfileTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _merchants = [];
  bool _isLoadingMerchants = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final userId = auth.currentUser?.id ?? 'usr-cust-01';

    // Fetch wallet dari backend D1
    wallet.fetchWallet(userId);

    // Fetch merchants
    final list = await GageApiClient.getMerchants();
    if (!mounted) return;
    setState(() {
      _merchants = list;
      _isLoadingMerchants = false;
    });
  }

  void _openFoodExplorer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => const FoodExploreScreen(),
      ),
    );
  }

  void _openSmartSearch() {
    SmartSearchSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadInitialData,
            color: GageTheme.primary,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero Banner 16:9 Statis Edge-to-Edge (Tanpa PageView/Dots) + Floating Wallet Card Overlap
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      const JogjaHeroBanner(),
                      const Positioned(
                        bottom: -46,
                        left: 0,
                        right: 0,
                        child: FloatingWalletCard(),
                      ),
                    ],
                  ),

                  // Spacer baku agar posisi icon menu tetap di koordinat presisi (gap 16px ke card)
                  const SizedBox(height: 56),

                  // Wrapper Responsif Tablet untuk Feed Konten Utama
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isTablet ? 680 : double.infinity),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 2. Grid 8 Layanan GAGE (100% Transparan Tanpa Card & Tanpa Overlap)
                          ServiceGridClay(
                            onFoodTap: _openFoodExplorer,
                          ),

                          const SizedBox(height: 16),

                          // 3. Hero Promo Banner Carousel (3 Slide 16:9)
                          const PromoCarousel(),

                          const SizedBox(height: 16),

                          // 4. Katalog Resto Unggulan Terdekat
                          HematRestoList(
                            merchants: _merchants,
                            isLoading: _isLoadingMerchants,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 2. Sticky Header Beranda: Search Bar & Profile Avatar dengan Smooth Fade-In saat scroll
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: JogjaHeader(
              scrollController: _scrollController,
              onSearchTap: _openSmartSearch,
              onProfileTap: widget.onProfileTap,
            ),
          ),
        ],
      ),

      // 5. Floating Cart Beranda (Melayang tepat di atas Bottom Navigation Bar saat ada belanjaan)
      bottomNavigationBar: cart.totalItemCount > 0
          ? _buildFloatingCartBar(context, cart, currencyFormatter, isTablet, isDark)
          : null,
    );
  }

  Widget _buildFloatingCartBar(
    BuildContext context,
    CartProvider cart,
    NumberFormat currencyFormatter,
    bool isTablet,
    bool isDark,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        color: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? GageTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon Keranjang Belanja dengan Badge Item
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: GageTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_rounded,
                          color: GageTheme.primary,
                          size: 22,
                        ),
                      ),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: GageTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Center(
                            child: Text(
                              '${cart.totalItemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Info Menu & Subtotal
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${cart.totalItemCount} Menu / Barang',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : GageTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (cart.merchantCount > 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${cart.merchantCount} Toko',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormatter.format(cart.subtotal),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: GageTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Tombol Checkout / Lihat Pesanan
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const CheckoutScreen()),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Pesanan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 15),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
