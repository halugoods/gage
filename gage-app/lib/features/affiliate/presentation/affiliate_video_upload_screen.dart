import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/services/gage_video_feed_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/mock/gage_mock_registry.dart';
import 'package:gage_app/features/video/presentation/video_feed_screen.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Layar Unggah Video Afiliasi & Integrasi Keranjang Kuning
/// Memungkinkan kreator/affiliator memilih video, menautkan produk merchant (Keranjang Kuning),
/// menulis caption, melihat live preview kartu belanja, dan mempublikasikannya langsung ke feed video GAGE.
class AffiliateVideoUploadScreen extends StatefulWidget {
  final Map<String, dynamic>? initialMerchant;
  final Map<String, dynamic>? initialProduct;

  const AffiliateVideoUploadScreen({
    super.key,
    this.initialMerchant,
    this.initialProduct,
  });

  @override
  State<AffiliateVideoUploadScreen> createState() => _AffiliateVideoUploadScreenState();
}

class _AffiliateVideoUploadScreenState extends State<AffiliateVideoUploadScreen> {
  final TextEditingController _captionController = TextEditingController(
    text: 'Rekomendasi kuliner terenak di Pracimantoro! Kuah gurih, porsi nampol pol 🔥 #gagekuliner #pracimantoro',
  );

  String? _videoPath;
  String _videoSourceName = 'assets/videos/vt_bakso_urat.mp4 (Template Sampel)';
  bool _isCustomVideo = false;
  bool _attachProduct = false;

  int _selectedServiceIndex = 0; // 0: Food, 1: Shop, 2: Farm, 3: Build
  final List<String> _serviceNames = ['Food', 'Shop', 'Farm', 'Build'];

