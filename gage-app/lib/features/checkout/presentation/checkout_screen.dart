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
import 'package:gage_app/features/auth/presentation/terms_and_privacy_screen.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';
import 'package:gage_app/features/voucher/presentation/voucher_selection_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notePatokanController = TextEditingController();
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartProvider>();
    _addressController.text = cart.deliveryAddress.isNotEmpty
        ? cart.deliveryAddress
        : 'Kecamatan Pracimantoro, Wonogiri (Titik Antar Utama)';

    // Auto-pasang Voucher Diskon Ongkir & Diskon Menu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = context.read<CartProvider>();
      if (c.deliveryPromoCode == null) {
        c.setDeliveryPromo('ONGKIRGRATIS', c.rawShippingFee);
      }
      if (c.subtotal >= 20000 && c.foodPromoCode == null) {
        c.setFoodPromo('DISKON50', (c.subtotal * 0.5).round().clamp(0, 15000));
      }
      if (c.promoCode != null) {
        _promoController.text = c.promoCode!;
      } else if (c.deliveryPromoCode != null) {
        _promoController.text = c.deliveryPromoCode!;
      }
    });
  }

  void _openLocationPicker() {
    LocationPickerSheet.show(
      context,
      title: 'Pilih Titik Pengantaran',
      onSelected: (title, fullAddress, latLng) {
        final addr = '$title - $fullAddress';
        setState(() {
          _addressController.text = addr;
        });
        final cart = context.read<CartProvider>();
        cart.setDeliveryAddress(addr, cart.distanceKm);
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
  void dispose() {
    _promoController.dispose();
    _addressController.dispose();
    _notePatokanController.dispose();
    super.dispose();
  }

  void _applyPromo(BuildContext context) {
    final code = _promoController.text.trim().toUpperCase();
    final cart = context.read<CartProvider>();
    if (code == 'DISKON50') {
      cart.setFoodPromo(code, (cart.subtotal * 0.5).round().clamp(0, 15000));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: GageTheme.accentGreen,
          content: Text('Voucher DISKON50 aktif! Diskon makanan 50%.'),
        ),
      );
    } else if (code == 'HEMATAJI') {
      cart.setFoodPromo(code, 8000);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: GageTheme.accentGreen,
          content: Text('Voucher HEMATAJI aktif! Hemat makanan Rp 8.000.'),
        ),
      );
    } else if (code == 'KULINER10') {
      cart.setFoodPromo(code, 10000);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: GageTheme.accentGreen,
          content: Text('Voucher KULINER10 aktif! Hemat makanan Rp 10.000.'),
        ),
      );
    } else if (code == 'ONGKIRGRATIS') {
      cart.setDeliveryPromo(code, cart.rawShippingFee);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: GageTheme.accentGreen,
          content: Text('Voucher ONGKIRGRATIS aktif! Subsidi ongkir 100%.'),
        ),
      );
    } else if (code == 'ONGKIR5RB') {
      cart.setDeliveryPromo(code, 5000);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: GageTheme.accentGreen,
          content: Text('Voucher ONGKIR5RB aktif! Subsidi ongkir Rp 5.000.'),
        ),
      );
    } else if (code == 'GAGERATIH') {
      cart.setDeliveryPromo(code, 2000);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: GageTheme.accentGreen,
          content: Text('Voucher GAGERATIH aktif! Hemat ongkir Rp 2.000.'),
        ),
      );
    } else if (code.isEmpty) {
      cart.removeFoodPromo();
      cart.removeDeliveryPromo();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode voucher tidak ditemukan atau sudah kadaluarsa.'),
        ),
      );
    }
  }

  Future<void> _handleCheckout(BuildContext context) async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang belanja kosong.')),
      );
      return;
    }

    final userId = auth.currentUser?.id ?? 'usr-cust-01';

    // Validasi Saldo GagePay
    if (cart.paymentMethod == 'GAGEPAY') {
      if (wallet.balance < cart.grandTotal) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Saldo GagePay Kurang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Text(
              'Saldo Anda: Rp ${wallet.balance.toLocaleString()} | Total: Rp ${cart.grandTotal.toLocaleString()}.\nSilakan top-up terlebih dahulu.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: GageTheme.primary, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (c) => TopupQrisDialog(
                      onTopupSuccess: (_) => wallet.fetchWallet(userId),
                    ),
                  );
                },
                child: const Text('Top-Up Sekarang'),
              ),
            ],
          ),
        );
        return;
      }
    }

    // Validasi Anti-Fraud COD
    if (cart.paymentMethod == 'CASH_COD') {
      if (cart.grandTotal > 75000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: GageTheme.primary,
            content: Text('Batas maksimal pesanan tunai (COD) adalah Rp 75.000. Silakan bayar via GagePay atau QRIS.'),
          ),
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
    }).toList();

    final newOrder = await orderProvider.placeOrder(
      userId: userId,
      merchantId: cart.merchantId ?? 'm-dimsum-sewu',
      items: itemsPayload,
      distanceKm: cart.distanceKm,
      paymentMethod: cart.paymentMethod,
      affiliatorId: cart.promoCode == 'GAGERATIH' ? 'usr-aff-01' : null,
      promoCode: cart.promoCode,
      deliveryAddress: _addressController.text.trim(),
    );

    setState(() => _isPlacingOrder = false);

    if (newOrder != null) {
      if (cart.paymentMethod == 'GAGEPAY') {
        wallet.deductBalance(cart.grandTotal);
      }

      // Jika bayar pakai QRIS Dinamis, tampilkan dialog QRIS
      if (cart.paymentMethod == 'QRIS' && newOrder.qrisString != null) {
        if (!context.mounted) return;
        await _showQrisOrderDialog(context, newOrder.qrisString!, newOrder.totalAmount, newOrder.orderNumber);
      }

      // Bersihkan keranjang
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat pesanan. Silakan periksa koneksi.')),
      );
    }
  }

  Future<void> _showQrisOrderDialog(BuildContext context, String qrisString, int amount, String orderNumber) async {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Text('Scan QRIS Dinamis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(orderNumber, style: const TextStyle(fontSize: 12, color: GageTheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: GageTheme.primary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bisa di-scan menggunakan BCA, Mandiri, BRI, ShopeePay, GoPay, DANA, OVO.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: GageTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GageTheme.accentGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Saya Sudah Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final wallet = context.watch<WalletProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: GageTheme.background,
      appBar: AppBar(
        title: const Text('Konfirmasi Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('Keranjang belanja kosong'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width >= 600 ? 600 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Titik Antar Tujuan Universal (Konsisten dengan GAGE Send, Food & Tani)
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: GageTheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Titik Antar Tujuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () => _openLocationPicker(),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.map_rounded, size: 14, color: GageTheme.primary),
                                          SizedBox(width: 4),
                                          Text('Pilih Peta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Display Titik Terpilih (Tap untuk ubah via peta/pencarian)
                              InkWell(
                                onTap: () => _openLocationPicker(),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.home_filled, size: 18, color: GageTheme.primary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _addressController.text.isNotEmpty
                                                  ? _addressController.text
                                                  : 'Kecamatan Pracimantoro (Titik Antar Utama)',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Jarak tempuh antar: ${cart.distanceKm} km',
                                              style: const TextStyle(fontSize: 11, color: GageTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Form Catatan Patokan Driver (Satu-satunya input teks patokan)
                              TextField(
                                controller: _notePatokanController,
                                style: const TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Catatan patokan untuk driver (contoh: pagar hitam, depan pos ronda)...',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                  const SizedBox(height: 12),

                  // Ringkasan Resto & Menu
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cart.merchantCount > 1
                                      ? 'Belanja Gabungan (${cart.merchantCount} Merchant)'
                                      : (cart.merchantName ?? 'Resto Mitra'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              if (cart.merchantCount > 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: GageTheme.accentGreen),
                                  ),
                                  child: const Text(
                                    'Multi-Merchant',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: GageTheme.accentGreen),
                                  ),
                                ),
                            ],
                          ),
                          const Divider(height: 20),

                          ...cart.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: item.serviceType == 'tani'
                                              ? const Color(0xFFDCFCE7)
                                              : item.serviceType == 'shop'
                                                  ? const Color(0xFFE0F2FE)
                                                  : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.serviceType == 'tani'
                                              ? '🌾 GAGE Tani'
                                              : item.serviceType == 'shop'
                                                  ? '🛍️ GAGE Shop'
                                                  : '🍔 Kuliner',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: item.serviceType == 'tani'
                                                ? const Color(0xFF166534)
                                                : item.serviceType == 'shop'
                                                    ? const Color(0xFF0369A1)
                                                    : GageTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Toko: ${item.merchantName}',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: GageTheme.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Thumbnail Foto Menu Makanan di Keranjang
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 52,
                                        height: 52,
                                        child: _buildProductThumbnail(item.imageUrl),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                          const SizedBox(height: 2),
                                          Text(currencyFormatter.format(item.price), style: const TextStyle(fontSize: 12, color: GageTheme.primary, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
                                          onPressed: () => cart.updateQuantity(item.menuId, -1),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, size: 20, color: GageTheme.primary),
                                          onPressed: () => cart.updateQuantity(item.menuId, 1),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () {
                                    final noteCtrl = TextEditingController(text: item.notes ?? '');
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: Text('Catatan untuk Dapur: ${item.name}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        content: TextField(
                                          controller: noteCtrl,
                                          maxLength: 100,
                                          decoration: const InputDecoration(
                                            hintText: 'Cth: Jangan pedas, tanpa seledri, kuah dipisah...',
                                            hintStyle: TextStyle(fontSize: 12),
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: GageTheme.primary, foregroundColor: Colors.white),
                                            onPressed: () {
                                              cart.setNotes(item.menuId, noteCtrl.text.trim());
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text('Simpan'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.edit_note_rounded, size: 16, color: GageTheme.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.notes != null && item.notes!.isNotEmpty ? 'Catatan dapur: "${item.notes}"' : '+ Catatan untuk dapur',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: item.notes != null && item.notes!.isNotEmpty ? GageTheme.textPrimary : GageTheme.primary,
                                            fontWeight: item.notes != null && item.notes!.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),

                          const SizedBox(height: 12),
                          // Tombol Tambah Pesanan / Menu Lain
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: GageTheme.primary,
                                side: const BorderSide(color: GageTheme.primary, width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (ctx) => const FoodExploreScreen()),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                              label: const Text('+ Tambah Pesanan / Menu Lain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // GoFood Dual-Voucher Standard Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.confirmation_number_rounded, color: GageTheme.accentGreen, size: 20),
                              const SizedBox(width: 8),
                              const Text('Promo & Voucher (Bisa Digabung!)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              const Spacer(),
                              InkWell(
                                onTap: () => _openVoucherSelection(),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Row(
                                    children: const [
                                      Text('Ganti Voucher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                                      SizedBox(width: 2),
                                      Icon(Icons.chevron_right_rounded, size: 16, color: GageTheme.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Banner Ringkasan Total Hemat
                          if (cart.totalFoodDiscount > 0 || cart.totalShippingDiscount > 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: GageTheme.accentGreen.withOpacity(0.35)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: GageTheme.accentGreen, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Voucher Aktif Terpasang! Total hemat ${currencyFormatter.format(cart.totalFoodDiscount + cart.totalShippingDiscount)}',
                                      style: const TextStyle(
                                        color: GageTheme.accentGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Slot 1: Diskon Makanan
                          InkWell(
                            onTap: () => _openVoucherSelection(initialTabIndex: 1),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: cart.foodPromoCode != null ? Colors.green.shade50 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: cart.foodPromoCode != null ? GageTheme.accentGreen : Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.restaurant_rounded, color: GageTheme.primary, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cart.foodPromoCode != null ? 'Voucher Makanan: ${cart.foodPromoCode}' : 'Voucher Diskon Makanan',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        Text(
                                          cart.foodPromoCode != null ? 'Hemat ${currencyFormatter.format(cart.totalFoodDiscount)}' : 'Belum memilih diskon makanan',
                                          style: TextStyle(fontSize: 11, color: cart.foodPromoCode != null ? GageTheme.accentGreen : Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (cart.foodPromoCode != null)
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                                      onPressed: () => cart.removeFoodPromo(),
                                      visualDensity: VisualDensity.compact,
                                    )
                                  else
                                    const Text('Pilih >', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Slot 2: Subsidi Ongkir
                          InkWell(
                            onTap: () => _openVoucherSelection(initialTabIndex: 0),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: cart.deliveryPromoCode != null ? Colors.green.shade50 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: cart.deliveryPromoCode != null ? GageTheme.accentGreen : Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.delivery_dining_rounded, color: GageTheme.accentGreen, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cart.deliveryPromoCode != null ? 'Voucher Ongkir: ${cart.deliveryPromoCode}' : 'Voucher Subsidi Ongkir',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        Text(
                                          cart.deliveryPromoCode != null ? 'Subsidi ${currencyFormatter.format(cart.totalShippingDiscount)}' : 'Belum memilih voucher ongkir',
                                          style: TextStyle(fontSize: 11, color: cart.deliveryPromoCode != null ? GageTheme.accentGreen : Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (cart.deliveryPromoCode != null)
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                                      onPressed: () => cart.removeDeliveryPromo(),
                                      visualDensity: VisualDensity.compact,
                                    )
                                  else
                                    const Text('Pilih >', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.accentGreen)),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Input Manual Kode Voucher
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _promoController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan kode voucher lain...',
                                    hintStyle: const TextStyle(fontSize: 11.5),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GageTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _applyPromo(context),
                                child: const Text('Terapkan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Pilihan Metode Pembayaran
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),

                          // GagePay Closed Loop Wallet
                          RadioListTile<String>(
                            value: 'GAGEPAY',
                            groupValue: cart.paymentMethod,
                            onChanged: (val) => cart.setPaymentMethod(val!),
                            activeColor: GageTheme.primary,
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                const Icon(Icons.account_balance_wallet_rounded, color: GageTheme.primary, size: 20),
                                const SizedBox(width: 8),
                                const Text('Saldo GagePay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const Spacer(),
                                Text(
                                  currencyFormatter.format(wallet.balance),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: wallet.balance >= cart.grandTotal ? GageTheme.accentGreen : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: wallet.balance < cart.grandTotal
                                ? const Text('Saldo kurang, klik top up', style: TextStyle(color: Colors.red, fontSize: 11))
                                : const Text('Bayar 1-klik instan', style: TextStyle(fontSize: 11, color: GageTheme.textSecondary)),
                          ),

                          const Divider(height: 8),

                          // Dynamic QRIS
                          RadioListTile<String>(
                            value: 'QRIS',
                            groupValue: cart.paymentMethod,
                            onChanged: (val) => cart.setPaymentMethod(val!),
                            activeColor: GageTheme.primary,
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: const [
                                Icon(Icons.qr_code_2_rounded, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Text('QRIS Dinamis Tag 54', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            subtitle: const Text('BCA, Mandiri, BRI, ShopeePay, GoPay', style: TextStyle(fontSize: 11, color: GageTheme.textSecondary)),
                          ),

                          const Divider(height: 8),

                          // Cash COD (dengan Anti-Fraud Limit)
                          RadioListTile<String>(
                            value: 'CASH_COD',
                            groupValue: cart.paymentMethod,
                            onChanged: (val) => cart.setPaymentMethod(val!),
                            activeColor: GageTheme.primary,
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: const [
                                Icon(Icons.money_rounded, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text('Tunai / Bayar di Tempat (COD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            subtitle: const Text('Biaya penanganan Rp 3.000 • Maks Rp 75.000', style: TextStyle(fontSize: 11, color: GageTheme.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Rincian Pembayaran
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rincian Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 10),
                          _buildPriceRow('Subtotal Menu (${cart.totalItemCount} item)', currencyFormatter.format(cart.subtotal)),
                          if (cart.totalFoodDiscount > 0)
                            _buildPriceRow('Diskon Makanan (${cart.foodPromoCode})', '- ${currencyFormatter.format(cart.totalFoodDiscount)}', isDiscount: true),
                          _buildPriceRow('Ongkos Kirim Pengantaran', currencyFormatter.format(cart.rawShippingFee)),
                          if (cart.totalShippingDiscount > 0)
                            _buildPriceRow('Subsidi Ongkir (${cart.deliveryPromoCode})', '- ${currencyFormatter.format(cart.totalShippingDiscount)}', isDiscount: true),
                          _buildPriceRow(
                            'Biaya Layanan & Penanganan (${cart.merchantCount} Toko)',
                            currencyFormatter.format(cart.adminFee),
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(
                                currencyFormatter.format(cart.grandTotal),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: GageTheme.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Notice Ketentuan Layanan & Transparansi Biaya (Pembulatan Rp 500)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.verified_rounded, color: GageTheme.accentGreen, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ketentuan Layanan & Transparansi Biaya',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: GageTheme.accentGreen),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Tarif pengantaran dibulatkan ke kelipatan Rp 500 terdekat ke atas demi kepraktisan transaksi lapangan & alokasi subsidi tarif bersama.',
                                style: TextStyle(fontSize: 11, color: GageTheme.textSecondary, height: 1.35),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TermsAndPrivacyScreen(initialTabIndex: 0),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Baca Ketentuan Layanan & Kebijakan >',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tombol Pesan Sekarang
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isPlacingOrder ? null : () => _handleCheckout(context),
                    child: _isPlacingOrder
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Pesan & Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 8),
                              Text('(${currencyFormatter.format(cart.grandTotal)})', style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDiscount ? GageTheme.accentGreen : GageTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
extension NumberFormatting on int {
  String toLocaleString() {
    return NumberFormat.decimalPattern('id_ID').format(this);
  }
}
