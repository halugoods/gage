import 'dart:math' as math;
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
import 'package:gage_app/core/services/osrm_routing_service.dart';
import 'package:gage_app/core/constants/qris_engine.dart';
import 'package:gage_app/data/models/order_model.dart';
import 'package:gage_app/features/orders/presentation/order_detail_screen.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';
import 'package:gage_app/shared/widgets/gage_split_payment_banner.dart';
import 'package:gage_app/core/services/user_address_service.dart';
import 'package:gage_app/shared/widgets/full_screen_map_picker.dart';
import 'package:gage_app/features/wallet/presentation/gagepay_screen.dart';
import 'package:gage_app/core/services/merchant_discount_tier_service.dart';
import 'package:gage_app/data/mock/gage_voucher_data.dart';
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
  late double _currentDistanceKm;
  bool _protectShipment = false;
  UserSavedAddress? _matchedDropoffFavorite;
  UserSavedAddress? _matchedPickupFavorite;

  // Selected Payment Method: '', 'GAGEPAY', 'GAGEPAY_COD', 'GAGEPAY_QRIS', 'QRIS', 'COD'
  String _selectedPaymentMethod = '';
  bool _isLoadingPreference = true;

  // Driver Tip
  int _driverTip = 0;

  // Voucher Diskon
  String? _appliedVoucherCode;
  int _voucherDiscount = 0;
  bool _voucherManuallyDismissed = false;
  bool _isVoucherManualSelection = false;

  // Driver notes controllers
  final TextEditingController _pickupNoteController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  late final TextEditingController _recipientNameCtrl;
  late final TextEditingController _recipientPhoneCtrl;
  late final TextEditingController _packageDescCtrl;
  late String _packageType;
  late String _weightTier;
  bool _isPlacingOrder = false;

  static const List<String> _packageTypes = [
    'Barang Dagangan',
    'Dokumen',
    'Makanan / Minuman',
    'Pakaian & Tekstil',
    'Elektronik',
  ];

  static const List<String> _weightOptions = [
    '< 1 kg',
    '1 - 5 kg',
    '5 - 10 kg',
    '10 - 20 kg',
  ];

  double get _parsedWeightKg {
    if (_weightTier.contains('10 - 20')) return 15.0;
    if (_weightTier.contains('5 - 10')) return 8.0;
    if (_weightTier.contains('1 - 5')) return 3.0;
    return 1.0;
  }

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _currentPickupLocation = widget.pickupLocation;
    _currentDropoffLocation = widget.dropoffLocation;
    _currentPickupAddress = widget.pickupAddress;
    _currentDropoffAddress = widget.dropoffAddress;
    _currentDistanceKm = widget.distanceKm;

    final savedName = UserAddressService.getLastRecipientNameSync();
    final savedPhone = UserAddressService.getLastRecipientPhoneSync();
    final initialRecipientName = (widget.recipientName != null && widget.recipientName!.trim().isNotEmpty)
        ? widget.recipientName!
        : savedName;
    final initialRecipientPhone = (widget.recipientPhone != null && widget.recipientPhone!.trim().isNotEmpty)
        ? widget.recipientPhone!
        : savedPhone;

    _recipientNameCtrl = TextEditingController(text: initialRecipientName);
    _recipientPhoneCtrl = TextEditingController(text: initialRecipientPhone);
    _packageDescCtrl = TextEditingController(text: widget.itemDescription ?? '');
    _packageType = widget.packageType ?? 'Barang Dagangan';
    _weightTier = widget.weightTier ?? '< 1 kg';

    // Set initial tier matching REGULER / HEMAT radio options
    final lowerOpt = widget.rideOption.toLowerCase();
    _selectedTier = (lowerOpt.contains('hemat') || lowerOpt.contains('sameday')) ? 'HEMAT' : 'REGULER';

    final initialBalance = context.read<WalletProvider>().balance;
    _selectedPaymentMethod = initialBalance <= 0 ? '' : 'GAGEPAY';
    _loadPaymentPreference();
    _syncAutoDeliveryVoucher(notify: false);
    _resolveFavoriteMatches();
  }

  void _syncAutoDeliveryVoucher({bool notify = true}) {
    bool changed = false;
    final currentFare = _tierBaseFare;

    if (_appliedVoucherCode != null) {
      final current = GageVoucherData.findByCode(_appliedVoucherCode!);
      if (current != null) {
        final minOrder = (current['minOrder'] as num?)?.toInt() ?? 0;
        if (currentFare < minOrder) {
          _appliedVoucherCode = null;
          _voucherDiscount = 0;
          _isVoucherManualSelection = false;
          changed = true;
        } else {
          final maxDisc = GageVoucherData.calculateDiscount(current, currentFare);
          final clamped = maxDisc.clamp(0, currentFare);
          if (clamped != _voucherDiscount) {
            _voucherDiscount = clamped;
            changed = true;
          }
        }
      }
    }

    if (!_voucherManuallyDismissed && !_isVoucherManualSelection) {
      final best = widget.serviceType == 'send'
          ? GageVoucherData.bestEligibleDeliveryVoucher(
              serviceType: 'send',
              subtotal: currentFare,
            )
          : GageVoucherData.bestEligibleOrderVoucher(
              serviceType: widget.serviceType,
              subtotal: currentFare,
            );
      if (best != null) {
        final nextCode = best['code'] as String;
        final nextDiscount = GageVoucherData.calculateDiscount(best, currentFare).clamp(0, currentFare);
        if (_appliedVoucherCode != nextCode || _voucherDiscount != nextDiscount) {
          _appliedVoucherCode = nextCode;
          _voucherDiscount = nextDiscount;
          changed = true;
        }
      } else if (_appliedVoucherCode != null) {
        _appliedVoucherCode = null;
        _voucherDiscount = 0;
        changed = true;
      }
    }

    if (notify && changed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pickupNoteController.dispose();
    _noteController.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _packageDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMethod = prefs.getString('last_ride_payment_method');
    if (mounted) {
      final walletBalance = context.read<WalletProvider>().balance;
      setState(() {
        if (lastMethod != null && lastMethod.isNotEmpty) {
          var normalized = lastMethod.toUpperCase();
          if (normalized == 'TUNAI') normalized = 'COD';
          // Jangan pilih GAGEPay atau split secara otomatis ketika saldo GAGEPay Rp 0.
          if (walletBalance <= 0 && normalized.startsWith('GAGEPAY')) {
            _selectedPaymentMethod = '';
          } else {
            _selectedPaymentMethod = normalized;
          }
        } else {
          _selectedPaymentMethod = walletBalance <= 0 ? '' : 'GAGEPAY';
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
    final isHemat = tier == 'HEMAT';
    if (widget.serviceType == 'send') {
      return GagePricingService.calculateCustomerShippingFee(
        distanceKm: _currentDistanceKm,
        deliveryOption: isHemat ? 'HEMAT' : 'REGULER',
        weightKg: _parsedWeightKg,
      );
    }
    final isCar = widget.serviceType == 'car';
    final service = isCar
        ? (isHemat ? 'car_hemat' : 'car_reguler')
        : (isHemat ? 'hemat' : 'reguler');
    return GagePricingService.calculateCustomerRideFare(
      serviceType: service,
      distanceKm: _currentDistanceKm,
    );
  }

  int get _adminFee => GagePricingService.calculateAdminFee(paymentMethod: _selectedPaymentMethod);

  int get _protectionFee => (widget.serviceType == 'send' && _protectShipment) ? 1000 : 0;

  int get _totalAmount {
    final effectiveDiscount = _voucherDiscount.clamp(0, _tierBaseFare);
    final raw = _tierBaseFare - effectiveDiscount + _adminFee + _protectionFee + _driverTip;
    return raw.clamp(0, 99999999);
  }

  // Realistic estimates for Pracimantoro hills
  Map<String, int> get _realisticEstimates {
    final isCar = widget.serviceType == 'car';
    final dist = _currentDistanceKm;

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

  void _editAddressNote({
    TextEditingController? controller,
    String title = 'Catatan Patokan Driver',
  }) async {
    final activeController = controller ?? _noteController;
    final text = await GageFloatingSheet.showNoteInput(
      context: context,
      title: title,
      subtitle: 'Beri petunjuk lokasi agar driver mudah menemukan alamat',
      initialValue: activeController.text,
      hintText: 'Contoh: pagar hitam depan balai desa, sebelah masjid...',
    );
    if (text != null && mounted) {
      setState(() {
        activeController.text = text;
      });
      GageToast.show(context, 'Catatan patokan disimpan', type: GageToastType.success);
    }
  }

  Future<void> _openVoucherSelection() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (ctx) => VoucherSelectionScreen(
          serviceType: widget.serviceType,
          initialTabIndex: 0,
          initialAppliedCode: _appliedVoucherCode,
          currentSubtotal: _tierBaseFare,
          onSelectionChanged: (result) {
            if (!mounted) return;
            setState(() {
              if (result == null) {
                _appliedVoucherCode = null;
                _voucherDiscount = 0;
                _voucherManuallyDismissed = true;
                _isVoucherManualSelection = false;
              } else {
                _appliedVoucherCode = result['code'] as String?;
                _voucherDiscount = ((result['discount'] as num?)?.toInt() ?? 0).clamp(0, _tierBaseFare);
                _voucherManuallyDismissed = false;
                _isVoucherManualSelection = true;
              }
            });
          },
        ),
      ),
    );
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
                badge: wallet.balance <= 0
                    ? 'SALDO RP 0'
                    : (wallet.balance < totalPay
                        ? 'Kurang ${currencyFormatter.format(totalPay - wallet.balance)}'
                        : 'CUKUP'),
                badgeColor: wallet.balance < totalPay ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                trailingAction: wallet.balance < totalPay
                    ? InkWell(
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          Navigator.pop(ctx);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GagePayScreen()),
                          );
                          if (mounted) setState(() {});
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: GageTheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Top Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  if (wallet.balance <= 0) {
                    GageToast.show(
                      context,
                      'Saldo GAGEPay Rp 0. Silakan Top Up atau pilih QRIS / COD.',
                      type: GageToastType.warning,
                    );
                  } else if (wallet.balance < totalPay) {
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
    Widget? trailingAction,
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
      child: Material(
        type: MaterialType.transparency,
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
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingAction != null) ...[
                trailingAction,
                const SizedBox(width: 8),
              ],
              isSelected
                  ? const Icon(Icons.check_circle_rounded, color: GageTheme.primary, size: 20)
                  : Icon(Icons.circle_outlined, color: isDark ? Colors.white24 : Colors.grey.shade400, size: 20),
            ],
          ),
        ),
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
    if (widget.serviceType == 'send') {
      if (_recipientNameCtrl.text.trim().isEmpty ||
          _recipientPhoneCtrl.text.trim().isEmpty) {
        GageToast.show(
          context,
          'Lengkapi nama dan nomor HP penerima paket terlebih dahulu.',
          type: GageToastType.warning,
        );
        return;
      }
    }

    final wallet = context.read<WalletProvider>();

    if (_selectedPaymentMethod.trim().isEmpty) {
      GageToast.show(
        context,
        'Pilih metode pembayaran terlebih dahulu (COD, QRIS, atau Top Up GAGEPay).',
        type: GageToastType.warning,
      );
      _showPaymentMethodSheet(context, wallet);
      return;
    }

    if (_selectedPaymentMethod == 'GAGEPAY') {
      if (wallet.balance <= 0) {
        GageToast.show(
          context,
          'Saldo GAGEPay Rp 0. Silakan Top Up atau pilih COD / QRIS.',
          type: GageToastType.warning,
        );
        _showPaymentMethodSheet(context, wallet);
        return;
      }
      if (wallet.balance < _totalAmount) {
        GageToast.show(
          context,
          'Saldo GAGEPay kurang. Pilih opsi GAGEPay + QRIS atau GAGEPay + COD.',
          type: GageToastType.warning,
        );
        return;
      }
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

    final sendTierLabel = _selectedTier == 'HEMAT' ? 'Hemat' : 'Instant';
    String itemName = 'Layanan Antar Jemput Motor ($_selectedTier)';
    if (isCar) itemName = 'Layanan Mobil Penumpang ($_selectedTier)';
    if (isSend) itemName = 'Pengiriman Paket GAGE Send ($sendTierLabel)';

    final recipientNameVal = _recipientNameCtrl.text.trim();
    final recipientPhoneVal = _recipientPhoneCtrl.text.trim();
    if (recipientNameVal.isNotEmpty || recipientPhoneVal.isNotEmpty) {
      UserAddressService.saveLastRecipient(
        name: recipientNameVal,
        phone: recipientPhoneVal,
      );
    }
    final pkgDescVal = _packageDescCtrl.text.trim();
    final pickupNote = _pickupNoteController.text.trim();
    final dropoffNote = _noteController.text.trim();
    final combinedNotes = [
      if (pickupNote.isNotEmpty) 'Jemput: $pickupNote',
      if (dropoffNote.isNotEmpty) 'Tujuan: $dropoffNote',
    ].join(' | ');
    final normalizedPayMethod = _selectedPaymentMethod == 'COD' ? 'CASH_COD' : _selectedPaymentMethod;

    final resolvedTier = isSend
        ? (_selectedTier == 'HEMAT' ? 'HEMAT' : 'INSTANT')
        : _selectedTier;

    final orderData = {
      'id': invoiceNumber,
      'user_id': auth.currentUser?.id ?? '',
      'service_type': widget.serviceType,
      'delivery_option': resolvedTier,
      'tier': resolvedTier,
      'status': 'SEARCHING_DRIVER',
      'payment_status': normalizedPayMethod == 'CASH_COD' ? 'PENDING' : 'PAID',
      'pickup_address': _currentPickupAddress,
      'delivery_address': _currentDropoffAddress,
      'destination_address': _currentDropoffAddress,
      'pickup_lat': _currentPickupLocation.latitude,
      'pickup_lng': _currentPickupLocation.longitude,
      'delivery_lat': _currentDropoffLocation.latitude,
      'delivery_lng': _currentDropoffLocation.longitude,
      'destination_lat': _currentDropoffLocation.latitude,
      'destination_lng': _currentDropoffLocation.longitude,
      'distance_km': _currentDistanceKm,
      'payment_method': normalizedPayMethod,
      'fare_amount': _tierBaseFare,
      'shipping_fee': isSend ? _tierBaseFare : 0,
      'shipping_discount': isSend ? _voucherDiscount : 0,
      'admin_fee': _adminFee,
      'protection_fee': _protectionFee,
      if (isSend)
        'package_details': {
          'recipient_name': recipientNameVal,
          'recipient_phone': recipientPhoneVal,
          'package_type': _packageType,
          'weight_tier': _weightTier,
          if (pkgDescVal.isNotEmpty) 'description': pkgDescVal,
        },
      'discount_amount': _voucherDiscount,
      'voucher_code': _appliedVoucherCode,
      'driver_tip': _driverTip,
      'tip_amount': _driverTip,
      'total_amount': _totalAmount,
      'merchant_name': serviceName,
      'notes': combinedNotes,
      'items': [
        {
          'id': 'item-transport-01',
          'name': itemName,
          'price': _tierBaseFare,
          'quantity': 1,
          'subtotal': _tierBaseFare,
          'notes': combinedNotes.isNotEmpty
              ? combinedNotes
              : (isSend
                  ? 'Penerima: ${recipientNameVal.isNotEmpty ? recipientNameVal : "-"} (${recipientPhoneVal.isNotEmpty ? recipientPhoneVal : "-"}) • $_packageType ($weightLabelSafe)'
                  : 'Jemput sesuai titik peta'),
        }
      ],
      'created_at': now.millisecondsSinceEpoch ~/ 1000,
    };

    orderProvider.createOrder(orderData);
    final createdOrder =
        orderProvider.getOrderById(invoiceNumber) ?? OrderModel.fromJson(orderData);

    GageToast.show(
      context,
      'Pesanan berhasil dibuat! Nomor Invoice: $invoiceNumber',
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (ctx) => OrderDetailScreen(
          order: createdOrder,
        ),
      ),
    );
  }

  String get weightLabelSafe => _weightTier;

  Future<void> _resolveFavoriteMatches() async {
    final dropoffFav = await UserAddressService.findMatchingFavorite(
      location: _currentDropoffLocation,
    );
    final pickupFav = await UserAddressService.findMatchingFavorite(
      location: _currentPickupLocation,
    );
    final lastRecName = await UserAddressService.getLastRecipientName();
    final lastRecPhone = await UserAddressService.getLastRecipientPhone();
    if (!mounted) return;
    setState(() {
      _matchedDropoffFavorite = dropoffFav;
      _matchedPickupFavorite = pickupFav;
      if (dropoffFav != null && (dropoffFav.notes?.trim().isNotEmpty ?? false)) {
        if (_noteController.text.trim().isEmpty) {
          _noteController.text = dropoffFav.notes!.trim();
        }
      }
      if (pickupFav != null && (pickupFav.notes?.trim().isNotEmpty ?? false)) {
        if (_pickupNoteController.text.trim().isEmpty) {
          _pickupNoteController.text = pickupFav.notes!.trim();
        }
      }
      if (dropoffFav != null && (dropoffFav.recipientName?.trim().isNotEmpty ?? false)) {
        if (_recipientNameCtrl.text.trim().isEmpty) {
          _recipientNameCtrl.text = dropoffFav.recipientName!.trim();
        }
        if (_recipientPhoneCtrl.text.trim().isEmpty && (dropoffFav.recipientPhone?.trim().isNotEmpty ?? false)) {
          _recipientPhoneCtrl.text = dropoffFav.recipientPhone!.trim();
        }
      } else {
        if (_recipientNameCtrl.text.trim().isEmpty && lastRecName.isNotEmpty) {
          _recipientNameCtrl.text = lastRecName;
        }
        if (_recipientPhoneCtrl.text.trim().isEmpty && lastRecPhone.isNotEmpty) {
          _recipientPhoneCtrl.text = lastRecPhone;
        }
      }
    });
  }

  Future<void> _openLocationPicker({required bool isDropoff}) async {
    final activeFav = isDropoff ? _matchedDropoffFavorite : _matchedPickupFavorite;
    final result = await FullScreenMapPicker.open(
      context,
      title: isDropoff ? 'Ubah Alamat Pengantaran' : 'Ubah Titik Jemput',
      initialLocation: isDropoff ? _currentDropoffLocation : _currentPickupLocation,
      initialTitle: activeFav?.name,
      selectedFavoriteId: activeFav?.id,
    );
    if (!mounted || result == null) return;
    final resolvedAddr =
        result.fullAddress.isNotEmpty ? result.fullAddress : result.title;
    final matched = result.matchedFavorite ??
        await UserAddressService.findMatchingFavorite(
          location: result.location,
          preferredName: result.title,
        );
    if (!mounted) return;
    final fallbackKm = const Distance().as(
      LengthUnit.Kilometer,
      isDropoff ? _currentPickupLocation : result.location,
      isDropoff ? result.location : _currentDropoffLocation,
    );
    setState(() {
      if (isDropoff) {
        _currentDropoffLocation = result.location;
        _currentDropoffAddress = resolvedAddr;
        _matchedDropoffFavorite = matched;
        if (matched?.notes != null && matched!.notes!.trim().isNotEmpty) {
          _noteController.text = matched.notes!.trim();
        }
        if (matched?.recipientName != null && matched!.recipientName!.trim().isNotEmpty) {
          _recipientNameCtrl.text = matched.recipientName!.trim();
        }
        if (matched?.recipientPhone != null && matched!.recipientPhone!.trim().isNotEmpty) {
          _recipientPhoneCtrl.text = matched.recipientPhone!.trim();
        }
      } else {
        _currentPickupLocation = result.location;
        _currentPickupAddress = resolvedAddr;
        _matchedPickupFavorite = matched;
        if (matched?.notes != null && matched!.notes!.trim().isNotEmpty) {
          _pickupNoteController.text = matched.notes!.trim();
        }
      }
      if (fallbackKm > 0) {
        _currentDistanceKm = fallbackKm;
      }
      _syncAutoDeliveryVoucher(notify: false);
    });

    try {
      final route = await OsrmRoutingService.getRoute(
        _currentPickupLocation,
        _currentDropoffLocation,
      );
      if (mounted && route.distanceKm > 0) {
        setState(() {
          _currentDistanceKm = route.distanceKm;
          _syncAutoDeliveryVoucher(notify: false);
        });
      }
    } catch (_) {}
  }

  Widget _buildTipChip(int amount, String label) {
    final isSelected = _driverTip == amount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _driverTip = amount);
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? GageTheme.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? GageTheme.primary
                : (isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? GageTheme.primary
                : (isDark ? Colors.white70 : Colors.black87),
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
                            // Opsi Reguler / Instant
                            _buildTierRadioOption(
                              id: 'REGULER',
                              title: isSend ? 'Instant' : 'Reguler',
                              badge: isSend ? 'Langsung' : '~${_realisticEstimates["pickup"] ?? 4} min',
                              badgeColor: const Color(0xFF3B82F6),
                              desc: isSend
                                  ? 'Kurir langsung menjemput dan mengantar paket ke tujuan'
                                  : 'Penjemputan prioritas dengan tarif standar langsung ke tujuan',
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
                              desc: isSend
                                  ? 'Tarif hemat dengan jadwal pengantaran rute gabungan'
                                  : 'Tarif lebih ekonomis untuk perjalanan jarak dekat hingga menengah',
                              price: _calculateTierFare('HEMAT'),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // =========================================================
                      // 2. COMBINED LOKASI CARD (Titik Jemput / Pengirim -> Titik Tujuan / Pengantaran)
                      // =========================================================
                      Container(
                        key: const ValueKey('checkout_combined_route_card'),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                          boxShadow: cardShadow,
                        ),
                        child: Column(
                          children: [
                            _buildCheckoutLocationRow(
                              isDark: isDark,
                              title: isSend ? 'Alamat Pengirim' : 'Titik Jemput',
                              defaultBadgeLabel: isSend ? 'Pengirim' : 'Jemput',
                              address: _currentPickupAddress,
                              location: _currentPickupLocation,
                              matchedFavorite: _matchedPickupFavorite,
                              onPickLocation: () => _openLocationPicker(isDropoff: false),
                              showDriverNoteButton: true,
                              noteText: _pickupNoteController.text,
                              onEditNote: () => _editAddressNote(
                                controller: _pickupNoteController,
                                title: isSend ? 'Catatan Alamat Pengirim' : 'Catatan Titik Jemput',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 68,
                                    child: Center(
                                      child: _RouteDotsConnector(
                                        key: const ValueKey('checkout_route_dots_connector'),
                                        isDark: isDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Divider(
                                      height: 1,
                                      thickness: 0.8,
                                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildCheckoutLocationRow(
                              isDark: isDark,
                              title: isSend ? 'Alamat Pengantaran' : 'Titik Tujuan',
                              defaultBadgeLabel: 'Utama',
                              address: _currentDropoffAddress,
                              location: _currentDropoffLocation,
                              matchedFavorite: _matchedDropoffFavorite,
                              onPickLocation: () => _openLocationPicker(isDropoff: true),
                              showDriverNoteButton: true,
                              noteText: _noteController.text,
                              onEditNote: () => _editAddressNote(
                                controller: _noteController,
                                title: isSend ? 'Catatan Alamat Penerima' : 'Catatan Titik Tujuan',
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
                                            ? 'Penerima: ${_recipientNameCtrl.text.trim().isEmpty ? "Belum diisi" : _recipientNameCtrl.text.trim()} (${_recipientPhoneCtrl.text.trim().isEmpty ? "-" : _recipientPhoneCtrl.text.trim()}) • $_packageType ($_weightTier)'
                                            : 'Jarak ${_currentDistanceKm.toStringAsFixed(1)} km • 1 Penumpang • Est. ~${_realisticEstimates["trip"] ?? 10} mnt',
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
                            if (isSend) ...[
                              const Divider(height: 20),
                              _buildSendPackageForm(isDark),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.verified_user_rounded,
                                      color: Color(0xFF0D9488),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Proteksi Pengiriman Barang',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'Perlindungan barang rusak/hilang (+Rp 1.000)',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: _protectShipment,
                                    activeTrackColor: GageTheme.primary,
                                    onChanged: (val) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _protectShipment = val);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // =========================================================
                      // 4. VOUCHER & DISKON PROMO CARD (1:1 with Food / Shop / Farm / Build)
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
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      'Voucher',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    if (_appliedVoucherCode != null && _voucherDiscount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                '-${MerchantDiscountTierService.formatRb(_voucherDiscount.clamp(0, _tierBaseFare))}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0D9488),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {
                                                setState(() {
                                                  _appliedVoucherCode = null;
                                                  _voucherDiscount = 0;
                                                  _voucherManuallyDismissed = true;
                                                  _isVoucherManualSelection = false;
                                                });
                                              },
                                              child: const Icon(
                                                Icons.close_rounded,
                                                size: 13,
                                                color: Color(0xFF0D9488),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Text(
                                        'Gunakan / masukkan kode',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark ? Colors.white60 : Colors.grey.shade500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark ? Colors.white38 : Colors.black45,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // =========================================================
                      // 5. METODE PEMBAYARAN CARD (In-Page Tile + Deficit Box Image 3)
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _selectedPaymentMethod.isEmpty ? 'Pilih' : 'Ganti',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: GageTheme.primary,
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, size: 16, color: GageTheme.primary),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Selected Payment Method Display
                            InkWell(
                              onTap: () => _showPaymentMethodSheet(context, wallet),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedPaymentMethod.isEmpty
                                        ? GageTheme.primary.withValues(alpha: 0.45)
                                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _selectedPaymentMethod.isEmpty
                                          ? Icons.account_balance_wallet_outlined
                                          : (_selectedPaymentMethod == 'GAGEPAY'
                                              ? Icons.account_balance_wallet_rounded
                                              : (_selectedPaymentMethod == 'GAGEPAY_QRIS'
                                                  ? Icons.qr_code_scanner_rounded
                                                  : (_selectedPaymentMethod == 'GAGEPAY_COD'
                                                      ? Icons.payments_outlined
                                                      : (_selectedPaymentMethod == 'QRIS'
                                                          ? Icons.qr_code_2_rounded
                                                          : Icons.payments_rounded)))),
                                      color: _selectedPaymentMethod.isEmpty
                                          ? GageTheme.primary
                                          : (_selectedPaymentMethod.startsWith('GAGEPAY')
                                              ? const Color(0xFF0284C7)
                                              : (_selectedPaymentMethod == 'QRIS'
                                                  ? GageTheme.primary
                                                  : const Color(0xFF16A34A))),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedPaymentMethod.isEmpty
                                                ? 'Pilih Metode Pembayaran'
                                                : (_selectedPaymentMethod == 'GAGEPAY'
                                                    ? 'GAGEPay'
                                                    : (_selectedPaymentMethod == 'GAGEPAY_QRIS'
                                                        ? 'GAGEPay + QRIS'
                                                        : (_selectedPaymentMethod == 'GAGEPAY_COD'
                                                            ? 'GAGEPay + COD'
                                                            : (_selectedPaymentMethod == 'QRIS'
                                                                ? 'QRIS'
                                                                : 'Tunai ke Driver (COD)')))),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            _selectedPaymentMethod.isEmpty
                                                ? (wallet.balance <= 0
                                                    ? 'Saldo GAGEPay Rp 0 • Ketuk untuk memilih metode pembayaran'
                                                    : 'Ketuk untuk memilih GAGEPay, QRIS, atau COD')
                                                : (_selectedPaymentMethod == 'GAGEPAY'
                                                    ? 'Saldo Anda: ${currencyFormatter.format(wallet.balance)}'
                                                    : (_selectedPaymentMethod == 'GAGEPAY_QRIS'
                                                        ? 'GAGEPay ${currencyFormatter.format(wallet.balance)} + QRIS ${currencyFormatter.format(_totalAmount - wallet.balance)}'
                                                        : (_selectedPaymentMethod == 'GAGEPAY_COD'
                                                            ? 'GAGEPay ${currencyFormatter.format(wallet.balance)} + Tunai ${currencyFormatter.format(_totalAmount - wallet.balance)}'
                                                            : (_selectedPaymentMethod == 'QRIS'
                                                                ? 'ShopeePay, GoPay, BCA, Mandiri'
                                                                : 'Bayar tunai ke driver')))),
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
                            ),

                            // Banner Split Payment hanya saat saldo > 0 tapi < _totalAmount dan user memilih GAGEPay
                            if (_selectedPaymentMethod == 'GAGEPAY' &&
                                wallet.balance > 0 &&
                                wallet.balance < _totalAmount) ...[
                              const SizedBox(height: 10),
                              GageSplitPaymentBanner(
                                walletBalance: wallet.balance,
                                totalAmount: _totalAmount,
                                currencyFormatter: currencyFormatter,
                                onTopUp: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const GagePayScreen()),
                                  );
                                  if (mounted) setState(() {});
                                },
                                onSelectCodSplit: () {
                                  _savePaymentPreference('GAGEPAY_COD');
                                },
                                onSelectQrisSplit: () {
                                  _savePaymentPreference('GAGEPAY_QRIS');
                                },
                                onSelectPureCod: () {
                                  _savePaymentPreference('COD');
                                },
                                onSelectPureQris: () {
                                  _savePaymentPreference('QRIS');
                                },
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // =========================================================
                      // 6. RINGKASAN PEMBAYARAN (Matching Image 2)
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
                            if (_protectionFee > 0) ...[
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Proteksi Pengiriman Barang',
                                currencyFormatter.format(_protectionFee),
                                isDark: isDark,
                              ),
                            ],
                            if (_voucherDiscount > 0) ...[
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Diskon Voucher',
                                '- ${currencyFormatter.format(_voucherDiscount)}',
                                badgeText: (_appliedVoucherCode != null && _appliedVoucherCode!.trim().isNotEmpty)
                                    ? _appliedVoucherCode!.trim().toUpperCase()
                                    : 'VOUCHER',
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

                      const SizedBox(height: 14),

                      // =========================================================
                      // 7. BERI TIP UNTUK DRIVER (Matching Image 2)
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
        setState(() {
          _selectedTier = id;
          _syncAutoDeliveryVoucher(notify: false);
        });
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

  Widget _buildCheckoutLocationRow({
    required bool isDark,
    required String title,
    required String defaultBadgeLabel,
    required String address,
    required LatLng location,
    required UserSavedAddress? matchedFavorite,
    required VoidCallback onPickLocation,
    bool showDriverNoteButton = false,
    String? noteText,
    VoidCallback? onEditNote,
  }) {
    final effectiveNote = noteText ?? _noteController.text;
    final favName = matchedFavorite?.name;
    final isFav = favName != null && favName.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MiniLocationPreviewMap(
          location: location,
          size: 68,
          borderRadius: 14,
          onTap: onPickLocation,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                address,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade300 : Colors.black87,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (showDriverNoteButton) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onEditNote ?? () => _editAddressNote(),
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
                                effectiveNote.isNotEmpty
                                    ? Icons.edit_note_rounded
                                    : Icons.add_comment_outlined,
                                size: 14,
                                color: GageTheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  effectiveNote.isNotEmpty
                                      ? 'Catatan: "$effectiveNote"'
                                      : '+ Tambah catatan / patokan driver',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: effectiveNote.isNotEmpty
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
                    ),
                    if (isFav) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? GageTheme.primary.withValues(alpha: 0.22)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: GageTheme.primary.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bookmark_rounded, size: 10, color: GageTheme.primary),
                            const SizedBox(width: 3),
                            Text(
                              'Favorit • $favName',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : GageTheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
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
          onPressed: onPickLocation,
          child: const Text('Ganti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    required bool isDark,
    String? badgeText,
    bool isDiscount = false,
    bool isTip = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: badgeText != null ? 13 : 12.5,
                    fontWeight: isDiscount ? FontWeight.w600 : FontWeight.normal,
                    color: isDiscount
                        ? const Color(0xFF16A34A)
                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                  ),
                ),
              ),
              if (badgeText != null && badgeText.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF16A34A).withValues(alpha: 0.18)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF22C55E).withValues(alpha: 0.45)
                          : const Color(0xFF86EFAC),
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isDiscount ? FontWeight.bold : FontWeight.w600,
            color: isDiscount
                ? const Color(0xFF16A34A)
                : (isTip ? GageTheme.primary : (isDark ? Colors.white : Colors.black87)),
          ),
        ),
      ],
    );
  }

  Widget _buildSendPackageForm(bool isDark) {
    final fieldFill = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final fieldBorder = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Barang',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _recipientNameCtrl,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 16, color: textSecondary),
                  hintText: 'Nama Penerima',
                  hintStyle: TextStyle(fontSize: 11.5, color: textSecondary),
                  filled: true,
                  fillColor: fieldFill,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorder),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _recipientPhoneCtrl,
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.phone_outlined, size: 16, color: textSecondary),
                  hintText: 'No. HP Penerima',
                  hintStyle: TextStyle(fontSize: 11.5, color: textSecondary),
                  filled: true,
                  fillColor: fieldFill,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: fieldBorder),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _packageDescCtrl,
          style: TextStyle(fontSize: 12, color: textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.inventory_2_outlined, size: 16, color: textSecondary),
            hintText: 'Catatan isi paket (opsional, misal: barang pecah belah)',
            hintStyle: TextStyle(fontSize: 11.5, color: textSecondary),
            filled: true,
            fillColor: fieldFill,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: fieldBorder),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Kategori Paket',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _packageTypes.map((type) {
              final selected = _packageType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _packageType = type);
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? GageTheme.primary : fieldFill,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? GageTheme.primary : fieldBorder,
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Estimasi Berat Paket',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _weightOptions.map((weight) {
              final selected = _weightTier == weight;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _weightTier = weight;
                      _syncAutoDeliveryVoucher(notify: false);
                    });
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? GageTheme.primary : fieldFill,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? GageTheme.primary : fieldBorder,
                      ),
                    ),
                    child: Text(
                      weight,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _RouteDotsConnector extends StatefulWidget {
  final bool isDark;

  const _RouteDotsConnector({
    super.key,
    required this.isDark,
  });

  @override
  State<_RouteDotsConnector> createState() => _RouteDotsConnectorState();
}

class _RouteDotsConnectorState extends State<_RouteDotsConnector>
    with SingleTickerProviderStateMixin {
  static const int _dotCount = 4;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = disableAnimations ? 0.0 : _controller.value * 2 * math.pi;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_dotCount, (i) {
              final wave = disableAnimations
                  ? (1.0 - (i / (_dotCount * 1.5)))
                  : (0.5 + 0.5 * math.sin(t - (i * 0.9)));
              final routeColor = Color.lerp(
                const Color(0xFF16A34A),
                GageTheme.primary,
                i / (_dotCount - 1),
              )!;
              final idleColor = widget.isDark
                  ? Colors.white24
                  : const Color(0xFFCBD5E1);
              final dotColor = Color.lerp(idleColor, routeColor, 0.4 + (0.6 * wave))!;
              final size = 4.0 + (1.5 * wave);

              return Padding(
                padding: EdgeInsets.only(bottom: i < _dotCount - 1 ? 3.0 : 0),
                child: SizedBox(
                  width: 8,
                  height: 6,
                  child: Center(
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        boxShadow: wave > 0.65
                            ? [
                                BoxShadow(
                                  color: routeColor.withValues(alpha: 0.3 * wave),
                                  blurRadius: 3,
                                  spreadRadius: 0.5,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
