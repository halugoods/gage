import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/services/gage_video_feed_service.dart';
import 'package:gage_app/core/services/social_profile_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';
import 'package:gage_app/features/video/presentation/video_feed_screen.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Layar Unggah Video Afiliasi & Integrasi Keranjang Merah (TikTok Creator Style)
/// - Form Caption Kosong Secara Default
/// - Chip Cepat # Hashtags & @ Mention
/// - Mini Thumbnail Kanan Atas dengan Badge 'Preview' & Tombol 'Edit cover'
/// - Penautan Keranjang Merah yang langsung memunculkan sheet pilihan produk etalase saat toggle aktif.
class AffiliateVideoUploadScreen extends StatefulWidget {
  final Map<String, dynamic>? initialMerchant;
  final Map<String, dynamic>? initialProduct;
  final String? initialVideoPath;
  final String? initialVideoName;
  final String? selectedSoundTitle;
  final String? selectedSoundArtist;
  final double originalAudioVolume;
  final double musicVolume;
  final String? customCoverPath;

  const AffiliateVideoUploadScreen({
    super.key,
    this.initialMerchant,
    this.initialProduct,
    this.initialVideoPath,
    this.initialVideoName,
    this.selectedSoundTitle,
    this.selectedSoundArtist,
    this.originalAudioVolume = 1.0,
    this.musicVolume = 1.0,
    this.customCoverPath,
  });

  @override
  State<AffiliateVideoUploadScreen> createState() => _AffiliateVideoUploadScreenState();
}

class _AffiliateVideoUploadScreenState extends State<AffiliateVideoUploadScreen> {
  // Caption default KOSONG per permintaan user
  final TextEditingController _captionController = TextEditingController();

  String? _videoPath;
  String? _coverPath;
  bool _isCustomVideo = false;
  bool _attachProduct = false;

  Map<String, dynamic>? _selectedProduct;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _coverPath = widget.customCoverPath;

    if (widget.initialVideoPath != null) {
      _videoPath = widget.initialVideoPath;
      _isCustomVideo = true;
    }

