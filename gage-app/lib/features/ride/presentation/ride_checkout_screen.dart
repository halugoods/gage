import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';
import 'package:gage_app/core/constants/qris_engine.dart';
import 'package:gage_app/features/orders/presentation/order_tracking_screen.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/features/wallet/presentation/gagepay_screen.dart';
import 'package:gage_app/features/voucher/presentation/voucher_selection_screen.dart';


class RideCheckoutScreen extends StatefulWidget {
  final String serviceType; // 'ride', 'car', or 'send'
  final String rideOption; // 'standard' (reguler), 'hemat', or packageType
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final String pickupAddress;
  final String dropoffAddress;
  final double distanceKm;
  final int baseFare;
  final String? recipientName;
  final String? recipientPhone;
  final String? packageType;
  final String? weightTier;
  final String? itemDescription;

  const RideCheckoutScreen({
    super.key,
    required this.serviceType,
    required this.rideOption,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.baseFare,
    this.recipientName,
    this.recipientPhone,
    this.packageType,
    this.weightTier,
    this.itemDescription,
  });

  @override
  State<RideCheckoutScreen> createState() => _RideCheckoutScreenState();
}

class _RideCheckoutScreenState extends State<RideCheckoutScreen> {
  // Service tier: REGULER, HEMAT, PRIORITAS (Ride/Car) or INSTANT, SAMEDAY (Send)
  late String _selectedTier;
  
  // Dynamic Locations (bisa diubah via Ganti)
  late LatLng _currentPickupLocation;
  late LatLng _currentDropoffLocation;
  late String _currentPickupAddress;
  late String _currentDropoffAddress;

  // Selected Payment Method: 'GAGEPAY', 'GAGEPAY_COD', 'GAGEPAY_QRIS', 'QRIS', 'COD'
  String _selectedPaymentMethod = 'GAGEPAY';
  bool _isLoadingPreference = true;

  // Driver Tip
  int _driverTip = 0;

  // Voucher Diskon
  String? _appliedVoucherCode;
  int _voucherDiscount = 0;

  // Driver notes controller
  final TextEditingController _noteController = TextEditingController();
  bool _isPlacingOrder = false;

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _currentPickupLocation = widget.pickupLocation;
    _currentDropoffLocation = widget.dropoffLocation;
    _currentPickupAddress = widget.pickupAddress;
    _currentDropoffAddress = widget.dropoffAddress;

    // Set initial tier
    if (widget.serviceType == 'send') {
      _selectedTier = 'INSTANT';
    } else {
      _selectedTier = widget.rideOption.toLowerCase().contains('hemat') ? 'HEMAT' : 'REGULER';
    }

