import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/features/admin/presentation/portal_interactive_preview_screen.dart';

/// Screen Manajemen Banner Terpadu Multi-Portal (Admin Command Tower)
/// Memisahkan banner per-portal (Customer, Driver, Merchant, Admin) dengan
/// Live Interactive Device Mockup Preview di masing-masing portal.
class AdminBannerScreen extends StatefulWidget {
  const AdminBannerScreen({super.key});

  @override
  State<AdminBannerScreen> createState() => _AdminBannerScreenState();
}

class _AdminBannerScreenState extends State<AdminBannerScreen> {
  // Portal yang sedang aktif dipilih
  String _selectedPortal = 'Customer'; // 'Customer', 'Driver', 'Merchant', 'Admin'
  String _selectedTarget = 'customer_home_hero';
  bool _isLoading = true;
  bool _showLivePreview = true;
  List<Map<String, dynamic>> _banners = [];

  // Definisi Portal & Layar
  static const List<Map<String, dynamic>> portals = [
    {
      'id': 'Customer',
      'label': 'Pelanggan',
      'icon': Icons.person_rounded,
      'badge': '16:9',
      'screens': ['customer_home_hero', 'customer_food_explore', 'customer_tani', 'customer_shop'],
    },
    {
      'id': 'Driver',
      'label': 'Driver',
      'icon': Icons.two_wheeler_rounded,
      'badge': '3:1',
      'screens': ['driver_home_info'],
    },
    {
      'id': 'Merchant',
      'label': 'Resto/Kios',
      'icon': Icons.storefront_rounded,
      'badge': '3:1',
      'screens': ['merchant_home_info'],
    },
    {
      'id': 'Admin',
      'label': 'Admin',
      'icon': Icons.admin_panel_settings_rounded,
      'badge': '16:9',
      'screens': ['admin_promo'],
    },
  ];

  // Spesifikasi Rekomendasi Resolusi Standalone per-Layar
  static const Map<String, Map<String, dynamic>> screenSpecs = {
    'customer_home_hero': {
      'label': 'Beranda Utama',
      'portal': 'Customer',
      'ratio': '16:9',
      'ratioVal': 16.0 / 9.0,
      'dimension': '1280 × 720 px',
      'defaultImg': 'assets/images/home_hero_banner.png',
      'defaultTitle': 'GAGE Pracimantoro SuperApp',
      'defaultSubtitle': 'Pesan kuliner, sembako, dan kirim barang se-kecamatan',
      'badge': 'PROMO UTAMA',
      'desc': 'Hero banner promosi utama di bagian atas beranda pelanggan.',
    },
    'customer_food_explore': {
      'label': 'GAGE Food',
      'portal': 'Customer',
      'ratio': '16:9',
      'ratioVal': 16.0 / 9.0,
      'dimension': '1280 × 720 px',
      'defaultImg': 'assets/images/food_hero_banner.png',
      'defaultTitle': 'Laper? GAGE Food-in dari resto terenak!',
      'defaultSubtitle': 'Diskon s/d 50% & ongkir flat bersahabat mitra lokal',
      'badge': 'KULINER HARI INI',
      'desc': 'Banner promosi kuliner, resto rekomendasi, dan diskon makanan.',
    },
    'customer_tani': {
      'label': 'GAGE Tani',
      'portal': 'Customer',
      'ratio': '16:9',
      'ratioVal': 16.0 / 9.0,
      'dimension': '1280 × 720 px',
      'defaultImg': 'assets/images/tani_hero_banner.png',
      'defaultTitle': 'Panen Segar Hasil Bumi Pracimantoro',
      'defaultSubtitle': 'Langsung dari petani lokal, pupuk organik, dan saprotan',
      'badge': 'PANEN RAYA',
      'desc': 'Banner panen raya, saprotan, dan hasil tani Pracimantoro.',
    },
    'customer_shop': {
      'label': 'GAGE Shop',
      'portal': 'Customer',
      'ratio': '16:9',
      'ratioVal': 16.0 / 9.0,
      'dimension': '1280 × 720 px',
      'defaultImg': 'assets/images/send_hero_banner.png',
      'defaultTitle': 'Belanja Sembako Hemat Tanpa Repot',
      'defaultSubtitle': 'Beras, minyak, telur diantar 15 menit sampai dapur',
      'badge': 'WARUNG LOKAL',
      'desc': 'Banner promo belanja sembako dan kebutuhan harian warung.',
    },
    'driver_home_info': {
      'label': 'Beranda Driver (GoPartner)',
      'portal': 'Driver',
      'ratio': '3:1',
      'ratioVal': 3.0 / 1.0,
      'dimension': '900 × 300 px',
      'defaultImg': 'assets/images/home_hero_banner.png',
      'defaultTitle': 'Tingkatkan Layanan, Raih Bonus Harian!',
      'defaultSubtitle': 'Gunakan helm SNI & selalu utamakan keselamatan penumpang',
      'badge': 'INFO MITRA',
      'desc': 'Banner info keselamatan berkendara & insentif driver.',
    },
    'merchant_home_info': {
      'label': 'Beranda Resto & Kios',
      'portal': 'Merchant',
      'ratio': '3:1',
      'ratioVal': 3.0 / 1.0,
      'dimension': '900 × 300 px',
      'defaultImg': 'assets/images/food_hero_banner.png',
      'defaultTitle': 'Tingkatkan Penjualan Dapurmu Hari Ini!',
      'defaultSubtitle': 'Update stok menu sebelum jam makan siang agar laris',
      'badge': 'INFO RESTO',
      'desc': 'Banner edukasi mitra merchant, panduan komisi & stok bahan.',
    },
    'admin_promo': {
      'label': 'Command Tower Promo',
      'portal': 'Admin',
      'ratio': '16:9',
      'ratioVal': 16.0 / 9.0,
      'dimension': '1280 × 720 px',
      'defaultImg': 'assets/images/home_hero_banner.png',
      'defaultTitle': 'Radar Armada & Logistik Terpadu',
      'defaultSubtitle': 'Pantau persebaran driver dan traffic pesanan 24 jam',
      'badge': 'TOWER OPS',
      'desc': 'Banner pengumuman operasional internal tim command tower.',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() => _isLoading = true);
    final data = await GageApiClient.getAllBannersForAdmin(screenTarget: _selectedTarget);
    if (!mounted) return;
    setState(() {
      _banners = data;
      _isLoading = false;
    });
  }

