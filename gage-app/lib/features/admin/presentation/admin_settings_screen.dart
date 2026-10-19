import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/fare_calculation_service.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';
import 'package:gage_app/features/admin/presentation/portal_interactive_preview_screen.dart';
import 'package:gage_app/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';

/// Screen Pengaturan Finansial, Tarif & Sistem GAGE - Tab 4
/// Didesain dengan arsitektur iOS Inset Grouped & GoPartner:
/// - Pengaturan biaya platform & MDR tanpa form generik
/// - Konfigurasi tarif dinamis per KM & ambang jarak dasar per armada
/// - Status infrastruktur Cloudflare D1/R2/RoomDO
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Controllers Biaya Platform / MDR
  late TextEditingController _cashlessFeeCtrl;
  late TextEditingController _codBaseFeeCtrl;
  late TextEditingController _codExtraFeeCtrl;

  // Controllers Tarif & Jarak Dasar GageRide Motor (Reguler & Hemat)
  late TextEditingController _rideRegBaseKmCtrl;
  late TextEditingController _rideRegBaseCtrl;
  late TextEditingController _rideRegPerKmCtrl;
  late TextEditingController _rideHematBaseKmCtrl;
  late TextEditingController _rideHematBaseCtrl;
  late TextEditingController _rideHematPerKmCtrl;

  // Controllers Tarif & Jarak Dasar GageCar Mobil
  late TextEditingController _carBaseKmCtrl;
  late TextEditingController _carBaseCtrl;
  late TextEditingController _carPerKmCtrl;

  // Controllers Ongkir & Jarak Dasar Belanja & Kurir (Food, Shop, Tani, Send)
  late TextEditingController _deliveryBaseKmCtrl;
  late TextEditingController _deliveryBaseCtrl;
  late TextEditingController _deliveryPerKmCtrl;
  late TextEditingController _multiMerchantBonusCtrl;

  @override
  void initState() {
    super.initState();
    // Memuat konfigurasi aktual yang digunakan di Customer & Driver
    _cashlessFeeCtrl = TextEditingController(text: GagePricingService.adminFeeCashlessPerMerchant.toString());
    _codBaseFeeCtrl = TextEditingController(text: GagePricingService.adminFeeCashCodBase.toString());
    _codExtraFeeCtrl = TextEditingController(text: GagePricingService.adminFeeCashCodExtraPerMerchant.toString());

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
  }

  @override
  void dispose() {
    _cashlessFeeCtrl.dispose();
    _codBaseFeeCtrl.dispose();
    _codExtraFeeCtrl.dispose();
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
    super.dispose();
  }

  Future<void> _saveFees() async {
    HapticFeedback.heavyImpact();
    final cashless = int.tryParse(_cashlessFeeCtrl.text) ?? 1000;
    final codBase = int.tryParse(_codBaseFeeCtrl.text) ?? 3000;
    final codExtra = int.tryParse(_codExtraFeeCtrl.text) ?? 1000;

    final rideRegBaseKm = double.tryParse(_rideRegBaseKmCtrl.text) ?? 2.0;
    final rideRegBase = int.tryParse(_rideRegBaseCtrl.text) ?? 6000;
    final rideRegPerKm = int.tryParse(_rideRegPerKmCtrl.text) ?? 4000;

    final rideHematBaseKm = double.tryParse(_rideHematBaseKmCtrl.text) ?? 2.0;
    final rideHematBase = int.tryParse(_rideHematBaseCtrl.text) ?? 6000;
    final rideHematPerKm = int.tryParse(_rideHematPerKmCtrl.text) ?? 3000;

    final carBaseKm = double.tryParse(_carBaseKmCtrl.text) ?? 1.0;
    final carBase = int.tryParse(_carBaseCtrl.text) ?? 8000;
    final carPerKm = int.tryParse(_carPerKmCtrl.text) ?? 5000;

    final deliveryBaseKm = double.tryParse(_deliveryBaseKmCtrl.text) ?? 2.0;
    final deliveryBase = int.tryParse(_deliveryBaseCtrl.text) ?? 6000;
    final deliveryPerKm = int.tryParse(_deliveryPerKmCtrl.text) ?? 3000;
    final multiBonus = int.tryParse(_multiMerchantBonusCtrl.text) ?? 2500;

    await GagePricingService.saveAdminPricingConfig(
      newRideRegulerBaseKm: rideRegBaseKm,
      newRideRegulerBase: rideRegBase,
      newRideRegulerPerKm: rideRegPerKm,
      newRideHematBaseKm: rideHematBaseKm,
      newRideHematBase: rideHematBase,
      newRideHematPerKm: rideHematPerKm,
      newCarBaseKm: carBaseKm,
      newCarBase: carBase,
      newCarPerKm: carPerKm,
      newDeliveryBaseKm: deliveryBaseKm,
      newDeliveryBase: deliveryBase,
      newDeliveryPerKm: deliveryPerKm,
      newMultiMerchantBonus: multiBonus,
      newAdminFeeCashless: cashless,
      newAdminFeeCodBase: codBase,
      newAdminFeeCodExtra: codExtra,
    );

    await FareCalculationService.updateConfig(
      cashless: cashless,
      codBase: codBase,
      codExtra: codExtra,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfigurasi tarif & jarak berhasil disimpan dan aktif di seluruh portal Customer & Driver.'),
          backgroundColor: Color(0xFF00AA13),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengaturan Finansial & Tarif',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              'MDR Platform, Tarif Jarak & Sistem Cloud',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. KELOMPOK: TARIF GAGERIDE MOTOR (REGULER & HEMAT)
            _buildSectionHeader('TARIF GAGERIDE MOTOR (REGULER & HEMAT)'),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    label: 'Jarak Dasar Reguler (KM Awal)',
                    subtitle: 'Batas jarak flat motor reguler (default: 2.0 km)',
                    controller: _rideRegBaseKmCtrl,
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildSettingRow(
                    label: 'Tarif Dasar Reguler (Flat KM Awal)',
                    subtitle: 'Tarif flat untuk jarak dasar motor reguler',
                    controller: _rideRegBaseCtrl,
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildSettingRow(
                    label: 'Tarif Lanjutan Reguler (Per KM)',
                    subtitle: 'Tarif per km setelah melewati batas jarak dasar',
                    controller: _rideRegPerKmCtrl,
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildSettingRow(
                    label: 'Jarak Dasar Hemat (KM Awal)',
                    subtitle: 'Batas jarak flat opsi hemat (default: 2.0 km)',
                    controller: _rideHematBaseKmCtrl,
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildSettingRow(
                    label: 'Tarif Dasar Hemat (Flat KM Awal)',
                    subtitle: 'Tarif flat opsi hemat jarak dasar',
                    controller: _rideHematBaseCtrl,
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildSettingRow(
                    label: 'Tarif Lanjutan Hemat (Per KM)',
                    subtitle: 'Tarif per km hemat setelah jarak dasar',
                    controller: _rideHematPerKmCtrl,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. KELOMPOK: TARIF GAGECAR MOBIL (1-4 PENUMPANG)
            _buildSectionHeader('TARIF GAGECAR MOBIL (1-4 PENUMPANG)'),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    label: 'Jarak Buka Pintu Mobil (KM Awal)',
                    subtitle: 'Batas jarak awal flat se-Kecamatan (default: 1.0 km)',
                    controller: _carBaseKmCtrl,
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildSettingRow(
                    label: 'Tarif Buka Pintu Mobil (Flat KM Awal)',
                    subtitle: 'Tarif flat buka pintu mobil AC nyaman',
                    controller: _carBaseCtrl,
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildSettingRow(
                    label: 'Tarif Lanjutan Mobil (Per KM)',
                    subtitle: 'Tambahan jarak per km mobil AC',
                    controller: _carPerKmCtrl,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. KELOMPOK: ONGKIR BELANJA & KURIR (FOOD, SHOP, TANI, SEND)
            _buildSectionHeader('ONGKIR BELANJA & KURIR (FOOD, SHOP, TANI, SEND)'),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    label: 'Jarak Dasar Pengantaran (KM Awal)',
                    subtitle: 'Batas jarak flat pengantaran kurir (default: 2.0 km)',
                    controller: _deliveryBaseKmCtrl,
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildSettingRow(
                    label: 'Ongkir Dasar (Flat KM Awal)',
                    subtitle: 'Tarif flat makanan, sembako & paket',
                    controller: _deliveryBaseCtrl,
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildSettingRow(
                    label: 'Ongkir Lanjutan (Per KM)',
                    subtitle: 'Tambahan ongkir per km rute pengantaran kurir',
                    controller: _deliveryPerKmCtrl,
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildSettingRow(
                    label: 'Bonus Mampir Multi-Merchant',
                    subtitle: 'Insentif kurir per toko ekstra pada keranjang gabungan',
                    controller: _multiMerchantBonusCtrl,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. KELOMPOK: BIAYA LAYANAN & MDR TRANSAKSI
            _buildSectionHeader('BIAYA LAYANAN & MDR TRANSAKSI'),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    label: 'Biaya GagePay & QRIS Cashless',
                    subtitle: 'MDR transaksi non-tunai per toko/merchant',
                    controller: _cashlessFeeCtrl,
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildSettingRow(
                    label: 'Biaya Dasar COD Tunai',
                    subtitle: 'Handling fee pembayaran di tempat (toko ke-1)',
                    controller: _codBaseFeeCtrl,
                    isDark: isDark,
                  ),
                  const Divider(height: 1),
                  _buildSettingRow(
                    label: 'Biaya Tambahan COD Toko Ekstra',
                    subtitle: 'Handling fee per toko belanja tambahan',
                    controller: _codExtraFeeCtrl,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 5. KELOMPOK: PRINSIP EKONOMI & BAGI HASIL MITRA
            _buildSectionHeader('PRINSIP EKONOMI & SISTEM PEMBULATAN'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Bagi Hasil Mitra Driver', '80% Hak Driver (Jarak Riil, Tanpa Mark Up)', const Color(0xFF00AA13)),
                  const Divider(height: 18),
                  _buildInfoRow('Sistem Pembulatan Transparan', 'Kelipatan Rp 500 ke atas (Khusus Customer)', GageTheme.primary),
                  const Divider(height: 18),
                  _buildInfoRow('Alokasi Selisih Pembulatan', '100% Subsidi Diskon & Voucher Belanja Pelanggan', Colors.blue.shade700),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Tombol Simpan Biaya
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
                label: const Text('Simpan Konfigurasi Tarif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: _saveFees,
              ),
            ),

            const SizedBox(height: 24),

            // 6. SHORTCUT MANAJEMEN PORTAL & LIVE APP WYSIWYG
            _buildSectionHeader('LIVE APP WYSIWYG EDITOR'),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PortalInteractivePreviewScreen(initialPortal: 'Customer')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GageTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: GageTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.devices_rounded, color: GageTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Live App Editor 100% Interaktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(width: 6),
                              Text('WYSIWYG', style: TextStyle(color: Colors.green, fontSize: 8.5, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text('Uji coba live native app, ketuk banner langsung di layar untuk CRUD D1', style: TextStyle(fontSize: 10.5, color: GageTheme.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: GageTheme.textSecondary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 7. INFRASTRUKTUR CLOUDFLARE GAGE
            _buildSectionHeader('STATUS INFRASTRUKTUR CLOUD'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildSystemRow('Cloudflare D1 Database', 'Terhubung (gage-db)', const Color(0xFF00AA13)),
                  const Divider(height: 18),
                  _buildSystemRow('Cloudflare R2 Object Storage', 'Active (gage-images)', const Color(0xFF00AA13)),
                  const Divider(height: 18),
                  _buildSystemRow('WebSocket RoomDO Broadcast', 'Active (<50ms)', const Color(0xFF00AA13)),
                  const Divider(height: 18),
                  _buildSystemRow('Wrangler Profile Akun', '@cloudgage (gagebyhalu)', Colors.grey.shade600),
                  const Divider(height: 18),
                  _buildSystemRow('Versi Sistem GAGE Core', 'v1.0.3+15', const Color(0xFF00AA13)),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: GageTheme.textSecondary),
      ),
    );
  }

  Widget _buildSettingRow({
    required String label,
    required String subtitle,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54)),
              ],
            ),
          ),
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Rp ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.textSecondary)),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildSystemRow(String title, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text(val, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
