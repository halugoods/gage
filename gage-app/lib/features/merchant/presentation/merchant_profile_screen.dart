import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/merchant_menu_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_photo_picker_sheet.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_printer_settings_sheet.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_receipt_settings_sheet.dart';
import 'package:gage_app/features/merchant/presentation/widgets/operating_schedule_editor_sheet.dart';
import 'package:gage_app/shared/widgets/full_screen_map_picker.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';
import 'package:gage_app/shared/widgets/storefront_image.dart';

/// Screen Profil Kios & Pengaturan Operasional Merchant - Tab 4
/// Mengatur jam buka-tutup toko Senin-Minggu, foto lapak, koordinat peta,
/// printer bluetooth thermal, waktu masak, dan pusat bantuan.
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
  double _deliveryRadius = 7.0;

  String _activeMerchantId = MerchantStorefrontService.defaultPortalMerchantId;
  String _storeName = 'Dimsum Sewu';
  String _storeAddress = 'Jl. Raya Pracimantoro No. 14, Depan Pasar';
  String _landmark = '';
  String _storeBio = 'Spesialis Dimsum Kukus & Goreng Hangat Gurih';
  String _storeBanner = 'assets/images/resto_dimsum_sewu.png';
  String _storeLogo = 'assets/images/resto_dimsum_sewu.png';
  String _locationPhoto = 'assets/images/resto_dimsum_sewu.png';
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
        if (stored.landmark != null) {
          _landmark = stored.landmark!;
        }
        if (stored.deliveryRadius != null) {
          _deliveryRadius = stored.deliveryRadius!;
        }
        if (stored.bio != null && stored.bio!.trim().isNotEmpty) {
          _storeBio = stored.bio!;
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
      deliveryRadius: _deliveryRadius,
      bio: _storeBio,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avgRating = _ratingSummary != null && _ratingSummary!.totalReviews > 0
        ? '${_ratingSummary!.averageRating.toStringAsFixed(1)} ★'
        : 'Baru';
    final countLabel = _ratingSummary != null ? '${_ratingSummary!.totalReviews} Ulasan' : 'Belum ada';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
            // 1. Profil Outlet & Banner Kios Mitra (Self-Managed)
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: StorefrontImage(
                          path: _storeBanner,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          fallback: _fallbackBanner(),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: _showEditStoreProfileSheet,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Ubah Foto & Profil', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 14,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: ClipOval(
                            child: StorefrontImage(
                              path: _storeLogo,
                              fit: BoxFit.cover,
                              fallback: const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 28),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _storeName,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: GageTheme.accentGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'TERVERIFIKASI',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: GageTheme.accentGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _storeAddress,
                          style: const TextStyle(fontSize: 11.5, color: GageTheme.textSecondary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _storeBio,
                          style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                        const SizedBox(height: 10),

                        // Foto Lapak & Pin Peta Preview untuk Driver & Pembeli
                        InkWell(
                          onTap: _showEditStoreProfileSheet,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: StorefrontImage(
                                      path: _locationPhoto,
                                      fit: BoxFit.cover,
                                      fallback: Container(
                                        color: GageTheme.primaryLight,
                                        child: const Icon(Icons.photo_camera_back_rounded, color: GageTheme.primary),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Foto Lapak & Titik Peta',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Pin: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
                                        style: const TextStyle(fontSize: 11, color: GageTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                MiniLocationPreviewMap(
                                  location: LatLng(_latitude, _longitude),
                                  size: 48,
                                  borderRadius: 10,
                                  markerImagePath: _storeLogo,
                                  useMerchantPin: true,
                                  onTap: _showEditStoreProfileSheet,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showEditStoreProfileSheet,
                                icon: const Icon(Icons.edit_note_rounded, size: 16),
                                label: const Text('Edit Profil & Lapak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: GageTheme.primary,
                                  side: const BorderSide(color: GageTheme.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (ctx) => const MerchantMenuScreen()),
                                  );
                                },
                                icon: const Icon(Icons.restaurant_menu_rounded, size: 16),
                                label: const Text('Katalog Menu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GageTheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
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

            // 2. Tiga Metrik Performa Resto
            Row(
              children: [
                Expanded(child: _buildStatTile('Rating Resto', avgRating, countLabel, isDark)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatTile('Tepat Waktu', '99.2%', 'Standar SOP', isDark)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatTile('Waktu Masak', '14 Mnt', 'Rata-rata', isDark)),
              ],
            ),

            const SizedBox(height: 18),

            // 3. Status Operasional Toko
            const Text(
              'Status & Jam Operasional',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Buka Kios untuk Pesanan Masuk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text(
                      _isOpen ? 'Outlet tampil aktif di katalog pelanggan GAGE' : 'Outlet ditandai tutup sementara',
                      style: const TextStyle(fontSize: 11.5, color: GageTheme.textSecondary),
                    ),
                    value: _isOpen,
                    activeThumbColor: GageTheme.accentGreen,
                    onChanged: (v) async {
                      HapticFeedback.lightImpact();
                      setState(() => _isOpen = v);
                      await _persistStorefront();
                    },
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    onTap: _openScheduleEditor,
                    leading: const Icon(Icons.access_time_rounded, color: GageTheme.primary, size: 20),
                    title: const Text('Jam Buka Reguler', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(
                      _schedule.portalSubtitle(),
                      style: const TextStyle(fontSize: 11.5, color: GageTheme.textSecondary),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimasi Waktu Penyiapan Default:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('$_cookingTime Menit', style: const TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [10, 15, 20, 25].map((mins) {
                            final isSel = _cookingTime == mins;
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _cookingTime = mins);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSel ? GageTheme.primary : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$mins mnt',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4. PERANGKAT (Paritas 1:1 Nusa Kasir)
            Text(
              'PERANGKAT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.print_rounded, color: Colors.orange, size: 20),
                    ),
                    title: const Text('Printer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: const Text('Atur printer thermal', style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      MerchantPrinterSettingsSheet.show(context);
                    },
                  ),
                  Divider(height: 1, indent: 56, color: isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.orange, size: 20),
                    ),
                    title: const Text('Pengaturan Struk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: const Text('Atur footer struk & upload logo toko', style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      MerchantReceiptSettingsSheet.show(context, storeName: _storeName);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 6. Pusat Bantuan & WhatsApp Center
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_rounded, color: Colors.green, size: 20),
                    ),
                    title: const Text('WhatsApp Layanan Mitra GAGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: const Text('Bantuan kendala pesanan, menu, atau settlement dana', style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    onTap: () async {
                      final uri = Uri.parse('https://wa.me/628111222333?text=Halo%20Admin%20GAGE,%20saya%20mitra%20$_storeName');
                      if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, String subtitle, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: GageTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: GageTheme.primary)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9.5, color: GageTheme.textSecondary)),
        ],
      ),
    );
  }

  static Widget _fallbackBanner() => Container(
        height: 110,
        color: GageTheme.primaryLight,
        child: const Center(
          child: Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 36),
        ),
      );

  void _showEditStoreProfileSheet() {
    final nameCtrl = TextEditingController(text: _storeName);
    final addrCtrl = TextEditingController(text: _storeAddress);
    final landmarkCtrl = TextEditingController(text: _landmark);
    final bioCtrl = TextEditingController(text: _storeBio);
    final latCtrl = TextEditingController(text: _latitude.toStringAsFixed(6));
    final lngCtrl = TextEditingController(text: _longitude.toStringAsFixed(6));

    String currentBanner = _storeBanner;
    String currentLogo = _storeLogo;
    String currentLocationPhoto = _locationPhoto;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final parsedLat = double.tryParse(latCtrl.text.trim()) ?? _latitude;
          final parsedLng = double.tryParse(lngCtrl.text.trim()) ?? _longitude;

          return Container(
            padding: EdgeInsets.only(
              top: 16,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Pengaturan Profil & Kios', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text(
                    'Perubahan otomatis tampil di Info Toko pelanggan dan navigasi kurir driver.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Nama Toko / Kios',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Misal: Dimsum Sewu Pracimantoro',
                      hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.storefront_rounded, size: 18, color: GageTheme.primary),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: GageTheme.primary, width: 1.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Alamat Lengkap Toko',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: addrCtrl,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Jl. Raya Pracimantoro No. 12',
                      hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: GageTheme.primary),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: GageTheme.primary, width: 1.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Patokan Lapak / Landmark Kurir',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: landmarkCtrl,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Misal: Depan mushola, samping Alfamidi',
                      hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.flag_outlined, size: 18, color: GageTheme.primary),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: GageTheme.primary, width: 1.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bio / Deskripsi Singkat Toko',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: bioCtrl,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Dimsum kukus dan goreng hangat khas Pracimantoro',
                      hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.info_outline_rounded, size: 18, color: GageTheme.primary),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: GageTheme.primary, width: 1.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Foto Profil & Banner Toko (Image Picker Riil)
                  Text(
                    'Foto & Visual Toko',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),

                  // 1. Logo / Profil Toko (1:1)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: StorefrontImage(
                              path: currentLogo,
                              fit: BoxFit.cover,
                              fallback: Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.storefront_rounded, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Foto Profil / Logo Toko',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Format persegi rasio 1:1',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                              ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.photo_camera_rounded, size: 14),
                          label: const Text('Ganti (1:1)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 2. Banner Sampul Toko (16:9)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 60,
                            height: 38,
                            child: StorefrontImage(
                              path: currentBanner,
                              fit: BoxFit.cover,
                              fallback: Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_rounded, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Banner / Sampul Toko',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Format lanskap rasio 16:9',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                              ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.image_rounded, size: 14),
                          label: const Text('Ganti (16:9)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 3. Foto Lapak Depan
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: StorefrontImage(
                              path: currentLocationPhoto,
                              fit: BoxFit.cover,
                              fallback: Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.storefront_rounded, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Foto Tampak Depan Kios',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Foto patokan untuk kurir',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final path = await MerchantPhotoPickerSheet.show(context);
                            if (path != null) {
                              setSheetState(() => currentLocationPhoto = path);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.storefront_rounded, size: 14),
                          label: const Text('Pilih Foto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Titik Pin Lokasi Kios / Toko (Bebas Angka Koordinat Mentah)
                  Text(
                    'Titik Lokasi Peta Kios / Toko',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        MiniLocationPreviewMap(
                          location: LatLng(parsedLat, parsedLng),
                          size: 60,
                          borderRadius: 12,
                          markerImagePath: currentLogo,
                          useMerchantPin: true,
                          onTap: () async {
                            final res = await FullScreenMapPicker.open(
                              context,
                              title: 'Tentukan Titik Kios Toko',
                              initialLocation: LatLng(parsedLat, parsedLng),
                              initialFullAddress: addrCtrl.text,
                            );
                            if (res != null) {
                              setSheetState(() {
                                latCtrl.text = res.location.latitude.toStringAsFixed(6);
                                lngCtrl.text = res.location.longitude.toStringAsFixed(6);
                                if (addrCtrl.text.trim().isEmpty) {
                                  addrCtrl.text = res.fullAddress;
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kecamatan Pracimantoro',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Titik GPS terverifikasi untuk panduan kurir GAGE',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      HapticFeedback.lightImpact();
                                      final res = await FullScreenMapPicker.open(
                                        context,
                                        title: 'Tentukan Titik Kios Toko',
                                        initialLocation: LatLng(parsedLat, parsedLng),
                                        initialFullAddress: addrCtrl.text,
                                      );
                                      if (res != null) {
                                        setSheetState(() {
                                          latCtrl.text = res.location.latitude.toStringAsFixed(6);
                                          lngCtrl.text = res.location.longitude.toStringAsFixed(6);
                                          if (addrCtrl.text.trim().isEmpty) {
                                            addrCtrl.text = res.fullAddress;
                                          }
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: GageTheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.map_rounded, size: 13),
                                    label: const Text('Buka Peta', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      HapticFeedback.lightImpact();
                                      final pos = await LocationService.getCurrentLocation(forceFresh: true);
                                      setSheetState(() {
                                        latCtrl.text = pos.latitude.toStringAsFixed(6);
                                        lngCtrl.text = pos.longitude.toStringAsFixed(6);
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(Icons.my_location_rounded, size: 13),
                                    label: const Text('GPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final nextLat = double.tryParse(latCtrl.text.trim()) ?? _latitude;
                        final nextLng = double.tryParse(lngCtrl.text.trim()) ?? _longitude;
                        setState(() {
                          _storeName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _storeName;
                          _storeAddress = addrCtrl.text.trim().isNotEmpty ? addrCtrl.text.trim() : _storeAddress;
                          _landmark = landmarkCtrl.text.trim();
                          _storeBio = bioCtrl.text.trim().isNotEmpty ? bioCtrl.text.trim() : _storeBio;
                          _storeBanner = currentBanner;
                          _storeLogo = currentLogo;
                          _locationPhoto = currentLocationPhoto.trim().isNotEmpty ? currentLocationPhoto.trim() : _locationPhoto;
                          _latitude = nextLat;
                          _longitude = nextLng;
                        });
                        await _persistStorefront();
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          GageToast.show(this.context, 'Profil, foto lapak & titik lokasi berhasil disimpan!', type: GageToastType.success);
                        }
                      },
                      child: const Text('Simpan Profil & Lokasi Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
