import 'dart:io';
import 'package:gage_app/core/services/notification_service.dart';
import 'package:gage_app/features/notification/presentation/notification_screen.dart';
import 'package:gage_app/features/chat/presentation/chat_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:gage_app/features/profile/presentation/widgets/gage_account_switcher_sheet.dart';
import 'package:gage_app/data/mock/gage_mock_registry.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/features/food/presentation/shop_screen.dart';
import 'package:gage_app/features/food/presentation/farm_screen.dart';
import 'package:gage_app/features/food/presentation/build_screen.dart';
import 'package:gage_app/features/ride/presentation/ride_booking_screen.dart';
import 'package:gage_app/features/ride/presentation/send_booking_screen.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/shared/widgets/live_app_edit_scope.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

/// 1. Banner Hero Beranda: 1 banner tunggal 16:9 statis tanpa slide/PageView dan tanpa dots indicator.
/// Menyatu edge-to-edge dari puncak layar (y = 0) ke bawah status bar.
class GageHomeHeroBanner extends StatelessWidget {
  const GageHomeHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final bannerManager = context.watch<BannerManagerService>();
    final banner = bannerManager.getBanner('customer_home_hero');
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final isTablet = screenWidth >= 600;
    final isEditMode = LiveAppEditScope.isEditModeActive(context);

    // Tinggi proporsional edge-to-edge mencakup area status bar atas
    final bannerHeight = isTablet
        ? 300.0 + topPadding
        : ((screenWidth * 9 / 16) + topPadding + 20).clamp(240.0 + topPadding, 275.0 + topPadding);

    final imgPath = banner.imagePath;

    Widget imageContent = SizedBox(
      height: bannerHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imgPath.startsWith('http://') || imgPath.startsWith('https://')
              ? Image.network(
                  imgPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (ctx, err, stack) => _buildFallback(),
                )
              : Image.asset(
                  imgPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (ctx, err, stack) => _buildFallback(),
                ),
          if (isEditMode)
            Positioned(
              top: topPadding + 10,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Edit Hero Banner',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (isEditMode) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          LiveAppEditScope.triggerEdit(
            context: context,
            screenTarget: 'customer_home_hero',
            title: banner.title,
            subtitle: banner.subtitle,
            badge: banner.badge,
            imageUrl: banner.imagePath,
            actionUrl: banner.ctaText,
            aspectRatio: 16 / 9,
          );
        },
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _buildFallback() {
    return Container(
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
    );
  }
}

/// 2. Sticky Header Beranda: Search Bar & Avatar Profil
/// Di posisi puncak (offset == 0): Background 100% transparan, menyatu edge-to-edge dengan banner hero.
/// Saat scroll ke bawah: Background memudar masuk (faded in) dengan rounded bottom corner & bayangan halus.
class GageHomeHeader extends StatefulWidget {
  final ScrollController? scrollController;
  final double? scrollOffset;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;

  const GageHomeHeader({
    super.key,
    this.scrollController,
    this.scrollOffset,
    this.onSearchTap,
    this.onProfileTap,
  });

  @override
  State<GageHomeHeader> createState() => _GageHomeHeaderState();
}

class _GageHomeHeaderState extends State<GageHomeHeader> {
  bool _isSearchActive = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // Master Directory Pencarian Cerdas (8 Layanan Resmi + Menu Terlaris + Toko/Resto Mitra)
  // Terpusat di GageMockRegistry [DUMMY_PRODUCTION_TARGET]
  List<Map<String, dynamic>> get _searchDirectory => GageMockRegistry.getUnifiedSearchDirectory();

  String _inferDomainFromStore(Map<String, dynamic> store) {
    final explicit = (store['domain'] ?? store['serviceType'] ?? '').toString().trim().toLowerCase();
    if (explicit.isNotEmpty) return explicit;
    final id = (store['id'] ?? '').toString().toLowerCase();
    if (id.startsWith('farm') || id.contains('tani')) return 'farm';
    if (id.startsWith('build') || id.contains('tb-') || id.contains('depo')) return 'build';
    if (id.startsWith('shop') || id.contains('sembako')) return 'shop';
    return 'food';
  }

