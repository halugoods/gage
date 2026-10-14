import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:gage_app/features/profile/presentation/profile_screen.dart';
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/features/home/presentation/promo_screen.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';

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
        'assets/images/home_hero_banner.png',
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
          left: 14,
          right: 14,
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
              onTap: () => _showProfileDropdownMenu(context, auth, topPadding),
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

  // Dropdown Menu Tepat di Bawah Avatar (Direct Screen Link, Tanpa Card, Tanpa Expand Option)
  void _showProfileDropdownMenu(BuildContext context, AuthProvider auth, double topPadding) {
    final user = auth.currentUser;
    final userName = (user?.name != null && user!.name.isNotEmpty) ? user.name : 'Pengguna GAGE';
    final userEmail = (user?.email != null && user!.email!.isNotEmpty)
        ? user.email!
        : (user?.phone ?? 'pengguna@gage.id');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup Menu Profil',
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (dialogCtx, anim1, anim2) {
        return Stack(
          children: [
            Positioned(
              top: topPadding + 52,
              right: 14,
              width: 265,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? GageTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Identitas Mini Pengguna
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                          child: Row(
                            children: [
                              ClipOval(
                                child: SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                                      ? Image.network(
                                          user.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Image.asset('assets/images/avatar_user.png', fit: BoxFit.cover),
                                        )
                                      : Image.asset('assets/images/avatar_user.png', fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : GageTheme.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      userEmail,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark ? Colors.white60 : GageTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),

                        // 2. Menu Pilihan Langsung ke Screen Terkait (Flat list, no cards, no expand)
                        _buildDropdownItem(
                          dialogCtx,
                          icon: Icons.person_outline_rounded,
                          title: 'Profil Saya',
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            if (widget.onProfileTap != null) {
                              widget.onProfileTap!();
                            } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                            }
                          },
                          isDark: isDark,
                        ),
                        _buildDropdownItem(
                          dialogCtx,
                          icon: Icons.edit_outlined,
                          title: 'Edit Data Diri',
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                          },
                          isDark: isDark,
                        ),
                        _buildDropdownItem(
                          dialogCtx,
                          icon: Icons.receipt_long_outlined,
                          title: 'Pesanan Saya',
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
                          },
                          isDark: isDark,
                        ),
                        _buildDropdownItem(
                          dialogCtx,
                          icon: Icons.discount_outlined,
                          title: 'Promo & Voucher',
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PromoScreen()));
                          },
                          isDark: isDark,
                        ),
                        _buildDropdownItem(
                          dialogCtx,
                          icon: Icons.monetization_on_outlined,
                          title: 'GAGE Cuan (Affiliate)',
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AffiliateHubScreen()));
                          },
                          isDark: isDark,
                        ),
                        _buildDropdownItem(
                          dialogCtx,
                          icon: Icons.chat_outlined,
                          title: 'Pusat Bantuan CS WA',
                          onTap: () async {
                            Navigator.pop(dialogCtx);
                            final uri = Uri.parse('https://wa.me/6281234567890?text=Halo%20Admin%20GAGE%2C%20saya%20butuh%20bantuan');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          isDark: isDark,
                        ),
                        Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
                        _buildDropdownItem(
                          dialogCtx,
                          icon: Icons.logout_rounded,
                          title: 'Keluar',
                          iconColor: Colors.red,
                          textColor: Colors.red,
                          onTap: () async {
                            Navigator.pop(dialogCtx);
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('Konfirmasi Keluar'),
                                content: const Text('Apakah Anda yakin ingin keluar dari akun GAGE?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Keluar'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              auth.signOut();
                            }
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          alignment: Alignment.topRight,
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildDropdownItem(
    BuildContext ctx, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: iconColor ?? (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
