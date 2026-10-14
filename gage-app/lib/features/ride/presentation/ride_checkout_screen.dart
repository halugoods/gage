import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/order/presentation/order_tracking_screen.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

class RideCheckoutScreen extends StatefulWidget {
  final String serviceType; // 'ride' or 'car'
  final String rideOption; // 'standard' (reguler) or 'hemat'
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final String pickupAddress;
  final String dropoffAddress;
  final double distanceKm;
  final int baseFare;

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
  });

  @override
  State<RideCheckoutScreen> createState() => _RideCheckoutScreenState();
}

class _RideCheckoutScreenState extends State<RideCheckoutScreen> {
  String? _selectedPaymentMethod; // null jika user baru belum pernah pilih
  bool _isLoadingPreference = true;

  // Voucher Diskon (diaktifkan di checkout)
  String? _appliedVoucherCode;
  int _voucherDiscount = 0;

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
        _selectedPaymentMethod = lastMethod; // Akan null jika pertama kali
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

  // Estimasi waktu realistis jalan perbukitan Pracimantoro
  Map<String, int> get _realisticEstimates {
    final isCar = widget.serviceType == 'car';
    final dist = widget.distanceKm;

    // Motor: jemput 3-5m, perjalanan 3-4 m/km
    // Mobil: jemput 5-8m, perjalanan 4-5 m/km
    final pickupMins = isCar ? 6 : 4;
    final tripMins = isCar ? (dist * 4.5).round().clamp(5, 60) : (dist * 3.5).round().clamp(4, 50);
    return {
      'pickup': pickupMins,
      'trip': tripMins,
      'total': pickupMins + tripMins,
    };
  }

  int get _adminFee => 1000;

  int get _totalAmount {
    final raw = widget.baseFare - _voucherDiscount + _adminFee;
    return raw.clamp(0, 99999999);
  }