  void _onSelectPortal(String portalId) {
    HapticFeedback.lightImpact();
    final p = portals.firstWhere((e) => e['id'] == portalId);
    final firstScreen = (p['screens'] as List<String>).first;
    setState(() {
      _selectedPortal = portalId;
      _selectedTarget = firstScreen;
    });
    _loadBanners();
  }

  void _onSelectScreen(String screenTarget) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedTarget = screenTarget;
    });
    _loadBanners();
  }

  Future<void> _handleDeleteBanner(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Banner?'),
        content: Text('Banner "$title" akan dihapus secara permanen dari Cloudflare D1.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      final success = await GageApiClient.deleteBanner(id);
      if (mounted) {
        if (success) {
          GageToast.show(context, 'Banner berhasil dihapus dari Cloudflare!', type: GageToastType.success);
          BannerManagerService.instance.loadFromPrefs();
          _loadBanners();
        } else {
          GageToast.show(context, 'Gagal menghapus banner', type: GageToastType.error);
        }
      }
    }
  }

  void _showBannerFormModal({Map<String, dynamic>? initialData}) {
    HapticFeedback.lightImpact();
    final isEdit = initialData != null;
    final spec = screenSpecs[_selectedTarget]!;

    final titleCtrl = TextEditingController(text: initialData?['title'] ?? spec['defaultTitle']);
    final subtitleCtrl = TextEditingController(text: initialData?['subtitle'] ?? spec['defaultSubtitle']);
    final badgeCtrl = TextEditingController(text: initialData?['badge'] ?? spec['badge']);
    final imageCtrl = TextEditingController(text: initialData?['image_url'] ?? spec['defaultImg']);
    final actionCtrl = TextEditingController(text: initialData?['action_url'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: GageTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.art_track_rounded, color: GageTheme.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'Edit Banner Standalone' : 'Tambah Banner Baru',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                              Text(
                                '${spec['portal']}: ${spec['label']} • ${spec['dimension']} (${spec['ratio']})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // LIVE CARD PREVIEW DALAM MODAL
                    const Text('Live Card Preview (Realtime):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildBannerCardPreview(
                      title: titleCtrl.text,
                      subtitle: subtitleCtrl.text,
                      badge: badgeCtrl.text,
                      imageUrl: imageCtrl.text,
                      aspectRatio: spec['ratioVal'] as double,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Input Judul
                    TextField(
                      controller: titleCtrl,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Judul Banner *',
                        hintText: 'Contoh: ${spec['defaultTitle']}',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Input Subtitle
                    TextField(
                      controller: subtitleCtrl,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Deskripsi / Subtitle',
                        hintText: 'Contoh: ${spec['defaultSubtitle']}',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Input Badge Tag
                    TextField(
                      controller: badgeCtrl,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Badge Tag (Label Merah)',
                        hintText: 'Contoh: ${spec['badge']}',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Input URL Gambar
                    TextField(
                      controller: imageCtrl,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        labelText: 'URL / Path Gambar Banner *',
                        hintText: 'assets/images/home_hero_banner.png atau https://...',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty || imageCtrl.text.trim().isEmpty) {
                            GageToast.show(context, 'Judul dan URL gambar wajib diisi!', type: GageToastType.warning);
                            return;
                          }

                          Navigator.pop(ctx);
                          HapticFeedback.heavyImpact();

                          if (isEdit) {
                            final success = await GageApiClient.updateBanner(
                              initialData['id'],
                              {
                                'title': titleCtrl.text.trim(),
                                'subtitle': subtitleCtrl.text.trim(),
                                'badge': badgeCtrl.text.trim(),
                                'image_url': imageCtrl.text.trim(),
                                'action_url': actionCtrl.text.trim(),
                                'screen_target': _selectedTarget,
                              },
                            );
                            if (mounted) {
                              if (success) {
                                GageToast.show(context, 'Banner berhasil diperbarui!', type: GageToastType.success);
                                await BannerManagerService.instance.updateBanner(
                                  _selectedTarget,
                                  BannerConfig(
                                    menuKey: _selectedTarget,
                                    menuName: spec['label'],
                                    title: titleCtrl.text.trim(),
                                    subtitle: subtitleCtrl.text.trim(),
                                    badge: badgeCtrl.text.trim(),
                                    imagePath: imageCtrl.text.trim(),
                                  ),
                                );
                                _loadBanners();
                              } else {
                                GageToast.show(context, 'Gagal update banner', type: GageToastType.error);
                              }
                            }
                          } else {
                            final res = await GageApiClient.createBanner(
                              screenTarget: _selectedTarget,
                              title: titleCtrl.text.trim(),
                              subtitle: subtitleCtrl.text.trim(),
                              imageUrl: imageCtrl.text.trim(),
                              actionUrl: actionCtrl.text.trim(),
                              aspectRatio: spec['ratio'] as String,
                            );
                            if (mounted) {
                              if (res != null) {
                                GageToast.show(context, 'Banner baru berhasil disimpan ke Cloudflare!', type: GageToastType.success);
                                await BannerManagerService.instance.updateBanner(
                                  _selectedTarget,
                                  BannerConfig(
                                    menuKey: _selectedTarget,
                                    menuName: spec['label'],
                                    title: titleCtrl.text.trim(),
                                    subtitle: subtitleCtrl.text.trim(),
                                    badge: badgeCtrl.text.trim(),
                                    imagePath: imageCtrl.text.trim(),
                                  ),
                                );
                                _loadBanners();
                              } else {
                                GageToast.show(context, 'Gagal menambah banner baru', type: GageToastType.error);
                              }
                            }
                          }
                        },
                        child: Text(
                          isEdit ? 'Simpan Perubahan ke Cloud' : 'Terbitkan Banner ke Cloud',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spec = screenSpecs[_selectedTarget]!;
    final portalData = portals.firstWhere((p) => p['id'] == _selectedPortal);
    final availableScreens = portalData['screens'] as List<String>;

    // Dapatkan data banner aktif (dari list cloud atau fallback spec)
    final activeBanner = _banners.isNotEmpty
        ? _banners.first
        : {
            'title': spec['defaultTitle'],
            'subtitle': spec['defaultSubtitle'],
            'badge': spec['badge'],
            'image_url': spec['defaultImg'],
            'is_active': 1,
          };

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manajemen Banner Multi-Portal',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              'Per-Portal Standalone • Live Mockup Preview',
              style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Buka Live App Fullscreen ($_selectedPortal)',
            icon: const Icon(Icons.fullscreen_rounded, color: GageTheme.primary, size: 28),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PortalInteractivePreviewScreen(initialPortal: _selectedPortal),
                ),
              );
            },
          ),
          IconButton(
            tooltip: _showLivePreview ? 'Sembunyikan Mockup' : 'Tampilkan Mockup',
            icon: Icon(_showLivePreview ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: GageTheme.primary),
            onPressed: () {
              setState(() => _showLivePreview = !_showLivePreview);
            },
          ),
          IconButton(
            tooltip: 'Refresh Banner',
            icon: const Icon(Icons.refresh_rounded, color: GageTheme.primary),
            onPressed: _loadBanners,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. TINGKAT UTAMA: Tab Pemilih Portal (Customer / Driver / Merchant / Admin)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Row(
                children: portals.map((p) {
                  final isSelected = p['id'] == _selectedPortal;
                  final icon = p['icon'] as IconData;
                  final label = p['label'] as String;
                  final ratioBadge = p['badge'] as String;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _onSelectPortal(p['id']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? GageTheme.primary
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? GageTheme.primary
                                  : (isDark ? Colors.white10 : Colors.grey.shade300),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: GageTheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 18,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : (isDark ? Colors.white12 : Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  ratioBadge,
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // 2. TINGKAT KEDUA: Sub-Screen Selector (Khusus jika portal punya > 1 screen)
            if (availableScreens.length > 1)
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: availableScreens.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final targetKey = availableScreens[i];
                    final s = screenSpecs[targetKey]!;
                    final isSelected = targetKey == _selectedTarget;

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _onSelectScreen(targetKey),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? Colors.white12 : Colors.red.shade50)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? GageTheme.primary
                                : (isDark ? Colors.white10 : Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: GageTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Text(
                              s['label'] as String,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? GageTheme.primary
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // 3. DAFTAR ISI: LIVE PREVIEW & DAFTAR BANNER
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                children: [
                  // 0. AKSI UTAMA: BUKA LIVE APP FULLSCREEN (1 SCREEN PENUH 100% INTERAKTIF)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PortalInteractivePreviewScreen(initialPortal: _selectedPortal),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: GageTheme.primary, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: GageTheme.primary.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Buka Live App $_selectedPortal Fullscreen',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: GageTheme.accentGreen,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '100% INTERAKTIF',
                                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Jalankan aplikasi 1 layar penuh & uji coba interaksi bebas layaknya native app',
                                    style: TextStyle(color: Colors.white70, fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // A. LIVE INTERACTIVE DEVICE MOCKUP PREVIEW
                  if (_showLivePreview) ...[
                    _buildPortalDeviceMockup(
                      portal: _selectedPortal,
                      screenTarget: _selectedTarget,
                      spec: spec,
                      bannerData: activeBanner,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // B. SPESIFIKASI RESOLUSI BANNER INFO BAR
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: GageTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.aspect_ratio_rounded, color: GageTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${spec['portal']}: ${spec['label']} (${spec['ratio']})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                              Text(
                                'Resolusi: ${spec['dimension']} • ${spec['desc']}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // C. DAFTAR BANNER DARI CLOUDFLARE D1
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daftar Banner Cloud D1 (${_banners.length})',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                      Text(
                        'Target: $_selectedTarget',
                        style: const TextStyle(fontSize: 11, color: GageTheme.textSecondary, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_banners.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada banner di Cloudflare D1 untuk layar ini.',
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Menggunakan banner default dari assets lokal.',
                            style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._banners.map((b) {
                      final id = b['id'] ?? '';
                      final title = b['title'] ?? '';
                      final subtitle = b['subtitle'] ?? '';
                      final badge = b['badge'] ?? '';
                      final imgUrl = b['image_url'] ?? '';
                      final isActive = (b['is_active'] == 1 || b['is_active'] == true);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Banner Image Preview dengan Aspek Rasio Sesuai Layar
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: AspectRatio(
                                aspectRatio: spec['ratioVal'] as double,
                                child: _buildImage(imgUrl),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (badge.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: GageTheme.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            badge.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isActive ? 'AKTIF' : 'NONAKTIF',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit_outlined, size: 15),
                                        label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                        onPressed: () => _showBannerFormModal(initialData: b),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Colors.red),
                                        label: const Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 12)),
                                        onPressed: () => _handleDeleteBanner(id, title),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: GageTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: Text('Tambah Banner ${spec['ratio']}'),
        onPressed: () => _showBannerFormModal(),
      ),
    );
  }

  // WIDGET CARD PREVIEW
  static Widget _buildBannerCardPreview({
    required String title,
    required String subtitle,
    required String badge,
    required String imageUrl,
    required double aspectRatio,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(imageUrl),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.70),
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (badge.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: GageTheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    if (title.isNotEmpty)
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                      ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET DEVICE MOCKUP PREVIEW PER PORTAL
  Widget _buildPortalDeviceMockup({
    required String portal,
    required String screenTarget,
    required Map<String, dynamic> spec,
    required Map<String, dynamic> bannerData,
    required bool isDark,
  }) {
    final title = bannerData['title'] ?? spec['defaultTitle'];
    final subtitle = bannerData['subtitle'] ?? spec['defaultSubtitle'];
    final badge = bannerData['badge'] ?? spec['badge'];
    final imageUrl = bannerData['image_url'] ?? spec['defaultImg'];
    final ratioVal = spec['ratioVal'] as double;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GageTheme.primary.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Mockup
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: GageTheme.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.smartphone_rounded, size: 16, color: GageTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Live Mockup: $portal (${spec['label']})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: GageTheme.primary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: GageTheme.accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fiber_manual_record_rounded, size: 8, color: GageTheme.accentGreen),
                      SizedBox(width: 4),
                      Text('LIVE REALTIME', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: GageTheme.accentGreen)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PortalInteractivePreviewScreen(initialPortal: portal),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: GageTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fullscreen_rounded, size: 13, color: Colors.white),
                        SizedBox(width: 3),
                        Text(
                          'Full 1 Screen',
                          style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tampilan Per-Portal Mockup
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (portal == 'Driver') ...[
                  // Driver Mockup (GoPartner Standard)
                  _buildMiniDriverHeader(isDark),
                  const SizedBox(height: 8),
                  _buildMiniAutobidBar(isDark),
                  const SizedBox(height: 10),
                  _buildBannerCardPreview(
                    title: title,
                    subtitle: subtitle,
                    badge: badge,
                    imageUrl: imageUrl,
                    aspectRatio: ratioVal,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildMiniDriverStatusCard(isDark),
                ] else if (portal == 'Merchant') ...[
                  // Merchant Mockup (Resto Standard)
                  _buildMiniMerchantHeader(isDark),
                  const SizedBox(height: 10),
                  _buildBannerCardPreview(
                    title: title,
                    subtitle: subtitle,
                    badge: badge,
                    imageUrl: imageUrl,
                    aspectRatio: ratioVal,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildMiniMerchantOrderCard(isDark),
                ] else if (portal == 'Admin') ...[
                  // Admin Mockup (Command Tower)
                  _buildMiniAdminHeader(isDark),
                  const SizedBox(height: 10),
                  _buildBannerCardPreview(
                    title: title,
                    subtitle: subtitle,
                    badge: badge,
                    imageUrl: imageUrl,
                    aspectRatio: ratioVal,
                    isDark: isDark,
                  ),
                ] else ...[
                  // Customer Mockup (SuperApp Beranda / Food)
                  _buildMiniCustomerHeader(screenTarget, isDark),
                  const SizedBox(height: 10),
                  _buildBannerCardPreview(
                    title: title,
                    subtitle: subtitle,
                    badge: badge,
                    imageUrl: imageUrl,
                    aspectRatio: ratioVal,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildMiniCustomerServiceGrid(isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mini Mockup Helpers
  static Widget _buildMiniDriverHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Text('S', style: TextStyle(color: Colors.white, fontSize: 10))),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Syamsul Maarif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                Text('AD 4521 WN • 4.96 ★', style: TextStyle(fontSize: 9.5, color: GageTheme.textSecondary)),
              ],
            ),
          ),
          Text('[ ONLINE ]', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  static Widget _buildMiniAutobidBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Alokasi Otomatis (Autobid)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          Text('AKTIF', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  static Widget _buildMiniDriverStatusCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.navigation_rounded, size: 14, color: GageTheme.primary),
          SizedBox(width: 6),
          Expanded(child: Text('Driver Online (Pracimantoro Kota)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  static Widget _buildMiniMerchantHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.restaurant_rounded, size: 14, color: GageTheme.primary),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dimsum Sewu Pracimantoro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                Text('Kios Buka • SPP Printer Siap', style: TextStyle(fontSize: 9.5, color: Colors.green)),
              ],
            ),
          ),
          Icon(Icons.toggle_on_rounded, color: Colors.green, size: 24),
        ],
      ),
    );
  }

  static Widget _buildMiniMerchantOrderCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('1 Pesanan Aktif (Menunggu Konfirmasi)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600)),
          Text('Rp 28.000', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: GageTheme.primary)),
        ],
      ),
    );
  }

  static Widget _buildMiniCustomerHeader(String screen, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, size: 14, color: GageTheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              screen.contains('food') ? 'GAGE Food • Pracimantoro' : 'Kirim ke: Dusun Gedong RT 02/01',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5),
            ),
          ),
          const Icon(Icons.search_rounded, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  static Widget _buildMiniCustomerServiceGrid(bool isDark) {
    final services = ['Ride', 'Car', 'Food', 'Send', 'Shop', 'BaBe', 'Tani', 'Clean'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: services.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(s, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  }

  static Widget _buildMiniAdminHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.radar_rounded, size: 14, color: GageTheme.primary),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'GAGE Command Tower • 12 Driver Online (Pracimantoro)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: const Color(0xFF1E293B),
          child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 24)),
        ),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: const Color(0xFF1E293B),
        child: const Center(child: Icon(Icons.image_outlined, color: Colors.white24, size: 24)),
      ),
    );
  }
}
