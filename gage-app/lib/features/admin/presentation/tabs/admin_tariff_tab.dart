import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/admin/presentation/widgets/tariff_edit_bottom_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Tab 3: Pengaturan Tarif Dinamis se-Pracimantoro
/// Kontrol langsung tarif Hemat, Reguler, Car, Biaya Layanan & Multi-Merchant
/// Dilengkapi Live Fare Simulator untuk menguji tarif sebelum diterapkan ke publik.
class AdminTariffTab extends StatefulWidget {
  const AdminTariffTab({super.key});

  @override
  State<AdminTariffTab> createState() => _AdminTariffTabState();
}

class _AdminTariffTabState extends State<AdminTariffTab> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Live Simulator State
  double _simulatedDistanceKm = 3.5;
  final int _simulatedMerchantCount = 1;
  final String _simulatedPayment = 'GAGEPAY';

  @override
  void initState() {
    super.initState();
    GagePricingService.loadAdminPricingConfig().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openEditSheet(String category) {
    TariffEditBottomSheet.show(
      context: context,
      category: category,
      onSaved: () {
        setState(() {});
        GageToast.show(context, 'Tarif berhasil diperbarui & disimpan!', type: GageToastType.success);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Hitung estimasi simulator
    final int fareHemat = GagePricingService.calculateCustomerRideFare(
      serviceType: 'hemat',
      distanceKm: _simulatedDistanceKm,
    );
    final int driverHemat = GagePricingService.calculateDriverRideCommission(
      serviceType: 'hemat',
      distanceKm: _simulatedDistanceKm,
    );
    final int gageHemat = fareHemat - driverHemat;

    final int fareReguler = GagePricingService.calculateCustomerRideFare(
      serviceType: 'reguler',
      distanceKm: _simulatedDistanceKm,
    );
    final int driverReguler = GagePricingService.calculateDriverRideCommission(
      serviceType: 'reguler',
      distanceKm: _simulatedDistanceKm,
    );
    final int gageReguler = fareReguler - driverReguler;

    final int fareCar = GagePricingService.calculateCustomerRideFare(
      serviceType: 'car',
      distanceKm: _simulatedDistanceKm,
    );
    final int driverCar = GagePricingService.calculateDriverRideCommission(
      serviceType: 'car',
      distanceKm: _simulatedDistanceKm,
    );
    final int gageCar = fareCar - driverCar;

    final int fareDelivery = GagePricingService.calculateCustomerShippingFee(
      distanceKm: _simulatedDistanceKm,
      merchantCount: _simulatedMerchantCount,
    );
    final int adminFee = GagePricingService.calculateAdminFee(
      paymentMethod: _simulatedPayment,
      merchantCount: _simulatedMerchantCount,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune_rounded, color: GageTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kontrol Tarif Dinamis Pracimantoro',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Atur jarak dasar, tarif per km, dan bagi hasil 80% mitra driver.',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 1. Tarif Opsi Hemat (GageRide Hemat)
        _buildTariffCard(
          isDark: isDark,
          title: 'Tarif Hemat (GageRide Hemat)',
          badge: 'OPSI EKONOMIS',
          badgeColor: Colors.teal,
          icon: Icons.electric_moped_rounded,
          iconColor: Colors.teal,
          baseKm: GagePricingService.rideHematBaseKm,
          baseFare: GagePricingService.rideHematBase,
          perKm: GagePricingService.rideHematPerKm,
          onEdit: () => _openEditSheet('motor'),
        ),
        const SizedBox(height: 12),

        // 2. Tarif Reguler (GageRide Motor)
        _buildTariffCard(
          isDark: isDark,
          title: 'Tarif Motor Reguler (GageRide)',
          badge: 'STANDAR',
          badgeColor: GageTheme.primary,
          icon: Icons.two_wheeler_rounded,
          iconColor: GageTheme.primary,
          baseKm: GagePricingService.rideRegulerBaseKm,
          baseFare: GagePricingService.rideRegulerBase,
          perKm: GagePricingService.rideRegulerPerKm,
          onEdit: () => _openEditSheet('motor'),
        ),
        const SizedBox(height: 12),

        // 3. Tarif Mobil (GageCar)
        _buildTariffCard(
          isDark: isDark,
          title: 'Tarif Mobil (GageCar)',
          badge: 'RODA EMPAT',
          badgeColor: Colors.blue.shade700,
          icon: Icons.directions_car_rounded,
          iconColor: Colors.blue.shade700,
          baseKm: GagePricingService.carBaseKm,
          baseFare: GagePricingService.carBase,
          perKm: GagePricingService.carPerKm,
          onEdit: () => _openEditSheet('car'),
        ),
        const SizedBox(height: 12),

        // 4. Pengantaran Belanja (Food, Shop, Send)
        _buildDeliveryTariffCard(isDark: isDark),
        const SizedBox(height: 12),

        // 5. Biaya Layanan & Pembagian Komisi
        _buildServiceFeeCard(isDark: isDark),
        const SizedBox(height: 20),

        // 6. LIVE FARE SIMULATOR (Sandbox Uji Coba)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.science_rounded, size: 16, color: Colors.greenAccent),
                      SizedBox(width: 6),
                      Text(
                        'LIVE FARE SIMULATOR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_simulatedDistanceKm.toStringAsFixed(1)} KM',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Geser jarak untuk memvalidasi pembulatan Rp 500 & bagi hasil driver:',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 8),

              // Slider Jarak
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: GageTheme.primary,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _simulatedDistanceKm,
                  min: 0.5,
                  max: 15.0,
                  divisions: 29, // per 0.5 km
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _simulatedDistanceKm = val);
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Hasil Komparasi Tarif Simulator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    _buildSimulatorRow(
                      service: 'GageRide Hemat',
                      customerTotal: fareHemat,
                      driverShare: driverHemat,
                      gageShare: gageHemat,
                    ),
                    const Divider(color: Colors.white12, height: 12),
                    _buildSimulatorRow(
                      service: 'GageRide Reguler',
                      customerTotal: fareReguler,
                      driverShare: driverReguler,
                      gageShare: gageReguler,
                    ),
                    const Divider(color: Colors.white12, height: 12),
                    _buildSimulatorRow(
                      service: 'GageCar (Mobil)',
                      customerTotal: fareCar,
                      driverShare: driverCar,
                      gageShare: gageCar,
                    ),
                    const Divider(color: Colors.white12, height: 12),
                    _buildSimulatorRow(
                      service: 'Ongkir Belanja + Admin',
                      customerTotal: fareDelivery + adminFee,
                      driverShare: (fareDelivery * 0.8).round(),
                      gageShare: (fareDelivery * 0.2).round() + adminFee,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTariffCard({
    required bool isDark,
    required String title,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
    required double baseKm,
    required int baseFare,
    required int perKm,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: badgeColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Jarak Dasar: ${baseKm.toStringAsFixed(1)} KM pertama',
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: GageTheme.primary, size: 22),
                tooltip: 'Ubah Parameter',
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tarif Dasar', style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.black45)),
                    const SizedBox(height: 2),
                    Text(currencyFormatter.format(baseFare), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Tarif Berikutnya / KM', style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.black45)),
                    const SizedBox(height: 2),
                    Text('+${currencyFormatter.format(perKm)}/km', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: GageTheme.primary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTariffCard({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade800.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delivery_dining_rounded, color: Colors.orange.shade800, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ongkir Pengantaran Belanja (Food & Shop)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      'Jarak Dasar: ${GagePricingService.deliveryBaseKm.toStringAsFixed(1)} KM',
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: GageTheme.primary, size: 22),
                tooltip: 'Ubah Parameter',
                onPressed: () => _openEditSheet('delivery'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ongkir Dasar', style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.black45)),
                    const SizedBox(height: 2),
                    Text(currencyFormatter.format(GagePricingService.deliveryBase), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Berikutnya/KM', style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.black45)),
                    const SizedBox(height: 2),
                    Text('+${currencyFormatter.format(GagePricingService.deliveryPerKm)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Bonus Multi-Toko', style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.black45)),
                    const SizedBox(height: 2),
                    Text('+${currencyFormatter.format(GagePricingService.multiMerchantStopBonus)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.orange.shade800)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceFeeCard({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade700.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_long_rounded, color: Colors.indigo.shade700, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Biaya Layanan Aplikasi & Bagi Hasil', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('Struktur biaya platform & rasio bagi hasil driver', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: GageTheme.primary, size: 22),
                tooltip: 'Ubah Parameter',
                onPressed: () => _openEditSheet('service_fee'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Biaya Cashless', style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.black45)),
                    const SizedBox(height: 2),
                    Text(currencyFormatter.format(GagePricingService.adminFeeCashlessPerMerchant), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Biaya COD Base', style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.black45)),
                    const SizedBox(height: 2),
                    Text(currencyFormatter.format(GagePricingService.adminFeeCashCodBase), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Bagi Hasil Driver', style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.black45)),
                    const SizedBox(height: 2),
                    Text('${(GagePricingService.driverCommissionRatio * 100).round()}% : ${(100 - (GagePricingService.driverCommissionRatio * 100)).round()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF00AA13))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatorRow({
    required String service,
    required int customerTotal,
    required int driverShare,
    required int gageShare,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(service, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
              Text('Cust bayar: ${currencyFormatter.format(customerTotal)}', style: TextStyle(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
        ),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(currencyFormatter.format(driverShare), style: const TextStyle(color: Colors.greenAccent, fontSize: 11.5, fontWeight: FontWeight.w800)),
                Text('Driver (80%)', style: TextStyle(fontSize: 8.5, color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(currencyFormatter.format(gageShare), style: const TextStyle(color: Colors.amberAccent, fontSize: 11.5, fontWeight: FontWeight.w800)),
                Text('GAGE Net', style: TextStyle(fontSize: 8.5, color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
