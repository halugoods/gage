import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/fare_calculation_service.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';

/// Modal iOS Floating Bottom Sheet untuk mengedit parameter tarif dinamis
/// per kategori (Motor, Mobil, Pengantaran, Biaya Layanan)
class TariffEditBottomSheet extends StatefulWidget {
  final String category; // 'motor', 'car', 'delivery', 'service_fee'
  final VoidCallback onSaved;

  const TariffEditBottomSheet({
    super.key,
    required this.category,
    required this.onSaved,
  });

  static Future<void> show({
    required BuildContext context,
    required String category,
    required VoidCallback onSaved,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TariffEditBottomSheet(category: category, onSaved: onSaved),
    );
  }

  @override
  State<TariffEditBottomSheet> createState() => _TariffEditBottomSheetState();
}

class _TariffEditBottomSheetState extends State<TariffEditBottomSheet> {
  // Motor Controllers
  late TextEditingController _rideRegBaseKmCtrl;
  late TextEditingController _rideRegBaseCtrl;
  late TextEditingController _rideRegPerKmCtrl;
  late TextEditingController _rideHematBaseKmCtrl;
  late TextEditingController _rideHematBaseCtrl;
  late TextEditingController _rideHematPerKmCtrl;

  // Car Controllers
  late TextEditingController _carBaseKmCtrl;
  late TextEditingController _carBaseCtrl;
  late TextEditingController _carPerKmCtrl;

  // Delivery Controllers
  late TextEditingController _deliveryBaseKmCtrl;
  late TextEditingController _deliveryBaseCtrl;
  late TextEditingController _deliveryPerKmCtrl;
  late TextEditingController _multiMerchantBonusCtrl;

  // Service Fee Controllers
  late TextEditingController _cashlessFeeCtrl;
  late TextEditingController _codBaseFeeCtrl;
  late TextEditingController _codExtraFeeCtrl;

  @override
  void initState() {
    super.initState();
    _rideRegBaseKmCtrl = TextEditingController(text: GagePricingService.rideRegulerBaseKm.toStringAsFixed(1));
    _rideRegBaseCtrl = TextEditingController(text: GagePricingService.rideRegulerBase.toString());
    _rideRegPerKmCtrl = TextEditingController(text: GagePricingService.rideRegulerPerKm.toString());
    _rideHematBaseKmCtrl = TextEditingController(text: GagePricingService.rideHematBaseKm.toStringAsFixed(1));
    _rideHematBaseCtrl = TextEditingController(text: GagePricingService.rideHematBase.toString());
    _rideHematPerKmCtrl = TextEditingController(text: GagePricingService.rideHematPerKm.toString());

    _carBaseKmCtrl = TextEditingController(text: GagePricingService.carBaseKm.toStringAsFixed(1));
    _carBaseCtrl = TextEditingController(text: GagePricingService.carBase.toString());
    _carPerKmCtrl = TextEditingController(text: GagePricingService.carPerKm.toString());

    _deliveryBaseKmCtrl = TextEditingController(text: GagePricingService.deliveryBaseKm.toStringAsFixed(1));
    _deliveryBaseCtrl = TextEditingController(text: GagePricingService.deliveryBase.toString());
    _deliveryPerKmCtrl = TextEditingController(text: GagePricingService.deliveryPerKm.toString());
    _multiMerchantBonusCtrl = TextEditingController(text: GagePricingService.multiMerchantStopBonus.toString());

    _cashlessFeeCtrl = TextEditingController(text: GagePricingService.adminFeeCashlessPerMerchant.toString());
    _codBaseFeeCtrl = TextEditingController(text: GagePricingService.adminFeeCashCodBase.toString());
    _codExtraFeeCtrl = TextEditingController(text: GagePricingService.adminFeeCashCodExtraPerMerchant.toString());
  }

