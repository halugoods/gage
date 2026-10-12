import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// Layar Penuh Detail Produk GAGE BaBe (Bukan Modal Drawer)
/// Dilengkapi Image Carousel Slider, Rincian Kondisi Fisik Riil,
/// Opsi Tawar/Nego Terintegrasi & Penyesuaian Harga Final,
/// Serta Proteksi Anti-Side Deal Escrow Resmi GAGE.
class BabeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const BabeDetailScreen({
    super.key,
    required this.item,
  });

  @override
  State<BabeDetailScreen> createState() => _BabeDetailScreenState();
}

class _BabeDetailScreenState extends State<BabeDetailScreen> {
  int _currentImageIdx = 0;
  final PageController _pageController = PageController();
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int? _negotiatedPrice;
  bool _isNegoAccepted = false;
  String? _dealCode;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveToBabeHistory({
    required String type,
    required String status,
    required int finalPrice,
    String? note,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final histList = prefs.getStringList('gage_babe_history') ?? [];
      final record = {
        'id': _dealCode ?? 'DEAL-BABE-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'type': type,
        'itemId': widget.item['id'] ?? '-',
        'title': widget.item['name'] ?? 'Produk BaBe',
        'originalPrice': widget.item['price'] ?? 0,
        'finalPrice': finalPrice,
        'status': status,
        'timestamp': DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
        'note': note ?? '',
      };
      histList.insert(0, jsonEncode(record));
      await prefs.setStringList('gage_babe_history', histList);
    } catch (_) {}
  }

  void _showNegoDialog(int basePrice) {
    int offer = (basePrice * 0.90).round();
    final ctrl = TextEditingController(text: offer.toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dCtx, setDState) {
          final maxAllowedDiscount = (basePrice * 0.20).round();
          final minAllowedOffer = basePrice - maxAllowedDiscount;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.handshake_rounded, color: Color(0xFFE52320), size: 24),
                SizedBox(width: 8),
                Text('Tawar Harga (Nego Online)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Harga Listing Saat Ini: ${currencyFormatter.format(basePrice)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text('Pilih Cepat Persentase Tawaran:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final pct in [0.95, 0.90, 0.85])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: BorderSide(
                                  color: offer == (basePrice * pct).round() ? GageTheme.primary : Colors.grey.shade300,
                                ),
                                backgroundColor: offer == (basePrice * pct).round() ? GageTheme.primaryLight : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                final calc = (basePrice * pct).round();
                                setDState(() {
                                  offer = calc;
                                  ctrl.text = calc.toString();
                                });
                              },
                              child: Text(
                                '-${((1 - pct) * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: offer == (basePrice * pct).round() ? GageTheme.primary : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Atau Masukkan Nominal Tawaran:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final p = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      setDState(() => offer = p);
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFB45309)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tawaran maksimal hemat 15-20% (minimal ${currencyFormatter.format(minAllowedOffer)}). Tawaran resmi akan tercatat di sistem dan admin GAGE menyetujui harga finalnya.',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF92400E), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (offer <= 0 || offer < minAllowedOffer) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tawaran terlalu rendah. Minimal penawaran adalah ${currencyFormatter.format(minAllowedOffer)}.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  final code = 'NEGO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                  setState(() {
                    _dealCode = code;
                    _negotiatedPrice = offer;
                    _isNegoAccepted = true;
                  });

