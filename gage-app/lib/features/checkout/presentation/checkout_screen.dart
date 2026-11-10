import 'package:gage_app/core/constants/qris_engine.dart';
import 'package:gage_app/core/services/qris_code_service.dart';
import 'package:gage_app/core/services/merchant_discount_tier_service.dart';
import 'package:gage_app/core/services/gage_security_service.dart';
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/features/orders/presentation/order_tracking_screen.dart';
import 'package:gage_app/features/wallet/presentation/topup_qris_dialog.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/features/voucher/presentation/voucher_selection_screen.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

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
  int _driverTip = 0;
  bool _isLoading = false;

  Future<void> _refreshCheckout() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartProvider>();
    _addressController.text = cart.deliveryAddress.isNotEmpty
        ? cart.deliveryAddress
        : 'XR89+JGX, Pracimantoro, Wonogiri';
    _notePatokanController.text = cart.addressNotes.isNotEmpty
        ? cart.addressNotes
        : '';
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

  Future<void> _showCustomTipDialog() async {
    final textController = TextEditingController(
      text: _driverTip > 0 ? _driverTip.toString() : '',
    );
    int currentNominal = _driverTip;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: GageTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.volunteer_activism_rounded, color: GageTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apresiasi Tip Driver Mitra',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '100% tip diberikan seutuhnya ke pengemudi mitra',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [2000, 5000, 10000, 20000].map((inc) {
                        return ActionChip(
                          avatar: const Icon(Icons.add_rounded, size: 14, color: GageTheme.primary),
                          label: Text(
                            'Rp ${NumberFormat("#,###", "id_ID").format(inc)}',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: GageTheme.primary),
                          ),
                          backgroundColor: GageTheme.primary.withValues(alpha: 0.08),
                          side: BorderSide(color: GageTheme.primary.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            final next = currentNominal + inc;
                            currentNominal = next;
                            textController.text = next.toString();
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: GageTheme.primary, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Rp ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: GageTheme.primary,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: textController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              autofocus: true,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                              ),
                              onChanged: (val) {
                                final parsed = int.tryParse(val) ?? 0;
                                currentNominal = parsed;
                                setModalState(() {});
                              },
                            ),
                          ),
                          if (textController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                              onPressed: () {
                                textController.clear();
                                currentNominal = 0;
                                setModalState(() {});
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _driverTip = currentNominal;
                        });
                        Navigator.pop(ctx);
                        if (mounted) {
                          GageToast.show(
                            context,
                            currentNominal > 0
                                ? 'Tip Rp ${NumberFormat("#,###", "id_ID").format(currentNominal)} berhasil dipasang'
                                : 'Tip diatur ke Rp 0',
                            type: GageToastType.success,
                          );
                        }
                      },
                      child: Text(
                        currentNominal > 0
                            ? 'Pasang Tip (Rp ${NumberFormat("#,###", "id_ID").format(currentNominal)})'
                            : 'Tanpa Tip',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

  Widget _buildTipChip(int amount, String label) {
    final isSelected = _driverTip == amount;
    return InkWell(
      onTap: () {
        setState(() {
          _driverTip = amount;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? GageTheme.primary.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? GageTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? GageTheme.primary : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTipChip() {
    final isCustom = _driverTip > 0 && _driverTip != 2000 && _driverTip != 5000 && _driverTip != 10000;
    return InkWell(
      onTap: _showCustomTipDialog,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isCustom ? GageTheme.primary.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCustom ? GageTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_outlined,
              size: 13,
              color: isCustom ? GageTheme.primary : Colors.black54,
            ),
            const SizedBox(width: 4),
            Text(
              isCustom ? 'Lain: Rp ${NumberFormat("#,###", "id_ID").format(_driverTip)}' : 'Lainnya...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCustom ? FontWeight.bold : FontWeight.w500,
                color: isCustom ? GageTheme.primary : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _openVoucherSelection({int initialTabIndex = 0}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => VoucherSelectionScreen(initialTabIndex: initialTabIndex),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _showMerchantMapDialog(BuildContext context, String merchantName, String address) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Lokasi Toko Mitra',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: const Color(0xFFE2E8F0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 90,
                          left: 0,
                          right: 0,
                          child: Container(height: 18, color: Colors.white),
                        ),
                        Positioned(
                          left: 120,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 18, color: Colors.white),
                        ),
                        const Icon(Icons.location_on, color: GageTheme.primary, size: 36),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  address,
                  style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    final effectiveTip = cart.isPickup ? 0 : _driverTip;
    final totalPay = cart.grandTotal + effectiveTip;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Validasi Saldo GagePay & Multi Metode
    if (cart.paymentMethod == 'GAGEPAY') {
      if (wallet.balance < totalPay) {
        GageFloatingSheet.showConfirm(
          context: context,
          title: 'Saldo GAGEPay Kurang',
          message:
              'Saldo Anda: ${currencyFormatter.format(wallet.balance)} | Total: ${currencyFormatter.format(totalPay)}.\nSilakan gunakan metode Split (GAGEPay + QRIS / COD) atau top-up saldo.',
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

      // Otorisasi Keamanan Biometrik / PIN 6 Digit untuk GAGEPay Penuh
      final authorized = await GageSecurityService.instance.verifyAuthorization(
        context,
        title: 'Pembayaran GAGEPay',
        amount: totalPay,
      );
      if (!authorized) {
        if (context.mounted) {
          GageToast.show(context, 'Otorisasi pembayaran GAGEPay dibatalkan.', type: GageToastType.warning);
        }
        return;
      }
    } else if (cart.paymentMethod == 'GAGEPAY_QRIS' || cart.paymentMethod == 'GAGEPAY_COD') {
      // Split payment otorisasi porsi GAGEPay
      final authorized = await GageSecurityService.instance.verifyAuthorization(
        context,
        title: 'Otorisasi GAGEPay (Split)',
        amount: wallet.balance,
      );
      if (!authorized) {
        if (context.mounted) {
          GageToast.show(context, 'Otorisasi pembayaran split dibatalkan.', type: GageToastType.warning);
        }
        return;
      }

      if (cart.paymentMethod == 'GAGEPAY_COD') {
        final remainingCod = totalPay - wallet.balance;
        if (remainingCod > 75000) {
          GageToast.show(
            context,
            'Sisa pembayaran tunai (COD) melebihi Rp 75.000. Silakan pilih GAGEPay + QRIS.',
            type: GageToastType.warning,
          );
          return;
        }
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

    final effectivePaymentMethod = cart.paymentMethod;

    final newOrder = await orderProvider.placeOrder(
      userId: userId,
      merchantId: cart.merchantId ?? 'm-dimsum-sewu',
      items: itemsPayload,
      distanceKm: cart.isPickup ? 0.0 : cart.distanceKm,
      paymentMethod: effectivePaymentMethod,
      affiliatorId: cart.promoCode == 'GAGERATIH' ? 'usr-aff-01' : null,
      promoCode: cart.promoCode,
      deliveryAddress: effectiveAddress,
      merchantName: allMerchantNames.isNotEmpty ? allMerchantNames : cart.merchantName,
      driverTip: effectiveTip,
    );

    setState(() => _isPlacingOrder = false);

    if (newOrder != null) {
      if (cart.paymentMethod == 'GAGEPAY') {
        wallet.deductBalance(totalPay);
      } else if (cart.paymentMethod == 'GAGEPAY_QRIS') {
        final gagePayPortion = wallet.balance;
        final remainingQris = totalPay - gagePayPortion;
        wallet.deductBalance(gagePayPortion);
        if (!context.mounted) return;
        final uniqueCode = await QrisCodeService.instance.allocateCode(newOrder.id);
        final finalAmount = remainingQris + uniqueCode;
        final dynamicQris = QrisEngine.generateDynamic(amount: finalAmount);
        if (!context.mounted) return;
        await _showQrisOrderDialog(context, dynamicQris, finalAmount, newOrder.orderNumber, uniqueCode: uniqueCode);
      } else if (cart.paymentMethod == 'GAGEPAY_COD') {
        final gagePayPortion = wallet.balance;
        final remainingCod = totalPay - gagePayPortion;
        wallet.deductBalance(gagePayPortion);
        if (context.mounted) {
          GageToast.show(
            context,
            'GAGEPay terpotong ${currencyFormatter.format(gagePayPortion)}. Sisa ${currencyFormatter.format(remainingCod)} dibayar tunai ke kurir.',
            type: GageToastType.success,
          );
        }
      } else if (cart.paymentMethod == 'QRIS') {
        if (!context.mounted) return;
        final uniqueCode = await QrisCodeService.instance.allocateCode(newOrder.id);
        final finalAmount = newOrder.totalAmount + uniqueCode;
        final dynamicQris = QrisEngine.generateDynamic(amount: finalAmount);
        if (!context.mounted) return;
        await _showQrisOrderDialog(context, dynamicQris, finalAmount, newOrder.orderNumber, uniqueCode: uniqueCode);
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

  Future<void> _showQrisOrderDialog(BuildContext context, String qrisString, int amount, String orderNumber, {int? uniqueCode}) async {
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
            if (uniqueCode != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF93C5FD)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Text(
                      'Termasuk Kode Unik: +Rp $uniqueCode',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1D4ED8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Transfer tepat hingga 3 digit terakhir agar terverifikasi otomatis.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
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
    final effectiveTip = cart.isPickup ? 0 : _driverTip;
    final totalPay = cart.grandTotal + effectiveTip;
    final hasPartialBalance = wallet.balance > 0 && wallet.balance < totalPay;

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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

              // 1. OPTION GAGEPAY (Full / Base)
              _buildPaymentOptionTile(
                ctx: ctx,
                isDark: isDark,
                isSelected: cart.paymentMethod == 'GAGEPAY',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'GAGEPay',
                subtitle: 'Saldo Anda: ${currencyFormatter.format(wallet.balance)} • 0% Biaya Layanan',
                badge: wallet.balance < totalPay ? 'Kurang ${currencyFormatter.format(totalPay - wallet.balance)}' : 'CUKUP',
                badgeColor: wallet.balance < totalPay ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                onTap: () {
                  if (wallet.balance < totalPay) {
                    GageToast.show(context, 'Saldo GAGEPay kurang. Gunakan opsi GAGEPay + QRIS atau GAGEPay + COD di bawah.', type: GageToastType.warning);
                  } else {
                    cart.setPaymentMethod('GAGEPAY');
                    Navigator.pop(ctx);
                  }
                },
              ),

              // 1b. SUB OPTIONS: SPLIT PAYMENT (jika saldo > 0 tapi < totalPay)
              if (hasPartialBalance) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 18, bottom: 8, top: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: GageTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Kombinasikan Saldo GAGEPay Anda:',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.orange.shade300 : const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                ),

                // GAGEPay + QRIS
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _buildPaymentOptionTile(
                    ctx: ctx,
                    isDark: isDark,
                    isSelected: cart.paymentMethod == 'GAGEPAY_QRIS',
                    icon: Icons.qr_code_scanner_rounded,
                    iconColor: const Color(0xFF0284C7),
                    title: 'GAGEPay + QRIS',
                    subtitle: 'GAGEPay ${currencyFormatter.format(wallet.balance)} + QRIS ${currencyFormatter.format(totalPay - wallet.balance)}',
                    badge: 'SPLIT',
                    badgeColor: const Color(0xFF0284C7),
                    onTap: () {
                      cart.setPaymentMethod('GAGEPAY_QRIS');
                      Navigator.pop(ctx);
                    },
                  ),
                ),

                // GAGEPay + COD
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _buildPaymentOptionTile(
                    ctx: ctx,
                    isDark: isDark,
                    isSelected: cart.paymentMethod == 'GAGEPAY_COD',
                    icon: Icons.payments_outlined,
                    iconColor: const Color(0xFF16A34A),
                    title: 'GAGEPay + COD',
                    subtitle: 'GAGEPay ${currencyFormatter.format(wallet.balance)} + Tunai ${currencyFormatter.format(totalPay - wallet.balance)}',
                    badge: 'SPLIT',
                    badgeColor: const Color(0xFF16A34A),
                    onTap: () {
                      cart.setPaymentMethod('GAGEPAY_COD');
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],

              // 2. OPTION QRIS (Full)
              _buildPaymentOptionTile(
                ctx: ctx,
                isDark: isDark,
                isSelected: cart.paymentMethod == 'QRIS',
                icon: Icons.qr_code_2_rounded,
                iconColor: GageTheme.primary,
                title: 'QRIS',
                subtitle: 'Bebas biaya admin • ShopeePay, GoPay, Dana, BCA, Mandiri',
                onTap: () {
                  cart.setPaymentMethod('QRIS');
                  Navigator.pop(ctx);
                },
              ),

              // 3. OPTION COD (Full)
              _buildPaymentOptionTile(
                ctx: ctx,
                isDark: isDark,
                isSelected: cart.paymentMethod == 'CASH_COD',
                icon: Icons.payments_rounded,
                iconColor: const Color(0xFF16A34A),
                title: 'Tunai ke Driver (COD)',
                subtitle: 'Bayar langsung saat pesanan tiba di tujuan (Maks. Rp 75rb)',
                onTap: () {
                  cart.setPaymentMethod('CASH_COD');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required BuildContext ctx,
    required bool isDark,
    required bool isSelected,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFF1F0))
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? GageTheme.primary : (isDark ? Colors.white12 : Colors.grey.shade300),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? GageTheme.primary.withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6)),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? GageTheme.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: badgeColor ?? GageTheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
        trailing: Icon(
          isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
          color: isSelected ? GageTheme.primary : Colors.grey,
          size: 19,
        ),
      ),
    );
  }

  String _inferDishImage(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('mentai')) return 'assets/images/dish_dimsum_mentai.png';
    if (n.contains('bakar') || n.contains('keju')) return 'assets/images/dish_dimsum_original.png';
    if (n.contains('pangsit') || n.contains('mie')) return 'assets/images/dish_mie_ayam.png';
    if (n.contains('dimsum')) return 'assets/images/dish_dimsum_original.png';
    if (n.contains('ayam') || n.contains('geprek') || n.contains('rocket') || n.contains('chicken')) {
      return 'assets/images/dish_ayam_geprek.png';
    }
    if (n.contains('burger')) return 'assets/images/dish_chicken_burger.png';
    if (n.contains('bakso')) return 'assets/images/dish_bakso_urat.png';
    if (n.contains('sate')) return 'assets/images/dish_sate_ayam.png';
    if (n.contains('seblak')) return 'assets/images/dish_seblak_komplit.png';
    if (n.contains('cimol')) return 'assets/images/dish_cimol_bojot.png';
    if (n.contains('teh') || n.contains('es') || n.contains('jeruk')) return 'assets/images/dish_es_teh.png';
    if (n.contains('kopi')) return 'assets/images/dish_kopi_susu.png';
    return 'assets/images/dish_dimsum_original.png';
  }

  Widget _buildProductThumbnail(String? imageUrl, [String? itemName]) {
    String? effectiveUrl = imageUrl;
    if (effectiveUrl == null || effectiveUrl.trim().isEmpty) {
      effectiveUrl = _inferDishImage(itemName);
    }
    final clean = effectiveUrl.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Image.network(
        clean,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Image.asset(
          _inferDishImage(itemName),
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      clean,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Image.asset(
        _inferDishImage(itemName),
        fit: BoxFit.cover,
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
    final effectiveTip = isPickup ? 0 : _driverTip;
    final totalPay = cart.grandTotal + effectiveTip;

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
      body: _isLoading
          ? const GageSkeletonCheckout()
          : cart.items.isEmpty
              ? const Center(child: Text('Keranjang belanja kosong'))
              : Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _refreshCheckout,
                      color: GageTheme.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width >= 600 ? 600 : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // =========================================================
                            // 1. SEGMENTED SWITCH DELIVERY VS PICKUP (Clean, no outer wrap, no icon)
                            // =========================================================
                            Container(
                              height: 44,
                              padding: const EdgeInsets.all(3.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Tab Delivery
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (isPickup) {
                                          HapticFeedback.lightImpact();
                                          cart.setIsPickup(false);
                                          GageToast.show(context, 'Beralih ke Delivery (Diantar Driver)', type: GageToastType.info);
                                        }
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          color: !isPickup ? GageTheme.primary : Colors.transparent,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: !isPickup
                                              ? [
                                                  BoxShadow(
                                                    color: GageTheme.primary.withValues(alpha: 0.28),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Delivery',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: !isPickup ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Tab Pickup
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (!isPickup) {
                                          HapticFeedback.lightImpact();
                                          cart.setIsPickup(true);
                                          GageToast.show(context, 'Beralih ke Pickup (Ambil Sendiri di Toko)', type: GageToastType.info);
                                        }
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          color: isPickup ? GageTheme.primary : Colors.transparent,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: isPickup
                                              ? [
                                                  BoxShadow(
                                                    color: GageTheme.primary.withValues(alpha: 0.28),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Pickup',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: isPickup ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                          ),
                                        ),
                                      ),
                                    ),
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
                                    // 1. Prioritas (Express Direct)
                                    InkWell(
                                      onTap: () => cart.setDeliveryOption('PRIORITAS'),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Text('Prioritas', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                                                  child: const Text('15-25 min', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  currencyFormatter.format(cart.prioritasShippingFee),
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  cart.deliveryOption == 'PRIORITAS' ? Icons.radio_button_checked : Icons.radio_button_off,
                                                  color: cart.deliveryOption == 'PRIORITAS' ? GageTheme.primary : Colors.grey,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            const Text('⚡ Kurir langsung jalan, jaminan makanan hangat & cepat', style: TextStyle(fontSize: 11.5, color: Color(0xFFD97706))),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 16),
                                    // 2. Reguler (Paling Populer)
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
                                                  currencyFormatter.format(cart.regulerShippingFee),
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
                                    // 3. Hemat (Saver Batch)
                                    InkWell(
                                      onTap: cart.isHematAvailable ? () => cart.setDeliveryOption('HEMAT') : null,
                                      child: Opacity(
                                        opacity: cart.isHematAvailable ? 1.0 : 0.45,
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
                                                    currencyFormatter.format(cart.hematShippingFee),
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
                                              Text(
                                                cart.isHematAvailable
                                                    ? '🍃 Rute pengantaran gabungan kurir, ongkir lebih hemat'
                                                    : '🍃 Khusus pengantaran jarak jauh (> 2.5 km)',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: cart.isHematAvailable ? const Color(0xFFEA580C) : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
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
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                    width: 1.0,
                                  ),
                                  boxShadow: cardShadow,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. Foto Profil / Logo Merchant Terkait
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: Image.asset(
                                          'assets/images/resto_dimsum_sewu.png',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: GageTheme.primary.withValues(alpha: 0.1),
                                            child: const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 24),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // 2. Info Detail Toko & Alamat
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Ambil di Toko Mitra',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            cart.merchantName ?? 'Resto Mitra GAGE',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Komplek Pasar Pracimantoro Lor, Wonogiri',
                                            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // 3. Mini Map View 1:1 Interaktif (Bisa di-expand)
                                    GestureDetector(
                                      onTap: () {
                                        _showMerchantMapDialog(
                                          context,
                                          cart.merchantName ?? 'Resto Mitra GAGE',
                                          'Komplek Pasar Pracimantoro Lor, Wonogiri',
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          width: 58,
                                          height: 58,
                                          color: const Color(0xFFE2E8F0),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Mini road grid simulation
                                              Positioned(
                                                top: 26,
                                                left: -4,
                                                right: -4,
                                                child: Container(height: 8, color: Colors.white),
                                              ),
                                              Positioned(
                                                left: 26,
                                                top: -4,
                                                bottom: -4,
                                                child: Container(width: 8, color: Colors.white),
                                              ),
                                              const Icon(Icons.location_on, color: GageTheme.primary, size: 22),
                                              Positioned(
                                                bottom: 2,
                                                right: 2,
                                                child: Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.black54,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(Icons.fullscreen, color: Colors.white, size: 10),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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
                                  border: Border.all(
                                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                    width: 1.0,
                                  ),
                                  boxShadow: cardShadow,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: GageTheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.location_on_rounded, color: GageTheme.primary, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Alamat Pengantaran',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Utama',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _addressController.text.isNotEmpty ? _addressController.text : 'Titik lokasi terpilih',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          // Catatan Driver Dinamis
                                          InkWell(
                                            onTap: _editAddressNote,
                                            borderRadius: BorderRadius.circular(14),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    _notePatokanController.text.isNotEmpty
                                                        ? Icons.edit_note_rounded
                                                        : Icons.add_comment_outlined,
                                                    size: 14,
                                                    color: GageTheme.primary,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      _notePatokanController.text.isNotEmpty
                                                          ? 'Catatan: "${_notePatokanController.text}"'
                                                          : '+ Tambah catatan / patokan driver',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: _notePatokanController.text.isNotEmpty
                                                            ? (isDark ? Colors.white : Colors.black87)
                                                            : (isDark ? Colors.white60 : Colors.grey.shade600),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: _openLocationPicker,
                                      child: const Text('Ganti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                                                child: _buildProductThumbnail(item.imageUrl, item.name),
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
                                          if (cart.merchantId != null && cart.merchantId!.isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (ctx) => RestoDetailScreen(
                                                  merchant: {
                                                    'id': cart.merchantId,
                                                    'name': cart.merchantName,
                                                    'service_type': cart.primaryServiceType,
                                                  },
                                                ),
                                              ),
                                            );
                                          } else {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (ctx) => const FoodExploreScreen()),
                                            );
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
                            // 4b. DRIVER TIP SELECTOR CARD (Apresiasi Driver 100%)
                            // =========================================================
                            if (!isPickup)
                              Container(
                                margin: const EdgeInsets.only(top: 14),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: cardShadow,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFEF3C7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.favorite_rounded, color: Color(0xFFD97706), size: 16),
                                        ),
                                        const SizedBox(width: 10),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Beri Tip untuk Driver?',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                '100% tip apresiasi diserahkan penuh ke driver',
                                                style: TextStyle(fontSize: 11, color: Colors.black54),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (_driverTip > 0)
                                          Text(
                                            currencyFormatter.format(_driverTip),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              color: GageTheme.primary,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _buildTipChip(0, 'Tanpa Tip'),
                                          const SizedBox(width: 8),
                                          _buildTipChip(2000, '+Rp 2.000'),
                                          const SizedBox(width: 8),
                                          _buildTipChip(5000, '+Rp 5.000'),
                                          const SizedBox(width: 8),
                                          _buildTipChip(10000, '+Rp 10.000'),
                                          const SizedBox(width: 8),
                                          _buildCustomTipChip(),
                                        ],
                                      ),
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
                                      // Diskon Makanan (jika ada)
                                      if (cart.totalFoodDiscount > 0) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Text(
                                                  'Diskon Makanan',
                                                  style: TextStyle(fontSize: 13.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFDCFCE7),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                                  ),
                                                  child: Text(
                                                    cart.foodPromoCode ?? 'DISKON',
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D), letterSpacing: 0.3),
                                                  ),
                                                ),
                                              ],
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
                                          Row(
                                            children: [
                                              Text(
                                                isPickup ? 'Biaya Pengiriman (Pickup)' : 'Ongkos Kirim',
                                                style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : Colors.black87),
                                              ),
                                              if (!isPickup) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    cart.deliveryOption,
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade700),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          Text(
                                            isPickup ? 'Gratis (Rp 0)' : currencyFormatter.format(cart.rawShippingFee),
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: isPickup ? const Color(0xFF16A34A) : (isDark ? Colors.white : Colors.black87),
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
                                            Row(
                                              children: [
                                                const Text(
                                                  'Diskon Ongkir',
                                                  style: TextStyle(fontSize: 13.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFDCFCE7),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                                  ),
                                                  child: Text(
                                                    cart.deliveryPromoCode ?? 'ONGKIR',
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D), letterSpacing: 0.3),
                                                  ),
                                                ),
                                              ],
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
                                      // Tip Driver (jika ada)
                                      if (!isPickup && _driverTip > 0) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Tip Driver (100% Mitra)', style: TextStyle(fontSize: 13.5, color: Colors.black87)),
                                            Text(
                                              currencyFormatter.format(_driverTip),
                                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: GageTheme.primary),
                                            ),
                                          ],
                                        ),
                                      ],
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
                            // 6. METODE PEMBAYARAN (In-Page Section + Split Payment)
                            // =========================================================
                            Container(
                              margin: const EdgeInsets.only(top: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: cardShadow,
                                border: Border.all(
                                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                  width: 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.account_balance_wallet_rounded,
                                              color: Color(0xFF0284C7),
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Metode Pembayaran',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () => _showPaymentMethodSheet(context, cart, wallet),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Ganti',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: GageTheme.primary,
                                              ),
                                            ),
                                            Icon(Icons.chevron_right_rounded, size: 16, color: GageTheme.primary),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Selected Payment Method Display
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          cart.paymentMethod == 'GAGEPAY'
                                              ? Icons.account_balance_wallet_rounded
                                              : (cart.paymentMethod == 'GAGEPAY_QRIS'
                                                  ? Icons.qr_code_scanner_rounded
                                                  : (cart.paymentMethod == 'GAGEPAY_COD'
                                                      ? Icons.payments_outlined
                                                      : (cart.paymentMethod == 'QRIS'
                                                          ? Icons.qr_code_2_rounded
                                                          : Icons.payments_rounded))),
                                          color: cart.paymentMethod.startsWith('GAGEPAY')
                                              ? const Color(0xFF0284C7)
                                              : (cart.paymentMethod == 'QRIS'
                                                  ? GageTheme.primary
                                                  : const Color(0xFF16A34A)),
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cart.paymentMethod == 'GAGEPAY'
                                                    ? 'GAGEPay'
                                                    : (cart.paymentMethod == 'GAGEPAY_QRIS'
                                                        ? 'GAGEPay + QRIS (Split)'
                                                        : (cart.paymentMethod == 'GAGEPAY_COD'
                                                            ? 'GAGEPay + COD (Split)'
                                                            : (cart.paymentMethod == 'QRIS'
                                                                ? 'QRIS'
                                                                : 'Tunai ke Driver (COD)'))),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                cart.paymentMethod == 'GAGEPAY'
                                                    ? 'Saldo Anda: ${currencyFormatter.format(wallet.balance)}'
                                                    : (cart.paymentMethod == 'GAGEPAY_QRIS'
                                                        ? 'GAGEPay ${currencyFormatter.format(wallet.balance)} + QRIS ${currencyFormatter.format(totalPay - wallet.balance)}'
                                                        : (cart.paymentMethod == 'GAGEPAY_COD'
                                                            ? 'GAGEPay ${currencyFormatter.format(wallet.balance)} + Tunai ${currencyFormatter.format(totalPay - wallet.balance)}'
                                                            : (cart.paymentMethod == 'QRIS'
                                                                ? 'ShopeePay, GoPay, BCA, Mandiri'
                                                                : 'Bayar saat pesanan tiba'))),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Pengingat Saldo Bersih Jika GAGEPay Kurang
                                  if (cart.paymentMethod == 'GAGEPAY' && wallet.balance < totalPay) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFFECACA)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Saldo GAGEPay kurang ${currencyFormatter.format(totalPay - wallet.balance)}',
                                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => TopupQrisDialog.showAsSheet(
                                              context,
                                              onTopupSuccess: (amt) {
                                                wallet.topUp(amt);
                                                setState(() {});
                                              },
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: GageTheme.primary,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: const Text('Top Up', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // =========================================================
                            // 7. VOUCHER & DISKON CARD (Sleek Ticket Row per Image 5)
                            // =========================================================
                            Builder(
                              builder: (ctx) {
                                final hasFoodPromo = cart.foodPromoCode != null;
                                final hasDeliveryPromo = cart.deliveryPromoCode != null;
                                final hasAnyPromo = hasFoodPromo || hasDeliveryPromo;

                                return Container(
                                  margin: const EdgeInsets.only(top: 14),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: cardShadow,
                                    border: Border.all(
                                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => _openVoucherSelection(initialTabIndex: 0),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: GageTheme.primary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.confirmation_number_rounded,
                                            color: GageTheme.primary,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                'Voucher',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.5,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (hasDeliveryPromo) ...[
                                                _buildTicketBadge(
                                                  text: 'Diskon Ongkir',
                                                  color: const Color(0xFF0D9488),
                                                  isDark: isDark,
                                                ),
                                                const SizedBox(width: 6),
                                              ],
                                              if (hasFoodPromo) ...[
                                                _buildTicketBadge(
                                                  text: '-${MerchantDiscountTierService.formatRb(cart.foodPromoDiscount)}',
                                                  color: const Color(0xFFEA580C),
                                                  isDark: isDark,
                                                ),
                                              ],
                                              if (!hasAnyPromo) ...[
                                                Text(
                                                  'Gunakan / masukkan kode',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: isDark ? Colors.white60 : Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.black45,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            // =========================================================
                            // 8. OPSI TAMBAHAN (Kirim Sebagai Hadiah)
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
                                                ? 'Penerima:  • Pesan tersimpan'
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

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Floating Pesan Sekarang Button (No white background container)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 4,
                          shadowColor: GageTheme.primary.withValues(alpha: 0.4),
                        ),
                        onPressed: _isPlacingOrder ? null : () => _handleCheckout(context),
                        child: _isPlacingOrder
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                isPickup ? 'Ambil Sekarang' : 'Pesan Sekarang',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTicketBadge({required String text, required Color color, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
