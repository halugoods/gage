import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Modal Intervensi Darurat: Manual Driver Re-assign
/// Digunakan oleh Admin Pracimantoro ketika driver yang bertugas berhalangan,
/// ban bocor, mogok, atau tidak merespons pesanan.
class EmergencyDriverReassignSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(String newDriver, String reason) onReassigned;

  const EmergencyDriverReassignSheet({
    super.key,
    required this.order,
    required this.onReassigned,
  });

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> order,
    required Function(String newDriver, String reason) onReassigned,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmergencyDriverReassignSheet(
        order: order,
        onReassigned: onReassigned,
      ),
    );
  }

  @override
  State<EmergencyDriverReassignSheet> createState() => _EmergencyDriverReassignSheetState();
}

class _EmergencyDriverReassignSheetState extends State<EmergencyDriverReassignSheet> {
  String _selectedReason = 'Driver Mogok / Kendaraan Rusak';
  String? _selectedDriverId;
  String? _selectedDriverName;
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Driver Mogok / Kendaraan Rusak',
    'Tidak Merespons WA / Panggilan (>10 Menit)',
    'Kecelakaan Ringan / Masalah Keluarga',
    'Overload Antrean di Merchant',
    'Permintaan Pelanggan / Ganti Tipe Kendaraan',
  ];

  // Daftar Armada Standby se-Pracimantoro yang siap menerima intervensi
  final List<Map<String, dynamic>> _standbyDrivers = [
    {
      'id': 'DRV-001',
      'name': 'Mas Budi Santoso',
      'phone': '6281234567890',
      'vehicle': 'Honda Vario 160 • AB 4521 WZ',
      'type': 'Motor',
      'rating': 4.96,
      'distance': '0.3 km dari Resto',
      'status': 'Standby',
      'avatar': 'assets/images/gage_ride_3d.png',
    },
    {
      'id': 'DRV-004',
      'name': 'Mas Hendra Pratama',
      'phone': '6289876543210',
      'vehicle': 'Honda Beat Deluxe • AD 2244 BB',
      'type': 'Motor',
      'rating': 4.89,
      'distance': '0.5 km dari Resto',
      'status': 'Standby',
      'avatar': 'assets/images/gage_ride_3d.png',
    },
    {
      'id': 'DRV-003',
      'name': 'Mas Agus Setiawan',
      'phone': '6281399887766',
      'vehicle': 'Yamaha NMAX • AD 3310 QR',
      'type': 'Motor',
      'rating': 4.98,
      'distance': '0.8 km dari Resto',
      'status': 'Standby',
      'avatar': 'assets/images/gage_ride_3d.png',
    },
    {
      'id': 'DRV-002',
      'name': 'Pak Joko Purnomo',
      'phone': '6285712345678',
      'vehicle': 'Toyota Avanza • AD 8912 TX',
      'type': 'Mobil',
      'rating': 4.92,
      'distance': '1.1 km dari Resto',
      'status': 'Standby',
      'avatar': 'assets/images/gage_car_3d.png',
    },
    {
      'id': 'DRV-005',
      'name': 'Pak Bambang Triyono',
      'phone': '6281244556677',
      'vehicle': 'Daihatsu Sigra • AD 9011 ZX',
      'type': 'Mobil',
      'rating': 4.95,
      'distance': '2.0 km dari Resto',
      'status': 'Standby',
      'avatar': 'assets/images/gage_car_3d.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Default seleksi driver standby pertama yang bukan driver saat ini
    final currentDriver = widget.order['driver']?.toString().toLowerCase() ?? '';
    for (final drv in _standbyDrivers) {
      if (!currentDriver.contains(drv['name'].toString().toLowerCase())) {
        _selectedDriverId = drv['id'];
        _selectedDriverName = drv['name'];
        break;
      }
    }
  }

  Future<void> _handleReassign() async {
    if (_selectedDriverId == null || _selectedDriverName == null) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.heavyImpact();

    final orderId = widget.order['id']?.toString() ?? 'ORD-UNKNOWN';
    await GageApiClient.reassignOrderDriver(
      orderId: orderId,
      newDriverId: _selectedDriverId!,
      newDriverName: _selectedDriverName!,
      reason: _selectedReason,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      widget.onReassigned(_selectedDriverName!, _selectedReason);
      GageToast.show(
        context,
        'Intervensi Berhasil: Pesanan $orderId dialihkan ke $_selectedDriverName',
        type: GageToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderId = widget.order['id']?.toString() ?? '-';
    final currentDriver = widget.order['driver']?.toString() ?? 'Belum Ditugaskan';
    final customer = widget.order['customer']?.toString() ?? '-';
    final merchant = widget.order['merchant']?.toString() ?? '-';
    final service = widget.order['service']?.toString() ?? 'Pesanan';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Emergency Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emergency_rounded, color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INTERVENSI DARURAT ADMIN',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          'Re-assign Driver: $orderId ($service)',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade700, width: 0.8),
                    ),
                    child: Text(
                      'PRACIMANTORO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Ringkasan Kondisi Pesanan
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storefront_rounded, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Toko/Resto: $merchant',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_pin_circle_rounded, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tujuan: $customer (${widget.order['dropoff'] ?? 'Pracimantoro'})',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_remove_rounded, size: 14, color: Colors.red),
                        const SizedBox(width: 6),
                        Text(
                          'Driver Saat Ini: ',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                        ),
                        Text(
                          currentDriver,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Alasan Intervensi Darurat
              const Text(
                'ALASAN INTERVENSI OPERASIONAL',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReason,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded),
                    items: _reasons.map((r) {
                      return DropdownMenuItem<String>(
                        value: r,
                        child: Text(r, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedReason = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pilih Driver Pengganti (Armada Standby)
              const Text(
                'PILIH DRIVER PENGGANTI (ARMADA STANDBY)',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),

              ..._standbyDrivers.map((driver) {
                final isSelected = _selectedDriverId == driver['id'];
                final isCurrent = currentDriver.toLowerCase().contains(driver['name'].toString().toLowerCase());

                return InkWell(
                  onTap: isCurrent
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedDriverId = driver['id'];
                            _selectedDriverName = driver['name'];
                          });
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GageTheme.primary.withValues(alpha: 0.08)
                          : (isDark ? const Color(0xFF0F172A) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? GageTheme.primary
                            : (isDark ? Colors.white10 : Colors.grey.shade200),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? GageTheme.primary : Colors.grey.shade300,
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              driver['type'] == 'Mobil' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                              size: 20,
                              color: isSelected ? GageTheme.primary : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    driver['name'],
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: isCurrent ? Colors.grey : null,
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'DRIVER AKTIF',
                                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${driver['vehicle']} • ★ ${driver['rating']}',
                                style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                driver['distance'],
                                style: const TextStyle(fontSize: 9.5, color: GageTheme.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? GageTheme.primary : (isDark ? Colors.white38 : Colors.grey.shade400),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting || _selectedDriverId == null ? null : _handleReassign,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.flash_on_rounded, size: 18),
                      label: Text(
                        _isSubmitting ? 'Mengalihkan...' : 'Tugaskan Sekarang',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
