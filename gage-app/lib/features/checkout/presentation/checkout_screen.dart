// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/features/order/presentation/order_tracking_screen.dart';
import 'package:gage_app/features/wallet/presentation/topup_qris_dialog.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';
import 'package:gage_app/features/voucher/presentation/voucher_selection_screen.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notePatokanController = TextEditingController();

  final TextEditingController _giftRecipientNameCtrl = TextEditingController();
  final TextEditingController _giftRecipientPhoneCtrl = TextEditingController();
  final TextEditingController _giftMessageCtrl = TextEditingController();

  bool _isPlacingOrder = false;
  bool _sendAsGift = false;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartProvider>();
    _addressController.text = cart.deliveryAddress.isNotEmpty
        ? cart.deliveryAddress
        : 'XR89+JGX, Pracimantoro, Wonogiri';
    _notePatokanController.text = cart.addressNotes.isNotEmpty
        ? cart.addressNotes
        : 'surya tani';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notePatokanController.dispose();
    _giftRecipientNameCtrl.dispose();
    _giftRecipientPhoneCtrl.dispose();
    _giftMessageCtrl.dispose();
    super.dispose();
  }

  void _openLocationPicker() {
    LocationPickerSheet.show(
      context,
      title: 'Pilih Titik Antar',
      onSelected: (title, fullAddress, latLng) {
        setState(() {
          _addressController.text = fullAddress;
        });
        context.read<CartProvider>().setDeliveryAddress(fullAddress, 1.8);
      },
    );
  }

  void _openVoucherSelection({int initialTabIndex = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => VoucherSelectionScreen(initialTabIndex: initialTabIndex),
      ),
    );
  }

  void _showGiftBottomSheet(BuildContext context) async {
    final result = await GageFloatingSheet.showGiftSheet(
      context: context,
      initialName: _giftRecipientNameCtrl.text,
      initialPhone: _giftRecipientPhoneCtrl.text,
      initialMessage: _giftMessageCtrl.text,
    );
    if (result != null) {
      setState(() {
        _giftRecipientNameCtrl.text = result['name'] ?? '';
        _giftRecipientPhoneCtrl.text = result['phone'] ?? '';
        _giftMessageCtrl.text = result['message'] ?? '';
        _sendAsGift = _giftRecipientNameCtrl.text.isNotEmpty ||
            _giftRecipientPhoneCtrl.text.isNotEmpty ||
            _giftMessageCtrl.text.isNotEmpty;
      });
      if (context.mounted) {
        GageToast.show(
          context,
          _sendAsGift ? 'Detail hadiah berhasil disimpan' : 'Opsi hadiah dinonaktifkan',
          type: GageToastType.success,
        );
      }
    }
  }

  void _editAddressNote() async {
    final text = await GageFloatingSheet.showNoteInput(
      context: context,
      title: 'Catatan Patokan Driver',
      subtitle: 'Beri petunjuk lokasi agar driver mudah menemukan alamat',
      initialValue: _notePatokanController.text,
      hintText: 'Contoh: surya tani, depan warung...',
    );
    if (text != null) {
      setState(() {
        _notePatokanController.text = text;
      });
      if (mounted) {
        context.read<CartProvider>().setAddressNotes(text);
        GageToast.show(context, 'Catatan patokan disimpan', type: GageToastType.success);
      }
    }
  }

  void _editItemNote(CartItemModel item) async {
    final text = await GageFloatingSheet.showNoteInput(
      context: context,
      title: 'Catatan untuk ${item.name}',
      subtitle: 'Instruksi khusus memasak atau penyajian menu',
      initialValue: item.notes ?? '',
      hintText: 'Contoh: Pedas sedang, kuah dipisah...',
    );
    if (text != null && mounted) {
      context.read<CartProvider>().setNotes(item.menuId, text);
      GageToast.show(context, 'Catatan menu disimpan', type: GageToastType.success);
    }
  }

  Future<void> _handleCheckout(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (cart.items.isEmpty) {
      GageToast.show(
        context,
        'Keranjang belanja kosong.',
        type: GageToastType.warning,
      );
      return;
    }

    final userId = auth.currentUser?.id ?? 'usr-cust-01';
    final totalPay = cart.grandTotal;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Validasi Saldo GagePay
    if (cart.paymentMethod == 'GAGEPAY') {
      if (wallet.balance < totalPay) {
        GageFloatingSheet.showConfirm(
          context: context,
          title: 'Saldo GagePay Kurang',
          message:
              'Saldo Anda: ${currencyFormatter.format(wallet.balance)} | Total: ${currencyFormatter.format(totalPay)}.\nSilakan top-up terlebih dahulu.',
          confirmLabel: 'Top-Up Sekarang',
          cancelLabel: 'Batal',
        ).then((ok) {
          if (ok == true && context.mounted) {
            TopupQrisDialog.showAsSheet(
              context,
              onTopupSuccess: (_) => wallet.fetchWallet(userId),
            );
          }
        });
        return;
      }
    }

    // Validasi COD
    if (cart.paymentMethod == 'CASH_COD') {
      if (totalPay > 75000) {
        GageToast.show(
          context,
          'Batas maksimal pesanan tunai (COD) adalah Rp 75.000. Silakan bayar via GagePay atau QRIS.',
          type: GageToastType.warning,
        );
        return;
      }
    }

    setState(() => _isPlacingOrder = true);

    final itemsPayload = cart.items.map((i) => {
      'menu_id': i.menuId,
      'name': i.name,
      'price': i.price,
      'quantity': i.quantity,
      'notes': i.notes,
      'image_url': i.imageUrl,
      'merchant_name': i.merchantName,
    }).toList();

    final allMerchantNames = cart.merchantNames.join(', ');
    final effectiveAddress = cart.isPickup
        ? 'Ambil Sendiri di Toko Mitra'
        : (_sendAsGift
            ? '${_addressController.text.trim()} [HADIAH: ${_giftRecipientNameCtrl.text} (${_giftRecipientPhoneCtrl.text}) - "${_giftMessageCtrl.text}"]'
            : _addressController.text.trim());

    final newOrder = await orderProvider.placeOrder(
      userId: userId,
      merchantId: cart.merchantId ?? 'm-dimsum-sewu',
      items: itemsPayload,
      distanceKm: cart.isPickup ? 0.0 : cart.distanceKm,
      paymentMethod: cart.paymentMethod,
      affiliatorId: cart.promoCode == 'GAGERATIH' ? 'usr-aff-01' : null,
      promoCode: cart.promoCode,
      deliveryAddress: effectiveAddress,
      merchantName: allMerchantNames.isNotEmpty ? allMerchantNames : cart.merchantName,
    );

    setState(() => _isPlacingOrder = false);

    if (newOrder != null) {
      if (cart.paymentMethod == 'GAGEPAY') {
        wallet.deductBalance(totalPay);
      }

      // Jika bayar pakai QRIS Dinamis, tampilkan dialog QRIS
      if (cart.paymentMethod == 'QRIS' && newOrder.qrisString != null) {
        if (!context.mounted) return;
        await _showQrisOrderDialog(context, newOrder.qrisString!, newOrder.totalAmount, newOrder.orderNumber);
      }

      cart.clearCart();

      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => OrderTrackingScreen(
            orderId: newOrder.id,
            initialOrder: newOrder,
          ),
        ),
      );
    } else {
      if (!context.mounted) return;
      GageToast.show(
        context,
        'Gagal membuat pesanan. Silakan periksa koneksi.',
        type: GageToastType.error,
      );
    }
  }

  Future<void> _showQrisOrderDialog(BuildContext context, String qrisString, int amount, String orderNumber) async {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    await GageFloatingSheet.show(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pembayaran QRIS GAGE Pay',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Scan QRIS untuk menyelesaikan pesanan #$orderNumber',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: qrisString,
                version: QrVersions.auto,
                size: 190.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              currencyFormatter.format(amount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: GageTheme.primary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Saya Sudah Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethodSheet(BuildContext context, CartProvider cart, WalletProvider wallet) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final methods = [
      {
        'id': 'GAGEPAY',
        'title': 'GAGEPay Saldo',
        'sub': 'Saldo Anda: ${currencyFormatter.format(wallet.balance)} • 0% Fee',
        'icon': Icons.account_balance_wallet_rounded,
        'iconColor': const Color(0xFF0284C7),
      },
      {
        'id': 'QRIS',
        'title': 'QRIS Dinamis GAGE Pay',
        'sub': 'Bebas biaya admin • ShopeePay, GoPay, Dana, BCA, Mandiri',
        'icon': Icons.qr_code_2_rounded,
        'iconColor': GageTheme.primary,
      },
      {
        'id': 'CASH_COD',
        'title': 'Tunai ke Driver (COD)',
        'sub': 'Bayar langsung saat pesanan tiba di tujuan (Maks. Rp 75rb)',
        'icon': Icons.payments_rounded,
        'iconColor': const Color(0xFF16A34A),
      },
    ];

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pilih Metode Pembayaran',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(ctx),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...methods.map((m) {
              final isSelected = cart.paymentMethod == m['id'];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFF1F0))
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? GageTheme.primary : (isDark ? Colors.white12 : Colors.grey.shade300),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    cart.setPaymentMethod(m['id'] as String);
                    Navigator.pop(ctx);
                  },
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GageTheme.primary.withValues(alpha: 0.12)
                          : (isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(m['icon'] as IconData, color: m['iconColor'] as Color, size: 20),
                  ),
                  title: Text(
                    m['title'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    m['sub'] as String,
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                  trailing: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? GageTheme.primary : Colors.grey,
                    size: 20,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProductThumbnail(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return Container(
        color: GageTheme.primaryLight,
        child: const Center(
          child: Icon(Icons.restaurant_rounded, color: GageTheme.primary, size: 24),
        ),
      );
    }
    final clean = imageUrl.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Image.network(
        clean,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          color: GageTheme.primaryLight,
          child: const Center(
            child: Icon(Icons.restaurant_rounded, color: GageTheme.primary, size: 24),
          ),
        ),
      );
    }
    return Image.asset(
      clean,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Container(
        color: GageTheme.primaryLight,
        child: const Center(
          child: Icon(Icons.restaurant_rounded, color: GageTheme.primary, size: 24),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final wallet = context.watch<WalletProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? GageTheme.darkSurface : Colors.white;
    final cardShadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];

    final isPickup = cart.isPickup;
    final totalPay = cart.grandTotal;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          cart.merchantName ?? 'Mie Ayam Mbak Linda, Maguhan',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        elevation: 0.5,
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('Keranjang belanja kosong'))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width >= 600 ? 600 : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // =========================================================
                            // 1. DELIVERY CARD (Persis Gambar 3 Gojek)
                            // =========================================================
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: cardShadow,
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/gage_ride_3d.png',
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) => Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFDCFCE7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF16A34A), size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isPickup ? 'Pickup' : 'Delivery',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const Spacer(),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: GageTheme.primary,
                                      side: const BorderSide(color: GageTheme.primary, width: 1.2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () {
                                      cart.setIsPickup(!isPickup);
                                      GageToast.show(
                                        context,
                                        cart.isPickup ? 'Beralih ke Pickup (Ambil Sendiri)' : 'Beralih ke Delivery (Diantar Driver)',
                                        type: GageToastType.info,
                                      );
                                    },
                                    child: Text(isPickup ? 'Ubah Delivery' : 'Ubah Pickup', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                  ),
                                ],
                              ),
                            ),

                            // =========================================================
                            // 2. SCHEDULED BADGE & SPEED OPTION CARD (Reguler vs Hemat)
                            // =========================================================
                            if (cart.scheduledDeliveryTime != null)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.schedule_rounded, color: Color(0xFF2563EB), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pengantaran Terjadwal',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${DateFormat('EEEE, d MMM yyyy • HH:mm', 'id_ID').format(cart.scheduledDeliveryTime!)} WIB',
                                            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.blue.shade300 : const Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => cart.setScheduledDeliveryTime(null),
                                      child: const Text('Batal', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),

                            if (!isPickup) ...[
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: cardShadow,
                                ),
                                child: Column(
                                  children: [
                                    // Reguler
                                    InkWell(
                                      onTap: () => cart.setDeliveryOption('REGULER'),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Text('Reguler', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                                                  child: const Text('25-35 min', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  currencyFormatter.format(cart.rawShippingFee),
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  cart.deliveryOption == 'REGULER' ? Icons.radio_button_checked : Icons.radio_button_off,
                                                  color: cart.deliveryOption == 'REGULER' ? GageTheme.primary : Colors.grey,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            const Text('Langsung ke kamu, pasti tepat waktu', style: TextStyle(fontSize: 11.5, color: Color(0xFF16A34A))),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 16),
                                    // Hemat
                                    InkWell(
                                      onTap: () => cart.setDeliveryOption('HEMAT'),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Text('Hemat', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                                                  child: const Text('45-55 min', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  currencyFormatter.format((cart.rawShippingFee - 3000).clamp(5000, 999999)),
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  cart.deliveryOption == 'HEMAT' ? Icons.radio_button_checked : Icons.radio_button_off,
                                                  color: cart.deliveryOption == 'HEMAT' ? GageTheme.primary : Colors.grey,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            const Text('Rute pengantaran gabungan, ongkir lebih hemat', style: TextStyle(fontSize: 11.5, color: Color(0xFFEA580C))),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // =========================================================
                            // 3. ADDRESS CARD (Pickup vs Delivery)
                            // =========================================================
                            if (isPickup)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: cardShadow,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Ambil Sendiri di Toko Mitra',
                                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            cart.merchantName ?? 'Resto Mitra GAGE',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Komplek Pasar Pracimantoro Lor, Kec. Pracimantoro, Kab. Wonogiri',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: cardShadow,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on_rounded, color: Color(0xFFF97316), size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Rumah', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                                          const SizedBox(height: 2),
                                          Text(
                                            _addressController.text.isNotEmpty ? _addressController.text : 'XR89+JGX',
                                            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          // Note pill with pencil
                                          InkWell(
                                            onTap: _editAddressNote,
                                            borderRadius: BorderRadius.circular(14),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      _notePatokanController.text.isNotEmpty ? _notePatokanController.text : 'surya tani',
                                                      style: const TextStyle(fontSize: 11.5, color: Colors.black87, fontWeight: FontWeight.w500),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  const Icon(Icons.edit_outlined, size: 13, color: Colors.black54),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: GageTheme.primary,
                                        side: const BorderSide(color: GageTheme.primary, width: 1.2),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: _openLocationPicker,
                                      child: const Text('Ganti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                    ),
                                  ],
                                ),
                              ),

                            // =========================================================
                            // 4. ORDERED ITEMS + "Ada lagi yang mau dibeli?" (Gambar 3 & 2)
                            // =========================================================
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: cardShadow,
                              ),
                              child: Column(
                                children: [
                                  ...cart.items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.black87)),
                                              const SizedBox(height: 4),
                                              Text(currencyFormatter.format(item.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87)),
                                              const SizedBox(height: 8),
                                              InkWell(
                                                onTap: () => _editItemNote(item),
                                                borderRadius: BorderRadius.circular(16),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(color: Colors.grey.shade300),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.edit_note_rounded, size: 14, color: Colors.black54),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        item.notes != null && item.notes!.isNotEmpty ? item.notes! : 'Catatan',
                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: SizedBox(
                                                width: 70,
                                                height: 70,
                                                child: _buildProductThumbnail(item.imageUrl),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              height: 32,
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: GageTheme.primary, width: 1.5),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  InkWell(
                                                    onTap: () => cart.updateQuantity(item.menuId, -1),
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                      child: Icon(Icons.remove, color: GageTheme.primary, size: 16),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                                    child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                                  ),
                                                  InkWell(
                                                    onTap: () => cart.updateQuantity(item.menuId, 1),
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                      child: Icon(Icons.add, color: GageTheme.primary, size: 16),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Ada lagi yang mau dibeli?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                                          SizedBox(height: 2),
                                          Text('Masih bisa nambah menu lain, ya.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                        ],
                                      ),
                                      const Spacer(),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: GageTheme.primary,
                                          side: const BorderSide(color: GageTheme.primary, width: 1.2),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: () {
                                          if (Navigator.canPop(context)) {
                                            Navigator.pop(context);
                                          } else {
                                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (ctx) => const FoodExploreScreen()));
                                          }
                                        },
                                        child: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // =========================================================
                            // 5. RINGKASAN PEMBAYARAN (Detail Terperinci)
                            // =========================================================
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 20, bottom: 10),
                                  child: Text('Ringkasan pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: cardShadow,
                                  ),
                                  child: Column(
                                    children: [
                                      // Subtotal Makanan
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Subtotal Pesanan', style: TextStyle(fontSize: 13.5, color: Colors.black87)),
                                          Text(currencyFormatter.format(cart.subtotal), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87)),
                                        ],
                                      ),
                                      // Diskon Makanan (jika ada)
                                      if (cart.totalFoodDiscount > 0) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Diskon Makanan (${cart.foodPromoCode ?? "Promo"})',
                                              style: const TextStyle(fontSize: 13.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              '- ${currencyFormatter.format(cart.totalFoodDiscount)}',
                                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      // Biaya Ongkir
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            isPickup ? 'Biaya Pengiriman (Pickup)' : 'Ongkos Kirim (${cart.deliveryOption})',
                                            style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                                          ),
                                          Text(
                                            isPickup ? 'Gratis (Rp 0)' : currencyFormatter.format(cart.rawShippingFee),
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: isPickup ? const Color(0xFF16A34A) : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Diskon Ongkir (jika ada)
                                      if (!isPickup && cart.totalShippingDiscount > 0) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Diskon Ongkir (${cart.deliveryPromoCode ?? "Promo"})',
                                              style: const TextStyle(fontSize: 13.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              '- ${currencyFormatter.format(cart.totalShippingDiscount)}',
                                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      // Biaya Layanan & Penanganan
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Biaya Layanan & Penanganan', style: TextStyle(fontSize: 13.5, color: Colors.black87)),
                                          Text(
                                            currencyFormatter.format(cart.adminFee),
                                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      // Total Pembayaran
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Total pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.black87)),
                                          Text(
                                            currencyFormatter.format(totalPay),
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5, color: GageTheme.primary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // =========================================================
                            // 6. VOUCHER & DISKON CARD (Dukungan Multi-Voucher Terpasang)
                            // =========================================================
                            Builder(
                              builder: (ctx) {
                                final hasFoodPromo = cart.foodPromoCode != null;
                                final hasDeliveryPromo = cart.deliveryPromoCode != null;
                                final hasAnyPromo = hasFoodPromo || hasDeliveryPromo;

                                return Container(
                                  margin: const EdgeInsets.only(top: 14),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: cardShadow,
                                  ),
                                  child: Column(
                                    children: [
                                      // 1. Voucher Diskon Makanan Terpasang
                                      if (hasFoodPromo)
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF16A34A),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Voucher Makanan: ${cart.foodPromoCode}',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                                    ),
                                                    Text(
                                                      'Hemat ${currencyFormatter.format(cart.totalFoodDiscount)}',
                                                      style: const TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  OutlinedButton(
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: const Color(0xFF16A34A),
                                                      side: const BorderSide(color: Color(0xFF16A34A), width: 1.2),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      visualDensity: VisualDensity.compact,
                                                    ),
                                                    onPressed: () => _openVoucherSelection(initialTabIndex: 0),
                                                    child: const Text('Ganti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  InkWell(
                                                    onTap: () {
                                                      cart.removeFoodPromo();
                                                      GageToast.show(context, 'Voucher makanan dilepas', type: GageToastType.info);
                                                    },
                                                    child: const Padding(
                                                      padding: EdgeInsets.all(4),
                                                      child: Icon(Icons.close_rounded, size: 18, color: Colors.black54),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                      if (hasFoodPromo && hasDeliveryPromo)
                                        const Divider(height: 1, color: Colors.black12),

                                      // 2. Voucher Diskon Ongkir Terpasang
                                      if (hasDeliveryPromo)
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.vertical(
                                              top: !hasFoodPromo ? const Radius.circular(16) : Radius.zero,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF2563EB),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 14),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Voucher Ongkir: ${cart.deliveryPromoCode}',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                                    ),
                                                    Text(
                                                      'Hemat ${currencyFormatter.format(cart.totalShippingDiscount)}',
                                                      style: const TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  OutlinedButton(
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: const Color(0xFF2563EB),
                                                      side: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      visualDensity: VisualDensity.compact,
                                                    ),
                                                    onPressed: () => _openVoucherSelection(initialTabIndex: 1),
                                                    child: const Text('Ganti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  InkWell(
                                                    onTap: () {
                                                      cart.removeDeliveryPromo();
                                                      GageToast.show(context, 'Voucher ongkir dilepas', type: GageToastType.info);
                                                    },
                                                    child: const Padding(
                                                      padding: EdgeInsets.all(4),
                                                      child: Icon(Icons.close_rounded, size: 18, color: Colors.black54),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                      // 3. Rekomendasi Diskon jika belum ada yang dipakai
                                      if (!hasAnyPromo) ...[
                                        Builder(
                                          builder: (c) {
                                            String bannerTitle;
                                            String bannerSubtitle;
                                            String buttonLabel;
                                            VoidCallback buttonAction;

                                            if (cart.subtotal >= 30000) {
                                              bannerTitle = 'Diskon Makanan Rp 10.000 Tersedia!';
                                              bannerSubtitle = 'Min. belanja Rp 30.000 terpenuhi';
                                              buttonLabel = 'Pakai';
                                              buttonAction = () {
                                                cart.setFoodPromo('KULINER10', 10000);
                                                GageToast.show(context, 'Voucher KULINER10 berhasil dipasang!', type: GageToastType.success);
                                              };
                                            } else if (cart.subtotal >= 15000) {
                                              bannerTitle = 'Diskon Makanan Rp 8.000 Tersedia!';
                                              bannerSubtitle = 'Min. belanja Rp 15.000 terpenuhi';
                                              buttonLabel = 'Pakai';
                                              buttonAction = () {
                                                cart.setFoodPromo('HEMATAJI', 8000);
                                                GageToast.show(context, 'Voucher HEMATAJI berhasil dipasang!', type: GageToastType.success);
                                              };
                                            } else {
                                              final needed = 15000 - cart.subtotal;
                                              bannerTitle = 'Tambah Rp ${NumberFormat("#,###", "id_ID").format(needed)} lagi untuk diskon';
                                              bannerSubtitle = 'Gunakan voucher hemat makanan GAGE';
                                              buttonLabel = 'Cek';
                                              buttonAction = () => _openVoucherSelection(initialTabIndex: 0);
                                            }

                                            return Container(
                                              padding: const EdgeInsets.all(14),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFFF1F2),
                                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: const BoxDecoration(
                                                      color: GageTheme.primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.percent_rounded, color: Colors.white, size: 14),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(bannerTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                                        const SizedBox(height: 2),
                                                        Text(bannerSubtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                                      ],
                                                    ),
                                                  ),
                                                  OutlinedButton(
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: GageTheme.primary,
                                                      side: const BorderSide(color: GageTheme.primary, width: 1.2),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                                      visualDensity: VisualDensity.compact,
                                                    ),
                                                    onPressed: buttonAction,
                                                    child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],

                                      // Footer link ke semua promo
                                      InkWell(
                                        onTap: () => _openVoucherSelection(initialTabIndex: 0),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              Text('Cek diskon lainnya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GageTheme.primary)),
                                              Spacer(),
                                              Icon(Icons.arrow_forward_rounded, color: GageTheme.primary, size: 18),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // =========================================================
                            // 7. OPSI TAMBAHAN (Kirim Sebagai Hadiah)
                            // =========================================================
                            Container(
                              margin: const EdgeInsets.only(top: 14),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: cardShadow,
                              ),
                              child: InkWell(
                                onTap: () => _showGiftBottomSheet(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _sendAsGift ? const Color(0xFFDCFCE7) : const Color(0xFFFFF1F2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.card_giftcard_rounded,
                                        color: _sendAsGift ? const Color(0xFF16A34A) : GageTheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Kirim sebagai hadiah',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _sendAsGift
                                                ? 'Penerima: ${_giftRecipientNameCtrl.text.isNotEmpty ? _giftRecipientNameCtrl.text : "Tersimpan"} • Pesan tersimpan'
                                                : 'Kirimkan makanan kejutan dengan kartu ucapan virtual.',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: _sendAsGift ? const Color(0xFF16A34A) : Colors.black54,
                                              fontWeight: _sendAsGift ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _sendAsGift ? const Color(0xFF16A34A) : GageTheme.primary,
                                        side: BorderSide(color: _sendAsGift ? const Color(0xFF16A34A) : GageTheme.primary, width: 1.2),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () => _showGiftBottomSheet(context),
                                      child: Text(_sendAsGift ? 'Ubah' : 'Atur', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // =============================================================
                // 8. STICKY BOTTOM BAR (Single Metode Pembayaran Murni)
                // =============================================================
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -3)),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Single Pure Payment Selector Row
                          InkWell(
                            onTap: () => _showPaymentMethodSheet(context, cart, wallet),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  // Payment Icon
                                  Icon(
                                    cart.paymentMethod == 'GAGEPAY'
                                        ? Icons.account_balance_wallet_rounded
                                        : (cart.paymentMethod == 'QRIS'
                                            ? Icons.qr_code_2_rounded
                                            : Icons.payments_rounded),
                                    color: cart.paymentMethod == 'GAGEPAY'
                                        ? const Color(0xFF0284C7)
                                        : (cart.paymentMethod == 'QRIS'
                                            ? GageTheme.primary
                                            : const Color(0xFF16A34A)),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  // Payment Name & Balance
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cart.paymentMethod == 'GAGEPAY'
                                              ? 'GAGEPay Saldo'
                                              : (cart.paymentMethod == 'QRIS'
                                                  ? 'QRIS Dinamis'
                                                  : 'Tunai ke Driver (COD)'),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                        ),
                                        Text(
                                          cart.paymentMethod == 'GAGEPAY'
                                              ? 'Saldo: ${currencyFormatter.format(wallet.balance)}'
                                              : (cart.paymentMethod == 'QRIS'
                                                  ? 'ShopeePay, GoPay, BCA, Mandiri'
                                                  : 'Bayar saat pesanan tiba'),
                                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Ganti link
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Ganti',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.black45),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Tombol Pesan Utama
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GageTheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              onPressed: _isPlacingOrder ? null : () => _handleCheckout(context),
                              child: _isPlacingOrder
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          isPickup ? 'Pesan & Ambil Sendiri' : 'Pesan dan Antar Sekarang',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '• ${currencyFormatter.format(totalPay)}',
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
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
    );
  }
}