  @override
  void dispose() {
    _rideRegBaseKmCtrl.dispose();
    _rideRegBaseCtrl.dispose();
    _rideRegPerKmCtrl.dispose();
    _rideHematBaseKmCtrl.dispose();
    _rideHematBaseCtrl.dispose();
    _rideHematPerKmCtrl.dispose();
    _carBaseKmCtrl.dispose();
    _carBaseCtrl.dispose();
    _carPerKmCtrl.dispose();
    _deliveryBaseKmCtrl.dispose();
    _deliveryBaseCtrl.dispose();
    _deliveryPerKmCtrl.dispose();
    _multiMerchantBonusCtrl.dispose();
    _cashlessFeeCtrl.dispose();
    _codBaseFeeCtrl.dispose();
    _codExtraFeeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.heavyImpact();

    if (widget.category == 'motor') {
      final regBaseKm = double.tryParse(_rideRegBaseKmCtrl.text) ?? 2.0;
      final regBase = int.tryParse(_rideRegBaseCtrl.text) ?? 6000;
      final regPerKm = int.tryParse(_rideRegPerKmCtrl.text) ?? 4000;
      final hematBaseKm = double.tryParse(_rideHematBaseKmCtrl.text) ?? 2.0;
      final hematBase = int.tryParse(_rideHematBaseCtrl.text) ?? 6000;
      final hematPerKm = int.tryParse(_rideHematPerKmCtrl.text) ?? 3000;

      await GagePricingService.saveAdminPricingConfig(
        newRideRegulerBaseKm: regBaseKm,
        newRideRegulerBase: regBase,
        newRideRegulerPerKm: regPerKm,
        newRideHematBaseKm: hematBaseKm,
        newRideHematBase: hematBase,
        newRideHematPerKm: hematPerKm,
      );
    } else if (widget.category == 'car') {
      final carBaseKm = double.tryParse(_carBaseKmCtrl.text) ?? 1.0;
      final carBase = int.tryParse(_carBaseCtrl.text) ?? 8000;
      final carPerKm = int.tryParse(_carPerKmCtrl.text) ?? 5000;

      await GagePricingService.saveAdminPricingConfig(
        newCarBaseKm: carBaseKm,
        newCarBase: carBase,
        newCarPerKm: carPerKm,
      );
    } else if (widget.category == 'delivery') {
      final delBaseKm = double.tryParse(_deliveryBaseKmCtrl.text) ?? 2.0;
      final delBase = int.tryParse(_deliveryBaseCtrl.text) ?? 6000;
      final delPerKm = int.tryParse(_deliveryPerKmCtrl.text) ?? 3000;
      final multiBonus = int.tryParse(_multiMerchantBonusCtrl.text) ?? 2500;

      await GagePricingService.saveAdminPricingConfig(
        newDeliveryBaseKm: delBaseKm,
        newDeliveryBase: delBase,
        newDeliveryPerKm: delPerKm,
        newMultiMerchantBonus: multiBonus,
      );
    } else if (widget.category == 'service_fee') {
      final cashless = int.tryParse(_cashlessFeeCtrl.text) ?? 1000;
      final codBase = int.tryParse(_codBaseFeeCtrl.text) ?? 3000;
      final codExtra = int.tryParse(_codExtraFeeCtrl.text) ?? 1000;

      await GagePricingService.saveAdminPricingConfig(
        newAdminFeeCashless: cashless,
        newAdminFeeCodBase: codBase,
        newAdminFeeCodExtra: codExtra,
      );

      await FareCalculationService.updateConfig(
        cashless: cashless,
        codBase: codBase,
        codExtra: codExtra,
      );
    }

    widget.onSaved();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfigurasi tarif berhasil diperbarui.'),
          backgroundColor: Color(0xFF00AA13),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    String title;
    String subtitle;
    Widget content;

    switch (widget.category) {
      case 'motor':
        title = 'Tarif Motor (GageRide)';
        subtitle = 'Atur jarak dasar dan tarif per kilometer motor reguler & hemat';
        content = _buildMotorFields(isDark);
        break;
      case 'car':
        title = 'Tarif Mobil (GageCar)';
        subtitle = 'Atur jarak dasar dan tarif per kilometer mobil';
        content = _buildCarFields(isDark);
        break;
      case 'delivery':
        title = 'Ongkir Pengantaran (Belanja & Paket)';
        subtitle = 'Tarif pengantaran Food, Shop, Tani, Send & bonus multi-toko';
        content = _buildDeliveryFields(isDark);
        break;
      case 'service_fee':
      default:
        title = 'Biaya Layanan & MDR Transaksi';
        subtitle = 'Handling fee non-tunai (GagePay & QRIS) dan COD tunai';
        content = _buildServiceFeeFields(isDark);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              content,

              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotorFields(bool isDark) {
    return Column(
      children: [
        _buildInputField('Jarak Dasar Reguler (KM)', 'Jarak flat motor reguler (default: 2.0 km)', _rideRegBaseKmCtrl, isDark),
        const SizedBox(height: 12),
        _buildInputField('Tarif Flat Reguler (Rp)', 'Tarif flat awal motor reguler', _rideRegBaseCtrl, isDark),
        const SizedBox(height: 12),
        _buildInputField('Tarif Lanjutan Reguler (Rp/KM)', 'Tarif per km setelah batas jarak dasar', _rideRegPerKmCtrl, isDark),
        const SizedBox(height: 16),
        _buildInputField('Jarak Dasar Hemat (KM)', 'Jarak flat opsi hemat (default: 2.0 km)', _rideHematBaseKmCtrl, isDark),
        const SizedBox(height: 12),
        _buildInputField('Tarif Flat Hemat (Rp)', 'Tarif flat awal opsi hemat', _rideHematBaseCtrl, isDark),
        const SizedBox(height: 12),
        _buildInputField('Tarif Lanjutan Hemat (Rp/KM)', 'Tarif per km opsi hemat', _rideHematPerKmCtrl, isDark),
      ],
    );
  }

  Widget _buildCarFields(bool isDark) {
    return Column(
      children: [
        _buildInputField('Jarak Dasar Mobil (KM)', 'Jarak flat armada mobil (default: 1.0 km)', _carBaseKmCtrl, isDark),
        const SizedBox(height: 12),
        _buildInputField('Tarif Flat Mobil (Rp)', 'Tarif flat awal armada mobil', _carBaseCtrl, isDark),
        const SizedBox(height: 12),
        _buildInputField('Tarif Lanjutan Mobil (Rp/KM)', 'Tarif per km armada mobil', _carPerKmCtrl, isDark),
      ],
    );
  }

  Widget _buildDeliveryFields(bool isDark) {
    return Column(
      children: [
        _buildInputField('Jarak Dasar Pengantaran (KM)', 'Jarak flat kurir belanja/paket (default: 2.0 km)', _deliveryBaseKmCtrl, isDark),
        const SizedBox(height: 12),
        _buildInputField('Ongkir Flat Dasar (Rp)', 'Ongkir flat awal pengantaran makanan/paket', _deliveryBaseCtrl, isDark),
        const SizedBox(height: 12),
        _buildInputField('Ongkir Lanjutan (Rp/KM)', 'Tambahan ongkir per km pengantaran', _deliveryPerKmCtrl, isDark),
        const SizedBox(height: 12),
        _buildInputField('Bonus Multi-Toko (Rp)', 'Insentif kurir per toko ekstra dalam keranjang', _multiMerchantBonusCtrl, isDark),
      ],
    );
  }

  Widget _buildServiceFeeFields(bool isDark) {
    return Column(
      children: [
        _buildInputField('Biaya Non-Tunai / QRIS (Rp)', 'Biaya layanan non-tunai per toko/merchant', _cashlessFeeCtrl, isDark),
        const SizedBox(height: 12),
        _buildInputField('Biaya Dasar COD Tunai (Rp)', 'Handling fee pesanan COD toko pertama', _codBaseFeeCtrl, isDark),
        const SizedBox(height: 12),
        _buildInputField('Biaya COD Toko Tambahan (Rp)', 'Handling fee COD per toko belanja ekstra', _codExtraFeeCtrl, isDark),
      ],
    );
  }

  Widget _buildInputField(String label, String helper, TextEditingController ctrl, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                Text(helper, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
