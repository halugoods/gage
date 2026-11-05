import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/admin/presentation/widgets/in_place_banner_editor_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Tab 4: Kurasi Merchant & In-Place Banner Editor
/// Menggabungkan dua fungsi utama kurasi operasional:
/// 1. Verifikasi pendaftaran merchant warung, resto, dan barang bekas (BaBe)
/// 2. WYSIWYG In-Place Banner Editor untuk seluruh portal (Customer, Driver, Merchant, Admin)
class AdminCurationBannerTab extends StatefulWidget {
  const AdminCurationBannerTab({super.key});

  @override
  State<AdminCurationBannerTab> createState() => _AdminCurationBannerTabState();
}

class _AdminCurationBannerTabState extends State<AdminCurationBannerTab> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Segmentasi Utama: 0: Kurasi Merchant & BaBe, 1: Editor Banner
  int _primarySegment = 0;

  // State Kurasi Merchant
  String _curationFilter = 'Menunggu'; // 'Semua', 'Menunggu', 'Disetujui'
  final List<Map<String, dynamic>> _merchantSubmissions = [
    {
      'id': 'MCH-101',
      'type': 'MERCHANT',
      'name': 'Ayam Geprek Sambal Korek Bu Sri',
      'owner': 'Ibu Sri Wahyuni',
      'phone': '6281322334455',
      'category': 'GageFood • Kuliner Siap Saji',
      'address': 'Jl. Lintas Selatan KM 1 (Dekat Alfamart)',
      'status': 'Menunggu',
      'menuCount': 8,
      'notes': 'Foto menu lengkap, jam buka 09:00 - 20:00 WIB. Perlu aktivasi Kitchen Display System.',
    },
    {
      'id': 'MCH-102',
      'type': 'MERCHANT',
      'name': 'Kios Pupuk & Bibit Tani Makmur',
      'owner': 'Pak Wardoyo',
      'phone': '6285299887766',
      'category': 'GageTani • Saprotan & Bibit',
      'address': 'Desa Sedayu RT 03/02 Pracimantoro',
      'status': 'Menunggu',
      'menuCount': 14,
      'notes': 'Menyediakan pupuk organik, bibit jagung hibrida & saprotan. Siap kirim via GageSend.',
    },
    {
      'id': 'BABE-001',
      'type': 'BABE',
      'name': 'iPad Gen 9 64GB Space Grey Mulus',
      'owner': 'Pak Joko Purnomo',
      'phone': '6281234567890',
      'category': 'Barang Bekas (BaBe) • Gadget',
      'address': 'Dusun Gedong RT 02/01 Pracimantoro',
      'status': 'Menunggu',
      'price': 3200000,
      'notes': 'Baterai Health 91%, box + charger ori lengkap. Driver terdekat siap cek fisik jam 14:00.',
    },
    {
      'id': 'MCH-103',
      'type': 'MERCHANT',
      'name': 'Dimsum Sewu Mas Agus',
      'owner': 'Mas Agus Setiawan',
      'phone': '6289911223344',
      'category': 'GageFood • Camilan & Frozen',
      'address': 'Jl. Raya Pracimantoro No. 14',
      'status': 'Disetujui',
      'menuCount': 12,
      'notes': 'Printer thermal bluetooth SPP 58mm sudah terpasang dan berhasil cetak struk.',
    },
  ];

  // State Banner Editor
  String _selectedPortal = 'Customer'; // 'Customer', 'Driver', 'Merchant', 'Admin'
  String _selectedTarget = 'customer_home_hero';

  static const List<Map<String, dynamic>> portals = [
    {'id': 'Customer', 'label': 'Pelanggan', 'icon': Icons.person_rounded},
    {'id': 'Driver', 'label': 'Driver', 'icon': Icons.two_wheeler_rounded},
    {'id': 'Merchant', 'label': 'Resto/Kios', 'icon': Icons.storefront_rounded},
    {'id': 'Admin', 'label': 'Admin', 'icon': Icons.admin_panel_settings_rounded},
  ];

  static const Map<String, List<Map<String, String>>> portalScreens = {
    'Customer': [
      {'target': 'customer_home_hero', 'name': 'Beranda Utama (16:9)'},
      {'target': 'customer_food_explore', 'name': 'GageFood Explore (16:9)'},
      {'target': 'customer_tani', 'name': 'GageTani Panen (16:9)'},
      {'target': 'customer_shop', 'name': 'GageShop Sembako (16:9)'},
    ],
    'Driver': [
      {'target': 'driver_home_info', 'name': 'Info Mitra Driver (3:1)'},
    ],
    'Merchant': [
      {'target': 'merchant_home_info', 'name': 'Edukasi Mitra Resto (3:1)'},
    ],
    'Admin': [
      {'target': 'admin_promo', 'name': 'Broadcast Admin (16:9)'},
    ],
  };

  void _openInPlaceEditorForTarget(String target) {
    final bannerService = BannerManagerService.instance;
    // Map internal key
    String internalKey = 'beranda';
    if (target.contains('food')) internalKey = 'food';
    if (target.contains('tani')) internalKey = 'tani';
    if (target.contains('shop')) internalKey = 'shop';

    final cfg = bannerService.getBanner(internalKey);

    InPlaceBannerEditorSheet.showConfirmationAndOpen(
      context: context,
      screenTarget: target,
      title: cfg.title,
      subtitle: cfg.subtitle,
      badge: cfg.badge,
      imageUrl: cfg.imagePath,
      actionUrl: '',
      aspectRatio: target.contains('info') ? 3.0 / 1.0 : 16.0 / 9.0,
      onSaved: () {
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Primary Segment Switcher (Apple Segmented Control)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSegmentButton(
                  title: 'Kurasi Merchant & BaBe',
                  index: 0,
                  icon: Icons.verified_user_rounded,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildSegmentButton(
                  title: 'In-Place Banner Editor',
                  index: 1,
                  icon: Icons.view_carousel_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_primarySegment == 0) ...[
          // Sub-view: Kurasi Merchant & BaBe
          _buildCurationView(isDark),
        ] else ...[
          // Sub-view: In-Place Banner Editor
          _buildBannerEditorView(isDark),
        ],
      ],
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required int index,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _primarySegment == index;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _primarySegment = index);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? GageTheme.primary : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? GageTheme.primary : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // KURASI MERCHANT & BABE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCurationView(bool isDark) {
    final filtered = _merchantSubmissions.where((m) {
      if (_curationFilter == 'Semua') return true;
      return m['status'] == _curationFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status filter pills
        Row(
          children: [
            _buildCurationStatusPill('Semua', isDark),
            const SizedBox(width: 6),
            _buildCurationStatusPill('Menunggu', isDark),
            const SizedBox(width: 6),
            _buildCurationStatusPill('Disetujui', isDark),
          ],
        ),
        const SizedBox(height: 12),

        ...filtered.map((item) => _buildCurationCard(item, isDark)),
      ],
    );
  }

  Widget _buildCurationStatusPill(String filter, bool isDark) {
    final isSelected = _curationFilter == filter;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _curationFilter = filter);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? GageTheme.primary.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? GageTheme.primary : Colors.transparent,
          ),
        ),
        child: Text(
          filter,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? GageTheme.primary : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildCurationCard(Map<String, dynamic> item, bool isDark) {
    final isApproved = item['status'] == 'Disetujui';
    final isBaBe = item['type'] == 'BABE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isBaBe ? Colors.purple.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isBaBe ? Icons.devices_other_rounded : Icons.storefront_rounded,
                  color: isBaBe ? Colors.purple : Colors.orange.shade800,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['name'],
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isApproved
                                ? const Color(0xFF00AA13).withValues(alpha: 0.12)
                                : Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item['status'],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isApproved ? const Color(0xFF00AA13) : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['category']} • Pemilik: ${item['owner']}',
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item['address'],
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Catatan: ${item['notes']}',
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  final phone = item['phone'] ?? '';
                  if (phone.isNotEmpty) {
                    launchUrl(Uri.parse('https://wa.me/$phone?text=Halo%20Admin%20GAGE%20Pracimantoro%20mengenai%20pendaftaran'));
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                label: const Text('Chat WA', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                ),
              ),
              const Spacer(),
              if (!isApproved) ...[
                OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => item['status'] = 'Ditolak');
                    GageToast.show(context, 'Pengajuan ${item['name']} ditolak.', type: GageToastType.info);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: const Text('Tolak', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    setState(() => item['status'] = 'Disetujui');
                    GageToast.show(context, 'Mitra ${item['name']} berhasil disetujui & aktif!', type: GageToastType.success);
                  },
                  icon: const Icon(Icons.check_rounded, size: 15),
                  label: const Text('Setujui Mitra', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AA13),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00AA13).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF00AA13)),
                      SizedBox(width: 4),
                      Text(
                        'Sudah Tayang di Aplikasi',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF00AA13)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IN-PLACE BANNER EDITOR
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBannerEditorView(bool isDark) {
    final screens = portalScreens[_selectedPortal] ?? [];
    final bannerService = BannerManagerService.instance;

    String internalKey = 'beranda';
    if (_selectedTarget.contains('food')) internalKey = 'food';
    if (_selectedTarget.contains('tani')) internalKey = 'tani';
    if (_selectedTarget.contains('shop')) internalKey = 'shop';

    final cfg = bannerService.getBanner(internalKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Portal Selector Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: portals.map((p) {
              final isSelected = _selectedPortal == p['id'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedPortal = p['id'];
                      _selectedTarget = (portalScreens[p['id']] ?? []).first['target']!;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GageTheme.primary
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? GageTheme.primary : (isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          p['icon'],
                          size: 15,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          p['label'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Screen Target Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTarget,
              isExpanded: true,
              items: screens.map((s) {
                return DropdownMenuItem<String>(
                  value: s['target'],
                  child: Text(s['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedTarget = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Live WYSIWYG Device Mockup Frame
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'LIVE BANNER PREVIEW (WYSIWYG)',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: Colors.grey),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: GageTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _selectedTarget.contains('info') ? 'ASIO 3:1' : 'ASIO 16:9',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: GageTheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Mockup Graphic Card
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: _selectedTarget.contains('info') ? (3.0 / 1.0) : (16.0 / 9.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        cfg.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade800,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_rounded, color: Colors.white54, size: 32),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: GageTheme.primary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            cfg.badge,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cfg.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (cfg.subtitle.isNotEmpty)
                              Text(
                                cfg.subtitle,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.85),
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
              ),
              const SizedBox(height: 14),

              // Button Trigger In-Place Editor
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openInPlaceEditorForTarget(_selectedTarget),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text(
                    'Buka In-Place Banner Editor (CRUD)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
