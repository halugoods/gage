import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/home/presentation/widgets/jogja_header.dart';
import 'package:gage_app/features/home/presentation/widgets/floating_wallet_card.dart';
import 'package:gage_app/features/home/presentation/widgets/service_grid_clay.dart';
import 'package:gage_app/features/home/presentation/widgets/promo_carousel.dart';
import 'package:gage_app/features/home/presentation/widgets/hemat_resto_list.dart';
import 'package:gage_app/features/home/presentation/widgets/smart_search_sheet.dart';
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';
import 'package:gage_app/features/profile/presentation/profile_screen.dart';
import 'package:gage_app/shared/widgets/gage_bottom_nav_bar.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';

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
    setState(() => _isLoadingMerchants = true);
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

  void _navigateToProfile() {
    if (widget.onProfileTap != null) {
      widget.onProfileTap!();
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
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

                  // Feed Konten Utama
                  Column(
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
              onProfileTap: _navigateToProfile,
            ),
          ),

          // 3. Floating Cart Melayang tepat di atas Navbar
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SeamlessFloatingCartBar(),
          ),
        ],
      ),
      bottomNavigationBar: const GageBottomNavBar(currentIndex: 0),
    );
  }
}

