import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/settings/merchant_location_and_requests_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_photo_picker_sheet.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';
import 'package:gage_app/shared/widgets/storefront_image.dart';

class MerchantStoreInfoResult {
  final String name;
  final String whatsapp;
  final String logoPath;
  final String bannerPath;

  const MerchantStoreInfoResult({
    required this.name,
    required this.whatsapp,
    required this.logoPath,
    required this.bannerPath,
  });
}

/// Full Screen Page: Informasi Toko (Branding Logo 1:1, Banner 16:9, Identitas & Kontak)
class MerchantStoreInfoScreen extends StatefulWidget {
  final String merchantId;
  final String storeIdFormatted;
  final String initialName;
  final String initialWhatsapp;
  final String initialLogo;
  final String initialBanner;
  final String storeAddress;
  final String landmark;
  final double latitude;
  final double longitude;

  const MerchantStoreInfoScreen({
    super.key,
    required this.merchantId,
    required this.storeIdFormatted,
    required this.initialName,
    required this.initialWhatsapp,
    required this.initialLogo,
    required this.initialBanner,
    required this.storeAddress,
    required this.landmark,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<MerchantStoreInfoScreen> createState() => _MerchantStoreInfoScreenState();
}

class _MerchantStoreInfoScreenState extends State<MerchantStoreInfoScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _waCtrl;
  late String _currentLogo;
  late String _currentBanner;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _waCtrl = TextEditingController(text: widget.initialWhatsapp);
    _currentLogo = widget.initialLogo;
    _currentBanner = widget.initialBanner;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _waCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveStoreInfo() async {
    final newName = _nameCtrl.text.trim();
    final newWa = _waCtrl.text.trim();
    if (newName.isEmpty) {
      GageToast.show(context, 'Nama toko wajib diisi', type: GageToastType.warning);
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final existing = await MerchantStorefrontService.loadStorefront(widget.merchantId);
    final dataToSave = (existing ?? MerchantStorefrontData(merchantId: widget.merchantId)).copyWith(
      name: newName,
      logoPhoto: _currentLogo,
      bannerPhoto: _currentBanner,
    );
    await MerchantStorefrontService.saveStorefront(dataToSave);

    if (mounted) {
      try {
        await context.read<MerchantOrderProvider>().updateActiveBranchName(
              newName,
              phone: newWa.isNotEmpty ? newWa : null,
            );
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    GageToast.show(context, 'Informasi toko berhasil disimpan!', type: GageToastType.success);
    Navigator.of(context).pop(
      MerchantStoreInfoResult(
        name: newName,
        whatsapp: newWa.isNotEmpty ? newWa : widget.initialWhatsapp,
        logoPath: _currentLogo,
        bannerPath: _currentBanner,
      ),
    );
  }

  void _openLocationAndRequests() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MerchantLocationAndRequestsScreen(
          merchantId: widget.merchantId,
          storeName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : widget.initialName,
          currentAddress: widget.storeAddress,
          currentLandmark: widget.landmark,
          currentLatitude: widget.latitude,
          currentLongitude: widget.longitude,
          markerImagePath: _currentLogo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Informasi Toko',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Hero Branding Preview (Banner 16:9 + Logo 1:1)
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Banner Sampul 16:9
                      SizedBox(
                        height: 148,
                        width: double.infinity,
                        child: StorefrontImage(
                          path: _currentBanner,
                          fit: BoxFit.cover,
                          fallback: Container(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            child: Icon(Icons.image_rounded, size: 42, color: subColor),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.05),
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: InkWell(
                          onTap: () async {
                            final path = await MerchantPhotoPickerSheet.show(
                              context,
                              aspectRatio: 16 / 9,
                            );
                            if (path != null && mounted) {
                              setState(() => _currentBanner = path);
                            }
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.58),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo_library_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Ubah Banner (16:9)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final path = await MerchantPhotoPickerSheet.show(
                              context,
                              aspectRatio: 1.0,
                            );
                            if (path != null && mounted) {
                              setState(() => _currentLogo = path);
                            }
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
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
                                    path: _currentLogo,
                                    fit: BoxFit.cover,
                                    fallback: const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 28),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -3,
                                right: -3,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: GageTheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: cardBg, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
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
                              Text(
                                'Logo & Identitas Visual',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rasio 1:1 tampil di katalog pelanggan, pin peta driver, dan header struk.',
                                style: TextStyle(fontSize: 11.5, color: subColor, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. Identitas & Kontak Operasional
            _buildSectionHeader('IDENTITAS & KONTAK TOKO', subColor),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID Toko Read-only Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_2_rounded, size: 18, color: GageTheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID Toko Terdaftar', style: TextStyle(fontSize: 10.5, color: subColor)),
                              Text(
                                widget.storeIdFormatted,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Clipboard.setData(ClipboardData(text: widget.storeIdFormatted));
                            GageToast.show(context, 'ID Toko ${widget.storeIdFormatted} disalin');
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: GageTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded, size: 12, color: GageTheme.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Salin',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: GageTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text('Nama Toko / Outlet', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textColor),
                    decoration: _inputDecoration(
                      hint: 'Misal: Dimsum Sewu Pracimantoro',
                      icon: Icons.storefront_rounded,
                      inputBg: inputBg,
                      borderColor: borderColor,
                      subColor: subColor,
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text('Nomor WhatsApp Koordinasi Order', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _waCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textColor),
                    decoration: _inputDecoration(
                      hint: '085156955735',
                      icon: Icons.phone_android_rounded,
                      inputBg: inputBg,
                      borderColor: borderColor,
                      subColor: subColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 3. Alamat & Lokasi Terverifikasi
            _buildSectionHeader('LOKASI FISIK TERVERIFIKASI', subColor),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MiniLocationPreviewMap(
                        location: LatLng(widget.latitude, widget.longitude),
                        size: 56,
                        borderRadius: 12,
                        markerImagePath: _currentLogo,
                        useMerchantPin: true,
                        onTap: _openLocationAndRequests,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.storeAddress,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Patokan: ${widget.landmark}',
                              style: TextStyle(fontSize: 11.5, color: subColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openLocationAndRequests,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GageTheme.primary,
                        side: BorderSide(color: GageTheme.primary.withValues(alpha: 0.45)),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.share_location_rounded, size: 15),
                      label: const Text(
                        'Kelola Lokasi & Ajukan Pindah Alamat',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? GageTheme.darkSurface : Colors.white,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveStoreInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Simpan Informasi Toko',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: color,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required Color inputBg,
    required Color borderColor,
    required Color subColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12.5, color: subColor),
      prefixIcon: Icon(icon, size: 18, color: GageTheme.primary),
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
      ),
    );
  }
}
