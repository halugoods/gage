import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';

enum PromoCardType { referral, merchant, product }

/// GagePromoCardShareDialog
/// Generator & preview kartu promosi visual resolusi tinggi untuk GAGE Cuan.
/// Menghasilkan kartu visual promosi (Toko Mitra, Menu Produk, atau Referral)
/// dengan grafis informatif, mini-map merchant, foto produk 1:1, badge promo,
/// dan tombol Bagikan langsung ke Android share sheet.
class GagePromoCardShareDialog extends StatefulWidget {
  final PromoCardType type;
  final String title;
  final String? subtitle;
  final String shareUrl;
  final String? referralCode;
  final String? merchantName;
  final String? productPrice;
  final String? commissionText;
  final String? imageUrl;
  final LatLng? location;

  const GagePromoCardShareDialog({
    super.key,
    required this.type,
    required this.title,
    this.subtitle,
    required this.shareUrl,
    this.referralCode,
    this.merchantName,
    this.productPrice,
    this.commissionText,
    this.imageUrl,
    this.location,
  });

  /// Direct Share Referral (Floating Sheet dengan Opsi Simpan Gambar & Bagikan)
  static Future<void> directShareReferral(
    BuildContext context, {
    required String referralCode,
    required String shareUrl,
  }) {
    return showReferralCard(
      context,
      referralCode: referralCode,
      shareUrl: shareUrl,
    );
  }

  /// Direct Share Merchant (Floating Sheet dengan Opsi Simpan Gambar & Bagikan)
  static Future<void> directShareMerchant(
    BuildContext context, {
    required String merchantName,
    required String category,
    required String shareUrl,
    String? imageUrl,
    LatLng? location,
  }) {
    return showMerchantCard(
      context,
      merchantName: merchantName,
      category: category,
      shareUrl: shareUrl,
      imageUrl: imageUrl,
      location: location,
    );
  }

  /// Direct Share Product (Floating Sheet dengan Opsi Simpan Gambar & Bagikan)
  static Future<void> directShareProduct(
    BuildContext context, {
    required String productName,
    required String merchantName,
    required String price,
    required String shareUrl,
    String? imageUrl,
  }) {
    return showProductCard(
      context,
      productName: productName,
      merchantName: merchantName,
      price: price,
      shareUrl: shareUrl,
      imageUrl: imageUrl,
    );
  }

  /// Helper untuk menampilkan floating sheet kartu referral
  static Future<void> showReferralCard(
    BuildContext context, {
    required String referralCode,
    required String shareUrl,
  }) {
    HapticFeedback.lightImpact();
    return GageFloatingSheet.show(
      context: context,
      title: 'Bagikan Referral Cuan',
      builder: (_) => GagePromoCardShareDialog(
        type: PromoCardType.referral,
        title: 'Ajak Teman',
        shareUrl: shareUrl,
        referralCode: referralCode,
      ),
    );
  }

  /// Helper untuk menampilkan floating sheet kartu toko mitra
  static Future<void> showMerchantCard(
    BuildContext context, {
    required String merchantName,
    required String category,
    required String shareUrl,
    String? commissionText,
    String? imageUrl,
    LatLng? location,
  }) {
    HapticFeedback.lightImpact();
    return GageFloatingSheet.show(
      context: context,
      title: 'Bagikan Toko Mitra',
      builder: (_) => GagePromoCardShareDialog(
        type: PromoCardType.merchant,
        title: merchantName,
        subtitle: category,
        shareUrl: shareUrl,
        merchantName: merchantName,
        commissionText: commissionText,
        imageUrl: imageUrl,
        location: location,
      ),
    );
  }

  /// Helper untuk menampilkan floating sheet kartu produk menu
  static Future<void> showProductCard(
    BuildContext context, {
    required String productName,
    required String merchantName,
    required String price,
    required String shareUrl,
    String? commissionText,
    String? imageUrl,
  }) {
    HapticFeedback.lightImpact();
    return GageFloatingSheet.show(
      context: context,
      title: 'Bagikan Produk Menu',
      builder: (_) => GagePromoCardShareDialog(
        type: PromoCardType.product,
        title: productName,
        subtitle: merchantName,
        shareUrl: shareUrl,
        merchantName: merchantName,
        productPrice: price,
        commissionText: commissionText,
        imageUrl: imageUrl,
      ),
    );
  }

  @override
  State<GagePromoCardShareDialog> createState() => _GagePromoCardShareDialogState();
}

