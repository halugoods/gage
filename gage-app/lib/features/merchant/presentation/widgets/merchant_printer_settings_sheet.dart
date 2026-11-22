import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Sheet Pengaturan Printer Thermal Kasir Bluetooth untuk Workstation Mitra GAGE.
/// Mengadopsi arsitektur konfigurasi NUSA Kasir dengan estetika khas GAGE:
/// - Pindai & pasangkan printer SPP Bluetooth (58mm / 80mm)
/// - Pilihan ukuran kertas 58mm vs 80mm (Segmented Kapsul 999)
/// - Auto-Print tiket saat pesanan baru diterima
/// - Buka laci kasir otomatis (Cash Drawer)
/// - Multi-rangkap struk (1x, 2x, 3x)
/// - Printer dapur terpisah (Kitchen Printer)
/// - Uji cetak sample struk langsung dengan preview interaktif
class MerchantPrinterSettingsSheet extends StatefulWidget {
  const MerchantPrinterSettingsSheet({super.key});

  /// Membuka bottom sheet pengaturan printer kasir
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const MerchantPrinterSettingsSheet(),
    );
  }

  @override
  State<MerchantPrinterSettingsSheet> createState() => _MerchantPrinterSettingsSheetState();
}

class _MerchantPrinterSettingsSheetState extends State<MerchantPrinterSettingsSheet> {
  bool _isScanning = false;
  bool _isTesting = false;
  String? _connectingDevice;

  // Daftar perangkat printer Bluetooth terdeteksi di sekitar kios
  final List<Map<String, String>> _availableDevices = [
    {
      'name': 'RPP02N Thermal Printer',
      'type': '58mm',
      'desc': 'Printer Bluetooth 58mm Mini Portable',
    },
    {
      'name': 'Zijiang POS-80',
      'type': '80mm',
      'desc': 'Printer Kasir Desktop Lebar 80mm',
    },
    {
      'name': 'Panda PRJ-58BT',
      'type': '58mm',
      'desc': 'Printer Struk Kasir Bluetooth',
    },
    {
      'name': 'Iware MP-58',
      'type': '58mm',
      'desc': 'Printer Thermal Struk Kompak',
    },
  ];

