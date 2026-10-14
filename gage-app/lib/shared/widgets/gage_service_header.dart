import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// Hero Banner 16:9 full-bleed mencapai batas atas status bar (edge-to-edge).
/// Mendukung animasi fade out halus saat halaman di-scroll ke bawah.
class GageServiceHeroBanner extends StatelessWidget {
  final String imageAsset;
  final String fallbackTitle;
  final ScrollController? scrollController;
  final Widget? overlayChild;

  const GageServiceHeroBanner({
    super.key,
    required this.imageAsset,
    this.fallbackTitle = 'GAGE INDONESIA',
    this.scrollController,
    this.overlayChild,
  });

  /// Menghitung tinggi banner 16:9 yang proporsional edge-to-edge termasuk status bar
  static double getBannerHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final isTablet = screenWidth >= 600;

    return isTablet
        ? 300.0 + topPadding
        : ((screenWidth * 9 / 16) + topPadding + 20).clamp(240.0 + topPadding, 275.0 + topPadding);
  }

  @override
  Widget build(BuildContext context) {
    final bannerHeight = getBannerHeight(context);

    Widget imageWidget = SizedBox(
      height: bannerHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (ctx, err, stack) => Container(
              color: GageTheme.primary,
              child: Center(
                child: Text(
                  fallbackTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
          if (overlayChild != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 36.0, // Tepat di atas search bar (50:50 docked overlap)
              child: overlayChild!,
            ),
        ],
      ),
    );

    if (scrollController != null) {
      return AnimatedBuilder(
        animation: scrollController!,
        builder: (context, child) {
          final rawOffset = scrollController!.hasClients ? scrollController!.offset : 0.0;
          final safeOffset = math.max(0.0, rawOffset);
          // Fade-out halus saat banner mulai tertutup scroll
          final bannerOpacity = (1.0 - (safeOffset / 190.0)).clamp(0.2, 1.0);
          return Opacity(
            opacity: bannerOpacity,
            child: child,
          );
        },
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Sticky Header Service:
/// 1. Baris Aksi Atas: Tombol Back (bulat), Pill Lokasi (ber-ellipsis), Tombol Favorit (bulat), Tombol Riwayat (bulat).
/// 2. Search Bar:
///    - Posisi Awal (scrollOffset == 0): Duduk tepat 50:50 hardcore menimpa batas bawah banner dan konten di bawahnya (tidak goyang saat overscroll stretch).
///    - Saat Scroll: Search bar meluncur naik secara seamless mengikuti scroll 1:1.
///    - Mentok di Atas: Begitu menyentuh batas bawah baris aksi, search bar mengunci (docked) menjadi persistent header.
///    - Background header memudar masuk halus menyatukan baris aksi dan search bar saat docked.
class GageServiceStickyHeader extends StatelessWidget {
  final ScrollController scrollController;
  final String locationText;
  final VoidCallback? onLocationTap;
  final VoidCallback? onBackTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onHistoryTap;
  final String searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchTap;
  final IconData? serviceIcon;

  const GageServiceStickyHeader({
    super.key,
    required this.scrollController,
    required this.locationText,
    this.onLocationTap,
    this.onBackTap,
    this.onFavoriteTap,
    this.onHistoryTap,
    required this.searchHint,
    this.searchController,
    this.onSearchChanged,
    this.onSearchTap,
    this.serviceIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final topPadding = MediaQuery.of(context).padding.top;
        final isTablet = screenWidth >= 600;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Anti-stretch: Mengunci offset ke minimal 0.0 agar tidak goyang saat overscroll bounce
        final rawOffset = scrollController.hasClients ? scrollController.offset : 0.0;
        final currentOffset = math.max(0.0, rawOffset);

        final bannerHeight = GageServiceHeroBanner.getBannerHeight(context);
        const searchBarHeight = 44.0;
        const actionButtonSize = 38.0;

        // 1. Posisi 50:50 overlap pada banner (setengah di banner, setengah di layar bawahnya)
        final initialTop = bannerHeight - (searchBarHeight / 2.0);

        // 2. Posisi mentok di atas (tepat di bawah baris tombol aksi)
        final actionRowHeight = topPadding + 6.0 + actionButtonSize;
        final dockedTop = actionRowHeight + 8.0;

        // 3. Jarak scroll yang dibutuhkan untuk mentok
        final dockDistance = (initialTop - dockedTop).clamp(1.0, double.infinity);
        final dockProgress = (currentOffset / dockDistance).clamp(0.0, 1.0);

        // 4. Posisi vertikal search bar saat ini (seamless glide dari initialTop ke dockedTop)
        final currentSearchTop = math.max(dockedTop, initialTop - currentOffset);
        final isDocked = currentSearchTop <= (dockedTop + 1.0);

        // 5. Header Background Fade & Height
        final bgFade = dockProgress.clamp(0.0, 1.0);
        final bgHeight = isDocked
            ? (dockedTop + searchBarHeight + 10.0)
            : (actionRowHeight + 8.0);

        // 6. Dynamic Status Bar Icon Brightness
        final iconBrightness = isDark
            ? Brightness.light
            : (isDocked || bgFade > 0.5 ? Brightness.dark : Brightness.light);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: iconBrightness,
            statusBarBrightness: isDark ? Brightness.dark : (isDocked || bgFade > 0.5 ? Brightness.light : Brightness.dark),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // A. Unified Header Background (fades in as user scrolls down & docks)
              if (bgFade > 0.02)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: bgHeight,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: (isDark ? GageTheme.darkSurface : Colors.white).withValues(alpha: bgFade),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(isDocked ? 16 : 0),
                        ),
                        boxShadow: bgFade > 0.1
                            ? [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black54
                                      : Colors.black.withValues(alpha: 0.08 * bgFade),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),

              // B. Baris Aksi Atas (Back, Lokasi, Favorit, Riwayat)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: actionRowHeight + 8,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topPadding + 6.0,
                    left: 14.0,
                    right: 14.0,
                  ),
                  child: Row(
                    children: [
                      // Tombol Back
                      GestureDetector(
                        onTap: onBackTap ?? () => Navigator.pop(context),
                        child: Container(
                          width: actionButtonSize,
                          height: actionButtonSize,
                          decoration: BoxDecoration(
                            color: isDark ? GageTheme.darkCard : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? GageTheme.darkBorder : Colors.black12,
                              width: 0.8,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: isDark ? Colors.white : Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Pill Lokasi (Max width & truncated text with ellipsis)
                      Flexible(
                        child: GestureDetector(
                          onTap: onLocationTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: isDark ? GageTheme.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? GageTheme.darkBorder : Colors.black12,
                                width: 0.8,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded, color: GageTheme.primary, size: 16),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    locationText.isNotEmpty ? '$locationText ▾' : 'Pilih Lokasi ▾',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Tombol Favorit
                      GestureDetector(
                        onTap: onFavoriteTap,
                        child: Container(
                          width: actionButtonSize,
                          height: actionButtonSize,
                          decoration: BoxDecoration(
                            color: isDark ? GageTheme.darkCard : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? GageTheme.darkBorder : Colors.black12,
                              width: 0.8,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.favorite_rounded, color: GageTheme.primary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tombol Riwayat Pesanan
                      GestureDetector(
                        onTap: onHistoryTap,
                        child: Container(
                          width: actionButtonSize,
                          height: actionButtonSize,
                          decoration: BoxDecoration(
                            color: isDark ? GageTheme.darkCard : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? GageTheme.darkBorder : Colors.black12,
                              width: 0.8,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: isDark ? Colors.white : Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // C. Search Bar 50:50 Overlap yang Meluncur Mulus dan Mentok Menjadi Header
              Positioned(
                top: currentSearchTop,
                left: 0,
                right: 0,
                height: searchBarHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isTablet ? 760 : double.infinity),
                      child: Container(
                        height: searchBarHeight,
                        decoration: BoxDecoration(
                          color: isDark ? GageTheme.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark ? GageTheme.darkBorder : Colors.black12,
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black38
                                  : Colors.black.withValues(alpha: isDocked ? 0.06 : 0.12),
                              blurRadius: isDocked ? 6 : 10,
                              offset: Offset(0, isDocked ? 2 : 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: onSearchChanged,
                          onTap: onSearchTap,
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: searchHint,
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 12, right: 8),
                              child: Icon(
                                Icons.search_rounded,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 44),
                            suffixIcon: (searchController != null && searchController!.text.isNotEmpty)
                                ? GestureDetector(
                                    onTap: () {
                                      searchController!.clear();
                                      if (onSearchChanged != null) onSearchChanged!('');
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 14),
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        size: 18,
                                      ),
                                    ),
                                  )
                                : (serviceIcon != null
                                    ? Padding(
                                        padding: const EdgeInsets.only(right: 14),
                                        child: Icon(serviceIcon, color: GageTheme.primary, size: 19),
                                      )
                                    : null),
                            suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 44),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