class _GagePromoCardShareDialogState extends State<GagePromoCardShareDialog> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _shareImageAndText() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    HapticFeedback.selectionClick();

    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Render boundary tidak ditemukan');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Gagal mengubah buffer visual ke PNG');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/gage_promo_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      final String shareText = _buildShareCaption();

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: shareText,
        ),
      );
    } catch (e) {
      if (mounted) {
        GageToast.showError(context, 'Gagal membagikan kartu visual: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _buildShareCaption() {
    switch (widget.type) {
      case PromoCardType.referral:
        return 'Yuk gabung ekosistem belanja & kuliner GAGE Pracimantoro! Nikmati DISKON hingga Rp 15.000 + GRATIS ONGKIR untuk pesanan pertamamu dengan kode referal: ${widget.referralCode}.\n\nPesan sekarang: ${widget.shareUrl}';
      case PromoCardType.merchant:
        return widget.shareUrl;
      case PromoCardType.product:
        return widget.shareUrl;
    }
  }

  Future<void> _saveImageToGallery() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    HapticFeedback.selectionClick();

    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Render boundary tidak ditemukan');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Gagal mengubah buffer visual ke PNG');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final fileName = 'promo_gage_${DateTime.now().millisecondsSinceEpoch}.png';

      // Simpan langsung ke MediaStore Android album "Gage by Halu Goods Indonesia" via Native Platform Channel
      const channel = MethodChannel('com.gage/media_scanner');
      try {
        await channel.invokeMethod('saveImageToGallery', {
          'bytes': pngBytes,
          'fileName': fileName,
        });
      } catch (nativeErr) {
        final appDir = await getApplicationDocumentsDirectory();
        final targetFile = File('${appDir.path}/$fileName');
        await targetFile.writeAsBytes(pngBytes);
      }

      if (mounted) {
        GageToast.showSuccess(
          context,
          'Gambar berhasil disimpan di album "Gage by Halu Goods Indonesia"',
        );
      }
    } catch (e) {
      if (mounted) {
        GageToast.showError(context, 'Gagal menyimpan gambar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visual Card Container yang di-capture oleh RepaintBoundary (Murni Kartu Grafis Tanpa Tombol UI)
          RepaintBoundary(
            key: _repaintBoundaryKey,
            child: GagePromoCardVisualContent(
              type: widget.type,
              title: widget.title,
              subtitle: widget.subtitle,
              shareUrl: widget.shareUrl,
              referralCode: widget.referralCode,
              merchantName: widget.merchantName,
              productPrice: widget.productPrice,
              commissionText: widget.commissionText,
              imageUrl: widget.imageUrl,
              location: widget.location,
            ),
          ),

          const SizedBox(height: 16),

          // Tombol Aksi Kapsul Simetris: Simpan Gambar & Bagikan (Lebar Seimbang & Bebas Truncate)
          Container(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      side: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    ),
                    onPressed: _isExporting ? null : _saveImageToGallery,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Simpan Gambar',
                        maxLines: 1,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      elevation: 2,
                    ),
                    onPressed: _isExporting ? null : _shareImageAndText,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Transform.flip(
                            flipX: true,
                            child: const Icon(Icons.reply_rounded, size: 18),
                          ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _isExporting ? 'Memproses...' : 'Bagikan',
                        maxLines: 1,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Field Teks Truncated Link + Tombol Ikon Salin
          Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 16,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.shareUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: widget.shareUrl));
                    GageToast.showSuccess(context, 'Tautan berhasil disalin');
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: isDark ? Colors.white : GageTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// GagePromoCardVisualContent
/// Konten visual murni kartu promosi 1:1 tanpa tombol aksi UI (Bagikan/Salin/Tutup).
/// Digunakan baik untuk dialog pratinjau maupun off-screen capture PNG.
class GagePromoCardVisualContent extends StatelessWidget {
  final PromoCardType type;
  final String title;
  final String? subtitle;
  final String shareUrl;
  final String? referralCode;
  final String? merchantName;
  final String? productPrice;
  final String? commissionText;
  final String? imageUrl;
  final LatLng? location;

  const GagePromoCardVisualContent({
    super.key,
    required this.type,
    required this.title,
    this.subtitle,
    required this.shareUrl,
    this.referralCode,
    this.merchantName,
    this.productPrice,
    this.commissionText,
    this.imageUrl,
    this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Branding GAGE (Poster Promosi Grafis Elegan)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/gage_logo.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: GageTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'GAGE by Halu Goods Indonesia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          _buildCleanDivider(),

          // 2. Konten Kartu Promosi Sesuai Tipe
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, type == PromoCardType.referral ? 12 : 18),
            child: _buildCardBody(),
          ),

          // 3. Verifikasi QR Code & Tautan (Eksklusif Hanya untuk Kartu Referral)
          if (type == PromoCardType.referral) ...[
            _buildCleanDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: QrImageView(
                      data: shareUrl,
                      version: QrVersions.auto,
                      size: 56,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Voucher Resmi Terverifikasi',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Pindai QR dengan kamera / Google Lens untuk klaim voucher di aplikasi GAGE.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shareUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: GageTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardBody() {
    switch (type) {
      case PromoCardType.merchant:
        return _buildMerchantContent();
      case PromoCardType.product:
        return _buildProductContent();
      case PromoCardType.referral:
        return _buildReferralContent();
    }
  }

  /// Bagikan Toko Mitra: Merchant profile photo + mini-map.
  Widget _buildMerchantContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: GageTheme.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: (imageUrl != null && imageUrl!.isNotEmpty)
                    ? (imageUrl!.startsWith('assets/')
                        ? Image.asset(imageUrl!, fit: BoxFit.cover)
                        : Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: GageTheme.primary,
                                size: 28,
                              ),
                            ),
                          ))
                    : Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: GageTheme.primary,
                          size: 28,
                        ),
                      ),
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
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        color: GageTheme.primary,
                        size: 16,
                      ),
                    ],
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Mini-Map Preview Toko Mitra (Proporsional Pas Rasio 9:16)
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 170,
            width: double.infinity,
            child: MiniLocationPreviewMap(
              location: location ?? const LatLng(-8.1887, 110.8242),
              height: 170,
              width: double.infinity,
              borderRadius: 16,
              zoom: 15.5,
              useMerchantPin: true,
              markerImagePath: imageUrl,
              markerFallbackIcon: Icons.storefront_rounded,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Lokasi Pracimantoro Label
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_rounded, size: 13, color: GageTheme.primary),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                'Pracimantoro, Wonogiri • Siap Antar Cepat',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Kotak Manfaat Voucher Toko Mitra (Sama dengan format Referal)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildBenefitRow(
                Icons.check_circle_rounded,
                'Voucher Diskon Rp 10.000 (Min. Belanja Rp 30.000)',
              ),
              const SizedBox(height: 4),
              _buildBenefitRow(
                Icons.check_circle_rounded,
                'Subsidi Gratis Ongkir Rp 5.000 (Min. Belanja Rp 25.000)',
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Bagikan Produk: Foto produk bersih tanpa badge melayang, benefit box & tombol solid Pesan Sekarang.
  Widget _buildProductContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Foto Produk Bersih (1:1 Aspect Ratio Murni)
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              color: const Color(0xFFF1F5F9),
              child: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? (imageUrl!.startsWith('assets/')
                      ? Image.asset(imageUrl!, fit: BoxFit.cover)
                      : Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.restaurant_rounded, size: 48, color: Colors.grey),
                          ),
                        ))
                  : const Center(
                      child: Icon(Icons.restaurant_rounded, size: 48, color: Colors.grey),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (merchantName != null && merchantName!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            merchantName!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        if (productPrice != null) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              productPrice!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: GageTheme.primary,
              ),
            ),
          ),
        ],

        const SizedBox(height: 8),

        // Kotak Manfaat Voucher Bersih (Sama dengan Referal & Mitra)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildBenefitRow(
                Icons.check_circle_rounded,
                'Voucher Diskon Rp 10.000 (Min. Belanja Rp 30.000)',
              ),
              const SizedBox(height: 4),
              _buildBenefitRow(
                Icons.check_circle_rounded,
                'Subsidi Gratis Ongkir Rp 5.000 (Min. Belanja Rp 25.000)',
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Tombol Solid CTA "Pesan Sekarang"
        Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: GageTheme.primary,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: GageTheme.primary.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pesan Sekarang',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_downward_rounded, size: 15, color: Colors.white),
            ],
          ),
        ),
      ],
    );
  }

  /// Bagikan Referral: Kartu voucher digital bersih dengan kode referral besar
  Widget _buildReferralContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle ?? 'Gabung ekosistem Niaga & Kuliner GAGE Pracimantoro dan nikmati voucher belanja spesial!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        if (referralCode != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: GageTheme.primary.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'KODE REFERAL RESMI',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  referralCode!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: GageTheme.primary,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              _buildBenefitRow(
                Icons.check_circle_rounded,
                'Voucher Diskon Rp 10.000 (Min. Belanja Rp 30.000)',
              ),
              const SizedBox(height: 8),
              _buildBenefitRow(
                Icons.check_circle_rounded,
                'Subsidi Gratis Ongkir Rp 5.000 (Min. Belanja Rp 25.000)',
              ),
              const SizedBox(height: 8),
              _buildBenefitRow(
                Icons.check_circle_rounded,
                'Dukung UMKM & kuliner lokal Pracimantoro',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF16A34A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Garis pembatas tipis elegan modern (Gaya Poster Grafis)
  Widget _buildCleanDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
    );
  }
}
