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

/// Layar Unggah Video Afiliasi & Integrasi Keranjang Kuning
/// Tata letak bersih ala TikTok: Form Caption di Kiri + Mini Thumbnail di Kanan,
/// Penautan Produk Keranjang Kuning di Bawah khusus dari Etalase Kreator.
class AffiliateVideoUploadScreen extends StatefulWidget {
  final Map<String, dynamic>? initialMerchant;
  final Map<String, dynamic>? initialProduct;
  final String? initialVideoPath;
  final String? initialVideoName;
  final String? selectedSoundTitle;
  final String? selectedSoundArtist;
  final double originalAudioVolume;
  final double musicVolume;

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
  });

  @override
  State<AffiliateVideoUploadScreen> createState() => _AffiliateVideoUploadScreenState();
}

class _AffiliateVideoUploadScreenState extends State<AffiliateVideoUploadScreen> {
  final TextEditingController _captionController = TextEditingController(
    text: 'Rekomendasi kuliner terenak di Pracimantoro! Kuah gurih, porsi mantap. #gagekuliner #pracimantoro',
  );

  String? _videoPath;
  String _videoSourceName = 'assets/videos/vt_bakso_urat.mp4';
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

    if (widget.initialVideoPath != null) {
      _videoPath = widget.initialVideoPath;
      _videoSourceName = widget.initialVideoName ?? 'Video Galeri';
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
    } else {
      // Cek apakah kreator sudah punya produk di etalase
      final showcase = SocialProfileService.instance.getShowcaseProducts(SocialProfileService.instance.userHandle);
      if (showcase.isNotEmpty) {
        _selectedProduct = showcase.first;
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideoFromGallery() async {
    HapticFeedback.selectionClick();
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _videoPath = pickedFile.path;
          _videoSourceName = pickedFile.name;
          _isCustomVideo = true;
        });
        GageToast.show(context, 'Video berhasil dipilih dari galeri', type: GageToastType.success);
      }
    } catch (e) {
      if (mounted) {
        GageToast.show(context, 'Gagal memilih video: $e', type: GageToastType.error);
      }
    }
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
      thumbnailUrl: hasProduct
          ? (_selectedProduct!['thumbnailUrl'] as String? ?? 'assets/images/dish_dimsum_mentai.png')
          : 'assets/images/resto_bakso_mas_no.png',
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
          ? 'Video dan Keranjang Kuning berhasil dipublikasikan'
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
    final showcaseProducts = SocialProfileService.instance.getShowcaseProducts(
      SocialProfileService.instance.userHandle,
    );

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
              child: Row(
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

                  // Mini Preview Thumbnail Video di Kanan
                  GestureDetector(
                    onTap: _pickVideoFromGallery,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 76,
                        height: 104,
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_isCustomVideo && _videoPath != null && _videoPath!.isNotEmpty)
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
                                  child: const Icon(Icons.play_circle_outline, color: Colors.white54),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.65),
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: const Text(
                                  'Ganti',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
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

            // 2. BAGIAN PENAUTAN KERANJANG KUNING (DITARUH DI BAWAH)
            Container(
              padding: const EdgeInsets.all(16),
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _attachProduct
                              ? const Color(0xFFFEF3C7)
                              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shopping_bag_rounded,
                          color: _attachProduct ? const Color(0xFFD97706) : Colors.grey,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tautkan Keranjang Kuning',
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
                          setState(() {
                            _attachProduct = val;
                          });
                        },
                      ),
                    ],
                  ),

                  if (_attachProduct) ...[
                    const Divider(height: 24),
                    if (showcaseProducts.isEmpty) ...[
                      // Etalase Kosong: Arahkan ke GAGE Cuan
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white12 : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Etalase Anda masih kosong',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Pilih produk dari mitra UMKM di menu GAGE Cuan untuk dimasukkan ke etalase Anda terlebih dahulu.',
                              style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: const StadiumBorder(),
                                side: const BorderSide(color: GageTheme.primary),
                                foregroundColor: GageTheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AffiliateHubScreen()),
                                );
                              },
                              icon: const Icon(Icons.storefront_rounded, size: 15),
                              label: const Text(
                                'Buka GAGE Cuan',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Pilihan Produk Khusus dari Etalase
                      Text(
                        'Pilih Produk dari Etalase:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedProduct?['productId'] as String?,
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            items: showcaseProducts.map((p) {
                              final price = p['productPrice'] as int? ?? 15000;
                              return DropdownMenuItem<String>(
                                value: p['productId'] as String,
                                child: Text(
                                  '${p['productTitle']} - ${_currencyFormat.format(price)}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (pId) {
                              if (pId != null) {
                                setState(() {
                                  _selectedProduct = showcaseProducts.firstWhere(
                                    (p) => p['productId'] == pId,
                                    orElse: () => showcaseProducts.first,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ),

                      if (_selectedProduct != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
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
                                            child: const Icon(Icons.fastfood, color: Colors.white, size: 20),
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
                            ],
                          ),
                        ),
                      ],
                    ],
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
