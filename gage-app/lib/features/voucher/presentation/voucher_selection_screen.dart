// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/mock/gage_voucher_data.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/features/home/presentation/widgets/gage_ticket_voucher_card.dart';

/// VoucherSelectionScreen
/// Layar pemilihan voucher promo pada alur pembayaran (Food, Shop, Ride, Car, Send).
/// Menggunakan desain 1:1 dengan Menu Promo (Voucher Saya) dan memfilter voucher sesuai layanan aktif.
class VoucherSelectionScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? serviceType; // 'ride', 'car', 'send', 'food' atau null

  const VoucherSelectionScreen({
    super.key,
    this.initialTabIndex = 0,
    this.serviceType,
  });

  @override
  State<VoucherSelectionScreen> createState() => _VoucherSelectionScreenState();
}

class _VoucherSelectionScreenState extends State<VoucherSelectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeCtrl = TextEditingController();
  int _selectedTabIndex = 0;

  final List<String> _tabs = ['Semua', 'Diskon', 'Gratis Ongkir'];

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, 2);
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _selectedTabIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _selectedTabIndex != _tabController.index) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  /// Filter voucher berdasarkan layanan yang sedang melakukan checkout
  List<Map<String, dynamic>> get _scopedVouchers {
    final st = widget.serviceType?.toLowerCase();
    if (st == 'ride') {
      return GageVoucherData.allVouchers.where((v) => v['service'] == 'GAGE Ride').toList();
    } else if (st == 'car') {
      return GageVoucherData.allVouchers.where((v) => v['service'] == 'GAGE Car').toList();
    } else if (st == 'send') {
      return GageVoucherData.allVouchers.where((v) => v['service'] == 'GAGE Send').toList();
    } else if (st == 'food' || st == 'mart' || st == 'shop' || st == 'farm' || st == 'build') {
      return GageVoucherData.allVouchers.where((v) => v['service'] == 'GAGE Food' || v['service'] == 'GAGE Mart').toList();
    }
    return GageVoucherData.allVouchers;
  }

  List<Map<String, dynamic>> _getVouchersForTab(int tabIndex) {
    final scoped = _scopedVouchers;
    switch (tabIndex) {
      case 1: // Diskon
        return scoped.where((v) => v['type'] != 'delivery').toList();
      case 2: // Gratis Ongkir
        return scoped.where((v) => v['type'] == 'delivery').toList();
      default: // Semua
        return scoped;
    }
  }

  void _onApplyVoucher(Map<String, dynamic> voucher, CartProvider cart) {
    final code = voucher['code'] as String;
    final discount = (voucher['discountAmount'] as num?)?.toInt() ?? 4000;
    final isDelivery = voucher['type'] == 'delivery';

    HapticFeedback.lightImpact();

    // Jika checkout ride / car / send
    final st = widget.serviceType?.toLowerCase();
    if (st == 'ride' || st == 'car' || st == 'send') {
      Navigator.pop(context, {
        'code': code,
        'discount': discount,
        'service': voucher['service'],
        'title': voucher['title'],
      });
      GageToast.show(context, '✓ Voucher $code berhasil dipasang!', type: GageToastType.success);
      return;
    }

    // Default: Food / Mart / Shop
    if (isDelivery) {
      cart.setDeliveryPromo(code, discount);
    } else {
      cart.setFoodPromo(code, discount);
    }

    GageToast.show(context, '✓ Voucher $code berhasil dipasang!', type: GageToastType.success);
    Navigator.pop(context, {
      'code': code,
      'discount': discount,
      'service': voucher['service'],
      'title': voucher['title'],
    });
  }

  void _showClaimPromoSheet(BuildContext context, CartProvider cart) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _codeCtrl.clear();

    GageFloatingSheet.show(
      context: context,
      title: 'Klaim Kode Promo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Masukkan kode promo atau voucher unik GAGE untuk pesanan ini:',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Misal: DISKON50, RIDEHEMAT',
              hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
              ),
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              onPressed: () {
                final code = _codeCtrl.text.trim().toUpperCase();
                if (code.isEmpty) return;
                Navigator.pop(context);

                final match = _scopedVouchers.firstWhere(
                  (v) => (v['code'] as String).toUpperCase() == code,
                  orElse: () => {},
                );

                if (match.isNotEmpty) {
                  _onApplyVoucher(match, cart);
                } else {
                  HapticFeedback.heavyImpact();
                  GageToast.show(
                    context,
                    'Kode voucher "$code" tidak berlaku untuk layanan ini.',
                    type: GageToastType.error,
                  );
                }
              },
              child: const Text('Terapkan Voucher', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showVoucherTerms(BuildContext context, Map<String, dynamic> voucher) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final terms = voucher['terms'] as List<dynamic>? ?? [];

    GageFloatingSheet.show(
      context: context,
      title: 'Syarat & Ketentuan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_rounded, color: GageTheme.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher['code'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                      ),
                      Text(
                        'Berlaku hingga ${voucher['expiry']}',
                        style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Ketentuan Pemakaian:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...terms.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: GageTheme.primary)),
                    Expanded(
                      child: Text(
                        t.toString(),
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700, height: 1.35),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String get _appBarTitle {
    final st = widget.serviceType?.toLowerCase();
    if (st == 'ride') return 'Pilih Voucher GAGE Ride';
    if (st == 'car') return 'Pilih Voucher GAGE Car';
    if (st == 'send') return 'Pilih Voucher GAGE Send';
    return 'Pilih Voucher Promo';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _appBarTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16.5,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Input Kode Promo Bar (1:1 dengan PromoScreen)
          Container(
            color: isDark ? GageTheme.darkSurface : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: InkWell(
              onTap: () => _showClaimPromoSheet(context, cart),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, color: GageTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Masukkan kode promo',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
                  ],
                ),
              ),
            ),
          ),

          // 2. Segmented Tab Switch Khas GAGE (1:1 dengan PromoScreen)
          Container(
            color: isDark ? GageTheme.darkSurface : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: List.generate(_tabs.length, (idx) {
                  final isSel = _selectedTabIndex == idx;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _tabController.animateTo(idx);
                        setState(() => _selectedTabIndex = idx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? GageTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: GageTheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          _tabs[idx],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel
                                ? Colors.white
                                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // 3. TabBarView dengan List Tiket Voucher Sesuai Layanan
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (tabIdx) {
                final list = _getVouchersForTab(tabIdx);

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.confirmation_number_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.35)),
                        const SizedBox(height: 10),
                        Text(
                          'Tidak ada voucher ${widget.serviceType ?? ""} untuk kategori ini.',
                          style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                  itemCount: list.length,
                  itemBuilder: (ctx, idx) {
                    final v = list[idx];
                    final isApplied = cart.deliveryPromoCode == v['code'] || cart.foodPromoCode == v['code'];

                    return GageTicketVoucherCard(
                      voucher: v,
                      isApplied: isApplied,
                      onApply: () => _onApplyVoucher(v, cart),
                      onTermsTap: () => _showVoucherTerms(context, v),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
