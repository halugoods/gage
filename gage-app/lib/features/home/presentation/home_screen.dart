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
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';

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
    _loadInitialData();
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        color: GageTheme.primary,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Seamless Hero Carousel 16:9 + Floating Wallet Card Overlap
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  JogjaHeader(
                    onSearchTap: _openFoodExplorer,
                    onProfileTap: widget.onProfileTap,
                  ),
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
