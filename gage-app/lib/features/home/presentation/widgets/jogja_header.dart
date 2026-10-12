import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/features/profile/presentation/widgets/profile_accordion_sheet.dart';

class JogjaHeader extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;

  const JogjaHeader({
    super.key,
    this.onSearchTap,
    this.onProfileTap,
  });

  @override
  State<JogjaHeader> createState() => _JogjaHeaderState();
}

class _JogjaHeaderState extends State<JogjaHeader> {
  final PageController _pageController = PageController();
  int _currentBannerIndex = 0;

  final List<String> _heroBanners = [
    'assets/images/hero_banner_1.png',
    'assets/images/hero_banner_2.png',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    // Tinggi banner proporsional untuk safe zone (Search bar atas + Visual tengah + Wallet card bawah)
    final heroHeight = isTablet ? 280.0 : ((screenWidth * 9 / 16) + 38).clamp(245.0, 265.0);
    final topPadding = MediaQuery.of(context).padding.top;
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark = platformBrightness == Brightness.dark || Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? GageTheme.darkBackground : GageTheme.primary;
    const iconBrightness = Brightness.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: barColor,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: Brightness.dark,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Drawer Status Bar Android Atas (Menyesuaikan tema hp: Dark -> Dark Slate #0F172A, Light -> Merah GAGE #E52320)
          Container(
            height: topPadding,
            color: barColor,
          ),

          // 2. Banner Hero dengan Gojek-Style Search Bar & Avatar Profil Proporsional
          SizedBox(
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Hero Banner Slider (Bagian atas 30% adalah safe zone merah solid)
                PageView.builder(
                  controller: _pageController,
                  itemCount: _heroBanners.length,
                  onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
                  itemBuilder: (ctx, idx) {
                    return Image.asset(
                      _heroBanners[idx],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (c, e, s) => Container(
                        color: GageTheme.primary,
                        child: const Center(
                          child: Text(
                            'GAGE INDONESIA',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Floating Top Bar: Search Bar Putih Solid (Kiri) + Avatar Profil Proporsional (Kanan)
                Positioned(
                  top: 10,
                  left: isTablet ? (screenWidth - 560) / 2 : 14,
                  right: isTablet ? (screenWidth - 560) / 2 : 14,
                  child: Row(
                    children: [
                      // Search Bar Putih Solid (Gojek Style)
                      Expanded(
                        child: InkWell(
                          onTap: widget.onSearchTap,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isDark ? GageTheme.darkSurface : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                                  size: 21,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Cari layanan, resto, atau makanan...',
                                    style: TextStyle(
                                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                                      fontSize: 13,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Avatar Profil Pengguna (Ukuran presisi 42x42 sama persis dengan tinggi search bar)
                      GestureDetector(
                        onTap: () {
                          ProfileAccordionSheet.show(
                            context,
                            onOpenFullProfile: widget.onProfileTap,
                          );
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                          child: ClipOval(
                            child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                                ? Image.network(
                                    user.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Image.asset('assets/images/avatar_user.png', fit: BoxFit.cover),
                                  )
                                : Image.asset('assets/images/avatar_user.png', fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Slider Dots Indicator: Posisikan tepat pada bottom: 38 (tepat 8px di atas FloatingWalletCard, tidak tertutup dan tidak terlalu ke atas)
                Positioned(
                  bottom: 38,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _heroBanners.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.fastOutSlowIn,
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: _currentBannerIndex == i ? 20 : 6,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _currentBannerIndex == i ? Colors.white : Colors.white54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