    _loadPaymentPreference();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMethod = prefs.getString('last_ride_payment_method');
    if (mounted) {
      setState(() {
        if (lastMethod != null && lastMethod.isNotEmpty) {
          _selectedPaymentMethod = lastMethod.toUpperCase();
          if (_selectedPaymentMethod == 'TUNAI') _selectedPaymentMethod = 'COD';
        } else {
          _selectedPaymentMethod = 'GAGEPAY';
        }
        _isLoadingPreference = false;
      });
    }
  }

  Future<void> _savePaymentPreference(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_ride_payment_method', method);
    if (mounted) {
      setState(() {
        _selectedPaymentMethod = method;
      });
    }
  }

  // Tier-based fare calculation (0-2 km fix rate, km berikutnya 5rb/km Reguler & 4rb/km Hemat)
  int get _tierBaseFare => _calculateTierFare(_selectedTier);

  int _calculateTierFare(String tier) {
    final isCar = widget.serviceType == 'car';
    final isHemat = tier == 'HEMAT';
    final dist = widget.distanceKm;

    if (isCar) {
      final base = isHemat ? 14000 : 16000;
      final perKm = isHemat ? 4000 : 5000;
      if (dist <= 2.0) return base;
      final raw = base + ((dist - 2.0) * perKm);
      return GagePricingService.roundUpTo500(raw.round());
    } else {
      // Ride dan Send
      final base = isHemat ? 8000 : 10000;
      final perKm = isHemat ? 4000 : 5000;
      if (dist <= 2.0) return base;
      final raw = base + ((dist - 2.0) * perKm);
      return GagePricingService.roundUpTo500(raw.round());
    }
  }

  int get _adminFee => 1000;

  int get _totalAmount {
    final raw = _tierBaseFare - _voucherDiscount + _adminFee + _driverTip;
    return raw.clamp(0, 99999999);
  }

  // Realistic estimates for Pracimantoro hills
  Map<String, int> get _realisticEstimates {
    final isCar = widget.serviceType == 'car';
    final dist = widget.distanceKm;

    int pickupMins = isCar ? 6 : 4;
    if (_selectedTier == 'PRIORITAS') pickupMins = (pickupMins * 0.6).round().clamp(2, 5);
    if (_selectedTier == 'HEMAT') pickupMins = (pickupMins * 1.4).round().clamp(5, 12);

    final tripMins = isCar ? (dist * 4.5).round().clamp(5, 60) : (dist * 3.5).round().clamp(4, 50);
    return {
      'pickup': pickupMins,
      'trip': tripMins,
      'total': pickupMins + tripMins,
    };
  }

  void _editAddressNote() async {
    final text = await GageFloatingSheet.showNoteInput(
      context: context,
      title: 'Catatan Patokan Driver',
      subtitle: 'Beri petunjuk lokasi agar driver mudah menemukan alamat',
      initialValue: _noteController.text,
      hintText: 'Contoh: surya tani, depan warung...',
    );
    if (text != null && mounted) {
      setState(() {
        _noteController.text = text;
      });
      GageToast.show(context, 'Catatan patokan disimpan', type: GageToastType.success);
    }
  }

  Future<void> _openVoucherSelection() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (ctx) => VoucherSelectionScreen(
          serviceType: widget.serviceType,
          initialTabIndex: 0,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _appliedVoucherCode = result['code'] as String?;
        _voucherDiscount = (result['discount'] as num?)?.toInt() ?? 0;
      });
    }
  }

  void _showPaymentMethodSheet(BuildContext context, WalletProvider wallet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalPay = _totalAmount;
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

              // 1. GAGEPAY
              _buildPaymentSheetTile(
                ctx: ctx,
                isDark: isDark,
                isSelected: _selectedPaymentMethod == 'GAGEPAY',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'GAGEPay',
                subtitle: 'Saldo Anda: ${currencyFormatter.format(wallet.balance)} • Bebas Biaya Admin',
                badge: wallet.balance < totalPay ? 'Kurang ${currencyFormatter.format(totalPay - wallet.balance)}' : 'CUKUP',
                badgeColor: wallet.balance < totalPay ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                onTap: () {
                  if (wallet.balance < totalPay) {
                    GageToast.show(
                      context,
                      'Saldo GAGEPay kurang. Gunakan opsi GAGEPay + QRIS atau GAGEPay + COD.',
                      type: GageToastType.warning,
                    );
                  } else {
                    _savePaymentPreference('GAGEPAY');
                    Navigator.pop(ctx);
                  }
                },
              ),

              // GAGEPAY KOMBINASI
              if (hasPartialBalance) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 18, bottom: 8, top: 4),
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
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _buildPaymentSheetTile(
                    ctx: ctx,
                    isDark: isDark,
                    isSelected: _selectedPaymentMethod == 'GAGEPAY_QRIS',
                    icon: Icons.qr_code_scanner_rounded,
                    iconColor: const Color(0xFF0284C7),
                    title: 'GAGEPay + QRIS',
                    subtitle: 'GAGEPay ${currencyFormatter.format(wallet.balance)} + QRIS ${currencyFormatter.format(totalPay - wallet.balance)}',
                    badge: 'KOMBO',
                    badgeColor: const Color(0xFF0284C7),
                    onTap: () {
                      _savePaymentPreference('GAGEPAY_QRIS');
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _buildPaymentSheetTile(
                    ctx: ctx,
                    isDark: isDark,
                    isSelected: _selectedPaymentMethod == 'GAGEPAY_COD',
                    icon: Icons.payments_outlined,
                    iconColor: const Color(0xFF16A34A),
                    title: 'GAGEPay + COD',
                    subtitle: 'GAGEPay ${currencyFormatter.format(wallet.balance)} + Tunai ${currencyFormatter.format(totalPay - wallet.balance)}',
                    badge: 'KOMBO',
                    badgeColor: const Color(0xFF16A34A),
                    onTap: () {
                      _savePaymentPreference('GAGEPAY_COD');
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],

              const SizedBox(height: 6),

              // 2. QRIS
              _buildPaymentSheetTile(
                ctx: ctx,
                isDark: isDark,
                isSelected: _selectedPaymentMethod == 'QRIS',
                icon: Icons.qr_code_2_rounded,
                iconColor: GageTheme.primary,
                title: 'QRIS Real-Time',
                subtitle: 'Scan via BCA Mobile, GoPay, ShopeePay, OVO, Dana',
                onTap: () {
                  _savePaymentPreference('QRIS');
                  Navigator.pop(ctx);
                },
              ),

              // 3. COD
              _buildPaymentSheetTile(
                ctx: ctx,
                isDark: isDark,
                isSelected: _selectedPaymentMethod == 'COD',
                icon: Icons.payments_rounded,
                iconColor: const Color(0xFF16A34A),
                title: widget.serviceType == 'send' ? 'Tunai ke Kurir (COD)' : 'Tunai ke Driver (COD)',
                subtitle: 'Bayar uang tunai langsung ke pengemudi saat perjalanan selesai',
                onTap: () {
                  _savePaymentPreference('COD');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSheetTile({
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFF1F0))
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? GageTheme.primary : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? GageTheme.primary).withValues(alpha: 0.15),
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
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: GageTheme.primary, size: 20)
            : Icon(Icons.circle_outlined, color: isDark ? Colors.white24 : Colors.grey.shade400, size: 20),
      ),
    );
  }

  void _showQrisModal(int amount, VoidCallback onPaid) {
    final invoiceNumber = 'INV-RIDE-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final qrisPayload = QrisEngine.generateDynamic(amount: amount);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    GageFloatingSheet.show(
      context: context,
      isDismissible: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_2_rounded, color: GageTheme.primary, size: 22),
                SizedBox(width: 8),
                Text(
                  'Pembayaran QRIS Standar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Scan kode QRIS menggunakan e-Wallet atau m-Banking pilihan Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: QrImageView(
                data: qrisPayload,
                version: QrVersions.auto,
                size: 190.0,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              currencyFormatter.format(amount),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: GageTheme.primary),
            ),
            const SizedBox(height: 4),
            Text(
              'Nomor Tagihan: $invoiceNumber',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onPaid();
                },
                child: const Text('Simulasi Sudah Dibayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCheckout() {
    final wallet = context.read<WalletProvider>();

    if (_selectedPaymentMethod == 'GAGEPAY' && wallet.balance < _totalAmount) {
      GageToast.show(
        context,
        'Saldo GAGEPay kurang. Pilih opsi GAGEPay + QRIS atau GAGEPay + COD.',
        type: GageToastType.warning,
      );
      return;
    }

    if (_selectedPaymentMethod == 'QRIS') {
      _showQrisModal(_totalAmount, () => _finalizeOrder());
    } else if (_selectedPaymentMethod == 'GAGEPAY_QRIS') {
      final qrisAmount = _totalAmount - wallet.balance;
      _showQrisModal(qrisAmount, () => _finalizeOrder());
    } else {
      _finalizeOrder();
    }
  }

  void _finalizeOrder() {
    setState(() => _isPlacingOrder = true);
    final auth = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();
    final wallet = context.read<WalletProvider>();

    final isSend = widget.serviceType == 'send';
    final isCar = widget.serviceType == 'car';
    final now = DateTime.now();
    final invoiceNumber = 'GAGE-${now.millisecondsSinceEpoch.toString().substring(5)}';

    String serviceName = 'GAGE Ride Pracimantoro';
    if (isSend) serviceName = 'GAGE Send Pracimantoro';
    if (isCar) serviceName = 'GAGE Car Pracimantoro';

    // Potong saldo GAGEPay jika memakai GAGEPay murni atau split
    if (_selectedPaymentMethod == 'GAGEPAY') {
      wallet.deductBalance(_totalAmount);
    } else if (_selectedPaymentMethod == 'GAGEPAY_COD' || _selectedPaymentMethod == 'GAGEPAY_QRIS') {
      if (wallet.balance > 0) {
        wallet.deductBalance(wallet.balance);
      }
    }

    String itemName = 'Layanan Antar Jemput Motor ($_selectedTier)';
    if (isCar) itemName = 'Layanan Mobil Penumpang ($_selectedTier)';
    if (isSend) itemName = 'Pengiriman Paket Instant ($_selectedTier)';

    final orderData = {
      'id': invoiceNumber,
      'user_id': auth.currentUser?.id ?? 'guest-praci',
      'service_type': widget.serviceType,
      'tier': _selectedTier,
      'status': 'searching_driver',
      'pickup_address': _currentPickupAddress,
      'destination_address': _currentDropoffAddress,
      'pickup_lat': _currentPickupLocation.latitude,
      'pickup_lng': _currentPickupLocation.longitude,
      'destination_lat': _currentDropoffLocation.latitude,
      'destination_lng': _currentDropoffLocation.longitude,
      'distance_km': widget.distanceKm,
      'payment_method': _selectedPaymentMethod,
      'fare_amount': _tierBaseFare,
      'admin_fee': _adminFee,
      'discount_amount': _voucherDiscount,
      'voucher_code': _appliedVoucherCode,
      'tip_amount': _driverTip,
      'total_amount': _totalAmount,
      'merchant_name': serviceName,
      'items': [
        {
          'id': 'item-transport-01',
          'name': itemName,
          'price': _tierBaseFare,
          'quantity': 1,
          'subtotal': _tierBaseFare,
          'notes': _noteController.text.isNotEmpty
              ? _noteController.text
              : (isSend
                  ? 'Penerima: ${widget.recipientName ?? "-"} (${widget.recipientPhone ?? "-"})'
                  : 'Jemput sesuai titik peta'),
        }
      ],
      'created_at': now.millisecondsSinceEpoch ~/ 1000,
    };

    orderProvider.createOrder(orderData);

    GageToast.show(
      context,
      'Pesanan berhasil dibuat! Nomor Invoice: $invoiceNumber',
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (ctx) => OrderTrackingScreen(
          orderId: orderData['id'] as String,
        ),
      ),
    );
  }

  void _openLocationPicker({required bool isDropoff}) {
    LocationPickerSheet.show(
      context,
      title: isDropoff ? 'Ubah Alamat Pengantaran' : 'Ubah Titik Jemput',
      initialLocation: isDropoff ? _currentDropoffLocation : _currentPickupLocation,
      onSelected: (title, fullAddress, latLng) {
        setState(() {
          if (isDropoff) {
            _currentDropoffLocation = latLng;
            _currentDropoffAddress = fullAddress;
          } else {
            _currentPickupLocation = latLng;
            _currentPickupAddress = fullAddress;
          }
        });
      },
    );
  }

  Widget _buildTipChip(int amount, String label) {
    final isSelected = _driverTip == amount;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _driverTip = amount);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? GageTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? GageTheme.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
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

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSend = widget.serviceType == 'send';
    final isCar = widget.serviceType == 'car';

    final cardColor = isDark ? GageTheme.darkSurface : Colors.white;
    final cardBorder = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final cardShadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ];

    final pageTitle = isSend
        ? 'GAGE Send Pracimantoro'
        : (isCar ? 'GAGE Car Pracimantoro' : 'GAGE Ride Pracimantoro');

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingPreference
          ? const GageSkeletonRideCheckout()
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =========================================================
                      // 1. SERVICE TIER SELECTOR (Reguler / Hemat / Prioritas)
                      // =========================================================
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                          boxShadow: cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Opsi Reguler
                            _buildTierRadioOption(
                              id: 'REGULER',
                              title: 'Reguler',
                              badge: isSend ? 'Langsung' : '~${_realisticEstimates["pickup"] ?? 4} min',
                              badgeColor: const Color(0xFF3B82F6),
                              desc: isSend ? 'Kurir langsung jalan, barang cepat tiba & aman' : 'Langsung ke titik tujuan, pasti tepat waktu',
                              price: _calculateTierFare('REGULER'),
                              isDark: isDark,
                            ),
                            const Divider(height: 16),
                            // Opsi Hemat
                            _buildTierRadioOption(
                              id: 'HEMAT',
                              title: 'Hemat',
                              badge: isSend ? 'Hemat' : '~${(_realisticEstimates["pickup"] ?? 4) + 4} min',
                              badgeColor: const Color(0xFF10B981),
                              desc: isSend ? 'Pengiriman hemat pengantaran rute gabungan' : 'Tarif super irit untuk perjalanan santai',
                              price: _calculateTierFare('HEMAT'),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // =========================================================
                      // 2. ALAMAT PENGANTARAN / TUJUAN (with Mini Map Preview 1:1 Food/Shop/Farm/Build)
                      // =========================================================
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                          boxShadow: cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MiniLocationPreviewMap(
                                  location: _currentDropoffLocation,
                                  size: 68,
                                  borderRadius: 14,
                                  onTap: () => _openLocationPicker(isDropoff: true),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            isSend ? 'Alamat Pengantaran' : 'Titik Tujuan',
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
                                            child: const Text(
                                              'Utama',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _currentDropoffAddress,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: isDark ? Colors.grey.shade300 : Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      // Catatan Driver Dinamis Button (1:1 with Food / Shop / Farm / Build)
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
                                                _noteController.text.isNotEmpty
                                                    ? Icons.edit_note_rounded
                                                    : Icons.add_comment_outlined,
                                                size: 14,
                                                color: GageTheme.primary,
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  _noteController.text.isNotEmpty
                                                      ? 'Catatan: "${_noteController.text}"'
                                                      : '+ Tambah catatan / patokan driver',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: _noteController.text.isNotEmpty
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
                                  onPressed: () => _openLocationPicker(isDropoff: true),
                                  child: const Text('Ganti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Titik Jemput Info Row
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.radio_button_checked, size: 16, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : Colors.black87),
                                        children: [
                                          const TextSpan(text: 'Titik Jemput: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                          TextSpan(text: _currentPickupAddress),
                                        ],
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _openLocationPicker(isDropoff: false),
                                    child: const Text(
                                      'Ubah',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // =========================================================
                      // 3. SERVICE / TRIP DETAILS CARD (Matching Food Item Card)
                      // =========================================================
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                          boxShadow: cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isSend
                                            ? 'Pengiriman Paket GAGE Send'
                                            : (isCar ? 'Perjalanan GAGE Car' : 'Perjalanan GAGE Ride'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        currencyFormatter.format(_tierBaseFare),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                          color: GageTheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isSend
                                            ? 'Penerima: ${widget.recipientName ?? "Penerima"} (${widget.recipientPhone ?? "-"}) • ${widget.packageType ?? "Barang"} (${widget.weightTier ?? "<1kg"})'
                                            : 'Jarak ${widget.distanceKm.toStringAsFixed(1)} km • 1 Penumpang • Est. ~${_realisticEstimates["trip"] ?? 10} mnt',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 58,
                                  height: 58,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? GageTheme.darkCard : const Color(0xFFFFF1F0),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: GageTheme.primary.withValues(alpha: 0.2)),
                                  ),
                                  child: Image.asset(
                                    isSend
                                        ? 'assets/images/gage_send_3d.png'
                                        : (isCar ? 'assets/images/gage_car_3d.png' : 'assets/images/gage_ride_3d.png'),
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) => Icon(
                                      isSend
                                          ? Icons.local_shipping_rounded
                                          : (isCar ? Icons.directions_car_rounded : Icons.two_wheeler_rounded),
                                      color: GageTheme.primary,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // =========================================================
                      // 4. BERI TIP UNTUK DRIVER (Matching Image 2)
                      // =========================================================
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                          boxShadow: cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.favorite_rounded, color: Color(0xFFD97706), size: 16),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Beri Tip untuk Driver?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '100% tip apresiasi diserahkan penuh ke driver',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                                        ),
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // =========================================================
                      // 5. VOUCHER & DISKON PROMO CARD (1:1 with Food / Shop / Farm / Build)
                      // =========================================================
                      Container(
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
                          onTap: _openVoucherSelection,
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
                                    if (_appliedVoucherCode != null && _voucherDiscount > 0) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$_appliedVoucherCode (-${currencyFormatter.format(_voucherDiscount)})',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0D9488),
                                          ),
                                        ),
                                      ),
                                    ] else ...[
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
                              if (_appliedVoucherCode != null)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _appliedVoucherCode = null;
                                      _voucherDiscount = 0;
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(Icons.close_rounded, size: 18, color: Colors.grey),
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
                      ),

                      const SizedBox(height: 14),

                      // =========================================================
                      // 6. METODE PEMBAYARAN CARD (In-Page Tile + Deficit Box Image 3)
                      // =========================================================
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                          boxShadow: cardShadow,
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
                                  onPressed: () => _showPaymentMethodSheet(context, wallet),
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
                                    _selectedPaymentMethod == 'GAGEPAY'
                                        ? Icons.account_balance_wallet_rounded
                                        : (_selectedPaymentMethod == 'GAGEPAY_QRIS'
                                            ? Icons.qr_code_scanner_rounded
                                            : (_selectedPaymentMethod == 'GAGEPAY_COD'
                                                ? Icons.payments_outlined
                                                : (_selectedPaymentMethod == 'QRIS'
                                                    ? Icons.qr_code_2_rounded
                                                    : Icons.payments_rounded))),
                                    color: _selectedPaymentMethod.startsWith('GAGEPAY')
                                        ? const Color(0xFF0284C7)
                                        : (_selectedPaymentMethod == 'QRIS'
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
                                          _selectedPaymentMethod == 'GAGEPAY'
                                              ? 'GAGEPay'
                                              : (_selectedPaymentMethod == 'GAGEPAY_QRIS'
                                                  ? 'GAGEPay + QRIS'
                                                  : (_selectedPaymentMethod == 'GAGEPAY_COD'
                                                      ? 'GAGEPay + COD'
                                                      : (_selectedPaymentMethod == 'QRIS'
                                                          ? 'QRIS'
                                                          : 'Tunai ke Driver (COD)'))),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          _selectedPaymentMethod == 'GAGEPAY'
                                              ? 'Saldo Anda: ${currencyFormatter.format(wallet.balance)}'
                                              : (_selectedPaymentMethod == 'GAGEPAY_QRIS'
                                                  ? 'GAGEPay ${currencyFormatter.format(wallet.balance)} + QRIS ${currencyFormatter.format(_totalAmount - wallet.balance)}'
                                                  : (_selectedPaymentMethod == 'GAGEPAY_COD'
                                                      ? 'GAGEPay ${currencyFormatter.format(wallet.balance)} + Tunai ${currencyFormatter.format(_totalAmount - wallet.balance)}'
                                                      : (_selectedPaymentMethod == 'QRIS'
                                                          ? 'ShopeePay, GoPay, BCA, Mandiri'
                                                          : 'Bayar tunai ke driver'))),
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

                            // Deficit Box (Image 3)
                            if (_selectedPaymentMethod == 'GAGEPAY' && wallet.balance < _totalAmount) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Saldo GAGEPay kurang ${currencyFormatter.format(_totalAmount - wallet.balance)}',
                                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                            ),
                                          ],
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const GagePayScreen()),
                                            );
                                            setState(() {});
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Top Up',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: GageTheme.primary,
                                                  ),
                                                ),
                                                SizedBox(width: 2),
                                                Icon(Icons.chevron_right_rounded, size: 16, color: GageTheme.primary),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: GageTheme.primary,
                                              side: const BorderSide(color: GageTheme.primary),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              padding: const EdgeInsets.symmetric(vertical: 7),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            onPressed: () {
                                              _savePaymentPreference('GAGEPAY_COD');
                                            },
                                            child: const Text('GAGEPay + COD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFF0284C7),
                                              side: const BorderSide(color: Color(0xFF0284C7)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              padding: const EdgeInsets.symmetric(vertical: 7),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            onPressed: () {
                                              _savePaymentPreference('GAGEPAY_QRIS');
                                            },
                                            child: const Text('GAGEPay + QRIS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // =========================================================
                      // 7. RINGKASAN PEMBAYARAN (Matching Image 2)
                      // =========================================================
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Text(
                          'Ringkasan pembayaran',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                          boxShadow: cardShadow,
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              'Subtotal Tarif Perjalanan',
                              currencyFormatter.format(_tierBaseFare),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _buildSummaryRow(
                              'Biaya Layanan & Penanganan',
                              currencyFormatter.format(_adminFee),
                              isDark: isDark,
                            ),
                            if (_voucherDiscount > 0) ...[
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Diskon Voucher ($_appliedVoucherCode)',
                                '-${currencyFormatter.format(_voucherDiscount)}',
                                isDark: isDark,
                                isDiscount: true,
                              ),
                            ],
                            if (_driverTip > 0) ...[
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Tip Driver',
                                '+${currencyFormatter.format(_driverTip)}',
                                isDark: isDark,
                                isTip: true,
                              ),
                            ],
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Pembayaran',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  currencyFormatter.format(_totalAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: GageTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // =========================================================
                // 8. FLOATING STICKY PESAN SEKARANG BUTTON (Matching Image 2)
                // =========================================================
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
                        onPressed: _isPlacingOrder ? null : _handleCheckout,
                        child: _isPlacingOrder
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Pesan Sekarang',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTierRadioOption({
    required String id,
    required String title,
    required String badge,
    required Color badgeColor,
    required String desc,
    required int price,
    required bool isDark,
  }) {
    final isSelected = _selectedTier == id;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedTier = id);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              currencyFormatter.format(price),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? GageTheme.primary : (isDark ? Colors.white24 : Colors.grey.shade400),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    required bool isDark,
    bool isDiscount = false,
    bool isTip = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDiscount
                ? const Color(0xFF16A34A)
                : (isTip ? GageTheme.primary : (isDark ? Colors.white : Colors.black87)),
          ),
        ),
      ],
    );
  }
}
