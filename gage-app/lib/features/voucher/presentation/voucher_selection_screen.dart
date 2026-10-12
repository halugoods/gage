// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/cart_provider.dart';

class VoucherModel {
  final String code;
  final String title;
  final String subtitle;
  final bool isDeliveryPromo; // true = diskon ongkir, false = diskon menu
  final int discountAmount; // nominal maksimal potongan
  final double? discountPercentage; // misal 0.5 untuk 50%
  final int minSpend; // minimum subtotal
  final String? requiredPaymentMethod; // 'GAGEPAY' atau null
  final String validUntil;
  final String badgeText;

  const VoucherModel({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.isDeliveryPromo,
    required this.discountAmount,
    this.discountPercentage,
    required this.minSpend,
    this.requiredPaymentMethod,
    required this.validUntil,
    required this.badgeText,
  });
}

class VoucherSelectionScreen extends StatefulWidget {
  final int initialTabIndex;
  const VoucherSelectionScreen({super.key, this.initialTabIndex = 0});

  @override
  State<VoucherSelectionScreen> createState() => _VoucherSelectionScreenState();
}

class _VoucherSelectionScreenState extends State<VoucherSelectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _customCodeController = TextEditingController();

  static const List<VoucherModel> _deliveryVouchers = [
    VoucherModel(
      code: 'ONGKIRGRATIS',
      title: 'Subsidi Ongkir GAGE',
      subtitle: 'Diskon biaya kirim pengantaran hingga Rp 7.000',
      isDeliveryPromo: true,
      discountAmount: 7000,
      minSpend: 15000,
      requiredPaymentMethod: null,
      validUntil: '31 Des 2026',
      badgeText: 'FAVORIT KASIR',
    ),
    VoucherModel(
      code: 'ONGKIR5RB',
      title: 'Potongan Ongkir Rp 5.000',
      subtitle: 'Keringanan ongkir untuk pesanan makan siang & sore',
      isDeliveryPromo: true,
      discountAmount: 5000,
      minSpend: 25000,
      requiredPaymentMethod: null,
      validUntil: '31 Des 2026',
      badgeText: 'HEMAT',
    ),
    VoucherModel(
      code: 'GAGEPAYONGKIR',
      title: 'Gratis Ongkir Super GAGEPay',
      subtitle: 'Potongan ongkir s.d. Rp 10.000 khusus saldo GAGEPay',
      isDeliveryPromo: true,
      discountAmount: 10000,
      minSpend: 35000,
      requiredPaymentMethod: 'GAGEPAY',
      validUntil: '31 Des 2026',
      badgeText: 'KHUSUS GAGEPAY',
    ),
    VoucherModel(
      code: 'GAGERATIH',
      title: 'Diskon Ongkir Komunitas Rp 2.000',
      subtitle: 'Tanpa batas minimal belanja, langsung potongan ongkir',
      isDeliveryPromo: true,
      discountAmount: 2000,
      minSpend: 0,
      requiredPaymentMethod: null,
      validUntil: '31 Des 2026',
      badgeText: 'SEMUA USER',
    ),
  ];

  static const List<VoucherModel> _foodVouchers = [
    VoucherModel(
      code: 'DISKON50',
      title: 'Diskon 50% Menu Makanan',
      subtitle: 'Potongan setengah harga menu favorit maks. Rp 15.000',
      isDeliveryPromo: false,
      discountAmount: 15000,
      discountPercentage: 0.5,
      minSpend: 20000,
      requiredPaymentMethod: null,
      validUntil: '31 Des 2026',
      badgeText: 'DISKON 50%',
    ),
    VoucherModel(
      code: 'KULINER10',
      title: 'Potongan Tunai Rp 10.000',
      subtitle: 'Potongan langsung Rp 10.000 untuk makan bersama',
      isDeliveryPromo: false,
      discountAmount: 10000,
      minSpend: 35000,
      requiredPaymentMethod: null,
      validUntil: '31 Des 2026',
      badgeText: 'HEMAT 10RB',
    ),
    VoucherModel(
      code: 'HEMATAJI',
      title: 'Hemat Aji Rp 8.000',
      subtitle: 'Diskon menu makan hemat spesial Pracimantoro',
      isDeliveryPromo: false,
      discountAmount: 8000,
      minSpend: 25000,
      requiredPaymentMethod: null,
      validUntil: '31 Des 2026',
      badgeText: 'PRACIMANTORO',
    ),
    VoucherModel(
      code: 'GAGEPAYFEST',
      title: 'GAGEPay Culinary Festival Rp 15.000',
      subtitle: 'Potongan ekstra Rp 15.000 untuk pesta kuliner via GAGEPay',
      isDeliveryPromo: false,
      discountAmount: 15000,
      minSpend: 50000,
      requiredPaymentMethod: 'GAGEPAY',
      validUntil: '31 Des 2026',
      badgeText: 'KHUSUS GAGEPAY',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customCodeController.dispose();
    super.dispose();
  }

  void _applyCustomCode(CartProvider cart) {
    final code = _customCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    // Cari di delivery vouchers
    final dVoucher = _deliveryVouchers.where((v) => v.code == code).firstOrNull;
    if (dVoucher != null) {
      final eligibility = _checkEligibility(dVoucher, cart);
      if (eligibility.isEligible) {
        _applyVoucher(dVoucher, cart);
        _customCodeController.clear();
        return;
      } else {
        _showErrorSnackBar(eligibility.reason);
        return;
      }
    }

    // Cari di food vouchers
    final fVoucher = _foodVouchers.where((v) => v.code == code).firstOrNull;
    if (fVoucher != null) {
      final eligibility = _checkEligibility(fVoucher, cart);
      if (eligibility.isEligible) {
        _applyVoucher(fVoucher, cart);
        _customCodeController.clear();
        return;
      } else {
        _showErrorSnackBar(eligibility.reason);
        return;
      }
    }

    _showErrorSnackBar('Kode voucher "$code" tidak ditemukan atau sudah habis.');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text(message),
      ),
    );
  }

  _EligibilityResult _checkEligibility(VoucherModel voucher, CartProvider cart) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final List<String> issues = [];

    // 1. Cek minimal belanja
    if (cart.subtotal < voucher.minSpend) {
      final diff = voucher.minSpend - cart.subtotal;
      issues.add('Kurang belanja ${currencyFormatter.format(diff)} lagi untuk pakai voucher ini');
    }

    // 2. Cek metode pembayaran khusus
    if (voucher.requiredPaymentMethod != null && cart.paymentMethod != voucher.requiredPaymentMethod) {
      final reqLabel = voucher.requiredPaymentMethod == 'GAGEPAY' ? 'GAGEPay' : voucher.requiredPaymentMethod!;
      issues.add('Khusus metode pembayaran $reqLabel');
    }

    if (issues.isNotEmpty) {
      return _EligibilityResult(
        isEligible: false,
        reason: issues.join(' • '),
      );
    }

    return const _EligibilityResult(isEligible: true, reason: '');
  }

  void _applyVoucher(VoucherModel voucher, CartProvider cart) {
    if (voucher.isDeliveryPromo) {
      final discount = voucher.discountAmount.clamp(0, cart.rawShippingFee);
      cart.setDeliveryPromo(voucher.code, discount);
    } else {
      int discount = voucher.discountAmount;
      if (voucher.discountPercentage != null) {
        discount = (cart.subtotal * voucher.discountPercentage!).round().clamp(0, voucher.discountAmount);
      }
      cart.setFoodPromo(voucher.code, discount);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: GageTheme.accentGreen,
        content: Text('✓ Voucher ${voucher.code} berhasil dipasang!'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: GageTheme.background,
      appBar: AppBar(
        title: const Text('Pilih Voucher Promo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: GageTheme.primary,
          unselectedLabelColor: GageTheme.textSecondary,
          indicatorColor: GageTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.motorcycle_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Diskon Ongkir ${cart.deliveryPromoCode != null ? "(1)" : ""}'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_offer_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Diskon Menu ${cart.foodPromoCode != null ? "(1)" : ""}'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Input Manual Kode Promo
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customCodeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Punya kode promo? Masukkan di sini...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                      prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 18, color: GageTheme.primary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => _applyCustomCode(cart),
                  child: const Text('Pakai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // List Voucher Ongkir
                _buildVoucherList(_deliveryVouchers, cart, isDeliveryTab: true),
                // List Voucher Makanan
                _buildVoucherList(_foodVouchers, cart, isDeliveryTab: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherList(List<VoucherModel> vouchers, CartProvider cart, {required bool isDeliveryTab}) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: vouchers.length,
      itemBuilder: (context, index) {
        final v = vouchers[index];
        final eligibility = _checkEligibility(v, cart);
        final isApplied = isDeliveryTab ? (cart.deliveryPromoCode == v.code) : (cart.foodPromoCode == v.code);
        final themeColor = isDeliveryTab ? GageTheme.accentGreen : GageTheme.primary;

        return Opacity(
          opacity: eligibility.isEligible ? 1.0 : 0.65,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: eligibility.isEligible ? Colors.white : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isApplied
                    ? themeColor
                    : (eligibility.isEligible ? themeColor.withOpacity(0.35) : Colors.grey.shade300),
                width: isApplied ? 1.8 : 1.0,
              ),
              boxShadow: eligibility.isEligible
                  ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))]
                  : [],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Ikon Tiket
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: eligibility.isEligible ? themeColor.withOpacity(0.12) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDeliveryTab ? Icons.motorcycle_rounded : Icons.local_offer_rounded,
                          color: eligibility.isEligible ? themeColor : Colors.grey.shade500,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Info Judul & Kode
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    v.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: eligibility.isEligible ? const Color(0xFF1E293B) : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: eligibility.isEligible ? themeColor.withOpacity(0.1) : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    v.badgeText,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: eligibility.isEligible ? themeColor : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              v.subtitle,
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Keterangan Syarat & Status
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('Berlaku s.d. ${v.validUntil}', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
                      const Spacer(),
                      Text(
                        v.minSpend > 0 ? 'Min. belanja ${currencyFormatter.format(v.minSpend)}' : 'Tanpa min. belanja',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                    ],
                  ),

                  // Jika tidak eligible, tampilkan bar warning informatif
                  if (!eligibility.isEligible) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: Colors.amber.shade900),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              eligibility.reason,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Tombol Aksi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isApplied) ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () {
                            if (isDeliveryTab) {
                              cart.removeDeliveryPromo();
                            } else {
                              cart.removeFoodPromo();
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Voucher ${v.code} dilepas.')),
                            );
                          },
                          child: const Text('Lepas Voucher', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Dipakai', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ] else ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: eligibility.isEligible ? themeColor : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: eligibility.isEligible ? () => _applyVoucher(v, cart) : null,
                          child: Text(
                            eligibility.isEligible ? 'Gunakan Voucher' : 'Belum Memenuhi Syarat',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EligibilityResult {
  final bool isEligible;
  final String reason;

  const _EligibilityResult({required this.isEligible, required this.reason});
}