                  _saveToBabeHistory(
                    type: 'nego',
                    status: 'Deal Nego Disetujui',
                    finalPrice: offer,
                    note: 'Tawaran Rp ${currencyFormatter.format(offer)} disetujui sistem & admin. Berlaku 2 jam.',
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tawaran ${currencyFormatter.format(offer)} disetujui! Harga final diperbarui.'),
                      backgroundColor: const Color(0xFF16A34A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Ajukan Tawaran'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openWhatsApp({required String phone, required String message}) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final List<String> images = (item['images'] as List<String>?) ?? [
      item['image'] as String? ?? 'assets/images/babe_iphone_11.jpg',
      'assets/images/hero_promo_1.png',
      'assets/images/promo_banner_1.png',
    ];

    final rawPrice = (item['price'] as int?) ?? 0;
    // Harga listing sudah termasuk markup 10% komisi resmi GAGE
    final listingPrice = rawPrice;
    final isNego = (item['isNego'] as bool?) ?? false;
    final Map<String, dynamic>? specs = item['specs'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // 1. Sliver App Bar dengan Image Carousel Slider (Banyak Foto Multi-Angle)
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 22),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, color: GageTheme.accentGreen, size: 15),
                    SizedBox(width: 4),
                    Text(
                      'Escrow Resmi GAGE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (idx) => setState(() => _currentImageIdx = idx),
                    itemBuilder: (ctx, idx) {
                      return Image.asset(
                        images[idx],
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: const Color(0xFF1E293B),
                          child: Center(
                            child: Icon(item['icon'] as IconData? ?? Icons.inventory_2_rounded, size: 64, color: Colors.white54),
                          ),
                        ),
                      );
                    },
                  ),
                  // Image Dots Indicator
                  Positioned(
                    bottom: 14,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentImageIdx + 1} / ${images.length} Foto • Geser Foto',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Detail Body Konten Lengkap
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label Kategori & Kondisi Riil
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00880C).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item['category'] as String? ?? 'Barang Bekas',
                          style: const TextStyle(color: Color(0xFF00880C), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          item['condition'] as String? ?? 'Kondisi Normal',
                          style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Nama Barang
                  Text(
                    item['name'] as String? ?? 'Produk BaBe',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                  ),

                  const SizedBox(height: 12),

                  // Harga Listing & Tag Nego
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isNegoAccepted ? 'HARGA NEGO DISETUJUI ✓' : 'HARGA PASAR RESMI GAGE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _isNegoAccepted ? const Color(0xFF16A34A) : Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (_isNegoAccepted) ...[
                              Row(
                                children: [
                                  Text(
                                    currencyFormatter.format(listingPrice),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Berlaku 2 Jam',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormatter.format(_negotiatedPrice!),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ] else
                              Text(
                                currencyFormatter.format(listingPrice),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFE52320),
                                ),
                              ),
                            const Text(
                              'Termasuk komisi platform 10%, garansi & ongkir lokal',
                              style: TextStyle(fontSize: 10.5, color: Colors.grey),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isNegoAccepted
                                ? const Color(0xFFDCFCE7)
                                : (isNego ? Colors.orange.shade50 : Colors.blue.shade50),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isNegoAccepted
                                  ? const Color(0xFF86EFAC)
                                  : (isNego ? Colors.orange.shade200 : Colors.blue.shade200),
                            ),
                          ),
                          child: Text(
                            _isNegoAccepted ? 'Deal Disetujui' : (isNego ? 'Bisa Nego' : 'Harga Pas'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isNegoAccepted
                                  ? const Color(0xFF16A34A)
                                  : (isNego ? Colors.deepOrange : Colors.blue.shade800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Proteksi Anti-Side Deal Banner (Mitigasi Kecurangan Transaksi Gelap di Luar BaBe)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Proteksi Transaksi GAGE Escrow',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '• Transaksi sah hanya melalui sistem GAGE & Rekening Escrow resmi.\n'
                                '• Uang Anda 100% aman hingga barang tiba dan dicek di rumah Anda.\n'
                                '• Dilindungi Garansi Toko GAGE 48 Jam (uang kembali jika bermasalah).\n'
                                '⚠️ Perhatian: Transaksi di luar sistem GAGE tidak dilindungi garansi dan melanggar ketentuan akad titip jual.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rincian Spesifikasi & Laporan Fisik
                  const Text(
                    'Spesifikasi & Rincian Fisik Riil',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['qcNote'] as String? ?? 'Kondisi barang sesuai deskripsi dan foto fisik terlampir.',
                          style: const TextStyle(fontSize: 13, height: 1.45, color: Colors.black87),
                        ),

                        if (specs != null && specs.isNotEmpty) ...[
                          const Divider(height: 24),
                          const Text(
                            'Detail Teknis:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          ...specs.entries.map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 110,
                                      child: Text(
                                        entry.key,
                                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                      ),
                                    ),
                                    const Text(': ', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                                    Expanded(
                                      child: Text(
                                        entry.value.toString(),
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],

                        const Divider(height: 24),
                        _buildDetailRow(Icons.security_rounded, 'Garansi Toko GAGE:', item['warranty'] as String? ?? 'Garansi Toko Resmi GAGE 48 Jam'),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.local_shipping_rounded, 'Pengantaran:', item['delivery'] as String? ?? 'Diantar langsung via GAGE Delivery'),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.location_on_rounded, 'Lokasi Unit:', 'Kecamatan Pracimantoro, Wonogiri'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Catatan Tanya Jawab dengan Pemilik via Escrow Proxy (Anti Transaksi Gelap)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.support_agent_rounded, color: Color(0xFF00880C), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Tanya Jawab Seputar Produk',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Punya pertanyaan detail mengenai riwayat kondisi barang kepada pemilik? Hubungi tim Admin CS GAGE BaBe untuk memfasilitasi tanya-jawab secara aman tanpa risiko pembeli & penjual bertransaksi gelap.',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF00880C),
                            side: const BorderSide(color: Color(0xFF00880C)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: const Size(double.infinity, 42),
                          ),
                          icon: const Icon(Icons.chat_outlined, size: 16),
                          label: const Text('Tanya Detail ke Admin CS GAGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            final msg = 'Halo Admin GAGE BaBe Pracimantoro,\n'
                                'Saya ada pertanyaan seputar produk bekas:\n'
                                '📦 *${item['name']}* (ID: ${item['id']})\n'
                                'Mohon bantu konfirmasi ke pemilik barang mengenai kondisi detailnya. Terima kasih!';
                            _openWhatsApp(phone: '6281234567890', message: msg);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 90), // Padding untuk bottom bar
                ],
              ),
            ),
          ),
        ],
      ),

      // 3. Bottom Sticky Bar: Beli / Booking Sekarang
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (isNego && !_isNegoAccepted) ...[
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE52320),
                      side: const BorderSide(color: Color(0xFFE52320)),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.handshake_rounded, size: 18),
                    label: const Text('Ajukan Nego', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () => _showNegoDialog(listingPrice),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isNegoAccepted ? const Color(0xFF16A34A) : GageTheme.accentGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  onPressed: () {
                    final finalPrice = _negotiatedPrice ?? listingPrice;
                    final code = _dealCode ?? 'DEAL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

                    _saveToBabeHistory(
                      type: 'pesanan',
                      status: 'Menunggu Pembayaran Escrow',
                      finalPrice: finalPrice,
                      note: 'Invoice checkout via rekening Escrow Resmi GAGE.',
                    );

                    final msg = 'Halo Admin Resmi GAGE BaBe Pracimantoro,\n\n'
                        'Saya berminat membeli produk resmi:\n'
                        '📦 *Produk:* ${item['name']}\n'
                        '🏷️ *ID:* ${item['id']}\n'
                        '🔖 *Kode Deal:* $code\n'
                        '💰 *Harga Final:* ${currencyFormatter.format(finalPrice)} ${_isNegoAccepted ? '(Hasil Nego Disetujui)' : ''}\n'
                        '🚚 *Pengiriman:* Diantar langsung ke rumah via GAGE Delivery\n'
                        '🛡️ *Metode:* Rekber Escrow Resmi GAGE (Garansi 48 Jam)\n\n'
                        'Mohon proses verifikasi ketersediaan dan invoice aman melalui GAGE Escrow. Terima kasih!';
                    _openWhatsApp(phone: '6281234567890', message: msg);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isNegoAccepted
                            ? 'Beli Harga Nego (${currencyFormatter.format(_negotiatedPrice!)})'
                            : 'Beli Sekarang (${currencyFormatter.format(listingPrice)})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
