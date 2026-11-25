import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/routing/portal_routes.dart';
import 'package:gage_app/core/services/gage_audio_service.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/merchant_review_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_terms_and_privacy_screen.dart';
import 'package:gage_app/features/merchant/presentation/settings/merchant_location_and_requests_screen.dart';
import 'package:gage_app/features/merchant/presentation/settings/merchant_operating_schedule_screen.dart';
import 'package:gage_app/features/merchant/presentation/settings/merchant_printer_settings_screen.dart';
import 'package:gage_app/features/merchant/presentation/settings/merchant_receipt_settings_screen.dart';
import 'package:gage_app/features/merchant/presentation/settings/merchant_store_info_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_branch_switcher_sheet.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_help_center_sheet.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/storefront_image.dart';

/// Halaman Utama Pengaturan Mitra Merchant (Customer & Menu Pesanan Design Parity)
/// Menggunakan arsitektur Seamless Inset Grouped Cards + Smart Split:
/// - Form/Preview panjang ke halaman Full Screen
/// - Toggle cepat ke GageFloatingSheet
/// - Sinkronisasi penuh dengan MerchantOrderProvider, MerchantStorefrontService, dan SharedPreferences
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
  static const String _appVersionLabel = 'Versi 1.0.4+50 • Pracimantoro';

  bool _isOpen = true;
  int _cookingTime = 15;
  bool _selfPickupEnabled = true;
  bool _autoConfirmOrders = false;
  bool _alarmRepeating = true;
  bool _popupNotification = true;
  int _receiptHeaderPx = 20;

  String _activeMerchantId = MerchantStorefrontService.defaultPortalMerchantId;
  String _storeName = 'Dimsum Sewu Pracimantoro (Pusat)';
  String _storeAddress = 'Jl. Raya Pracimantoro No. 14, Depan Pasar';
  String _landmark = 'Depan Pasar Pracimantoro, samping Alfamidi';
  String _storeBanner = 'assets/images/resto_dimsum_sewu.png';
  String _storeLogo = 'assets/images/resto_dimsum_sewu.png';
  String _whatsapp = '085156955735';
  double _latitude = MerchantStorefrontService.defaultPracimantoroCenter.latitude;
  double _longitude = MerchantStorefrontService.defaultPracimantoroCenter.longitude;

  MerchantOperatingSchedule _schedule = MerchantOperatingSchedule.defaults();
  MerchantRatingSummary? _ratingSummary;
  MerchantLocationChangeRequest? _pendingLocationReq;
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
    _loadAllSettings();
  }

  MerchantOrderProvider? _maybeWatchProvider(BuildContext context) {
    try {
      return context.watch<MerchantOrderProvider>();
    } catch (_) {
      return null;
    }
  }

  MerchantOrderProvider? _maybeReadProvider(BuildContext context) {
    try {
      return context.read<MerchantOrderProvider>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadAllSettings() async {
    final stored = await MerchantStorefrontService.loadStorefront(
      _activeMerchantId,
      merchantName: _storeName,
    );
    final rating = await MerchantStorefrontService.loadRatingSummary(
      merchantId: _activeMerchantId,
      merchantName: _storeName,
      domain: 'food',
    );
    final locReq = await MerchantStorefrontService.loadLocationChangeRequest(_activeMerchantId);

    int savedCooking = _cookingTime;
    bool savedPickup = _selfPickupEnabled;
    bool savedAuto = _autoConfirmOrders;
    bool savedAlarm = _alarmRepeating;
    bool savedPopup = _popupNotification;
    int savedHeaderPx = _receiptHeaderPx;

    try {
      final prefs = await SharedPreferences.getInstance();
      savedCooking = prefs.getInt('merchant_cooking_time') ?? savedCooking;
      savedPickup = prefs.getBool('merchant_self_pickup') ?? savedPickup;
      savedAuto = prefs.getBool('merchant_auto_accept') ?? savedAuto;
      savedAlarm = prefs.getBool('merchant_alarm_repeating') ?? savedAlarm;
      savedPopup = prefs.getBool('merchant_popup_notif') ?? savedPopup;
      savedHeaderPx = prefs.getInt('gage_receipt_header_px') ?? savedHeaderPx;
    } catch (_) {}

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
      _pendingLocationReq = locReq;
      _cookingTime = savedCooking;
      _selfPickupEnabled = savedPickup;
      _autoConfirmOrders = savedAuto;
      _alarmRepeating = savedAlarm;
      _popupNotification = savedPopup;
      _receiptHeaderPx = savedHeaderPx;
    });
  }

  Future<void> _persistStoreOpen(bool val) async {
    final existing = await MerchantStorefrontService.loadStorefront(_activeMerchantId);
    final dataToSave = (existing ?? MerchantStorefrontData(merchantId: _activeMerchantId)).copyWith(
      name: _storeName,
      isOpen: val,
    );
    await MerchantStorefrontService.saveStorefront(dataToSave);
  }

  String _resolveStoreId(MerchantOrderProvider? provider) {
    final branchId = provider?.activeBranchId ?? '';
    if (branchId.toUpperCase().startsWith('GAGE-')) {
      return branchId;
    }
    final cleanId = _activeMerchantId.toLowerCase();
    String sector = 'FD';
    if (cleanId.contains('shop') || cleanId.contains('toko') || cleanId.contains('sembako')) {
      sector = 'SH';
    } else if (cleanId.contains('farm') || cleanId.contains('tani') || cleanId.contains('kebun')) {
      sector = 'FM';
    }
    final digits = RegExp(r'\d+').allMatches(cleanId).map((m) => m.group(0)).join();
    final seq = digits.isNotEmpty
        ? digits.padLeft(2, '0').substring(0, digits.length > 2 ? 2 : digits.length)
        : '01';
    return 'GAGE-PRC-$sector$seq';
  }

  Future<void> _openStoreInfoScreen(MerchantOrderProvider? provider) async {
    HapticFeedback.lightImpact();
    final displayName = provider?.activeBranchName ?? _storeName;
    final displayAddr = provider?.activeBranchAddress ?? _storeAddress;
    final result = await Navigator.of(context).push<MerchantStoreInfoResult>(
      MaterialPageRoute(
        builder: (_) => MerchantStoreInfoScreen(
          merchantId: _activeMerchantId,
          storeIdFormatted: _resolveStoreId(provider),
          initialName: displayName,
          initialWhatsapp: _whatsapp,
          initialLogo: _storeLogo,
          initialBanner: _storeBanner,
          storeAddress: displayAddr,
          landmark: _landmark,
          latitude: _latitude,
          longitude: _longitude,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _storeName = result.name;
        _whatsapp = result.whatsapp;
        _storeLogo = result.logoPath;
        _storeBanner = result.bannerPath;
      });
    }
  }

  Future<void> _openScheduleScreen() async {
    HapticFeedback.lightImpact();
    final updated = await Navigator.of(context).push<MerchantOperatingSchedule>(
      MaterialPageRoute(
        builder: (_) => MerchantOperatingScheduleScreen(
          merchantId: _activeMerchantId,
          initialSchedule: _schedule,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _schedule = updated);
    }
  }

  Future<void> _openLocationAndRequestsScreen(MerchantOrderProvider? provider) async {
    HapticFeedback.lightImpact();
    final displayName = provider?.activeBranchName ?? _storeName;
    final displayAddr = provider?.activeBranchAddress ?? _storeAddress;
    final latestReq = await Navigator.of(context).push<MerchantLocationChangeRequest>(
      MaterialPageRoute(
        builder: (_) => MerchantLocationAndRequestsScreen(
          merchantId: _activeMerchantId,
          storeName: displayName,
          currentAddress: displayAddr,
          currentLandmark: _landmark,
          currentLatitude: _latitude,
          currentLongitude: _longitude,
          markerImagePath: _storeLogo,
        ),
      ),
    );
    if (mounted) {
      final refreshed = latestReq ?? await MerchantStorefrontService.loadLocationChangeRequest(_activeMerchantId);
      setState(() => _pendingLocationReq = refreshed);
    }
  }

  Future<void> _openReceiptSettingsScreen(MerchantOrderProvider? provider) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MerchantReceiptSettingsScreen(
          storeName: provider?.activeBranchName ?? _storeName,
          storeLogo: _storeLogo,
        ),
      ),
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final px = prefs.getInt('gage_receipt_header_px');
      if (px != null && mounted) {
        setState(() => _receiptHeaderPx = px);
      }
    } catch (_) {}
  }

  Future<void> _openPrinterSettingsScreen() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MerchantPrinterSettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    final orderProvider = _maybeWatchProvider(context);
    final displayStoreName = orderProvider?.activeBranchName ?? _storeName;
    final displayAddress = orderProvider?.activeBranchAddress ?? _storeAddress;
    final storeIdFormatted = _resolveStoreId(orderProvider);

    final isOpen = orderProvider?.isOpen ?? _isOpen;
    final cookingTime = orderProvider?.cookingTime ?? _cookingTime;
    final selfPickup = orderProvider?.selfPickupEnabled ?? _selfPickupEnabled;
    final autoAccept = orderProvider?.autoAccept ?? _autoConfirmOrders;
    final alarmRepeating = orderProvider?.soundAlarmEnabled ?? _alarmRepeating;
    final popupNotif = orderProvider?.popupNotificationEnabled ?? _popupNotification;
    final acceptanceScore = orderProvider?.acceptanceScore ?? 98.0;

    final printerConnected = orderProvider?.printerConnected ?? false;
    final printerName = orderProvider?.printerDeviceName ?? 'RPP02N-Thermal-58mm';
    final paperSize = orderProvider?.preferredPaperSize ?? '58mm';
    final receiptCopies = orderProvider?.receiptCopies ?? 2;

    final avgRating = _ratingSummary != null && _ratingSummary!.totalReviews > 0
        ? '${_ratingSummary!.averageRating.toStringAsFixed(1)} ★'
        : 'Baru';
    final countLabel = _ratingSummary != null ? '${_ratingSummary!.totalReviews} Ulasan' : 'Belum ada';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textColor),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: GageTheme.primary,
          onRefresh: _loadAllSettings,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Kartu Identitas Toko (Parity Customer Identity Card)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _openStoreInfoScreen(orderProvider),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: GageTheme.primary.withValues(alpha: 0.45),
                                  width: 1.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: StorefrontImage(
                                  path: _storeLogo,
                                  fit: BoxFit.cover,
                                  fallback: const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 28),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: GageTheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: cardBg, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
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
                                      fontWeight: FontWeight.w800,
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
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: GageTheme.accentGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Kecamatan Pracimantoro, Kab. Wonogiri',
                              style: TextStyle(fontSize: 11.5, color: subColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'ID Toko: $storeIdFormatted',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Clipboard.setData(ClipboardData(text: storeIdFormatted));
                                    GageToast.show(context, 'ID Toko $storeIdFormatted berhasil disalin!');
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
                      IconButton(
                        tooltip: 'Edit Informasi Toko',
                        onPressed: () => _openStoreInfoScreen(orderProvider),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: GageTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded, color: GageTheme.primary, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Strip Metrik Dinamis Nyata
                Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        label: 'Rating Toko',
                        value: avgRating,
                        subtitle: countLabel,
                        isDark: isDark,
                        cardBg: cardBg,
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
                    Expanded(
                      child: _buildStatTile(
                        label: 'Penerimaan',
                        value: '${acceptanceScore.toStringAsFixed(0)}%',
                        subtitle: 'Skor Mitra',
                        isDark: isDark,
                        cardBg: cardBg,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatTile(
                        label: 'Waktu Siap',
                        value: '$cookingTime Mnt',
                        subtitle: 'Estimasi Dapur',
                        isDark: isDark,
                        cardBg: cardBg,
                        onTap: () => _showPengaturanPesananSheet(
                          isDark: isDark,
                          initialCooking: cookingTime,
                          initialPickup: selfPickup,
                          initialAuto: autoAccept,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Section: TOKO & OPERASIONAL
                _buildSectionHeader('TOKO & OPERASIONAL', subColor),
                const SizedBox(height: 8),
                _buildGroupedCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  children: [
                    _buildSwitchRow(
                      icon: isOpen ? Icons.store_rounded : Icons.store_mall_directory_outlined,
                      iconColor: isOpen ? GageTheme.accentGreen : GageTheme.primary,
                      title: 'Status Toko Buka',
                      subtitle: isOpen
                          ? 'Toko tampil buka di katalog pelanggan'
                          : 'Toko ditutup sementara dari pesanan baru',
                      value: isOpen,
                      isDark: isDark,
                      onChanged: (v) async {
                        HapticFeedback.lightImpact();
                        setState(() => _isOpen = v);
                        _maybeReadProvider(context)?.toggleStoreOpen(v);
                        await _persistStoreOpen(v);
                      },
                    ),
                    _buildSoftDivider(isDark),
                    _buildSeamlessMenuTile(
                      icon: Icons.storefront_rounded,
                      iconColor: const Color(0xFFEF4444),
                      title: 'Informasi Toko',
                      subtitle: 'Logo 1:1, banner sampul 16:9, nama & WhatsApp',
                      isDark: isDark,
                      onTap: () => _openStoreInfoScreen(orderProvider),
                    ),
                    _buildSoftDivider(isDark),
                    _buildSeamlessMenuTile(
                      icon: Icons.access_time_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'Jam Operasional Mingguan',
                      subtitle: _schedule.portalSubtitle(),
                      isDark: isDark,
                      onTap: _openScheduleScreen,
                    ),
                    _buildSoftDivider(isDark),
                    _buildSeamlessMenuTile(
                      icon: Icons.swap_horiz_rounded,
                      iconColor: const Color(0xFF0284C7),
                      title: 'Kelola Cabang Outlet',
                      subtitle: displayStoreName,
                      isDark: isDark,
                      onTap: () => MerchantBranchSwitcherSheet.show(context),
                    ),
                    _buildSoftDivider(isDark),
                    _buildSeamlessMenuTile(
                      icon: Icons.share_location_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'Lokasi Toko & Pindah Alamat',
                      subtitle: _pendingLocationReq != null
                          ? 'Menunggu tinjauan: ${_pendingLocationReq!.newAddress}'
                          : displayAddress,
                      badge: _pendingLocationReq != null ? 'PENDING' : null,
                      badgeColor: Colors.orange,
                      isDark: isDark,
                      onTap: () => _openLocationAndRequestsScreen(orderProvider),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 4. Section: PESANAN, NOTIFIKASI & PRINTER
                _buildSectionHeader('PESANAN, NOTIFIKASI & PRINTER', subColor),
                const SizedBox(height: 8),
                _buildGroupedCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  children: [
                    _buildSeamlessMenuTile(
                      icon: Icons.assignment_turned_in_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Pengaturan Pesanan',
                      subtitle: 'Estimasi $cookingTime mnt • ${autoAccept ? "Terima Otomatis" : "Konfirmasi Manual"}',
                      isDark: isDark,
                      onTap: () => _showPengaturanPesananSheet(
                        isDark: isDark,
                        initialCooking: cookingTime,
                        initialPickup: selfPickup,
                        initialAuto: autoAccept,
                      ),
                    ),
                    _buildSoftDivider(isDark),
                    _buildSeamlessMenuTile(
                      icon: Icons.notifications_active_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Pengaturan Notifikasi & Alarm',
                      subtitle: alarmRepeating
                          ? 'Alarm dering berulang aktif • Pop-up ${popupNotif ? "aktif" : "mati"}'
                          : 'Alarm dering tunggal',
                      isDark: isDark,
                      onTap: () => _showPengaturanNotifikasiSheet(
                        isDark: isDark,
                        initialAlarm: alarmRepeating,
                        initialPopup: popupNotif,
                      ),
                    ),
                    _buildSoftDivider(isDark),
                    _buildSeamlessMenuTile(
                      icon: Icons.print_rounded,
                      iconColor: const Color(0xFF0EA5E9),
                      title: 'Printer Bluetooth Thermal',
                      subtitle: printerConnected
                          ? '$printerName ($paperSize • ${receiptCopies}x)'
                          : 'Belum terhubung ke printer thermal',
                      badge: printerConnected ? 'AKTIF' : null,
                      badgeColor: GageTheme.accentGreen,
                      isDark: isDark,
                      onTap: _openPrinterSettingsScreen,
                    ),
                    _buildSoftDivider(isDark),
                    _buildSeamlessMenuTile(
                      icon: Icons.receipt_long_rounded,
                      iconColor: const Color(0xFF14B8A6),
                      title: 'Pengaturan Struk',
                      subtitle: 'Header ${_receiptHeaderPx}px • Pratinjau struk & catatan footer',
                      isDark: isDark,
                      onTap: () => _openReceiptSettingsScreen(orderProvider),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 5. Section: ULASAN, BANTUAN & LEGALITAS
                _buildSectionHeader('ULASAN, BANTUAN & LEGALITAS', subColor),
                const SizedBox(height: 8),
                _buildGroupedCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  children: [
                    _buildSeamlessMenuTile(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Penilaian & Ulasan Toko',
                      subtitle: '$avgRating • $countLabel dari pelanggan',
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MerchantReviewScreen()),
                        );
                      },
                    ),
                    _buildSoftDivider(isDark),
                    _buildSeamlessMenuTile(
                      icon: Icons.support_agent_rounded,
                      iconColor: GageTheme.primary,
                      title: 'Pusat Bantuan & Hotline',
                      subtitle: 'Hotline Dispatcher Pracimantoro, WhatsApp CS & FAQ',
                      badge: 'CS',
                      badgeColor: GageTheme.accentGreen,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        MerchantHelpCenterSheet.show(
                          context,
                          storeName: displayStoreName,
                          storeId: storeIdFormatted,
                        );
                      },
                    ),
                    _buildSoftDivider(isDark),
                    _buildSeamlessMenuTile(
                      icon: Icons.verified_user_outlined,
                      iconColor: const Color(0xFF475569),
                      title: 'Kebijakan Privasi & Kemitraan',
                      subtitle: 'Ketentuan komisi MDR 10% & perlindungan data pelanggan',
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MerchantTermsAndPrivacyScreen()),
                        );
                      },
                    ),
                    _buildSoftDivider(isDark),
                    _buildSeamlessMenuTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF0284C7),
                      title: 'Tentang Aplikasi GAGE Merchant',
                      subtitle: _appVersionLabel,
                      isDark: isDark,
                      onTap: () => _showAboutMerchantSheet(isDark),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // 6. Zona Keluar Akun Mitra (Parity Customer Portal)
                InkWell(
                  onTap: () => _confirmLogout(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.28),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Keluar dari Akun Mitra',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'GAGE Merchant Pracimantoro • Halu Goods Indonesia',
                    style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white38 : Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color subColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: subColor,
        ),
      ),
    );
  }

  Widget _buildGroupedCard({
    required bool isDark,
    required Color cardBg,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          type: MaterialType.transparency,
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildSoftDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 58,
      endIndent: 16,
      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
    );
  }

  Widget _buildSeamlessMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: badgeColor ?? GageTheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white30 : Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: GageTheme.primary.withValues(alpha: 0.45),
            activeThumbColor: GageTheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required String subtitle,
    required bool isDark,
    required Color cardBg,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 3),
                const Icon(Icons.arrow_forward_ios_rounded, size: 8, color: GageTheme.primary),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: GageTheme.primary),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.5,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: content,
        ),
      );
    }
    return content;
  }

  // ── Quick Floating Sheet: Pengaturan Pesanan ──
  void _showPengaturanPesananSheet({
    required bool isDark,
    required int initialCooking,
    required bool initialPickup,
    required bool initialAuto,
  }) {
    int tempCooking = initialCooking;
    bool tempPickup = initialPickup;
    bool tempAuto = initialAuto;

    GageFloatingSheet.show(
      context: context,
      title: 'Pengaturan Pesanan',
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final sheetCardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
          final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
          final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Atur estimasi waktu penyiapan pesanan dan alur konfirmasi toko.',
                style: TextStyle(fontSize: 12, color: subColor),
              ),
              const SizedBox(height: 16),

              // Waktu Siap Segmented Kapsul Penuh (999 Track + Thumb)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Estimasi Penyiapan Default', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor)),
                  Text('$tempCooking Menit', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: GageTheme.primary)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [10, 15, 20, 25].map((mins) {
                    final isSel = tempCooking == mins;
                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheetState(() => tempCooking = mins);
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? GageTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$mins mnt',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel ? Colors.white : subColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(
                  color: sheetCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildSwitchRow(
                      icon: Icons.directions_walk_rounded,
                      iconColor: const Color(0xFF0284C7),
                      title: 'Pesanan Ambil di Toko',
                      subtitle: 'Izinkan pelanggan mengambil langsung di kasir',
                      value: tempPickup,
                      isDark: isDark,
                      onChanged: (v) => setSheetState(() => tempPickup = v),
                    ),
                    Divider(height: 1, indent: 56, endIndent: 14, color: borderColor),
                    _buildSwitchRow(
                      icon: Icons.bolt_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Konfirmasi Otomatis',
                      subtitle: 'Langsung terima pesanan baru masuk tanpa sentuh',
                      value: tempAuto,
                      isDark: isDark,
                      onChanged: (v) => setSheetState(() => tempAuto = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _cookingTime = tempCooking;
                      _selfPickupEnabled = tempPickup;
                      _autoConfirmOrders = tempAuto;
                    });
                    final prov = _maybeReadProvider(this.context);
                    if (prov != null) {
                      prov.setCookingTime(tempCooking);
                      prov.setSelfPickupEnabled(tempPickup);
                      prov.toggleAutoAccept(tempAuto);
                    } else {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('merchant_cooking_time', tempCooking);
                        await prefs.setBool('merchant_self_pickup', tempPickup);
                        await prefs.setBool('merchant_auto_accept', tempAuto);
                      } catch (_) {}
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      GageToast.show(this.context, 'Pengaturan pesanan berhasil disimpan!', type: GageToastType.success);
                    }
                  },
                  child: const Text('Simpan Pengaturan Pesanan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Quick Floating Sheet: Pengaturan Notifikasi & Alarm Dapur ──
  void _showPengaturanNotifikasiSheet({
    required bool isDark,
    required bool initialAlarm,
    required bool initialPopup,
  }) {
    bool tempAlarm = initialAlarm;
    bool tempPopup = initialPopup;

    GageFloatingSheet.show(
      context: context,
      title: 'Pengaturan Notifikasi',
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final sheetCardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
          final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
          final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pastikan alarm pesanan baru selalu terdengar jelas saat toko beroperasi.',
                style: TextStyle(fontSize: 12, color: subColor),
              ),
              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(
                  color: sheetCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildSwitchRow(
                      icon: Icons.volume_up_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'Dering Pesanan Berulang',
                      subtitle: 'Bunyikan alarm berulang hingga pesanan diterima',
                      value: tempAlarm,
                      isDark: isDark,
                      onChanged: (v) => setSheetState(() => tempAlarm = v),
                    ),
                    Divider(height: 1, indent: 56, endIndent: 14, color: borderColor),
                    _buildSwitchRow(
                      icon: Icons.screen_lock_portrait_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'Pop-up di Layar Kunci',
                      subtitle: 'Tampilkan ringkasan order baru di layar kunci',
                      value: tempPopup,
                      isDark: isDark,
                      onChanged: (v) => setSheetState(() => tempPopup = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tombol Uji Suara Alarm Nyata
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  GageAudioService.instance.playOrderIncomingChime();
                  GageToast.show(context, 'Memutar suara nada dering pesanan masuk...');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: GageTheme.primary,
                  side: BorderSide(color: GageTheme.primary.withValues(alpha: 0.4)),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                icon: const Icon(Icons.music_note_rounded, size: 17),
                label: const Text(
                  'Uji Suara Alarm Pesanan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _alarmRepeating = tempAlarm;
                      _popupNotification = tempPopup;
                    });
                    final prov = _maybeReadProvider(this.context);
                    if (prov != null) {
                      prov.toggleSoundAlarm(tempAlarm);
                      prov.setPopupNotificationEnabled(tempPopup);
                    } else {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('merchant_alarm_repeating', tempAlarm);
                        await prefs.setBool('merchant_popup_notif', tempPopup);
                      } catch (_) {}
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      GageToast.show(this.context, 'Pengaturan notifikasi berhasil disimpan!', type: GageToastType.success);
                    }
                  },
                  child: const Text('Simpan Pengaturan Notifikasi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Quick Floating Sheet: Tentang Aplikasi GAGE Merchant ──
  void _showAboutMerchantSheet(bool isDark) {
    HapticFeedback.lightImpact();
    GageFloatingSheet.show(
      context: context,
      title: 'Tentang GAGE Merchant',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: GageTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: GageTheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'GAGE Merchant Pracimantoro',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          Center(
            child: Text(
              _appVersionLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Text(
              'Portal kasir & manajemen toko resmi bagi Mitra GAGE Food, GAGE Shop, dan GAGE Farm di Kecamatan Pracimantoro. Dikembangkan oleh Halu Goods Indonesia.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await GageFloatingSheet.showConfirm(
      context: context,
      title: 'Keluar dari Akun Mitra?',
      message: 'Anda dapat masuk kembali kapan saja menggunakan nomor WhatsApp atau akun mitra terdaftar.',
      confirmLabel: 'Ya, Keluar',
      cancelLabel: 'Batal',
      confirmColor: const Color(0xFFDC2626),
      icon: Icons.logout_rounded,
    );
    if (confirm != true || !context.mounted) return;

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.signOut();
    } catch (_) {}

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        MerchantRoutes.login,
        (route) => false,
      );
    }
  }
}
