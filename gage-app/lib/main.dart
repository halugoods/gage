import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/features/auth/presentation/login_screen.dart';
import 'package:gage_app/features/home/presentation/home_screen.dart';
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/features/profile/presentation/profile_screen.dart';
import 'package:gage_app/features/video/presentation/video_feed_screen.dart';
import 'package:gage_app/features/home/presentation/promo_screen.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';

import 'package:gage_app/core/services/banner_manager_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GageApp());
}

class GageApp extends StatelessWidget {
  const GageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MultiMerchantCartService()),
        ChangeNotifierProvider.value(value: BannerManagerService.instance),
      ],
      child: MaterialApp(
        title: 'Gage Pracimantoro',
        debugShowCheckedModeBanner: false,
        theme: GageTheme.lightTheme,
        darkTheme: GageTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthGate(),
      ),
    );
  }
}

// Gerbang Autentikasi Pengguna
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: GageTheme.primary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'GAGE',
                    style: TextStyle(
                      color: GageTheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ],
          ),
        ),
      );
    }

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    return const MainNavigationScreen();
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    final List<Widget> pages = [
      HomeScreen(
        onProfileTap: () => setState(() => _currentIndex = 4),
      ),
      const OrdersScreen(),
      const PromoScreen(),
      const VideoFeedScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1)),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 640 : double.infinity),
              child: Row(
                children: [
                  _buildNavItem(0, 'assets/images/nav_home_active.png', 'assets/images/nav_home_inactive.png', 'Beranda'),
                  _buildNavItem(1, 'assets/images/nav_orders_active.png', 'assets/images/nav_orders_inactive.png', 'Pesanan'),
                  _buildNavItem(2, 'assets/images/nav_promo_active.png', 'assets/images/nav_promo_inactive.png', 'Promo', hasBadge: true),
                  _buildNavItem(3, 'assets/images/nav_video_active.png', 'assets/images/nav_video_inactive.png', 'Video'),
                  _buildNavItem(4, 'assets/images/nav_profile_active.png', 'assets/images/nav_profile_inactive.png', 'Profil'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String activeAsset,
    String inactiveAsset,
    String label, {
    bool hasBadge = false,
  }) {
    final isSelected = _currentIndex == index;
    final activeColor = GageTheme.primary;
    final inactiveColor = const Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    isSelected ? activeAsset : inactiveAsset,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  if (hasBadge)
                    Positioned(
                      top: -2,
                      right: -4,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE52320),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
