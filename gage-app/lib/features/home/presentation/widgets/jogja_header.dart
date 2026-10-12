import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/features/profile/presentation/widgets/profile_accordion_sheet.dart';

/// 1. Banner Hero Beranda: 1 banner tunggal 16:9 statis tanpa slide/PageView dan tanpa dots indicator.
/// Menyatu edge-to-edge dari puncak layar (y = 0) ke bawah status bar.
class JogjaHeroBanner extends StatelessWidget {
  const JogjaHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final isTablet = screenWidth >= 600;

    // Tinggi proporsional edge-to-edge mencakup area status bar atas
    final bannerHeight = isTablet
        ? 300.0 + topPadding
        : ((screenWidth * 9 / 16) + topPadding + 20).clamp(240.0 + topPadding, 275.0 + topPadding);

    return SizedBox(
      height: bannerHeight,
      width: double.infinity,
      child: Image.asset(
        'assets/images/hero_banner_1.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (ctx, err, stack) => Container(
          color: GageTheme.primary,
          child: const Center(
            child: Text(
              'GAGE INDONESIA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 2. Sticky Header Beranda: Search Bar & Avatar Profil
/// Di posisi puncak (offset == 0): Background 100% transparan, menyatu edge-to-edge dengan banner hero.
/// Saat scroll ke bawah: Background memudar masuk (faded in) dengan rounded bottom corner & bayangan halus.
class JogjaHeader extends StatefulWidget {
  final ScrollController? scrollController;
  final double? scrollOffset;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;

  const JogjaHeader({
    super.key,
    this.scrollController,
    this.scrollOffset,
    this.onSearchTap,
    this.onProfileTap,
  });

  @override
  State<JogjaHeader> createState() => _JogjaHeaderState();
}

class _JogjaHeaderState extends State<JogjaHeader> {
  @override
  Widget build(BuildContext context) {
    if (widget.scrollController != null) {
      return AnimatedBuilder(
        animation: widget.scrollController!,
        builder: (context, _) => _buildHeaderContent(context),
      );
    }
    return _buildHeaderContent(context);
  }

  Widget _buildHeaderContent(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentOffset = widget.scrollController != null && widget.scrollController!.hasClients
        ? widget.scrollController!.offset
        : (widget.scrollOffset ?? 0.0);

    // Fade progress dari 0.0 sampai 1.0 (dalam jarak scroll 70px)
    final fade = (currentOffset / 70.0).clamp(0.0, 1.0);

    // Sesuai Web Audit: gunakan isDark ? GageTheme.darkBackground : Colors.white untuk sticky header
    final stickyBgColor = isDark ? GageTheme.darkBackground : Colors.white;
    final headerColor = stickyBgColor.withValues(alpha: fade);

    // Dynamic icon brightness status bar
    final iconBrightness = fade > 0.5
        ? (isDark ? Brightness.light : Brightness.dark)
        : Brightness.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: fade > 0.5 && !isDark ? Brightness.light : Brightness.dark,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: headerColor,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16.0 * fade),
          ),
          boxShadow: fade > 0.05
              ? [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.35 * fade)
                        : Colors.black.withValues(alpha: 0.08 * fade),
                    blurRadius: 10 * fade,
                    offset: Offset(0, 3 * fade),
                  ),
                ]
              : null,
        ),
        padding: EdgeInsets.only(
          top: topPadding + 6,
          bottom: 10,
          left: isTablet ? (screenWidth - 560) / 2 : 14,
          right: isTablet ? (screenWidth - 560) / 2 : 14,
        ),
        child: Row(
          children: [
            // Search Bar Putih Solid (Gojek / Tokopedia Style)
            Expanded(
              child: InkWell(
                onTap: widget.onSearchTap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? GageTheme.darkSurface
                        : (fade > 0.6 ? Colors.grey.shade100 : Colors.white),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white12
                          : (fade > 0.6 ? Colors.grey.shade300 : Colors.transparent),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
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

            // Avatar Profil Pengguna (Ukuran presisi 42x42 sama dengan tinggi search bar)
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
                  color: isDark ? GageTheme.darkSurface : Colors.white,
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.white,
                    width: 2,
                  ),
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
    );
  }
}
