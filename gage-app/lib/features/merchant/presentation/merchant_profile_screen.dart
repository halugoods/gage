import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/merchant_review_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_terms_and_privacy_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_branch_switcher_sheet.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_help_center_sheet.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_location_change_request_sheet.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_photo_picker_sheet.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_printer_settings_sheet.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_receipt_settings_sheet.dart';
import 'package:gage_app/features/merchant/presentation/widgets/operating_schedule_editor_sheet.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';
import 'package:gage_app/shared/widgets/storefront_image.dart';

/// Screen Pengaturan Merchant (Paritas Arsitektur Shopee Partner) - Tab 4
/// Mengelola informasi toko, pengaturan pesanan, notifikasi alarm pesanan,
/// konfigurasi printer thermal, pengajuan perubahan lokasi toko, dan jam operasional.
class MerchantProfileScreen extends StatefulWidget {
  final String? merchantId;
  final String? merchantName;

  const MerchantProfileScreen({
    super.key,
    this.merchantId,
    this.merchantName,
  });

  @override
  State<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends State<MerchantProfileScreen> {
  bool _isOpen = true;
  int _cookingTime = 15;
  bool _selfPickupEnabled = true;
  bool _autoConfirmOrders = false;
  bool _alarmRepeating = true;
  bool _popupNotification = true;

  String _activeMerchantId = MerchantStorefrontService.defaultPortalMerchantId;
  String _storeName = 'Dimsum Sewu Pracimantoro (Pusat)';
  String _storeAddress = 'Jl. Raya Pracimantoro No. 14, Depan Pasar';
  String _landmark = 'Depan Pasar Pracimantoro, samping Alfamidi';
  String _storeBanner = 'assets/images/resto_dimsum_sewu.png';
  String _storeLogo = 'assets/images/resto_dimsum_sewu.png';
  String _locationPhoto = 'assets/images/resto_dimsum_sewu.png';
  String _whatsapp = '085156955735';
  double _latitude = MerchantStorefrontService.defaultPracimantoroCenter.latitude;
  double _longitude = MerchantStorefrontService.defaultPracimantoroCenter.longitude;

  MerchantOperatingSchedule _schedule = MerchantOperatingSchedule.defaults();
  MerchantRatingSummary? _ratingSummary;
  bool _didResolveRouteArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didResolveRouteArgs) return;
    _didResolveRouteArgs = true;