    if (widget.initialProduct != null) {
      _attachProduct = true;
      _selectedProduct = {
        'productId': widget.initialProduct!['id'] ?? widget.initialProduct!['productId'],
        'productTitle': widget.initialProduct!['name'] ?? widget.initialProduct!['productTitle'] ?? 'Produk Mitra',
        'productPrice': widget.initialProduct!['price'] ?? widget.initialProduct!['productPrice'] ?? 15000,
        'merchantId': widget.initialMerchant?['id'] ?? widget.initialProduct!['merchantId'] ?? 'mch-01',
        'merchantName': widget.initialMerchant?['name'] ?? widget.initialProduct!['merchantName'] ?? 'Mitra GAGE',
        'merchantRating': widget.initialMerchant?['rating'] ?? 4.9,
        'thumbnailUrl': widget.initialProduct!['image'] ?? widget.initialProduct!['thumbnailUrl'] ?? 'assets/images/dish_dimsum_mentai.png',
      };

      // Otomatis masukkan ke etalase profil kreator
      SocialProfileService.instance.addProductToShowcase(_selectedProduct!);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // --- Quick Chip Inserters ---
  void _insertHashtag() {
    HapticFeedback.lightImpact();
    final currentText = _captionController.text;
    const tag = '#gagekuliner ';
    _captionController.text = currentText.isEmpty ? tag : '$currentText $tag';
    _captionController.selection = TextSelection.fromPosition(
      TextPosition(offset: _captionController.text.length),
    );
  }

  void _insertMention() {
    HapticFeedback.lightImpact();
    final currentText = _captionController.text;
    const mention = '@wonogirifoodie ';
    _captionController.text = currentText.isEmpty ? mention : '$currentText $mention';
    _captionController.selection = TextSelection.fromPosition(
      TextPosition(offset: _captionController.text.length),
    );
  }

  // --- Ganti Sampul (Edit Cover) ---
  Future<void> _pickCoverImage() async {
    HapticFeedback.selectionClick();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null && mounted) {
        setState(() {
          _coverPath = picked.path;
        });
        GageToast.show(context, 'Sampul kustom berhasil diperbarui', type: GageToastType.success);
      }
    } catch (e) {
      if (mounted) {
        GageToast.show(context, 'Gagal memilih sampul: $e', type: GageToastType.error);
      }
    }
  }

  // --- Sheet Pilihan Produk Etalase Keranjang Merah ---
  void _showShowcasePickerSheet() {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showcaseProducts = SocialProfileService.instance.getShowcaseProducts(
      SocialProfileService.instance.userHandle,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: GageTheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_bag_rounded, color: GageTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Pilih Produk Keranjang Merah',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),

                if (showcaseProducts.isEmpty) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: GageTheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 36),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Etalase Anda Masih Kosong',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tambahkan produk kuliner atau belanjaan dari mitra UMKM di menu GAGE Cuan untuk memunculkannya di sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GageTheme.primary,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AffiliateHubScreen()),
                              );
                            },
                            icon: const Icon(Icons.storefront_rounded, size: 16),
                            label: const Text('Buka GAGE Cuan', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: showcaseProducts.length,
                      itemBuilder: (context, idx) {
                        final product = showcaseProducts[idx];
                        final isSelected = _selectedProduct?['productId'] == product['productId'];
                        final price = product['productPrice'] is num
                            ? (product['productPrice'] as num).toInt()
                            : int.tryParse('${product['productPrice']}') ?? 15000;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? GageTheme.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? GageTheme.primary
                                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedProduct = product;
                                _attachProduct = true;
                              });
                              Navigator.pop(sheetCtx);
                              GageToast.show(
                                context,
                                'Produk Keranjang Merah terpilih: ${product['productTitle']}',
                                type: GageToastType.success,
                              );
                            },
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: (product['thumbnailUrl'] as String? ?? '').startsWith('assets/')
                                    ? Image.asset(product['thumbnailUrl'], fit: BoxFit.cover)
                                    : Image.network(
                                        product['thumbnailUrl'] ?? '',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade400,
                                          child: const Icon(Icons.fastfood_rounded, color: Colors.white, size: 24),
                                        ),
                                      ),
                              ),
                            ),
                            title: Text(
                              product['productTitle'] as String? ?? 'Produk Mitra',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                color: isSelected
                                    ? GageTheme.primary
                                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${product['merchantName'] ?? 'Mitra GAGE'} • ${_currencyFormat.format(price)}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              ),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? GageTheme.primary
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                foregroundColor: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                elevation: 0,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedProduct = product;
                                  _attachProduct = true;
                                });
                                Navigator.pop(sheetCtx);
                                GageToast.show(
                                  context,
                                  'Produk Keranjang Merah terpilih: ${product['productTitle']}',
                                  type: GageToastType.success,
                                );
                              },
                              child: Text(
                                isSelected ? 'Terpilih' : 'Pilih',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _publishVideo() {
    HapticFeedback.heavyImpact();

    final caption = _captionController.text.trim();
    if (caption.isEmpty) {
      GageToast.show(context, 'Tuliskan caption terlebih dahulu', type: GageToastType.error);
      return;
    }

    final hasProduct = _attachProduct && _selectedProduct != null;
    final int videoIdInt = DateTime.now().millisecondsSinceEpoch;
    final String videoId = 'vid-$videoIdInt';

    final int rawPrice = _selectedProduct?['productPrice'] is num
        ? (_selectedProduct!['productPrice'] as num).toInt()
        : int.tryParse('${_selectedProduct?['productPrice']}') ?? 15000;

    final newItem = GageVideoItem(
      id: videoId,
      videoUrl: _videoPath ?? 'assets/videos/vt_bakso_urat.mp4',
      thumbnailUrl: _coverPath != null
          ? _coverPath!
          : (hasProduct
              ? (_selectedProduct!['thumbnailUrl'] as String? ?? 'assets/images/dish_dimsum_mentai.png')
              : 'assets/images/resto_bakso_mas_no.png'),
      creatorHandle: SocialProfileService.instance.userHandle.startsWith('@')
          ? SocialProfileService.instance.userHandle
          : '@${SocialProfileService.instance.userHandle}',
      creatorName: 'Kreator GAGE Praci',
      creatorAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
      caption: caption,
      merchantId: hasProduct ? (_selectedProduct!['merchantId'] as String? ?? 'mch-01') : '',
      merchantName: hasProduct ? (_selectedProduct!['merchantName'] as String? ?? '') : '',
      merchantRating: hasProduct ? ((_selectedProduct!['merchantRating'] as num?)?.toDouble() ?? 4.9) : 0.0,
      merchantLocation: hasProduct ? 'Pracimantoro' : '',
      merchantAddress: hasProduct ? 'Pracimantoro, Kab. Wonogiri' : '',
      deliveryEstimate: hasProduct ? '10-20 mnt' : '',
      productId: hasProduct ? (_selectedProduct!['productId'] as String? ?? '') : '',
      productTitle: hasProduct ? (_selectedProduct!['productTitle'] as String? ?? '') : '',
      productPrice: rawPrice,
      productDescription: hasProduct ? (_selectedProduct!['productDescription'] as String? ?? '') : '',
      likesCount: 1,
      commentsCount: 0,
      bookmarksCount: 0,
      sharesCount: 0,
    );

    GageVideoFeedService.instance.addVideo(newItem);

    GageToast.show(
      context,
      hasProduct
          ? 'Video dan Keranjang Merah berhasil dipublikasikan'
          : 'Video berhasil dipublikasikan ke feed',
      type: GageToastType.success,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const VideoFeedScreen(initialIndex: 0)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.maybePop(context);
          },
        ),
        title: Text(
          'Posting Baru',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. KONTEN POSTINGAN (TikTok Style: Form Caption Kiri + Mini Thumbnail Kanan)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form Teks Caption di Kiri
                      Expanded(
                        child: TextField(
                          controller: _captionController,
                          maxLines: 5,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tulis caption ulasan atau deskripsi video...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Mini Preview Thumbnail Video di Kanan (Screenshot 4: Preview Badge + Edit Cover)
                      GestureDetector(
                        onTap: _pickCoverImage,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 84,
                            height: 114,
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (_coverPath != null && File(_coverPath!).existsSync())
                                  Image.file(File(_coverPath!), fit: BoxFit.cover)
                                else if (_isCustomVideo && _videoPath != null && _videoPath!.isNotEmpty)
                                  Container(
                                    color: const Color(0xFF1E293B),
                                    child: const Center(
                                      child: Icon(Icons.videocam_rounded, color: Colors.white70, size: 28),
                                    ),
                                  )
                                else
                                  Image.asset(
                                    'assets/images/resto_bakso_mas_no.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFF1E293B),
                                      child: const Icon(Icons.play_circle_rounded, color: Colors.white54),
                                    ),
                                  ),

                                // Top Badge: "Preview" (Screenshot 4)
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Preview',
                                      style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),

                                // Bottom Button: "Edit cover" (Screenshot 4)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.edit_rounded, color: Colors.white, size: 10),
                                        SizedBox(width: 3),
                                        Text(
                                          'Edit cover',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Quick Chips: # Hashtags & @ Mention (Screenshot 4)
                  Row(
                    children: [
                      ActionChip(
                        avatar: const Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        label: const Text('Hashtags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                        shape: const StadiumBorder(),
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                        onPressed: _insertHashtag,
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Text('@', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        label: const Text('Mention', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                        shape: const StadiumBorder(),
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                        onPressed: _insertMention,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (widget.selectedSoundTitle != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: GageTheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.music_note_rounded, color: GageTheme.primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.selectedSoundTitle!,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Musik: ${(widget.musicVolume * 100).round()}% • Suara Asli: ${(widget.originalAudioVolume * 100).round()}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 2. BAGIAN PENAUTAN KERANJANG MERAH (SEKETIKA MEMUNCULKAN SHEET PRODUK ETALASE)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _attachProduct
                      ? GageTheme.primary.withValues(alpha: 0.4)
                      : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _attachProduct
                              ? GageTheme.primary.withValues(alpha: 0.15)
                              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shopping_bag_rounded,
                          color: _attachProduct ? GageTheme.primary : Colors.grey,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tautkan Keranjang Merah',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Produk belanja dari etalase kreator Anda',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _attachProduct,
                        activeColor: GageTheme.primary,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          if (val) {
                            _showShowcasePickerSheet();
                          } else {
                            setState(() {
                              _attachProduct = false;
                              _selectedProduct = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  // Jika Keranjang Merah aktif dan produk terpilih
                  if (_attachProduct && _selectedProduct != null) ...[
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GageTheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: (_selectedProduct!['thumbnailUrl'] as String? ?? '').startsWith('assets/')
                                  ? Image.asset(_selectedProduct!['thumbnailUrl'], fit: BoxFit.cover)
                                  : Image.network(
                                      _selectedProduct!['thumbnailUrl'] ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey.shade400,
                                        child: const Icon(Icons.fastfood_rounded, color: Colors.white, size: 20),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedProduct!['productTitle'] as String? ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _selectedProduct!['merchantName'] as String? ?? 'Mitra GAGE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _currencyFormat.format(_selectedProduct!['productPrice'] ?? 15000),
                            style: const TextStyle(
                              color: GageTheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.swap_horiz_rounded, size: 20, color: GageTheme.primary),
                            tooltip: 'Ganti Produk',
                            onPressed: _showShowcasePickerSheet,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 3. TOMBOL PUBLIKASIKAN VIDEO
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 1,
              ),
              onPressed: _publishVideo,
              child: const Text(
                'Posting Video',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