  Map<String, dynamic>? _selectedMerchant;
  Map<String, dynamic>? _selectedProduct;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    if (widget.initialMerchant != null || widget.initialProduct != null) {
      _attachProduct = true;
      if (widget.initialMerchant != null) {
        final mId = widget.initialMerchant!['id'];
        if (GageMockRegistry.foodMerchants.any((m) => m['id'] == mId)) {
          _selectedServiceIndex = 0;
        } else if (GageMockRegistry.shopMerchants.any((m) => m['id'] == mId)) {
          _selectedServiceIndex = 1;
        } else if (GageMockRegistry.farmMerchants.any((m) => m['id'] == mId)) {
          _selectedServiceIndex = 2;
        } else if (GageMockRegistry.buildMerchants.any((m) => m['id'] == mId)) {
          _selectedServiceIndex = 3;
        }

        final activeList = _getMerchantsForActiveService();
        _selectedMerchant = activeList.firstWhere(
          (m) => m['id'] == mId,
          orElse: () => activeList.first,
        );

        final menus = (_selectedMerchant?['menus'] as List<dynamic>?) ?? [];
        if (widget.initialProduct != null) {
          final pId = widget.initialProduct!['id'];
          _selectedProduct = menus.firstWhere(
            (p) => p['id'] == pId,
            orElse: () => menus.isNotEmpty ? menus.first as Map<String, dynamic> : null,
          ) as Map<String, dynamic>?;
        } else {
          _selectedProduct = menus.isNotEmpty ? menus.first as Map<String, dynamic> : null;
        }
      }
    } else {
      // Default untuk kreator biasa: keranjang kuning nonaktif
      _attachProduct = false;
      _selectedMerchant = GageMockRegistry.foodMerchants.first;
      final menus = _selectedMerchant?['menus'] as List<dynamic>?;
      _selectedProduct = (menus != null && menus.isNotEmpty) ? menus.first as Map<String, dynamic> : null;
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
      if (pickedFile != null) {
        setState(() {
          _videoPath = pickedFile.path;
          _videoSourceName = 'File Galeri: ${pickedFile.name}';
          _isCustomVideo = true;
        });
        if (mounted) {
          GageToast.show(context, 'Video berhasil dipilih dari galeri!', type: GageToastType.success);
        }
      }
    } catch (e) {
      if (mounted) {
        GageToast.show(context, 'Gagal memilih video: $e', type: GageToastType.error);
      }
    }
  }

  List<Map<String, dynamic>> _getMerchantsForActiveService() {
    switch (_selectedServiceIndex) {
      case 0:
        return GageMockRegistry.foodMerchants;
      case 1:
        return GageMockRegistry.shopMerchants;
      case 2:
        return GageMockRegistry.farmMerchants;
      case 3:
        return GageMockRegistry.buildMerchants;
      default:
        return GageMockRegistry.foodMerchants;
    }
  }

  void _addHashtag(String tag) {
    HapticFeedback.selectionClick();
    if (!_captionController.text.contains(tag)) {
      _captionController.text = '${_captionController.text.trim()} $tag';
      setState(() {});
    }
  }

  void _publishVideo() {
    HapticFeedback.heavyImpact();

    final hasProduct = _attachProduct && _selectedMerchant != null && _selectedProduct != null;

    if (_attachProduct && (_selectedMerchant == null || _selectedProduct == null)) {
      GageToast.show(context, 'Pilih toko dan produk untuk Keranjang Kuning terlebih dahulu!', type: GageToastType.warning);
      return;
    }

    final rawPrice = hasProduct ? _selectedProduct!['price'] : 0;
    final price = (rawPrice is num ? rawPrice.toInt() : int.tryParse('$rawPrice') ?? 0);

    final rawRate = hasProduct ? (_selectedMerchant!['commissionRate'] ?? 10) : 0;
    final commissionRate = (rawRate is num ? rawRate.toInt() : int.tryParse('$rawRate') ?? 10).clamp(0, 20);

    final newItem = GageVideoItem(
      id: 'vid-user-${DateTime.now().millisecondsSinceEpoch}',
      videoUrl: _videoPath ?? 'assets/videos/vt_bakso_urat.mp4',
      thumbnailUrl: hasProduct
          ? (_selectedProduct!['image'] as String? ?? 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400&q=80')
          : 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&q=80',
      creatorHandle: '@kreator_praci',
      creatorName: 'Kreator GAGE Praci',
      creatorAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
      caption: _captionController.text.trim(),
      merchantId: hasProduct ? (_selectedMerchant!['id'] as String? ?? 'mch-01') : '',
      merchantName: hasProduct ? (_selectedMerchant!['name'] as String? ?? '') : '',
      merchantRating: hasProduct ? ((_selectedMerchant!['rating'] as num?)?.toDouble() ?? 4.9) : 0.0,
      merchantLocation: hasProduct ? 'Pracimantoro' : '',
      merchantAddress: hasProduct ? (_selectedMerchant!['address'] as String? ?? '') : '',
      deliveryEstimate: hasProduct ? (_selectedMerchant!['eta'] as String? ?? '') : '',
      productId: hasProduct ? (_selectedProduct!['id'] as String? ?? '') : '',
      productTitle: hasProduct ? (_selectedProduct!['name'] as String? ?? '') : '',
      productPrice: price,
      productDescription: hasProduct ? (_selectedProduct!['description'] as String? ?? '') : '',
      likesCount: 1,
      commentsCount: 0,
      bookmarksCount: 0,
      sharesCount: 0,
    );

    GageVideoFeedService.instance.addVideo(newItem);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
            SizedBox(width: 10),
            Text('Video Dipublikasikan!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasProduct
                  ? 'Video Anda beserta Keranjang Kuning produk telah aktif di feed GAGE Video!'
                  : 'Video Anda berhasil dipublikasikan ke feed GAGE Video dan dapat ditonton oleh seluruh pengguna!',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            if (hasProduct) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Komisi $commissionRate%: Tiap ada yang order menu ini via videomu, Anda otomatis dapat komisi!',
                  style: const TextStyle(color: Color(0xFF166534), fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
            },
            child: const Text('Tutup', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GageTheme.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VideoFeedScreen(initialIndex: 0)),
              );
            },
            child: const Text('Buka GAGE Video 📹', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rawPrice = _selectedProduct?['price'];
    final productPrice = (rawPrice is num ? rawPrice.toInt() : int.tryParse('$rawPrice') ?? 15000);
    final rawRate = _selectedMerchant?['commissionRate'] ?? 10;
    final commissionRate = (rawRate is num ? rawRate.toInt() : int.tryParse('$rawRate') ?? 10).clamp(0, 20);
    final commissionRupiah = (productPrice * (commissionRate / 100.0)).round();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
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
          'Buat Video & Tag Produk',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STEP 1: Pilih Video
            _buildSectionHeader('1. PILIH SUMBER VIDEO', Icons.video_file_rounded),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: GageTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.movie_creation_rounded, color: GageTheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isCustomVideo ? 'Video Galeri Kustom' : 'Template Sampel Video Kuliner',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _videoSourceName,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: GageTheme.primary),
                        foregroundColor: GageTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                      onPressed: _pickVideoFromGallery,
                      icon: const Icon(Icons.folder_open_rounded, size: 16),
                      label: const Text('Pilih Video dari Galeri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // STEP 2: Pilih Keranjang Kuning (Toko & Produk)
            _buildSectionHeader('2. TAUTKAN KERANJANG KUNING (OPSIONAL)', Icons.shopping_bag_rounded),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle Switch Keranjang Kuning
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _attachProduct
                              ? const Color(0xFFFEF3C7)
                              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shopping_bag_rounded,
                          color: _attachProduct ? const Color(0xFFD97706) : (isDark ? Colors.white54 : Colors.grey),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sematkan Produk Belanja',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              _attachProduct
                                  ? 'Keranjang Kuning aktif (Dapatkan komisi jika ada yang order).'
                                  : 'Nonaktif (Posting video murni tanpa tautan belanja).',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
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
                    const Divider(height: 22),
                    // Switch Layanan 4 Pilar
                    Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: List.generate(_serviceNames.length, (idx) {
                        final isSel = _selectedServiceIndex == idx;
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedServiceIndex = idx;
                                final list = _getMerchantsForActiveService();
                                _selectedMerchant = list.isNotEmpty ? list.first : null;
                                final menus = _selectedMerchant?['menus'] as List<dynamic>?;
                                _selectedProduct = (menus != null && menus.isNotEmpty) ? menus.first as Map<String, dynamic> : null;
                              });
                            },
                            borderRadius: BorderRadius.circular(999),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel ? GageTheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Center(
                                child: Text(
                                  _serviceNames[idx],
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                    color: isSel ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dropdown Pilih Toko
                  const Text('Pilih Toko Mitra:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedMerchant?['id'] as String?,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: _getMerchantsForActiveService().map((m) {
                          return DropdownMenuItem<String>(
                            value: m['id'] as String,
                            child: Text(
                              '${m['name']} (${m['category']})',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            final list = _getMerchantsForActiveService();
                            setState(() {
                              _selectedMerchant = list.firstWhere(
                                (m) => m['id'] == id,
                                orElse: () => list.first,
                              );
                              final menus = _selectedMerchant?['menus'] as List<dynamic>?;
                              _selectedProduct = (menus != null && menus.isNotEmpty) ? menus.first as Map<String, dynamic> : null;
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Dropdown Pilih Produk
                  const Text('Pilih Menu / Produk yang Ditag:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedProduct?['id'] as String?,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: ((_selectedMerchant?['menus'] as List<dynamic>?) ?? []).map((p) {
                          final itemMap = p as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: itemMap['id'] as String,
                            child: Text(
                              '${itemMap['name']} - ${_currencyFormat.format(itemMap['price'])}',
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
                            final menus = ((_selectedMerchant?['menus'] as List<dynamic>?) ?? []).cast<Map<String, dynamic>>();
                            setState(() {
                              _selectedProduct = menus.firstWhere(
                                (p) => p['id'] == pId,
                                orElse: () => menus.first,
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  // Estimasi komisi per sale
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, size: 16, color: Color(0xFF166534)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Potensi Komisi: $commissionRate% (+${_currencyFormat.format(commissionRupiah)} per pesanan)',
                            style: const TextStyle(
                              color: Color(0xFF166534),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // STEP 3: Deskripsi & Tagar
            _buildSectionHeader('3. CAPTION & HASHTAG', Icons.edit_note_rounded),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _captionController,
                    maxLines: 3,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tulis review menarik tentang makanan ini...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(height: 16),
                  const Text('Tambah Tagar Cepat:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      '#gagekuliner',
                      '#pracimantoro',
                      '#wonogiri',
                      '#gagecuan',
                      '#makanenak',
                    ].map((tag) {
                      return InkWell(
                        onTap: () => _addHashtag(tag),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // STEP 4: Live Preview
            _buildSectionHeader(_attachProduct ? '4. LIVE PREVIEW KERANJANG KUNING' : '4. LIVE PREVIEW VIDEO', Icons.visibility_rounded),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: _attachProduct
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shopping_bag_rounded, color: Color(0xFFFBBF24), size: 15),
                            SizedBox(width: 5),
                            Text(
                              'Belanja dari Video (Tampil di Feed)',
                              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                _selectedProduct?['image'] as String? ?? 'assets/images/dish_dimsum_mentai.png',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 44,
                                  height: 44,
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.fastfood, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedProduct?['name'] as String? ?? 'Pilih Produk',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _currencyFormat.format(productPrice),
                                    style: const TextStyle(
                                      color: Color(0xFFFBBF24),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedMerchant?['name'] ?? ''} • 10-15 mnt',
                                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBF24),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.shopping_bag_outlined, size: 13, color: Colors.black),
                                  SizedBox(width: 4),
                                  Text(
                                    'PESAN',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.videocam_rounded, color: Colors.white70, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Feed Video Biasa (Tanpa Keranjang Belanja)',
                              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _captionController.text.trim().isEmpty
                              ? 'Tulis caption menarik untuk video Anda...'
                              : _captionController.text.trim(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '@kreator_praci • GAGE Video',
                          style: TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 28),

            // Tombol Publikasikan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                ),
                onPressed: _publishVideo,
                icon: const Icon(Icons.cloud_upload_rounded, size: 20),
                label: const Text(
                  'Publikasikan ke GAGE Video',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: GageTheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: GageTheme.primary,
          ),
        ),
      ],
    );
  }
}