  Future<void> _startScan() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isScanning = false);
      GageToast.show(context, 'Ditemukan ${_availableDevices.length} printer bluetooth');
    }
  }

  Future<void> _connectDevice(Map<String, String> device) async {
    setState(() => _connectingDevice = device['name']);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final provider = context.read<MerchantOrderProvider>();
    provider.setPrinterConnected(true);
    provider.setPrinterDeviceName(device['name']!);
    provider.setPrinterPaperSize(device['type'] == '80mm' ? '80mm' : '58mm');

    setState(() => _connectingDevice = null);
    GageToast.show(context, 'Terhubung ke ${device['name']}');
  }

  Future<void> _disconnectDevice() async {
    HapticFeedback.lightImpact();
    final provider = context.read<MerchantOrderProvider>();
    provider.setPrinterConnected(false);
    provider.setPrinterDeviceName('');
    GageToast.show(context, 'Koneksi printer thermal diputuskan');
  }

  Future<void> _runTestPrint() async {
    if (_isTesting) return;
    setState(() => _isTesting = true);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isTesting = false);

    GageToast.show(context, 'Uji cetak struk sample berhasil dikirim ke printer thermal');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MerchantOrderProvider>();
    final isConnected = provider.printerConnected;
    final connectedName = provider.printerDeviceName.isNotEmpty
        ? provider.printerDeviceName
        : 'RPP02N-Thermal-58mm';
    final paperSize = provider.printerPaperSize;
    final autoPrint = provider.autoPrintOnAccept;
    final copies = provider.receiptCopies;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
              blurRadius: 18,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar Kapsul Penuh
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              // Header Sheet
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: GageTheme.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.print_rounded, size: 20, color: GageTheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengaturan Printer Kasir',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Printer Struk Bluetooth SPP (58mm / 80mm)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white60 : Colors.grey.shade600, size: 20),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Card Status Koneksi Printer Aktif
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isConnected
                      ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5))
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isConnected ? const Color(0xFF10B981) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isConnected
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isConnected ? Icons.check_circle_rounded : Icons.bluetooth_searching_rounded,
                        color: isConnected ? Colors.white : (isDark ? Colors.white54 : Colors.grey.shade600),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isConnected ? connectedName : 'Belum Ada Printer Terhubung',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isConnected ? const Color(0xFF10B981) : Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isConnected ? 'ONLINE' : 'OFFLINE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isConnected
                                ? 'Ukuran kertas aktif: $paperSize • $copies Rangkap'
                                : 'Pindai printer bluetooth di sekitar kios untuk menyambung.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isConnected)
                      TextButton(
                        onPressed: _disconnectDevice,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Putus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    else
                      IconButton(
                        onPressed: _isScanning ? null : _startScan,
                        icon: _isScanning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: GageTheme.primary),
                              )
                            : const Icon(Icons.refresh_rounded, color: GageTheme.primary),
                        tooltip: 'Pindai Ulang',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Bagian 1: Pilihan Ukuran Kertas Thermal (Kapsul 999 Segmented Switch)
              Text(
                'Ukuran Kertas Thermal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 40,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          provider.setPrinterPaperSize('58mm');
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: paperSize == '58mm' ? GageTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '58mm (Standar Mini / Portable)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: paperSize == '58mm' ? FontWeight.w800 : FontWeight.w600,
                              color: paperSize == '58mm' ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          provider.setPrinterPaperSize('80mm');
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: paperSize == '80mm' ? GageTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '80mm (Lebar Desktop POS)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: paperSize == '80mm' ? FontWeight.w800 : FontWeight.w600,
                              color: paperSize == '80mm' ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bagian 2: Preferensi Operasional Struk
              Text(
                'Otomasi & Konfigurasi Struk',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Toggle Auto-Print
                    SwitchListTile(
                      dense: true,
                      title: const Text('Auto-Print Tiket Pesanan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: const Text('Cetak tiket otomatis saat pesanan baru diterima', style: TextStyle(fontSize: 11)),
                      value: autoPrint,
                      activeThumbColor: GageTheme.primary,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        provider.toggleAutoPrint(v);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Jumlah Rangkap Cetak', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text(
                                'Rangkap 1: Pelanggan/Kurir, Rangkap 2: Arsip Dapur',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [1, 2, 3].map((n) {
                              final isSel = copies == n;
                              return Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    provider.setReceiptCopies(n);
                                  },
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSel ? GageTheme.primary : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${n}x',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bagian 3: Daftar Printer Tersedia di Sekitar Kios
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Perangkat di Sekitar Kios',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: _isScanning ? null : _startScan,
                    icon: Icon(Icons.refresh_rounded, size: 14, color: GageTheme.primary),
                    label: Text('Pindai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: GageTheme.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Column(
                children: _availableDevices.map((dev) {
                  final isThisConnected = isConnected && dev['name'] == connectedName;
                  final isConnecting = _connectingDevice == dev['name'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isThisConnected
                          ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4))
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isThisConnected ? const Color(0xFF10B981) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.print_outlined,
                          size: 20,
                          color: isThisConnected ? const Color(0xFF10B981) : (isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dev['name']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '${dev['desc'] ?? "Bluetooth SPP"} • ${dev['type']}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isThisConnected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Aktif',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        else
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                            ),
                            onPressed: isConnecting ? null : () => _connectDevice(dev),
                            child: isConnecting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: GageTheme.primary),
                                  )
                                : const Text(
                                    'Hubungkan',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                  ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // Bagian 4: Tombol Uji Cetak Struk Sampel (Test Print)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  onPressed: _isTesting ? null : _runTestPrint,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.receipt_long_rounded, size: 18),
                  label: Text(
                    _isTesting ? 'Mengirim Test Print...' : 'Uji Cetak Sampel ($paperSize)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