  void _showVoucherPickerModal() {
    final List<Map<String, dynamic>> availableVouchers = [
      {
        'code': 'GAGEHEMAT',
        'title': 'Diskon Perjalanan Rp 2.000',
        'desc': 'Khusus pengguna GAGE Ride & Car Pracimantoro',
        'discount': 2000,
      },
      {
        'code': 'PRACICAR',
        'title': 'Diskon GAGE Car Rp 3.000',
        'desc': 'Keluarga & Rombongan nyaman keliling Wonogiri',
        'discount': 3000,
      },
      {
        'code': 'PELAJARPRACI',
        'title': 'Diskon Pelajar Rp 1.500',
        'desc': 'Tarif hemat pulang pergi sekolah se-Kecamatan',
        'discount': 1500,
      },
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    GageFloatingSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pilih Voucher Diskon',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
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
          ...availableVouchers.map((v) {
            final isApplied = _appliedVoucherCode == v['code'];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isApplied
                    ? (isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFF1F0))
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isApplied ? GageTheme.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                  width: isApplied ? 1.5 : 1.0,
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isApplied
                        ? GageTheme.primary.withValues(alpha: 0.12)
                        : (isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.confirmation_number_rounded, color: isApplied ? GageTheme.primary : Colors.grey.shade600, size: 20),
                ),
                title: Text(v['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isDark ? Colors.white : Colors.black87)),
                subtitle: Text(v['desc'], style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isApplied ? Colors.grey.shade300 : GageTheme.primary,
                    foregroundColor: isApplied ? Colors.black87 : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    visualDensity: VisualDensity.compact,
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isApplied) {
                        _appliedVoucherCode = null;
                        _voucherDiscount = 0;
                      } else {
                        _appliedVoucherCode = v['code'];
                        _voucherDiscount = v['discount'] as int;
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: Text(isApplied ? 'Batal' : 'Pakai', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showQrisModal(VoidCallback onConfirmed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    GageFloatingSheet.show(
      context: context,
      isScrollControlled: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QRIS Dinamis GAGE Pay',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
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
          const SizedBox(height: 6),
          Text(
            'Scan kode QRIS ini dengan BCA Mobile, GoPay, OVO, ShopeePay, atau m-Banking Anda.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/qris_static.png',
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Container(
                      height: 180,
                      width: 180,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(Icons.qr_code_2_rounded, size: 90, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currencyFormatter.format(_totalAmount),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: GageTheme.primary),
                  ),
                  const Text('NMID: ID102003847291 • GAGE Pracimantoro', style: TextStyle(fontSize: 10, color: Colors.black54)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: const Text('Saya Sudah Bayar via QRIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              onPressed: () {
                Navigator.pop(context);
                onConfirmed();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _processBooking() {
    if (_selectedPaymentMethod == null) {
      GageToast.show(
        context,
        'Silakan pilih salah satu metode pembayaran terlebih dahulu!',
        type: GageToastType.error,
      );
      return;
    }

    if (_selectedPaymentMethod == 'gagepay') {
      final wallet = context.read<WalletProvider>();
      if (wallet.balance < _totalAmount) {
        GageToast.show(
          context,
          'Saldo GAGEPay (${currencyFormatter.format(wallet.balance)}) tidak mencukupi total $_totalAmount!',
          type: GageToastType.error,
        );
        return;
      }
    }

    if (_selectedPaymentMethod == 'qris') {
      _showQrisModal(() => _finalizeRideOrder());
    } else {
      _finalizeRideOrder();
    }
  }

  void _finalizeRideOrder() {
    final auth = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();
    final user = auth.currentUser;
    final userId = user?.id ?? 'usr-cust-01';

    // Buat format invoice unik per user
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final userSuffix = (user?.name ?? 'USER').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final shortUser = userSuffix.length >= 4 ? userSuffix.substring(0, 4) : userSuffix.padRight(4, 'X');
    final hashSuffix = now.millisecondsSinceEpoch.toString().substring(8);
    final serviceCode = widget.serviceType == 'car' ? 'CR' : (widget.rideOption == 'hemat' ? 'RH' : 'RD');
    final invoiceNumber = 'INV/GG/$dateStr/$serviceCode/$shortUser-$hashSuffix';

    final orderData = {
      'id': 'ord-ride-${now.millisecondsSinceEpoch}',
      'order_number': invoiceNumber,
      'user_id': userId,
      'merchant_id': 'mch-gage-transport',
      'merchant_name': widget.serviceType == 'car' ? 'GAGE Car Pracimantoro' : 'GAGE Ride Pracimantoro',
      'merchant_address': widget.pickupAddress,
      'driver_name': widget.serviceType == 'car' ? 'Budi Santoso (Avanza AD 1892 TG)' : 'Slamet Widodo (Vario AD 4521 WN)',
      'driver_plate': widget.serviceType == 'car' ? 'AD 1892 TG' : 'AD 4521 WN',
      'driver_phone': '081234567890',
      'status': 'ON_DELIVERY',
      'payment_method': _selectedPaymentMethod?.toUpperCase() ?? 'GAGEPAY',
      'payment_status': 'PAID',
      'total_amount': _totalAmount,
      'items_subtotal': widget.baseFare,
      'shipping_fee': 0,
      'shipping_discount': _voucherDiscount,
      'admin_fee': _adminFee,
      'delivery_address': widget.dropoffAddress,
      'distance_km': widget.distanceKm,
      'tracking_token': 'trk-ride-${now.millisecondsSinceEpoch}',
      'items': [
        {
          'id': 'item-ride-01',
          'name': widget.serviceType == 'car'
              ? 'Perjalanan GAGE Car (${widget.distanceKm.toStringAsFixed(1)} km)'
              : 'Perjalanan GAGE Ride ${widget.rideOption == "hemat" ? "Hemat" : "Reguler"} (${widget.distanceKm.toStringAsFixed(1)} km)',
          'price': widget.baseFare,
          'quantity': 1,
          'subtotal': widget.baseFare,
          'notes': _noteController.text.isNotEmpty ? _noteController.text : 'Jemput sesuai titik peta',
        }
      ],
      'created_at': now.millisecondsSinceEpoch ~/ 1000,
    };

    orderProvider.createOrder(orderData);

    GageToast.show(
      context,
      'Pesanan berhasil dibuat! Nomor Invoice: $invoiceNumber',
    );

    // Buka screen order tracking
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (ctx) => OrderTrackingScreen(
          orderId: orderData['id'] as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final isCar = widget.serviceType == 'car';
    final est = _realisticEstimates;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isCar ? 'Checkout GAGE Car' : 'Checkout GAGE Ride',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0.5,
      ),
      body: _isLoadingPreference
          ? const Center(child: CircularProgressIndicator(color: GageTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Kartu Estimasi Waktu Realistis
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isCar
                          ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
                          : (isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFF1F0)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCar
                            ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFFBFDBFE))
                            : (isDark ? GageTheme.primary : const Color(0xFFFFCCC7)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? GageTheme.darkSurface : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCar ? const Color(0xFF3B82F6) : GageTheme.primary,
                            ),
                          ),
                          child: Image.asset(
                            isCar ? 'assets/images/gage_car_3d.png' : 'assets/images/gage_ride_3d.png',
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => Icon(
                              isCar ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                              color: isCar ? const Color(0xFF1D4ED8) : GageTheme.primary,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Driver Tiba dlm ~${est["pickup"]} Menit',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Jarak ${widget.distanceKm.toStringAsFixed(1)} km • Estimasi durasi sampai tujuan ~${est["trip"]} mnt',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Rincian Titik Rute Penjemputan & Tujuan
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? GageTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Perjalanan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.radio_button_checked, color: GageTheme.primary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Titik Jemput',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.pickupAddress,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 4, bottom: 4),
                          child: Container(width: 2, height: 16, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_rounded, color: GageTheme.primary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Titik Tujuan',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.dropoffAddress,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Catatan driver (contoh: tunggu di depan gang mawar)',
                            hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : Colors.black38),
                            prefixIcon: Icon(Icons.note_alt_outlined, size: 18, color: isDark ? Colors.grey.shade400 : Colors.black45),
                            filled: true,
                            fillColor: isDark ? GageTheme.darkCard : Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: isDark ? GageTheme.darkBorder : Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: isDark ? GageTheme.darkBorder : Colors.grey.shade300),
                            ),
                          ),
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Voucher Diskon Perjalanan (Bisa diotak-atik)
                  Container(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.confirmation_number_rounded, color: GageTheme.primary, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Voucher Diskon',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: _showVoucherPickerModal,
                              child: const Text(
                                'Ganti / Pilih ▾',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GageTheme.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_appliedVoucherCode != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFF1F0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFCCC7)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: GageTheme.primary, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Voucher $_appliedVoucherCode (Hemat ${currencyFormatter.format(_voucherDiscount)})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : GageTheme.primary,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => setState(() {
                                    _appliedVoucherCode = null;
                                    _voucherDiscount = 0;
                                  }),
                                  child: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white70 : Colors.black45),
                                ),
                              ],
                            ),
                          )
                        else
                          Text('Belum ada voucher terpasang.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Pilihan Metode Pembayaran (Wajib pilih user baru / Ingat user lama / Lengkap dgn QRIS)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? GageTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedPaymentMethod == null
                            ? Colors.orange.shade400
                            : (isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                        width: _selectedPaymentMethod == null ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Metode Pembayaran',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (_selectedPaymentMethod == null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                                child: Text('Wajib Pilih', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Opsi 1: GAGEPay Saldo
                        _buildPaymentOptionTile(
                          id: 'gagepay',
                          title: 'GAGEPay Saldo',
                          subtitle: 'Saldo Anda: ${currencyFormatter.format(wallet.balance)}',
                          icon: Icons.account_balance_wallet_rounded,
                          iconColor: GageTheme.primary,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 8),

                        // Opsi 2: QRIS Dinamis
                        _buildPaymentOptionTile(
                          id: 'qris',
                          title: 'QRIS Dinamis',
                          subtitle: 'Scan via BCA Mobile, GoPay, ShopeePay, OVO',
                          icon: Icons.qr_code_2_rounded,
                          iconColor: const Color(0xFF0284C7),
                          isDark: isDark,
                        ),

                        const SizedBox(height: 8),

                        // Opsi 3: Tunai ke Driver
                        _buildPaymentOptionTile(
                          id: 'cash',
                          title: 'Tunai ke Driver',
                          subtitle: 'Bayar uang tunai langsung ke driver saat sampai',
                          icon: Icons.payments_rounded,
                          iconColor: const Color(0xFFD97706),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5. Ringkasan Rincian Pembayaran
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? GageTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rincian Pembayaran',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isCar
                                  ? 'Tarif Dasar GAGE Car'
                                  : 'Tarif GAGE Ride (${widget.rideOption == "hemat" ? "Hemat" : "Reguler"})',
                              style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey.shade300 : Colors.black87),
                            ),
                            Text(
                              currencyFormatter.format(widget.baseFare),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        if (_voucherDiscount > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Voucher Diskon ($_appliedVoucherCode)',
                                style: const TextStyle(fontSize: 12.5, color: GageTheme.primary, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '- ${currencyFormatter.format(_voucherDiscount)}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: GageTheme.primary),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Biaya Layanan & Asuransi',
                              style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey.shade300 : Colors.black87),
                            ),
                            Text(
                              currencyFormatter.format(_adminFee),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 20, color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estimasi Total Bayar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              currencyFormatter.format(_totalAmount),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: GageTheme.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? GageTheme.darkSurface : Colors.white,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
          border: Border(top: BorderSide(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pembayaran',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.black54),
                  ),
                  Text(
                    currencyFormatter.format(_totalAmount),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: GageTheme.primary),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPaymentMethod == null
                      ? (isDark ? Colors.grey.shade700 : Colors.grey.shade400)
                      : GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  elevation: 0,
                ),
                onPressed: _processBooking,
                child: Row(
                  children: [
                    Text(
                      _selectedPaymentMethod == null
                          ? 'Pilih Pembayaran'
                          : (isCar ? 'Pesan GAGE Car' : 'Pesan GAGE Ride'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    final isSelected = _selectedPaymentMethod == id;

    return InkWell(
      onTap: () => _savePaymentPreference(id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFF1F0))
              : (isDark ? GageTheme.darkCard : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? GageTheme.primary : (isDark ? GageTheme.darkBorder : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? GageTheme.primary : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
