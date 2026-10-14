import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// Layar Penuh Detail Produk GAGE BaBe (Bukan Modal Drawer)
/// Dilengkapi Image Carousel Slider, Rincian Kondisi Fisik Riil,
/// Opsi Tawar/Nego Terintegrasi & Penyesuaian Harga Final,
/// Serta Garansi Keamanan Transaksi GAGE.
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

  void _showNegoModal(int basePrice) {
    int currentOffer = _negotiatedPrice ?? 0;
    final ctrl = TextEditingController(
      text: currentOffer > 0 ? currentOffer.toString() : '',
    );
    String? validationError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final itemName = widget.item['name'] as String? ?? 'Barang BaBe';
          final hargaAwalFormatted = NumberFormat('#,###', 'id_ID').format(basePrice);
          final rawDigits = ctrl.text.replaceAll(RegExp(r'[^0-9]'), '');
          final parsedOffer = int.tryParse(rawDigits) ?? 0;
          final diff = basePrice - parsedOffer;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: GageTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.handshake_rounded,
                            color: GageTheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tawar Harga (Nego Online)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                itemName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Harga Listing Saat Ini',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormatter.format(basePrice),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: const Text(
                              'Bisa Nego Wajar',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Nominal Tawaran Anda (Rp):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: validationError != null
                              ? Colors.red.shade400
                              : GageTheme.primary.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: ctrl,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 14, right: 8),
                            child: Align(
                              widthFactor: 1.0,
                              alignment: Alignment.center,
                              child: Text(
                                'Rp',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: GageTheme.primary,
                                ),
                              ),
                            ),
                          ),
                          hintText: 'Ketik nominal rupiah...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          suffixIcon: ctrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    ctrl.clear();
                                    setSheetState(() {
                                      validationError = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          setSheetState(() {
                            validationError = null;
                          });
                        },
                      ),
                    ),
                    if (validationError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        validationError!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ] else if (parsedOffer > 0 && parsedOffer < basePrice) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            Text(
                              'Nominal Hemat: Rp ${NumberFormat('#,###', 'id_ID').format(diff)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 18, color: GageTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Penawaran harga Anda akan langsung dikirimkan ke WhatsApp untuk konfirmasi kesepakatan harga.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 1,
                        ),
                        icon: const Icon(Icons.chat_rounded, size: 20),
                        label: const Text(
                          'Kirim Penawaran ke WhatsApp',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          if (parsedOffer <= 0) {
                            setSheetState(() {
                              validationError = 'Silakan masukkan nominal tawaran Anda.';
                            });
                            return;
                          }
                          if (parsedOffer >= basePrice) {
                            setSheetState(() {
                              validationError = 'Nominal tawaran harus lebih rendah dari harga awal (Rp $hargaAwalFormatted).';
                            });
                            return;
                          }

                          final hargaTawaranFormatted = NumberFormat('#,###', 'id_ID').format(parsedOffer);
                          final message = 'Halo Admin BaBe GAGE, saya ingin menawar barang *${widget.item['name']}* dari harga Rp $hargaAwalFormatted menjadi *Rp $hargaTawaranFormatted*. Mohon konfirmasinya. Terima kasih.';

                          Navigator.pop(sheetCtx);

                          final code = 'NEGO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                          setState(() {
                            _dealCode = code;
                            _negotiatedPrice = parsedOffer;
                            _isNegoAccepted = true;
                          });

                          _saveToBabeHistory(
                            type: 'nego',
                            status: 'Tawaran Dikirim ke WA',
                            finalPrice: parsedOffer,
                            note: 'Menawar barang dari Rp $hargaAwalFormatted menjadi Rp $hargaTawaranFormatted via WhatsApp.',
                          );

                          _openWhatsApp(phone: '6281234567890', message: message);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Penawaran Rp $hargaTawaranFormatted sedang dikirim ke WhatsApp Admin BaBe.'),
                              backgroundColor: GageTheme.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
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
    // Harga listing resmi bersahabat
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
                      'Garansi Keamanan GAGE',
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
                          color: GageTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item['category'] as String? ?? 'Barang Bekas',
                          style: const TextStyle(color: GageTheme.primary, fontWeight: FontWeight.bold, fontSize: 11),
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
                              'Harga resmi bersahabat • Dilindungi garansi toko 48 jam & ongkir lokal',
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

                  // Garansi Keamanan Transaksi GAGE
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
                                'Garansi Keamanan Transaksi GAGE',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Transaksi sah dan aman melalui sistem pembayaran resmi GAGE. Dilindungi Garansi Toko 48 Jam.\n'
                                '• Uang Anda 100% aman hingga barang tiba dan dicek langsung di rumah.\n'
                                '• Garansi toko 48 jam: retur & dana kembali jika kondisi fisik unit tidak sesuai laporan.\n'
                                '⚠️ Perhatian: Transaksi di luar sistem resmi GAGE tidak dilindungi garansi keamanan.',
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

                  // Catatan Tanya Jawab dengan Pemilik via Proxy CS Resmi (Anti Transaksi Gelap)
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
                            Icon(Icons.support_agent_rounded, color: GageTheme.primary, size: 20),
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
                            foregroundColor: GageTheme.primary,
                            side: const BorderSide(color: GageTheme.primary),
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
              if (isNego) ...[
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GageTheme.primary,
                      side: const BorderSide(color: GageTheme.primary),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.handshake_rounded, size: 18),
                    label: Text(
                      _isNegoAccepted ? 'Ubah Nego' : 'Tawar Harga',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => _showNegoModal(listingPrice),
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
                      status: 'Menunggu Pembayaran',
                      finalPrice: finalPrice,
                      note: 'Invoice checkout via sistem pembayaran resmi GAGE.',
                    );

                    final msg = 'Halo Admin Resmi GAGE BaBe Pracimantoro,\n\n'
                        'Saya berminat membeli produk resmi:\n'
                        '📦 *Produk:* ${item['name']}\n'
                        '🏷️ *ID:* ${item['id']}\n'
                        '🔖 *Kode Deal:* $code\n'
                        '💰 *Harga Final:* ${currencyFormatter.format(finalPrice)} ${_isNegoAccepted ? '(Hasil Nego Disetujui)' : ''}\n'
                        '🚚 *Pengiriman:* Diantar langsung ke rumah via GAGE Delivery\n'
                        '🛡️ *Metode:* Garansi Keamanan Transaksi GAGE (Garansi Toko 48 Jam)\n\n'
                        'Mohon proses verifikasi ketersediaan dan invoice aman melalui sistem pembayaran resmi GAGE. Terima kasih!';
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
