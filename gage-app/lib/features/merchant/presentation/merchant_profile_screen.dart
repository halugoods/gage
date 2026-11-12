import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/merchant_menu_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_bottom_nav_bar.dart';
import 'package:gage_app/features/merchant/presentation/widgets/operating_schedule_editor_sheet.dart';
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
  bool _autoPrint = true;
  int _cookingTime = 15;
  double _deliveryRadius = 7.0;

  String _activeMerchantId = MerchantStorefrontService.defaultPortalMerchantId;
  String _storeName = 'Dimsum Sewu';
  String _storeAddress = 'Jl. Raya Pracimantoro No. 14, Depan Pasar';
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
    await MerchantStorefrontService.saveStorefront(
      MerchantStorefrontData(
        merchantId: _activeMerchantId,
        name: _storeName,
        address: _storeAddress,
        bio: _storeBio,
        bannerPhoto: _storeBanner,
        logoPhoto: _storeLogo,
        locationPhoto: _locationPhoto,
        latitude: _latitude,
        longitude: _longitude,
        isOpen: _isOpen,
        schedule: _schedule,
      ),
    );
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
          'Kios & Pengaturan Mitra',
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
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
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
                  const Divider(height: 1),
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
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimasi Waktu Masak Default:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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

            // 4. Pengaturan Printer Kasir Bluetooth SPP
            const Text(
              'Printer Struk & Tiket Thermal',
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
                  const ListTile(
                    leading: Icon(Icons.print_rounded, color: GageTheme.primary, size: 22),
                    title: Text('Printer SPP Bluetooth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text('Thermal 58mm (RPP02N / Iware / Panda)', style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
                    trailing: Text('TERHUBUNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: GageTheme.accentGreen)),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Auto-Print Tiket Dapur', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: const Text('Cetak tiket otomatis saat pesanan baru masuk', style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
                    value: _autoPrint,
                    activeThumbColor: GageTheme.primary,
                    onChanged: (v) => setState(() => _autoPrint = v),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: const Text('Uji Cetak Sample 58mm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test print 58mm dikirim ke printer bluetooth SPP.'),
                            backgroundColor: GageTheme.accentGreen,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 5. Radius Pengantaran Slider
            const Text(
              'Jangkauan Pesan Antar',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Radius Layanan:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${_deliveryRadius.toStringAsFixed(1)} KM', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: GageTheme.primary)),
                    ],
                  ),
                  Slider(
                    value: _deliveryRadius,
                    min: 2.0,
                    max: 12.0,
                    divisions: 10,
                    activeColor: GageTheme.primary,
                    label: '${_deliveryRadius.toStringAsFixed(1)} KM',
                    onChanged: (v) => setState(() => _deliveryRadius = v),
                  ),
                  const Text(
                    'Menjangkau seluruh pelosok desa di Pracimantoro dan sekitarnya.',
                    style: TextStyle(fontSize: 11, color: GageTheme.textSecondary),
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
      bottomNavigationBar: const MerchantBottomNavBar(currentIndex: 4),
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
    final bioCtrl = TextEditingController(text: _storeBio);
    final locationPhotoUrlCtrl = TextEditingController(text: _locationPhoto);
    final latCtrl = TextEditingController(text: _latitude.toStringAsFixed(6));
    final lngCtrl = TextEditingController(text: _longitude.toStringAsFixed(6));

    String currentBanner = _storeBanner;
    String currentLogo = _storeLogo;
    String currentLocationPhoto = _locationPhoto;

    final presetPhotos = [
      {'label': 'Lapak Utama', 'path': 'assets/images/resto_dimsum_sewu.png'},
      {'label': 'Toko Sembako', 'path': 'assets/images/shop_hero_banner.png'},
      {'label': 'Etalase Resto', 'path': 'assets/images/resto_rocket_chicken.png'},
    ];

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
                  const Text('Kelola Profil, Foto Lapak & Pin', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text(
                    'Perubahan otomatis tampil di Info Toko pelanggan dan navigasi kurir driver.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Toko / Kios',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addrCtrl,
                    decoration: InputDecoration(
                      labelText: 'Alamat Lengkap Toko',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bioCtrl,
                    decoration: InputDecoration(
                      labelText: 'Bio / Deskripsi Singkat Toko',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Foto Lapak / Lokasi Merchant
                  const Text('Foto Lapak / Tampak Lokasi Merchant:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 68,
                          height: 68,
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  final picker = ImagePicker();
                                  final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                                  if (file != null) {
                                    setSheetState(() {
                                      currentLocationPhoto = file.path;
                                      locationPhotoUrlCtrl.text = file.path;
                                    });
                                  }
                                } catch (_) {}
                              },
                              icon: const Icon(Icons.photo_library_rounded, size: 16),
                              label: const Text('Pilih Foto Galeri', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locationPhotoUrlCtrl,
                    onChanged: (v) => setSheetState(() => currentLocationPhoto = v.trim()),
                    decoration: InputDecoration(
                      labelText: 'Atau URL / Asset Foto Lapak',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: presetPhotos.map((b) {
                        final isSel = currentLocationPhoto == b['path'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(b['label']!),
                            selected: isSel,
                            onSelected: (_) => setSheetState(() {
                              currentLocationPhoto = b['path']!;
                              locationPhotoUrlCtrl.text = b['path']!;
                            }),
                            selectedColor: GageTheme.primary.withValues(alpha: 0.15),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Koordinat Titik Pin Peta Merchant
                  const Text('Koordinat Titik Pin Lokasi Toko:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                          onChanged: (_) => setSheetState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: lngCtrl,
                          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                          onChanged: (_) => setSheetState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      MiniLocationPreviewMap(
                        location: LatLng(parsedLat, parsedLng),
                        size: 52,
                        borderRadius: 10,
                        markerImagePath: currentLogo,
                        useMerchantPin: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: () async {
                        final nextLat = double.tryParse(latCtrl.text.trim()) ?? _latitude;
                        final nextLng = double.tryParse(lngCtrl.text.trim()) ?? _longitude;
                        setState(() {
                          _storeName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _storeName;
                          _storeAddress = addrCtrl.text.trim().isNotEmpty ? addrCtrl.text.trim() : _storeAddress;
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
                      child: const Text('Simpan Profil & Lokasi Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