  void _onSelectSearchResult(Map<String, dynamic> item) {
    HapticFeedback.lightImpact();
    setState(() {
      _isSearchActive = false;
      _searchCtrl.clear();
    });
    _searchFocus.unfocus();

    final target = item['target'] as String;
    Widget destination;
    switch (target) {
      case 'ride':
        destination = const RideBookingScreen();
        break;
      case 'car':
        destination = const RideBookingScreen(initialTab: 'car');
        break;
      case 'food':
        destination = const FoodExploreScreen();
        break;
      case 'shop':
        destination = const ShopScreen();
        break;
      case 'send':
        destination = const SendBookingScreen();
        break;
      case 'farm':
        destination = const FarmScreen();
        break;
      case 'build':
        destination = const BuildScreen();
        break;
      case 'cuan':
        destination = const AffiliateHubScreen();
        break;
      case 'menu_item':
        if (item.containsKey('merchant')) {
          destination = MerchantDetailScreen(merchant: item['merchant'] as Map<String, dynamic>);
        } else if (item.containsKey('store')) {
          final store = item['store'] as Map<String, dynamic>;
          final domain = _inferDomainFromStore(store);
          destination = MerchantDetailScreen(merchant: {'domain': domain, 'serviceType': domain, ...store});
        } else {
          destination = const FoodExploreScreen();
        }
        break;
      case 'merchant_food':
        destination = MerchantDetailScreen(merchant: item['merchant'] as Map<String, dynamic>);
        break;
      case 'merchant_shop':
      case 'merchant_farm':
      case 'merchant_build':
        final domain = target.replaceFirst('merchant_', '');
        final store = item['store'] as Map<String, dynamic>;
        destination = MerchantDetailScreen(merchant: {'domain': domain, 'serviceType': domain, ...store});
        break;
      default:
        destination = const FoodExploreScreen();
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
  }

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

    final fade = _isSearchActive ? 1.0 : (currentOffset / 70.0).clamp(0.0, 1.0);

    final stickyBgColor = isDark ? GageTheme.darkBackground : Colors.white;
    final headerColor = _isSearchActive
        ? stickyBgColor
        : stickyBgColor.withValues(alpha: fade);

    final iconBrightness = _isSearchActive || fade > 0.5
        ? (isDark ? Brightness.light : Brightness.dark)
        : Brightness.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: (_isSearchActive || fade > 0.5) && !isDark ? Brightness.light : Brightness.dark,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: headerColor,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(_isSearchActive ? 20.0 : (16.0 * fade)),
          ),
          boxShadow: _isSearchActive || fade > 0.05
              ? [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: _isSearchActive ? 0.12 : (0.08 * fade)),
                    blurRadius: _isSearchActive ? 16 : (10 * fade),
                    offset: Offset(0, _isSearchActive ? 5 : (3 * fade)),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Baris Atas: Input Search & Avatar Profil
            Row(
              children: [
                if (_isSearchActive) ...[
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : GageTheme.textPrimary,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      setState(() {
                        _isSearchActive = false;
                        _searchCtrl.clear();
                      });
                      _searchFocus.unfocus();
                    },
                  ),
                  const SizedBox(width: 6),
                ],

