import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/features/home/presentation/widgets/gage_home_header.dart';
import 'package:gage_app/features/home/presentation/widgets/floating_wallet_card.dart';
import 'package:gage_app/features/home/presentation/widgets/gage_service_grid.dart';
import 'package:gage_app/features/home/presentation/widgets/promo_carousel.dart';
import 'package:gage_app/features/home/presentation/widgets/smart_search_sheet.dart';
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';
import 'package:gage_app/features/profile/presentation/profile_screen.dart';
import 'package:gage_app/shared/widgets/gage_bottom_nav_bar.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

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
  final ScrollController _scrollController = ScrollController();
  DateTime? _lastBackPressTime;

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
    final userId = auth.currentUser?.id ?? (GageApiClient.useDevSeedData ? 'usr-cust-01' : '');

    // Fetch wallet dari backend D1
    if (userId.isNotEmpty) {
      wallet.fetchWallet(userId);
    }

    // Pre-warm GPS location in background cache
    LocationService.getCurrentLocation().ignore();
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          GageToast.show(context, 'Tekan sekali lagi untuk keluar', type: GageToastType.info);
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true,
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
                        const GageHomeHeroBanner(),
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
                        GageServiceGrid(
                          onFoodTap: _openFoodExplorer,
                        ),

                        const SizedBox(height: 16),

                        // 3. Hero Promo Banner Carousel (3 Slide 16:9)
                        const PromoCarousel(),
                      ],
                    ),

                    // Breathing room di bawah feed agar kartu terakhir tidak tertutup floating navbar / cart
                    Consumer<CartProvider>(
                      builder: (context, cart, _) {
                        return SizedBox(
                          height: cart.totalItemCount > 0 ? 170 : 100,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 2. Sticky Header Beranda: Search Bar & Profile Avatar dengan Smooth Fade-In saat scroll
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: GageHomeHeader(
                scrollController: _scrollController,
                onSearchTap: _openSmartSearch,
                onProfileTap: _navigateToProfile,
              ),
            ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 3. Floating Cart Melayang tepat berdampingan vertikal di atas Floating Navbar (Gap 6px)
            Consumer<CartProvider>(
              builder: (context, cart, _) {
                if (cart.totalItemCount <= 0) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: SeamlessFloatingCartBar(
                    bottomPadding: 0,
                    useSafeArea: false,
                  ),
                );
              },
            ),
            const GageBottomNavBar(currentIndex: 0),
          ],
        ),
      ),
    );
  }
}

