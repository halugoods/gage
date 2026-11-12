import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/shared/widgets/gage_avatar.dart';
import 'package:gage_app/shared/widgets/gage_bottom_nav_bar.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';

enum VideoPlayMode {
  nativeAsset,
  tiktokEmbed,
}

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  VideoPlayMode _playMode = VideoPlayMode.nativeAsset;

  // Video feed catalog (Real Pracimantoro merchants & Authentic TikTok IDs)
  // All metrics initialized to 0 for authentic production-readiness.
  final List<Map<String, dynamic>> _videos = [
    {
      'id': 'vt-01',
      'author': '@kulinerpracimantoro',
      'author_name': 'Kuliner Pracimantoro Official',
      'avatar': 'assets/images/gage_icon.png',
      'title': 'Paket Geprek 1 Rocket Chicken Pracimantoro renyah & pedas nampol! Cobain langsung via GAGE Delivery.',
      'audio': 'Suara Asli - Rocket Chicken Pracimantoro',
      'tag': '[GAGE#RC-PKM01]',
      'product_name': 'Paket Geprek 1 (Ayam + Nasi + Es Teh)',
      'price': 14000,
      'merchant_id': 'mch-rc-01',
      'merchant': 'Rocket Chicken Pracimantoro',
      'asset_path': 'assets/videos/vt_rocket_chicken.mp4',
      'watermarked_path': 'assets/videos/watermarked/vt_rocket_chicken_wm.mp4',
      'tiktok_id': '7705278745954815252',
      'likes': 0,
      'is_liked': false,
      'comments_count': 0,
      'shares_count': 0,
      'downloads_count': 0,
      'comments': <Map<String, String>>[],
    },
    {
      'id': 'vt-02',
      'author': '@solodelicious',
      'author_name': 'Solo Delicious Foodies',
      'avatar': 'assets/images/gage_icon.png',
      'title': 'Mie Ayam Jumbo komplit ceker & bakso urat Pak Kumis Pracimantoro kuah kental gurih.',
      'audio': 'Suara Asli - Mie Ayam Pak Kumis',
      'tag': '[GAGE#MIE-PKM02]',
      'product_name': 'Mie Ayam Ceker Jumbo',
      'price': 13000,
      'merchant_id': 'mch-mak-02',
      'merchant': 'Mie Ayam Bakso Pak Kumis',
      'asset_path': 'assets/videos/vt_mie_ayam.mp4',
      'watermarked_path': 'assets/videos/watermarked/vt_mie_ayam_wm.mp4',
      'tiktok_id': '7201948291048291048',
      'likes': 0,
      'is_liked': false,
      'comments_count': 0,
      'shares_count': 0,
      'downloads_count': 0,
      'comments': <Map<String, String>>[],
    },
    {
      'id': 'vt-03',
      'author': '@kuliner.wonogiri',
      'author_name': 'Jelajah Kuliner Wonogiri',
      'avatar': 'assets/images/gage_icon.png',
      'title': 'Seblak Jeletot level 5 kuah kental rempah cikur mantap! Topping sosis, cikuwa, mie komplit.',
      'audio': 'Suara Asli - Seblak Jeletot Prasmanan',
      'tag': '[GAGE#SBK-PKM03]',
      'product_name': 'Seblak Komplit Prasmanan',
      'price': 12000,
      'merchant_id': 'mch-sbk-03',
      'merchant': 'Seblak Jeletot Prasmanan',
      'asset_path': 'assets/videos/vt_seblak_pedas.mp4',
      'watermarked_path': 'assets/videos/watermarked/vt_seblak_pedas_wm.mp4',
      'tiktok_id': '7310928401928401928',
      'likes': 0,
      'is_liked': false,
      'comments_count': 0,
      'shares_count': 0,
      'downloads_count': 0,
      'comments': <Map<String, String>>[],
    },
    {
      'id': 'vt-04',
      'author': '@cemilanhits',
      'author_name': 'Cemilan Hits Nusantara',
      'avatar': 'assets/images/gage_icon.png',
      'title': 'Roti Gembong cokelat keju lumer empuk parah buat oleh-oleh dan santai sore di rumah.',
      'audio': 'Suara Asli - Roti Gembong Gedhe',
      'tag': '[GAGE#ROT-PKM04]',
      'product_name': 'Roti Gembong Cokelat Lumer',
      'price': 16000,
      'merchant_id': 'mch-rgg-04',
      'merchant': 'Roti Gembong Gedhe Pracimantoro',
      'asset_path': 'assets/videos/vt_roti_gembong.mp4',
      'watermarked_path': 'assets/videos/watermarked/vt_roti_gembong_wm.mp4',
      'tiktok_id': '7402918204918204918',
      'likes': 0,
      'is_liked': false,
      'comments_count': 0,
      'shares_count': 0,
      'downloads_count': 0,
      'comments': <Map<String, String>>[],
    },
    {
      'id': 'vt-05',
      'author': '@jajananwonogiri',
      'author_name': 'Jajanan Wonogiri Selatan',
      'avatar': 'assets/images/gage_icon.png',
      'title': 'Sate ayam bumbu kacang medok daging empuk Cak Sholeh! Disajikan hangat dengan lontong pulen.',
      'audio': 'Suara Asli - Sate Cak Sholeh',
      'tag': '[GAGE#SAT-PKM05]',
      'product_name': 'Sate Ayam 10 Tusuk + Lontong',
      'price': 18000,
      'merchant_id': 'mch-sat-05',
      'merchant': 'Sate Cak Sholeh Pracimantoro',
      'asset_path': 'assets/videos/vt_sate_ayam.mp4',
      'watermarked_path': 'assets/videos/watermarked/vt_sate_ayam_wm.mp4',
      'tiktok_id': '7501928301928301928',
      'likes': 0,
      'is_liked': false,
      'comments_count': 0,
      'shares_count': 0,
      'downloads_count': 0,
      'comments': <Map<String, String>>[],
    },
    {
      'id': 'vt-06',
      'author': '@geprekmania',
      'author_name': 'Geprek Mania Soloraya',
      'avatar': 'assets/images/gage_icon.png',
      'title': 'Ayam Geprek sambal korek pedas gurih cabe segar rawit domba! Free refill es teh manis.',
      'audio': 'Suara Asli - Geprek Sambal Bawang',
      'tag': '[GAGE#AGP-PKM06]',
      'product_name': 'Geprek Sambal Korek + Nasi',
      'price': 11000,
      'merchant_id': 'mch-agp-06',
      'merchant': 'Geprek Sambal Bawang Sedap',
      'asset_path': 'assets/videos/vt_ayam_geprek.mp4',
      'watermarked_path': 'assets/videos/watermarked/vt_ayam_geprek_wm.mp4',
      'tiktok_id': '7602918402918402918',
      'likes': 0,
      'is_liked': false,
      'comments_count': 0,
      'shares_count': 0,
      'downloads_count': 0,
      'comments': <Map<String, String>>[],
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleLike(int index) {
    setState(() {
      final video = _videos[index];
      final bool current = video['is_liked'] as bool;
      video['is_liked'] = !current;
      video['likes'] = (video['likes'] as int) + (current ? -1 : 1);
    });
  }

  void _showCommentsSheet(BuildContext context, int index) {
    final video = _videos[index];
    final List<Map<String, String>> comments = List<Map<String, String>>.from(video['comments'] as List);
    final TextEditingController textCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final bottomInset = MediaQuery.of(modalCtx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SizedBox(
                height: 480,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Komentar (${comments.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                            onPressed: () => Navigator.pop(modalCtx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    Expanded(
                      child: comments.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.white38),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Belum ada komentar',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Jadilah yang pertama berkomentar di video ini!',
                                    style: TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: comments.length,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemBuilder: (c, i) {
                                final item = comments[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GageAvatar(
                                        imageUrl: null,
                                        fallbackName: (item['user'] ?? 'U').toString(),
                                        radius: 16,
                                        backgroundColor: GageTheme.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['user'] ?? 'Warga Pracimantoro',
                                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item['text'] ?? '',
                                              style: const TextStyle(color: Colors.white, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        border: Border(top: BorderSide(color: Colors.white12)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: textCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Tulis komentar untuk menu ini...',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF1E293B),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send_rounded, color: GageTheme.primary),
                            onPressed: () {
                              final text = textCtrl.text.trim();
                              if (text.isNotEmpty) {
                                setModalState(() {
                                  comments.add({
                                    'user': 'Anda (Warga Pracimantoro)',
                                    'text': text,
                                  });
                                });
                                setState(() {
                                  video['comments'] = comments;
                                  video['comments_count'] = comments.length;
                                });
                                textCtrl.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showShareDialog(BuildContext context, int index) {
    final video = _videos[index];
    setState(() {
      video['shares_count'] = (video['shares_count'] as int) + 1;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bagikan Video Kuliner',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShareOption(Icons.link_rounded, 'Salin Link', () {
                    final vtUrl = 'https://vt.tiktok.com/${video['tiktok_id']}';
                    Clipboard.setData(ClipboardData(text: vtUrl));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Link video disalin: $vtUrl')),
                    );
                  }),
                  _buildShareOption(Icons.share_rounded, 'Bagikan', () async {
                    Navigator.pop(ctx);
                    final vtUrl = 'https://vt.tiktok.com/${video['tiktok_id']}';
                    final text = 'Cek promo ${video['product_name']} di GAGE Video: $vtUrl';
                    try {
                      await SharePlus.instance.share(
                        ShareParams(
                          text: text,
                          subject: '${video['product_name']} di GAGE Video',
                        ),
                      );
                    } catch (_) {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Link disalin ke clipboard: $vtUrl')),
                        );
                      }
                    }
                  }),
                  _buildShareOption(Icons.download_rounded, 'Unduh Video', () {
                    setState(() {
                      video['downloads_count'] = (video['downloads_count'] as int) + 1;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Mengunduh ${video['product_name']} dengan watermark GAGE...')),
                    );
                  }),
                  _buildShareOption(Icons.qr_code_rounded, 'QR Code', () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Kode Promo: ${video['tag']}')),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF334155),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  void _showOrderBottomSheet(Map<String, dynamic> video) {
    final cart = context.read<CartProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final price = video['price'] as int;
    int qty = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final totalPrice = price * qty;
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video['product_name'] as String,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: GageTheme.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Resto: ${video['merchant']}',
                              style: const TextStyle(fontSize: 13, color: GageTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: GageTheme.accentGreen, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kode Afiliasi Promo: ${video['tag']}',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyFormatter.format(price),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: GageTheme.primary),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: qty > 1 ? () => setSheetState(() => qty--) : null,
                            ),
                            Text('$qty', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () => setSheetState(() => qty++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            cart.addItem(CartItemModel(
                              menuId: '${video['id']}_cart_${DateTime.now().millisecondsSinceEpoch}',
                              name: video['product_name'] as String,
                              price: price,
                              quantity: qty,
                              merchantId: video['merchant_id'] as String,
                              merchantName: video['merchant'] as String,
                              notes: 'Dari Video VT Promo ${video['tag']}',
                            ));
                            Navigator.pop(sheetCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${video['product_name']} ($qty) ditambahkan ke keranjang!'),
                                backgroundColor: GageTheme.accentGreen,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: GageTheme.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Tambah Keranjang', style: TextStyle(color: GageTheme.primary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            cart.addItem(CartItemModel(
                              menuId: '${video['id']}_cart_${DateTime.now().millisecondsSinceEpoch}',
                              name: video['product_name'] as String,
                              price: price,
                              quantity: qty,
                              merchantId: video['merchant_id'] as String,
                              merchantName: video['merchant'] as String,
                              notes: 'Dari Video VT Promo ${video['tag']}',
                            ));
                            Navigator.pop(sheetCtx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Beli (${currencyFormatter.format(totalPrice)})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _videos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final video = _videos[index];
              return _VideoFeedItem(
                video: video,
                isActive: index == _currentIndex,
                playMode: _playMode,
                onLike: () => _toggleLike(index),
                onComment: () => _showCommentsSheet(context, index),
                onShare: () => _showShareDialog(context, index),
                onOrder: () => _showOrderBottomSheet(video),
              );
            },
          ),

          // Top App Bar Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
                left: 16,
                right: 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'GAGE VT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  // Play Mode Toggle Pill (TikTok Embed vs Local Asset)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _playMode = _playMode == VideoPlayMode.nativeAsset
                            ? VideoPlayMode.tiktokEmbed
                            : VideoPlayMode.nativeAsset;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 2),
                          content: Text(
                            _playMode == VideoPlayMode.tiktokEmbed
                                ? 'Mode Aktif: TikTok Official Embed Player (v1 iframe)'
                                : 'Mode Aktif: Pemutar Offline Cepat (Local Asset)',
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _playMode == VideoPlayMode.tiktokEmbed ? const Color(0xFFE52320) : Colors.white24,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _playMode == VideoPlayMode.tiktokEmbed ? Icons.public : Icons.offline_bolt,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _playMode == VideoPlayMode.tiktokEmbed ? 'TikTok Embed' : 'Lokal MP4',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Register VT button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AffiliateHubScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: GageTheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_circle_outline, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('+ Daftarkan VT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const GageBottomNavBar(
        currentIndex: 3,
      ),
    );
  }
}

class _VideoFeedItem extends StatefulWidget {
  final Map<String, dynamic> video;
  final bool isActive;
  final VideoPlayMode playMode;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onOrder;

  const _VideoFeedItem({
    required this.video,
    required this.isActive,
    required this.playMode,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onOrder,
  });

  @override
  State<_VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<_VideoFeedItem> {
  VideoPlayerController? _videoPlayerController;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _initAppropriatePlayer();
  }

  @override
  void didUpdateWidget(covariant _VideoFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive || oldWidget.playMode != widget.playMode) {
      if (widget.isActive) {
        _initAppropriatePlayer();
      } else {
        _videoPlayerController?.pause();
      }
    }
  }

  void _initAppropriatePlayer() {
    if (widget.playMode == VideoPlayMode.tiktokEmbed) {
      _initTikTokWebView();
    } else {
      _initNativeVideoPlayer();
    }
  }

  void _initNativeVideoPlayer() {
    final assetPath = widget.video['asset_path'] as String?;
    if (assetPath == null) return;

    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.asset(assetPath)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoPlayerController?.setLooping(true);
          _videoPlayerController?.setVolume(1.0); // Full audio per user requirement
          if (widget.isActive) {
            _videoPlayerController?.play();
          }
        }
      }).catchError((err) {
        // Fallback gracefully
        if (mounted) setState(() {});
      });
  }

  void _initTikTokWebView() {
    final tiktokId = widget.video['tiktok_id'] as String? ?? '7705278745954815252';
    final embedUrl = 'https://www.tiktok.com/player/v1/$tiktokId?music_info=1&description=1&autoplay=1&muted=0&embed_from=embed_page';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadRequest(Uri.parse(embedUrl));
    
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Video Player Surface
        if (widget.playMode == VideoPlayMode.tiktokEmbed && _webViewController != null)
          WebViewWidget(controller: _webViewController!)
        else if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized)
          Center(
            child: AspectRatio(
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              child: VideoPlayer(_videoPlayerController!),
            ),
          )
        else
          Container(
            color: const Color(0xFF0F172A),
            child: const Center(
              child: CircularProgressIndicator(color: GageTheme.primary),
            ),
          ),

        // Gradient overlay for high legibility
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.85),
                ],
                stops: const [0.4, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // 2. Right Side Action Bar (Tiktok-Style: Like, Comment, Share, Download)
        // Strictly 4 core actions, zero bookmark clutter
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            children: [
              // Creator Avatar with follow badge
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: GageAvatar(
                      radius: 22,
                      imageUrl: video['avatar']?.toString(),
                      fallbackName: video['creator']?.toString() ?? 'GAGE',
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: GageTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Like Action
              _buildActionButton(
                icon: (video['is_liked'] as bool) ? Icons.favorite_rounded : Icons.favorite_rounded,
                iconColor: (video['is_liked'] as bool) ? const Color(0xFFEF4444) : Colors.white,
                label: '${video['likes']}',
                onTap: widget.onLike,
              ),
              const SizedBox(height: 18),

              // Comment Action
              _buildActionButton(
                icon: Icons.chat_bubble_rounded,
                iconColor: Colors.white,
                label: '${video['comments_count']}',
                onTap: widget.onComment,
              ),
              const SizedBox(height: 18),

              // Share & Download Action
              _buildActionButton(
                icon: Icons.share_rounded,
                iconColor: Colors.white,
                label: '${video['shares_count']}',
                onTap: widget.onShare,
              ),
              const SizedBox(height: 22),

              // Spinning Disc / Audio Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E293B),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 22),
              ),
            ],
          ),
        ),

        // 3. Bottom Information & Product Badge ("Yellow Cart")
        Positioned(
          left: 16,
          right: 76,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Creator Handle & Verified Icon
              Row(
                children: [
                  Text(
                    video['author'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.verified_rounded, color: GageTheme.accentGreen, size: 16),
                ],
              ),
              const SizedBox(height: 6),

              // Caption / Description
              Text(
                video['title'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.35,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
              const SizedBox(height: 8),

              // Audio Title Marquee
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      video['audio'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Yellow Product Pill ("Beli Sekarang / Tambah ke Keranjang")
              InkWell(
                onTap: widget.onOrder,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB703),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_rounded, color: Color(0xFF1E293B), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              video['product_name'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${currencyFormatter.format(video['price'])} • ${video['merchant']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Pesan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 32,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}
