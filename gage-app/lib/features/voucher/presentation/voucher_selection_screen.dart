// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/features/home/presentation/widgets/gage_ticket_voucher_card.dart';

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
  bool _isLoading = true;

  static const List<VoucherModel> _deliveryVouchers = [
    VoucherModel(
      code: 'ONGKIRGRATIS',
      title: 'Gratis Ongkir s.d 7RB',
      subtitle: 'Min. belanja Rp 15.000',
      isDeliveryPromo: true,
      discountAmount: 7000,
      minSpend: 15000,
      requiredPaymentMethod: null,
      validUntil: '31 Des 2026',
      badgeText: '',
    ),
    VoucherModel(
      code: 'ONGKIR5RB',
      title: 'Gratis Ongkir s.d 5RB',
      subtitle: 'Min. belanja Rp 25.000',
      isDeliveryPromo: true,
      discountAmount: 5000,
      minSpend: 25000,
      requiredPaymentMethod: null,
      validUntil: '31 Des 2026',
      badgeText: '',
    ),
    VoucherModel(
      code: 'GAGEPAYONGKIR',
      title: 'Gratis Ongkir s.d 10RB',
      subtitle: 'Khusus saldo GAGEPay',
      isDeliveryPromo: true,
      discountAmount: 10000,
      minSpend: 35000,
      requiredPaymentMethod: 'GAGEPAY',
      validUntil: '31 Des 2026',
      badgeText: 'Khusus GAGEPay',
    ),
    VoucherModel(
      code: 'GAGERATIH',
      title: 'Gratis Ongkir s.d 2RB',
      subtitle: 'Tanpa min. belanja',
      isDeliveryPromo: true,
      discountAmount: 2000,
      minSpend: 0,
      requiredPaymentMethod: null,
      validUntil: '31 Des 2026',
      badgeText: '',
    ),
  ];

  static const List<VoucherModel> _foodVouchers = [
    VoucherModel(
      code: 'DISKON50',
      title: 'Diskon 50% s.d 15RB',
      subtitle: 'Maks. potongan Rp 15.000',
      isDeliveryPromo: false,
      discountAmount: 15000,
      discountPercentage: 0.5,
      minSpend: 20000,
      requiredPaymentMethod: null,
      validUntil: '31 Des 2026',
      badgeText: '',
    ),
    VoucherModel(
      code: 'KULINER10',
      title: 'Diskon 10RB',
      subtitle: 'Min. belanja Rp 35.000',
      isDeliveryPromo: false,
      discountAmount: 10000,
      minSpend: 35000,
      requiredPaymentMethod: null,
      validUntil: '31 Des 2026',
      badgeText: '',
    ),
    VoucherModel(
      code: 'HEMATAJI',
      title: 'Diskon 8RB',
      subtitle: 'Min. belanja Rp 25.000',
      isDeliveryPromo: false,
      discountAmount: 8000,
      minSpend: 25000,
      requiredPaymentMethod: null,
      validUntil: '31 Des 2026',
      badgeText: 'PRACIMANTORO',
    ),
    VoucherModel(
      code: 'GAGEPAYFEST',
      title: 'Diskon 15RB',
      subtitle: 'Potongan ekstra Rp 15.000 untuk pesta kuliner via GAGEPay',
      isDeliveryPromo: false,
      discountAmount: 15000,
      minSpend: 50000,
      requiredPaymentMethod: 'GAGEPAY',
      validUntil: '31 Des 2026',
      badgeText: 'Khusus GAGEPay',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _isLoading = false);
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

  void _showTermsBottomSheet(VoucherModel v) {
    HapticFeedback.lightImpact();
    GageFloatingSheet.show(
      context: context,
      title: 'Syarat & Ketentuan Voucher',
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: GageTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  v.code,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  v.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(v.subtitle, style: const TextStyle(fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          const Text('Ketentuan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          Text('• Berlaku sampai dengan ${v.validUntil}', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          if (v.minSpend > 0)
            Text('• Minimal transaksi Rp ${NumberFormat.currency(locale: "id_ID", symbol: "", decimalDigits: 0).format(v.minSpend)}', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          if (v.requiredPaymentMethod != null)
            Text('• Khusus pembayaran menggunakan saldo ${v.requiredPaymentMethod}', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          const SizedBox(height: 16),
        ],
      ),
    );
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: GageTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                tabs: [
                  const Tab(text: 'Semua'),
                  Tab(text: 'Diskon Ongkir${cart.deliveryPromoCode != null ? " (1)" : ""}'),
                  Tab(text: 'Diskon Menu${cart.foodPromoCode != null ? " (1)" : ""}'),
                ],
              ),
            ),
          ),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24)), borderSide: BorderSide(color: GageTheme.primary, width: 1.5)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                // Tab Semua (Section 1: Ongkir, Section 2: Diskon Menu)
                _buildCombinedAllTab(cart),
                // Tab Voucher Ongkir
                _buildVoucherList(_deliveryVouchers, cart, isDeliveryTab: true),
                // Tab Voucher Makanan
                _buildVoucherList(_foodVouchers, cart, isDeliveryTab: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedAllTab(CartProvider cart) {
    return RefreshIndicator(
      onRefresh: _loadVouchers,
      color: GageTheme.primary,
      child: _isLoading
          ? ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: 4,
              itemBuilder: (context, index) => const GageSkeletonVoucherCard(),
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Section 1: Diskon Ongkir
                _buildSectionHeader(
                  title: 'Voucher Gratis & Diskon Ongkir',
                  subtitle: 'Gunakan untuk hemat biaya antar kurir',
                  icon: Icons.local_shipping_rounded,
                  count: _deliveryVouchers.length,
                ),
                const SizedBox(height: 10),
                ..._deliveryVouchers.map((v) => _buildVoucherCard(v, cart, isDeliveryTab: true)),

                const SizedBox(height: 20),

                // Section 2: Diskon Menu
                _buildSectionHeader(
                  title: 'Voucher Diskon Menu Makanan',
                  subtitle: 'Potongan langsung menu pilihan',
                  icon: Icons.local_offer_rounded,
                  count: _foodVouchers.length,
                ),
                const SizedBox(height: 10),
                ..._foodVouchers.map((v) => _buildVoucherCard(v, cart, isDeliveryTab: false)),
              ],
            ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: GageTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: GageTheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(VoucherModel v, CartProvider cart, {required bool isDeliveryTab}) {
    final eligibility = _checkEligibility(v, cart);
    final isApplied = isDeliveryTab
        ? (cart.deliveryPromoCode == v.code)
        : (cart.foodPromoCode == v.code);

    final voucherMap = {
      'id': v.code,
      'code': v.code,
      'service': 'GAGE Food',
      'type': v.isDeliveryPromo ? 'delivery' : 'order',
      'title': v.title,
      'discountText': v.title,
      'minOrder': v.minSpend,
      'quantity': 1,
      'tag': v.badgeText,
      'expiry': v.validUntil,
      'terms': [
        v.subtitle,
        'Berlaku hingga ',
        if (v.minSpend > 0) 'Minimal transaksi Rp ',
        if (v.requiredPaymentMethod != null) 'Khusus pembayaran dengan ',
      ],
    };

    return GageTicketVoucherCard(
      voucher: voucherMap,
      isApplied: isApplied,
      isEligible: eligibility.isEligible,
      ineligibilityReason: eligibility.reason,
      onApply: () {
        if (isApplied) {
          if (isDeliveryTab) {
            cart.removeDeliveryPromo();
          } else {
            cart.removeFoodPromo();
          }
          setState(() {});
        } else if (eligibility.isEligible) {
          _applyVoucher(v, cart);
        }
      },
      onTermsTap: () => _showTermsBottomSheet(v),
    );
  }

  Widget _buildVoucherList(List<VoucherModel> vouchers, CartProvider cart, {required bool isDeliveryTab}) {
    return RefreshIndicator(
      onRefresh: _loadVouchers,
      color: GageTheme.primary,
      child: _isLoading
          ? ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: 4,
              itemBuilder: (context, index) => const GageSkeletonVoucherCard(),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: vouchers.length,
              itemBuilder: (context, index) {
                final v = vouchers[index];
                final eligibility = _checkEligibility(v, cart);
                final isApplied = isDeliveryTab
                    ? (cart.deliveryPromoCode == v.code)
                    : (cart.foodPromoCode == v.code);

                final voucherMap = {
                  'id': v.code,
                  'code': v.code,
                  'service': 'GAGE Food',
                  'type': v.isDeliveryPromo ? 'delivery' : 'order',
                  'title': v.title,
                  'discountText': v.title,
                  'minOrder': v.minSpend,
                  'quantity': 1,
                  'tag': v.badgeText,
                  'expiry': v.validUntil,
                  'terms': [
                    v.subtitle,
                    'Berlaku hingga ${v.validUntil}',
                    if (v.minSpend > 0) 'Minimal transaksi Rp ${v.minSpend}',
                    if (v.requiredPaymentMethod != null) 'Khusus pembayaran dengan ${v.requiredPaymentMethod}',
                  ],
                };

                return GageTicketVoucherCard(
                  voucher: voucherMap,
                  isApplied: isApplied,
                  isEligible: eligibility.isEligible,
                  ineligibilityReason: eligibility.reason,
                  onApply: () {
                    if (isApplied) {
                      if (isDeliveryTab) {
                        cart.removeDeliveryPromo();
                      } else {
                        cart.removeFoodPromo();
                      }
                      setState(() {});
                    } else if (eligibility.isEligible) {
                      _applyVoucher(v, cart);
                    }
                  },
                  onTermsTap: () => _showTermsBottomSheet(v),
                );
              },
            ),
    );
  }
}

class _EligibilityResult {
  final bool isEligible;
  final String reason;

  const _EligibilityResult({required this.isEligible, required this.reason});
}