    String? routeMerchantId = widget.merchantId;
    String? routeMerchantName = widget.merchantName;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      routeMerchantId ??= args['merchantId']?.toString();
      routeMerchantName ??= args['merchantName']?.toString();
    }

    if (routeMerchantId != null && routeMerchantId.trim().isNotEmpty) {
      _activeMerchantId = routeMerchantId.trim();
    }
    if (routeMerchantName != null && routeMerchantName.trim().isNotEmpty) {
      _storeName = routeMerchantName.trim();
    }
    _loadStorefront();
  }

  Future<void> _loadStorefront() async {
    final stored = await MerchantStorefrontService.loadStorefront(
      _activeMerchantId,
      merchantName: _storeName,
    );
    final rating = await MerchantStorefrontService.loadRatingSummary(
      merchantId: _activeMerchantId,
      merchantName: _storeName,
      domain: 'food',
    );
    if (!mounted) return;
    setState(() {
      if (stored != null) {
        if (stored.name != null && stored.name!.trim().isNotEmpty) {
          _storeName = stored.name!;
        }
        if (stored.address != null && stored.address!.trim().isNotEmpty) {
          _storeAddress = stored.address!;
        }
        if (stored.landmark != null && stored.landmark!.trim().isNotEmpty) {
          _landmark = stored.landmark!;
        }
        if (stored.bannerPhoto != null && stored.bannerPhoto!.trim().isNotEmpty) {
          _storeBanner = stored.bannerPhoto!;
        }
        if (stored.logoPhoto != null && stored.logoPhoto!.trim().isNotEmpty) {
          _storeLogo = stored.logoPhoto!;
        }
        if (stored.locationPhoto != null && stored.locationPhoto!.trim().isNotEmpty) {
          _locationPhoto = stored.locationPhoto!;
        }
        if (stored.latitude != null) _latitude = stored.latitude!;
        if (stored.longitude != null) _longitude = stored.longitude!;
        if (stored.isOpen != null) _isOpen = stored.isOpen!;
        if (stored.schedule != null) _schedule = stored.schedule!;
      } else {
        final seedCoord = MerchantStorefrontService.seedCoordinateFor(_activeMerchantId);
        if (seedCoord != null) {
          _latitude = seedCoord.latitude;
          _longitude = seedCoord.longitude;
        }
      }
      _ratingSummary = rating;
    });
  }

  Future<void> _persistStorefront() async {
    final existing = await MerchantStorefrontService.loadStorefront(_activeMerchantId);
    final dataToSave = (existing ?? MerchantStorefrontData(merchantId: _activeMerchantId)).copyWith(
      name: _storeName,
      address: _storeAddress,
      landmark: _landmark,
      bannerPhoto: _storeBanner,
      logoPhoto: _storeLogo,
      locationPhoto: _locationPhoto,
      latitude: _latitude,
      longitude: _longitude,
      isOpen: _isOpen,
      schedule: _schedule,
    );
    await MerchantStorefrontService.saveStorefront(dataToSave);
  }

  Future<void> _openScheduleEditor() async {
    final updated = await showOperatingScheduleEditorSheet(
      context: context,
      initialSchedule: _schedule,
    );
    if (updated != null && mounted) {
      setState(() => _schedule = updated);
      await _persistStorefront();
      if (mounted) {
        GageToast.show(
          context,
          'Jam operasional berhasil diperbarui!',
          type: GageToastType.success,
        );
      }
    }
  }

  String get _storeIdFormatted {
    final cleanId = _activeMerchantId.toLowerCase();
    String sector = 'FD';
    if (cleanId.contains('shop') || cleanId.contains('toko') || cleanId.contains('sembako')) {
      sector = 'SH';
    } else if (cleanId.contains('farm') || cleanId.contains('tani') || cleanId.contains('kebun')) {
      sector = 'FM';
    }
    final digits = RegExp(r'\d+').allMatches(cleanId).map((m) => m.group(0)).join();
    final seq = digits.isNotEmpty ? digits.padLeft(2, '0').substring(0, digits.length > 2 ? 2 : digits.length) : '01';
    return 'GAGE-PRC-$sector$seq';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    final avgRating = _ratingSummary != null && _ratingSummary!.totalReviews > 0
        ? '${_ratingSummary!.averageRating.toStringAsFixed(1)} ★'
        : 'Baru';
    final countLabel = _ratingSummary != null ? '${_ratingSummary!.totalReviews} Ulasan' : 'Belum ada';
    String displayStoreName = _storeName;
    try {
      displayStoreName = context.watch<MerchantOrderProvider>().activeBranchName;
    } catch (_) {}

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: cardBg,
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Header Toko (Shopee Partner Architecture)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar Kotak Rounded 14px
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: GageTheme.primary.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: StorefrontImage(
                        path: _storeLogo,
                        fit: BoxFit.cover,
                        fallback: const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info Toko & Store ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayStoreName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.5,
                                  letterSpacing: -0.2,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: GageTheme.accentGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'TERVERIFIKASI',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: GageTheme.accentGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kecamatan Pracimantoro, Kab. Wonogiri',
                          style: TextStyle(fontSize: 11, color: subColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'ID Toko: $_storeIdFormatted',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Clipboard.setData(ClipboardData(text: _storeIdFormatted));
                                GageToast.show(context, 'ID Toko $_storeIdFormatted berhasil disalin!');
                              },
                              borderRadius: BorderRadius.circular(999),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(Icons.copy_rounded, size: 12, color: GageTheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. Metrik Rating Resto Singkat
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    'Rating Toko',
                    avgRating,
                    countLabel,
                    isDark,
                    cardBg,
                    borderColor,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MerchantReviewScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildStatTile('Kepatuhan SOP', '99.5%', 'Standar GAGE', isDark, cardBg, borderColor)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatTile('Waktu Masak', '$_cookingTime Mnt', 'Estimasi Default', isDark, cardBg, borderColor)),
              ],
            ),

            const SizedBox(height: 16),

            // 3. Grid Menu Fitur Utama (Shopee Partner Architecture - 7 Tiles)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  // Baris 1: 4 Menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGridMenuItem(
                        icon: Icons.storefront_rounded,
                        iconColor: const Color(0xFFEF4444),
                        bgColor: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.2 : 0.09),
                        title: 'Informasi\nToko',
                        onTap: _showInfoTokoSheet,
                        isDark: isDark,
                      ),
                      _buildGridMenuItem(
                        icon: Icons.assignment_turned_in_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        bgColor: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.2 : 0.09),
                        title: 'Pengaturan\nPesanan',
                        onTap: _showPengaturanPesananSheet,
                        isDark: isDark,
                      ),
                      _buildGridMenuItem(
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        bgColor: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.2 : 0.09),
                        title: 'Pengaturan\nNotifikasi',
                        onTap: _showPengaturanNotifikasiSheet,
                        isDark: isDark,
                      ),
                      _buildGridMenuItem(
                        icon: Icons.print_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        bgColor: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.2 : 0.09),
                        title: 'Printer\nThermal',
                        onTap: () => MerchantPrinterSettingsSheet.show(context),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Baris 2: 3 Menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGridMenuItem(
                        icon: Icons.receipt_long_rounded,
                        iconColor: const Color(0xFF10B981),
                        bgColor: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.09),
                        title: 'Pengaturan\nStruk',
                        onTap: () => MerchantReceiptSettingsSheet.show(context, storeName: _storeName),
                        isDark: isDark,
                      ),
                      _buildGridMenuItem(
                        icon: Icons.assignment_rounded,
                        iconColor: const Color(0xFF6366F1),
                        bgColor: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.2 : 0.09),
                        title: 'Pengajuan\nSaya',
                        onTap: _showPengajuanSayaSheet,
                        isDark: isDark,
                      ),
                      _buildGridMenuItem(
                        icon: Icons.help_outline_rounded,
                        iconColor: const Color(0xFF14B8A6),
                        bgColor: const Color(0xFF14B8A6).withValues(alpha: isDark ? 0.2 : 0.09),
                        title: 'Pusat\nBantuan',
                        onTap: _openHelpCenter,
                        isDark: isDark,
                      ),
                      // Spacer untuk menjaga perataan 4-kolom simetris
                      const SizedBox(width: 68),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4. Operasional Toko
            Text(
              'OPERASIONAL KIOS',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: subColor,
              ),
            ),
            const SizedBox(height: 8),

            Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Buka Toko untuk Pesanan Masuk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: Text(
                        _isOpen ? 'Toko tampil buka di katalog pelanggan GAGE Pracimantoro' : 'Toko ditandai tutup sementara',
                        style: TextStyle(fontSize: 11.5, color: subColor),
                      ),
                      value: _isOpen,
                      activeTrackColor: GageTheme.primary.withValues(alpha: 0.45),
                      activeThumbColor: GageTheme.primary,
                      onChanged: (v) async {
                        HapticFeedback.lightImpact();
                        setState(() => _isOpen = v);
                        await _persistStorefront();
                      },
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
                    ListTile(
                      onTap: _openScheduleEditor,
                      leading: const Icon(Icons.access_time_rounded, color: GageTheme.primary, size: 20),
                      title: const Text('Jam Operasional Mingguan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(
                        _schedule.portalSubtitle(),
                        style: TextStyle(fontSize: 11.5, color: subColor),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
                    ListTile(
                      onTap: () => MerchantBranchSwitcherSheet.show(context),
                      leading: const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 20),
                      title: const Text('Kelola Cabang Outlet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(
                        'Ganti outlet aktif atau tambah cabang baru',
                        style: TextStyle(fontSize: 11.5, color: subColor),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
                    ListTile(
                      onTap: _openLocationChangeSheet,
                      leading: const Icon(Icons.share_location_rounded, color: GageTheme.primary, size: 20),
                      title: const Text('Ajukan Pindah Lokasi Toko', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(
                        'Pindah alamat fisik atau titik koordinat GPS toko',
                        style: TextStyle(fontSize: 11.5, color: subColor),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 5. Informasi & Bantuan
            Text(
              'INFORMASI & BANTUAN',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: subColor,
              ),
            ),
            const SizedBox(height: 8),

            Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.support_agent_rounded, color: GageTheme.primary, size: 20),
                      title: const Text('Pusat Bantuan & Hotline Dispatcher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: Text('Hotline darurat Pracimantoro & FAQ mitra', style: TextStyle(fontSize: 11.5, color: subColor)),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                      onTap: _openHelpCenter,
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined, color: Colors.blueGrey, size: 20),
                      title: const Text('Kebijakan Privasi & Kemitraan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MerchantTermsAndPrivacyScreen()),
                        );
                      },
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded, color: Colors.blueGrey, size: 20),
                      title: const Text('Tentang Aplikasi GAGE Merchant', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('Versi 1.0.4+45 (Pracimantoro)', style: TextStyle(fontSize: 11, color: subColor)),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                      onTap: () {
                        GageToast.show(context, 'GAGE Pracimantoro v1.0.4+45');
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGridMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                height: 1.15,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    String subtitle,
    bool isDark,
    Color cardBg,
    Color borderColor, {
    VoidCallback? onTap,
  }) {
    final tileContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(fontSize: 10.5, color: GageTheme.textSecondary)),
              if (onTap != null) ...[
                const SizedBox(width: 3),
                const Icon(Icons.arrow_forward_ios_rounded, size: 8, color: GageTheme.primary),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: GageTheme.primary)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9.5, color: GageTheme.textSecondary)),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: tileContent,
        ),
      );
    }
    return tileContent;
  }

  Future<void> _openHelpCenter() async {
    HapticFeedback.lightImpact();
    await MerchantHelpCenterSheet.show(
      context,
      storeName: _storeName,
      storeId: _storeIdFormatted,
    );
  }

  Future<void> _openLocationChangeSheet() async {
    HapticFeedback.lightImpact();
    final req = await MerchantLocationChangeRequestSheet.show(
      context,
      merchantId: _activeMerchantId,
      currentAddress: _storeAddress,
      currentLatitude: _latitude,
      currentLongitude: _longitude,
      markerImagePath: _storeLogo,
    );
    if (req != null && mounted) {
      GageToast.show(
        context,
        'Pengajuan pindah lokasi toko berhasil dicatat di menu Pengajuan Saya',
        type: GageToastType.success,
      );
    }
  }

  // ── Sheet 1: Informasi Toko (Shopee Partner Style) ──
  void _showInfoTokoSheet() {
    final nameCtrl = TextEditingController(text: _storeName);
    final waCtrl = TextEditingController(text: _whatsapp);
    String currentBanner = _storeBanner;
    String currentLogo = _storeLogo;

    GageFloatingSheet.show(
      context: context,
      title: 'Informasi Toko',
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
          final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
          final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kelola branding foto profil, banner, dan kontak operasional.',
                style: TextStyle(fontSize: 11, color: subColor),
              ),
              const SizedBox(height: 14),

              // Foto Profil (1:1)
              Text('Foto Profil / Logo Toko (Rasio 1:1)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: StorefrontImage(
                          path: currentLogo,
                          fit: BoxFit.cover,
                          fallback: const Icon(Icons.storefront_rounded, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Logo Toko', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textColor)),
                          Text('Tampil di navigasi pembeli & struk', style: TextStyle(fontSize: 10.5, color: subColor)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final path = await MerchantPhotoPickerSheet.show(context);
                        if (path != null) {
                          setSheetState(() => currentLogo = path);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.photo_camera_rounded, size: 13),
                      label: const Text('Ganti (1:1)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

                  // Banner Sampul (16:9)
                  Text('Banner / Sampul Toko (Rasio 16:9)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 64,
                            height: 38,
                            child: StorefrontImage(
                              path: currentBanner,
                              fit: BoxFit.cover,
                              fallback: const Icon(Icons.image_rounded, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Banner Header', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textColor)),
                              Text('Header visual di katalog GAGE', style: TextStyle(fontSize: 10.5, color: subColor)),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final path = await MerchantPhotoPickerSheet.show(context, aspectRatio: 16 / 9);
                            if (path != null) {
                              setSheetState(() => currentBanner = path);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.image_rounded, size: 13),
                          label: const Text('Ganti (16:9)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Nama Toko
                  Text('Nama Toko / Toko', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(fontSize: 13, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Misal: Dimsum Sewu Pracimantoro',
                      hintStyle: TextStyle(fontSize: 12, color: subColor),
                      prefixIcon: const Icon(Icons.storefront_rounded, size: 18, color: GageTheme.primary),
                      filled: true,
                      fillColor: inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: GageTheme.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // WhatsApp
                  Text('Nomor WhatsApp Koordinasi Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: waCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: 13, color: textColor),
                    decoration: InputDecoration(
                      hintText: '085156955735',
                      hintStyle: TextStyle(fontSize: 12, color: subColor),
                      prefixIcon: const Icon(Icons.phone_android_rounded, size: 18, color: GageTheme.primary),
                      filled: true,
                      fillColor: inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: GageTheme.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Alamat Toko & Peta (Read-Only)
                  Text('Lokasi Toko Fisik & Titik Peta (Terverifikasi)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            MiniLocationPreviewMap(
                              location: LatLng(_latitude, _longitude),
                              size: 48,
                              borderRadius: 10,
                              markerImagePath: currentLogo,
                              useMerchantPin: true,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_storeAddress, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor), maxLines: 2),
                                  const SizedBox(height: 2),
                                  Text('Patokan: $_landmark', style: TextStyle(fontSize: 10.5, color: subColor), maxLines: 1),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Alamat toko dan titik GPS adalah data resmi terverifikasi saat pendaftaran awal. Jika lapak berpindah lokasi, ajukan perubahan melalui tombol di bawah:',
                          style: TextStyle(fontSize: 10.5, color: subColor, height: 1.25),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _openLocationChangeSheet();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GageTheme.primary,
                              side: const BorderSide(color: GageTheme.primary),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.share_location_rounded, size: 14),
                            label: const Text('Ajukan Pindah Lokasi Toko', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final newName = nameCtrl.text.trim();
                        if (newName.isEmpty) {
                          GageToast.show(context, 'Nama toko wajib diisi', type: GageToastType.warning);
                          return;
                        }
                        setState(() {
                          _storeName = newName;
                          _storeLogo = currentLogo;
                          _storeBanner = currentBanner;
                          _whatsapp = waCtrl.text.trim().isNotEmpty ? waCtrl.text.trim() : _whatsapp;
                        });
                        await _persistStorefront();
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          GageToast.show(this.context, 'Informasi toko berhasil disimpan!', type: GageToastType.success);
                        }
                      },
                      child: const Text('Simpan Informasi Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

  // ── Sheet 2: Pengaturan Pesanan (Shopee Partner Style) ──
  void _showPengaturanPesananSheet() {
    int tempCooking = _cookingTime;
    bool tempPickup = _selfPickupEnabled;
    bool tempAuto = _autoConfirmOrders;

    GageFloatingSheet.show(
      context: context,
      title: 'Pengaturan Pesanan',
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
          final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Atur waktu penyiapan makanan dan alur konfirmasi.', style: TextStyle(fontSize: 11, color: subColor)),
              const SizedBox(height: 16),

              // Waktu Masak Segmented Kapsul
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Estimasi Waktu Penyiapan Default:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textColor)),
                  Text('$tempCooking Menit', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: GageTheme.primary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [10, 15, 20, 25].map((mins) {
                  final isSel = tempCooking == mins;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheetState(() => tempCooking = mins);
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? GageTheme.primary : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$mins mnt',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : subColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pesanan Ambil di Toko (Self-Pickup)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Izinkan pelanggan mengambil pesanan langsung ke toko', style: TextStyle(fontSize: 11, color: subColor)),
                value: tempPickup,
                activeTrackColor: GageTheme.primary.withValues(alpha: 0.45),
                activeThumbColor: GageTheme.primary,
                onChanged: (v) => setSheetState(() => tempPickup = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Konfirmasi Pesanan Otomatis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Langsung terima pesanan baru saat masuk tanpa sentuh layar', style: TextStyle(fontSize: 11, color: subColor)),
                value: tempAuto,
                activeTrackColor: GageTheme.primary.withValues(alpha: 0.45),
                activeThumbColor: GageTheme.primary,
                onChanged: (v) => setSheetState(() => tempAuto = v),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() {
                      _cookingTime = tempCooking;
                      _selfPickupEnabled = tempPickup;
                      _autoConfirmOrders = tempAuto;
                    });
                    Navigator.pop(ctx);
                    GageToast.show(this.context, 'Pengaturan pesanan berhasil disimpan!');
                  },
                  child: const Text('Simpan Pengaturan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Sheet 3: Pengaturan Notifikasi (Shopee Partner Style) ──
  void _showPengaturanNotifikasiSheet() {
    bool tempAlarm = _alarmRepeating;
    bool tempPopup = _popupNotification;

    GageFloatingSheet.show(
      context: context,
      title: 'Pengaturan Notifikasi',
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pastikan notifikasi alarm dapur tidak terlewat saat pesanan masuk.', style: TextStyle(fontSize: 11, color: subColor)),
              const SizedBox(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dering Pesanan Baru Berulang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Bunyikan alarm pesanan berulang hingga pesanan ditekan / diterima', style: TextStyle(fontSize: 11, color: subColor)),
                value: tempAlarm,
                activeTrackColor: GageTheme.primary.withValues(alpha: 0.45),
                activeThumbColor: GageTheme.primary,
                onChanged: (v) => setSheetState(() => tempAlarm = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notifikasi Pop-up di Layar Kunci', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Tampilkan banner detail pesanan saat aplikasi di latar belakang', style: TextStyle(fontSize: 11, color: subColor)),
                value: tempPopup,
                activeTrackColor: GageTheme.primary.withValues(alpha: 0.45),
                activeThumbColor: GageTheme.primary,
                onChanged: (v) => setSheetState(() => tempPopup = v),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() {
                      _alarmRepeating = tempAlarm;
                      _popupNotification = tempPopup;
                    });
                    Navigator.pop(ctx);
                    GageToast.show(this.context, 'Pengaturan notifikasi berhasil disimpan!');
                  },
                  child: const Text('Simpan Pengaturan Notifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Sheet 4: Pengajuan Saya (Shopee Partner Style) ──
  Future<void> _showPengajuanSayaSheet() async {
    final req = await MerchantStorefrontService.loadLocationChangeRequest(_activeMerchantId);

    if (!mounted) return;
    GageFloatingSheet.show(
      context: context,
      title: 'Pengajuan Saya',
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
        final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status peninjauan perubahan informasi toko oleh Admin GAGE.', style: TextStyle(fontSize: 11, color: subColor)),
            const SizedBox(height: 16),

            if (req != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pindah Lokasi Toko Fisik',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'MENUNGGU PERSETUJUAN ADMIN',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Alamat Asal: ${req.currentAddress}', style: TextStyle(fontSize: 11, color: subColor)),
                      const SizedBox(height: 3),
                      Text('Alamat Baru: ${req.newAddress}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                      if (req.newLandmark.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('Patokan: ${req.newLandmark}', style: TextStyle(fontSize: 11, color: subColor)),
                      ],
                      const SizedBox(height: 6),
                      Text('Alasan: "${req.reason}"', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: subColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 36, color: subColor),
                      const SizedBox(height: 8),
                      Text('Belum Ada Pengajuan Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                      const SizedBox(height: 4),
                      Text(
                        'Semua informasi toko Anda saat ini telah sesuai dengan data verifikasi pendaftaran awal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: subColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openLocationChangeSheet();
                  },
                  icon: const Icon(Icons.share_location_rounded, size: 16),
                  label: const Text('Buat Pengajuan Pindah Toko Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          );
        },
      );
    }
  }