                // Search Bar Input Interaktif Langsung di Layar (Tanpa Modal Bottom Sheet)
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? GageTheme.darkSurface
                          : (_isSearchActive || fade > 0.6 ? Colors.grey.shade100 : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isSearchActive
                            ? GageTheme.primary
                            : (isDark
                                ? Colors.white12
                                : (fade > 0.6 ? Colors.grey.shade300 : Colors.transparent)),
                        width: _isSearchActive ? 1.4 : 1.0,
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
                          color: _isSearchActive ? GageTheme.primary : (isDark ? Colors.white70 : Colors.grey.shade700),
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _isSearchActive
                              ? TextField(
                                  controller: _searchCtrl,
                                  focusNode: _searchFocus,
                                  onChanged: (val) => setState(() {}),
                                  decoration: const InputDecoration(
                                    hintText: 'Cari layanan, toko, atau menu...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : GageTheme.textPrimary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _isSearchActive = true;
                                    });
                                    _searchFocus.requestFocus();
                                  },
                                  child: Text(
                                    'Cari layanan, toko, atau menu...',
                                    style: TextStyle(
                                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                        ),
                        if (_isSearchActive && _searchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() => _searchCtrl.clear()),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                if (!_isSearchActive) ...[
                  const SizedBox(width: 8),

                  // 1. Tombol Chat/Pesan Mandiri (Di sebelah kiri Lonceng Notifikasi)
                  // Badge Angka Unread Chat
                  AnimatedBuilder(
                    animation: NotificationService.instance,
                    builder: (context, _) {
                      final unreadChats = NotificationService.instance.unreadChatCount;
                      return InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChatHubScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          width: 36,
                          height: 38,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.chat_rounded,
                                size: 22,
                                color: isDark
                                    ? Colors.white
                                    : (fade > 0.4 ? GageTheme.textPrimary : Colors.white),
                                shadows: fade <= 0.4
                                    ? [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.55),
                                          blurRadius: 5,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ]
                                    : null,
                              ),
                              if (unreadChats > 0)
                                Positioned(
                                  top: 4,
                                  right: 1,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white, width: 1.2),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 15, minHeight: 14),
                                    child: Text(
                                      '${unreadChats.clamp(1, 99)}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        height: 1.05,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 4),

                  // 2. Tombol Lonceng Notifikasi Polosan (Badge Angka Unread Notifikasi)
                  AnimatedBuilder(
                    animation: NotificationService.instance,
                    builder: (context, _) {
                      return InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          width: 36,
                          height: 38,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.notifications_rounded,
                                size: 24,
                                color: isDark
                                    ? Colors.white
                                    : (fade > 0.4 ? GageTheme.textPrimary : Colors.white),
                                shadows: fade <= 0.4
                                    ? [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.55),
                                          blurRadius: 5,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ]
                                    : null,
                              ),
                              if (NotificationService.instance.unreadCount > 0)
                                Positioned(
                                  top: 3,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: GageTheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white, width: 1.2),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 15, minHeight: 14),
                                    child: Text(
                                      '${NotificationService.instance.unreadCount.clamp(1, 99)}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        height: 1.05,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  // Avatar Profil Pengguna
                  GestureDetector(
                    onTap: () => _showProfileDropdownMenu(context, auth, topPadding),
                    child: Container(
                      width: 38,
                      height: 38,
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
                            ? (user.avatarUrl!.startsWith('http')
                                ? Image.network(
                                    user.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Image.asset('assets/images/avatar_user.png', fit: BoxFit.cover),
                                  )
                                : Image.file(
                                    File(user.avatarUrl!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Image.asset('assets/images/avatar_user.png', fit: BoxFit.cover),
                                  ))
                            : Image.asset('assets/images/avatar_user.png', fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Panel Ekspansi Dropdown Pencarian Cerdas ke Bawah
            if (_isSearchActive) ...[
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.52,
                ),
                child: _buildSearchResultsList(context, isDark),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(BuildContext context, bool isDark) {
    final query = _searchCtrl.text.trim().toLowerCase();

    if (query.isEmpty) {
      // Tampilan Awal: Pintasan Cepat & Pencarian Populer (Bebas Gap Putih)
      return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pencarian Populer di Pracimantoro',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  'Rocket Chicken',
                  'Dimsum Sewu',
                  'Beras C4',
                  'Pupuk Urea',
                  'Semen Tiga Roda',
                  'Ojek Motor',
                  'Kirim Paket',
                ].map((keyword) {
                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _searchCtrl.text = keyword;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        keyword,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              Text(
                'Layanan Utama',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Builder(
                builder: (ctx) {
                  final services = _searchDirectory.where((e) => e['type'] == 'service').take(4).toList();
                  return MediaQuery.removePadding(
                    context: ctx,
                    removeTop: true,
                    removeBottom: true,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: services.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 2),
                      itemBuilder: (ctx, idx) => _buildSearchItemTile(services[idx], isDark),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    // Tampilan Hasil Pencarian Cerdas dengan Algoritma Relevansi
    // Menu (150) > Toko / Resto Merchant (90) > Layanan (20) + Bonus Kecocokan Awalan/Kata
    final scoredMatches = <Map<String, dynamic>>[];
    for (final item in _searchDirectory) {
      final t = (item['title'] as String).toLowerCase();
      final c = (item['category'] as String).toLowerCase();
      final k = (item['keywords'] as String).toLowerCase();
      final matchesQuery = t.contains(query) || c.contains(query) || k.contains(query);
      if (!matchesQuery) continue;

      int score = 0;
      final type = item['type'] as String;
      if (type == 'menu') {
        score += 150;
      } else if (type == 'merchant') {
        score += 90;
      } else if (type == 'service') {
        score += 20;
      }

      if (t == query) {
        score += 120;
      } else if (t.startsWith(query)) {
        score += 80;
      } else if (t.contains(query)) {
        score += 50;
      }

      if (c.contains(query)) score += 15;
      if (k.contains(query)) score += 8;

      scoredMatches.add({
        ...item,
        '_score': score,
      });
    }

    scoredMatches.sort((a, b) => (b['_score'] as int).compareTo(a['_score'] as int));

    if (scoredMatches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Tidak ada layanan atau toko untuk "$query"',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Coba gunakan kata kunci umum seperti motor, ayam, sembako, atau pupuk',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: scoredMatches.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
        ),
        itemBuilder: (ctx, idx) {
          final item = scoredMatches[idx];
          return _buildSearchItemTile(item, isDark);
        },
      ),
    );
  }

  Widget _buildSearchItemTile(Map<String, dynamic> item, bool isDark) {
    final type = item['type'] as String;
    Widget leadingWidget;

    if (type == 'service') {
      final iconAsset = item['iconAsset'] as String? ?? 'assets/icons/ic_food.png';
      leadingWidget = SizedBox(
        width: 38,
        height: 38,
        child: Image.asset(iconAsset, fit: BoxFit.contain),
      );
    } else {
      // Merchant atau Menu: Gambar Asli
      final imagePath = item['image'] as String? ?? 'assets/images/hero_promo_1.png';
      leadingWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.storefront_rounded, size: 20, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Type Badge Label
    String typeLabel;
    Color typeColor;
    if (type == 'menu') {
      typeLabel = 'Menu';
      typeColor = const Color(0xFFE52320);
    } else if (type == 'merchant') {
      typeLabel = 'Toko/Resto';
      typeColor = const Color(0xFF2563EB);
    } else {
      typeLabel = 'Layanan';
      typeColor = const Color(0xFF16A34A);
    }

    return InkWell(
      onTap: () => _onSelectSearchResult(item),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: Row(
          children: [
            leadingWidget,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : GageTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: typeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['category'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: isDark ? Colors.white24 : Colors.grey.shade400,
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
                                      ? (user.avatarUrl!.startsWith('http')
                                          ? Image.network(
                                              user.avatarUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => Image.asset('assets/images/avatar_user.png', fit: BoxFit.cover),
                                            )
                                          : Image.file(
                                              File(user.avatarUrl!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => Image.asset('assets/images/avatar_user.png', fit: BoxFit.cover),
                                            ))
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

                        // 2. Menu Pilihan Langsung ke Screen Terkait (Ramping & Tanpa Duplikasi)
                        _buildDropdownItem(
                          dialogCtx,
                          icon: Icons.edit_note_rounded,
                          title: 'Edit Data Diri',
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                            );
                          },
                          isDark: isDark,
                        ),
                        _buildDropdownItem(
                          dialogCtx,
                          icon: Icons.chat_outlined,
                          title: 'Pusat Bantuan CS WA',
                          onTap: () async {
                            Navigator.pop(dialogCtx);
                            final uri = Uri.parse('https://wa.me/6281226001000?text=Halo%20Admin%20GAGE%2C%20saya%20butuh%20bantuan');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          isDark: isDark,
                        ),
                        _buildDropdownItem(
                          dialogCtx,
                          icon: Icons.switch_account_rounded,
                          title: 'Ganti Akun',
                          onTap: () {
                            Navigator.pop(dialogCtx);
                            GageAccountSwitcherSheet.show(context);
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
                            final confirm = await GageFloatingSheet.showConfirm(
                              context: context,
                              title: 'Konfirmasi Keluar',
                              message: 'Apakah Anda yakin ingin keluar dari akun GAGE?',
                              confirmLabel: 'Keluar',
                              cancelLabel: 'Batal',
                              confirmColor: Colors.red,
                              icon: Icons.logout_rounded,
                            );
                            if (confirm == true) {
                              await auth.signOut();
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
