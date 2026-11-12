import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/order_model.dart';
import 'package:gage_app/features/home/presentation/home_screen.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Layar Fullscreen Selebrasi Pesanan Selesai & Invoice Berhasil
/// Otomatis terbuka saat status pesanan di pengantaran selesai (driver menyelesaikan pengantaran & upload PoD).
class OrderSuccessReviewScreen extends StatefulWidget {
  final OrderModel order;
  final String? proofImageUrl;
  final String driverName;
  final String driverVehicle;

  const OrderSuccessReviewScreen({
    super.key,
    required this.order,
    this.proofImageUrl,
    this.driverName = '',
    this.driverVehicle = '',
  });

  @override
  State<OrderSuccessReviewScreen> createState() => _OrderSuccessReviewScreenState();
}

class _OrderSuccessReviewScreenState extends State<OrderSuccessReviewScreen> {
  int _merchantStars = 5;
  int _driverStars = 5;
  final Set<String> _selectedMerchantChips = {};
  final Set<String> _selectedDriverChips = {};
  final TextEditingController _commentCtrl = TextEditingController();
  bool _isSubmitted = false;

  final List<String> _merchantChipOptions = [
    'Rasa Lezat 🍲',
    'Porsi Pas 👍',
    'Packing Rapi 📦',
    'Harga Bersahabat 💰',
    'Sesuai Pesanan ✔️',
  ];

  final List<String> _driverChipOptions = [
    'Tepat Waktu ⚡',
    'Sopan & Ramah 😊',
    'Pengantaran Aman 🛵',
    'Hati-hati Berkendara 🛡️',
  ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Widget _buildStarRow(int currentStars, ValueChanged<int> onStarTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= currentStars;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onStarTap(starIndex);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 32,
              color: isFilled ? const Color(0xFFF59E0B) : Colors.grey.shade400,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      },
      child: Scaffold(
        backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
          title: const Text('Pesanan Selesai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            children: [
              // 1. Kartu Selebrasi Sukses
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF064E3B), const Color(0xFF022C22)]
                        : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x3310B981), blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pengantaran Telah Tiba!',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: isDark ? Colors.white : const Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pesanan #${widget.order.orderNumber} telah diterima dengan baik.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Foto Bukti Pengantaran (Proof of Delivery)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? GageTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.camera_alt_outlined, color: GageTheme.primary, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Bukti Pengiriman Driver (PoD)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        child: widget.proofImageUrl != null && widget.proofImageUrl!.isNotEmpty
                            ? Image.network(widget.proofImageUrl!, fit: BoxFit.cover)
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/resto_dimsum_sewu.png',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (c, e, s) => const SizedBox(),
                                  ),
                                  Container(
                                    color: Colors.black45,
                                    padding: const EdgeInsets.all(8),
                                    child: const Text(
                                      '✓ Barang Diterima di Depan Pintu',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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

              // 3. Ringkasan Invoice Pesanan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? GageTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.order.merchantName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          currencyFormatter.format(widget.order.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Divider(height: 1, color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                    const SizedBox(height: 8),
                    ...widget.order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.quantity}x ${item.name}', style: const TextStyle(fontSize: 12)),
                              Text(currencyFormatter.format(item.price * item.quantity), style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Metode Pembayaran', style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.grey.shade600)),
                        Text(widget.order.paymentMethod, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Formulir Rating Terpadu Toko & Driver
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? GageTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Beri Penilaian Pengalaman Anda',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bantu ${widget.order.merchantName} dan ${widget.driverName} meningkatkan pelayanan.',
                      style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    ),
                    const SizedBox(height: 14),

                    // Rating Resto
                    Text('1. Mitra Toko: ${widget.order.merchantName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    _buildStarRow(_merchantStars, (val) => setState(() => _merchantStars = val)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _merchantChipOptions.map((c) {
                        final isSel = _selectedMerchantChips.contains(c);
                        return FilterChip(
                          shape: const StadiumBorder(),
                          label: Text(c, style: TextStyle(fontSize: 10.5, color: isSel ? GageTheme.primary : (isDark ? Colors.white70 : Colors.black87))),
                          selected: isSel,
                          selectedColor: GageTheme.primaryLight,
                          onSelected: (val) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (val) {
                                _selectedMerchantChips.add(c);
                              } else {
                                _selectedMerchantChips.remove(c);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    if (widget.driverName.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Divider(height: 1, color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                      const SizedBox(height: 14),

                      // Rating Driver
                      Text('2. Mitra Driver: ${widget.driverName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const SizedBox(height: 6),
                      _buildStarRow(_driverStars, (val) => setState(() => _driverStars = val)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _driverChipOptions.map((c) {
                          final isSel = _selectedDriverChips.contains(c);
                          return FilterChip(
                            shape: const StadiumBorder(),
                            label: Text(c, style: TextStyle(fontSize: 10.5, color: isSel ? const Color(0xFF2563EB) : (isDark ? Colors.white70 : Colors.black87))),
                            selected: isSel,
                            selectedColor: const Color(0xFFDBEAFE),
                            onSelected: (val) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (val) {
                                  _selectedDriverChips.add(c);
                                } else {
                                  _selectedDriverChips.remove(c);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentCtrl,
                      decoration: InputDecoration(
                        hintText: 'Tulis komentar atau ulasan tambahan...',
                        hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tombol Simpan & Selesai
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    final typedComment = _commentCtrl.text.trim();
                    final chipsText = _selectedMerchantChips.join(', ');
                    final finalComment = [
                      if (typedComment.isNotEmpty) typedComment,
                      if (chipsText.isNotEmpty) chipsText,
                    ].join(' - ');
                    MerchantStorefrontService.submitBuyerReview(
                      merchantId: widget.order.merchantId,
                      merchantName: widget.order.merchantName,
                      domain: widget.order.channel,
                      stars: _merchantStars,
                      comment: finalComment,
                      orderedItems: widget.order.items.map((e) => e.name).toList(),
                      userName: widget.order.customerName ?? 'Pelanggan GAGE',
                    );
                    setState(() => _isSubmitted = true);
                    GageToast.show(
                      context,
                      'Penilaian berhasil dikirim! Terima kasih telah menggunakan GAGE.',
                      type: GageToastType.success,
                    );
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    _isSubmitted ? 'Terkirim ✓' : 'Kirim Penilaian & Selesai',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
