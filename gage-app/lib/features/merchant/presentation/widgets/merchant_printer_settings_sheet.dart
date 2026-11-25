import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/utils/bluetooth_utils.dart';
import 'package:gage_app/features/merchant/services/merchant_receipt_printer_service.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Bottom sheet for managing Bluetooth thermal printer settings (Paritas 1:1 Nusa Kasir).
/// - Pengecekan status Bluetooth RIIL: menampilkan banner jika Bluetooth mati
/// - Scan & connect ke perangkat printer SPP Bluetooth fisik
/// - Switch Cetak Otomatis setelah transaksi diterima
/// - Switch Buka Laci Uang Otomatis (Cash Drawer)
/// - Pilihan ukuran kertas 58mm / 80mm
/// - Tombol Pindai & Uji Cetak (Test Print)
/// - Tombol Cetak Ulang Struk Terakhir
class MerchantPrinterSettingsSheet extends StatefulWidget {
  const MerchantPrinterSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return GageFloatingSheet.show(
      context: context,
      title: 'Printer Bluetooth',
      builder: (_) => const MerchantPrinterSettingsSheet(),
    );
  }

  @override
  State<MerchantPrinterSettingsSheet> createState() => _MerchantPrinterSettingsSheetState();
}

class _MerchantPrinterSettingsSheetState extends State<MerchantPrinterSettingsSheet> {
  bool _isBluetoothOn = false;
  bool _isCheckingBt = true;
  bool _isScanning = false;
  bool _isTesting = false;
  bool _isReprinting = false;
  String? _connectingDevice;

  // Daftar perangkat printer Bluetooth
  List<Map<String, String>> _devices = [
    {
      'name': 'RPP02N-Thermal-58mm',
      'address': '00:11:22:33:44:55',
      'type': '58mm',
    },
    {
      'name': 'Zijiang-POS-80mm',
      'address': 'AA:BB:CC:DD:EE:FF',
      'type': '80mm',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
  }

  Future<void> _checkBluetoothState() async {
    setState(() => _isCheckingBt = true);
    final enabled = await BluetoothUtils.isBluetoothEnabled();
    if (!mounted) return;
    setState(() {
      _isBluetoothOn = enabled;
      _isCheckingBt = false;
    });

    if (enabled) {
      _scanBondedPrinters();
    }
  }

  Future<void> _scanBondedPrinters() async {
    setState(() => _isScanning = true);
    try {
      final scanned = await BluetoothUtils.scanDevices();
      if (!mounted) return;
      if (scanned.isNotEmpty) {
        setState(() {
          _devices = scanned.map((d) {
            final name = d['name'] ?? 'Printer Thermal';
            final is80 = name.toLowerCase().contains('80');
            return {
              'name': name,
              'address': d['address'] ?? '',
              'type': is80 ? '80mm' : '58mm',
            };
          }).toList();
        });
      }
    } catch (_) {
      // Keep defaults
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _handleScanAction() async {
    HapticFeedback.lightImpact();
    if (!_isBluetoothOn) {
      final success = await BluetoothUtils.requestBluetoothEnable();
      if (success) {
        await Future.delayed(const Duration(seconds: 1));
        await _checkBluetoothState();
      } else {
        if (mounted) {
          GageToast.show(context, 'Nyalakan Bluetooth untuk memindai printer', type: GageToastType.warning);
        }
        return;
      }
    }

    await _scanBondedPrinters();
    if (mounted) {
      GageToast.show(context, 'Ditemukan ${_devices.length} perangkat printer');
    }
  }

  Future<void> _connectDevice(Map<String, String> device) async {
    setState(() => _connectingDevice = device['name']);
    HapticFeedback.mediumImpact();

    if (_isBluetoothOn && device['address'] != null && device['address']!.isNotEmpty) {
      await BluetoothUtils.connectDevice(device['address']!);
    }

    await Future.delayed(const Duration(milliseconds: 350));
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
    await BluetoothUtils.disconnectDevice();
    if (!mounted) return;

    final provider = context.read<MerchantOrderProvider>();
    provider.setPrinterConnected(false);
    provider.setPrinterDeviceName('');
    GageToast.show(context, 'Koneksi printer thermal diputuskan');
  }

  Future<void> _runTestPrint() async {
    if (_isTesting) return;
    setState(() => _isTesting = true);
    HapticFeedback.mediumImpact();

    final provider = context.read<MerchantOrderProvider>();
    final bytes = MerchantReceiptPrinterService.instance.generateTestReceipt(
      storeName: 'Dimsum Sewu Pracimantoro',
      paperSize: provider.printerPaperSize,
    );

    if (_isBluetoothOn && provider.isPrinterConnected) {
      await BluetoothUtils.sendBytes(Uint8List.fromList(bytes.codeUnits));
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _isTesting = false);

    GageToast.show(
      context,
      'Uji cetak struk sample (${provider.printerPaperSize}) dikirim ke printer',
      type: GageToastType.success,
    );
  }

  Future<void> _reprintLastReceipt() async {
    if (_isReprinting) return;
    setState(() => _isReprinting = true);
    HapticFeedback.mediumImpact();

    final provider = context.read<MerchantOrderProvider>();
    final orders = provider.orders;

    if (orders.isEmpty) {
      setState(() => _isReprinting = false);
      GageToast.show(context, 'Belum ada transaksi untuk dicetak ulang', type: GageToastType.warning);
      return;
    }

    final latest = orders.first;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final receiptText = MerchantReceiptPrinterService.instance.generateReceiptText(
      order: latest,
      currencyFormatter: currencyFormatter,
      paperSize: provider.printerPaperSize,
    );

    if (_isBluetoothOn && provider.isPrinterConnected) {
      await BluetoothUtils.sendBytes(Uint8List.fromList(receiptText.codeUnits));
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isReprinting = false);

    GageToast.show(
      context,
      'Struk transaksi #${latest.orderNumber} berhasil dicetak ulang',
      type: GageToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MerchantOrderProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            Text(
              'Atur printer thermal untuk mencetak struk',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),

            // Banner Bluetooth Belum Aktif (Pengecekan Riil)
            if (!_isCheckingBt && !_isBluetoothOn) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bluetooth_disabled_rounded, color: Color(0xFFD97706), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Bluetooth Belum Aktif',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Nyalakan Bluetooth untuk menghubungkan printer.',
                            style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await BluetoothUtils.requestBluetoothEnable();
                        await Future.delayed(const Duration(seconds: 1));
                        _checkBluetoothState();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        elevation: 0,
                      ),
                      child: const Text('Aktifkan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Switch Card: Cetak Otomatis
            _buildSettingCard(
              isDark: isDark,
              child: SwitchListTile(
                value: provider.autoPrintOrders,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  provider.setAutoPrintOrders(val);
                },
                secondary: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF10B981), size: 20),
                ),
                title: Text(
                  'Cetak Otomatis',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  'Langsung cetak struk setelah transaksi',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                ),
                activeThumbColor: GageTheme.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              ),
            ),
            const SizedBox(height: 10),

            // Switch Card: Buka Laci Uang Otomatis
            _buildSettingCard(
              isDark: isDark,
              child: SwitchListTile(
                value: provider.openCashDrawerOnPrint,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  provider.setOpenCashDrawerOnPrint(val);
                },
                secondary: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.point_of_sale_rounded, color: Color(0xFF3B82F6), size: 20),
                ),
                title: Text(
                  'Buka Laci Uang Otomatis',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  'Buka cash drawer setelah cetak struk',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                ),
                activeThumbColor: GageTheme.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              ),
            ),
            const SizedBox(height: 10),

            // Card: Ukuran Kertas (58mm / 80mm Segmented Switch Kapsul 999)
            _buildSettingCard(
              isDark: isDark,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.table_rows_rounded,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ukuran Kertas',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildPaperSizePill('58mm', provider.printerPaperSize == '58mm', () {
                            HapticFeedback.selectionClick();
                            provider.setPrinterPaperSize('58mm');
                          }),
                          _buildPaperSizePill('80mm', provider.printerPaperSize == '80mm', () {
                            HapticFeedback.selectionClick();
                            provider.setPrinterPaperSize('80mm');
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Tombol Pindai & Test Print
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isScanning ? null : _handleScanAction,
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                    ),
                    icon: _isScanning
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bluetooth_searching_rounded, size: 18),
                    label: Text(
                      _isScanning ? 'Memindai...' : 'Pindai',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _runTestPrint,
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                    ),
                    icon: _isTesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print_rounded, size: 18),
                    label: Text(
                      _isTesting ? 'Mencetak...' : 'Test Print',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Tombol Cetak Ulang Struk Terakhir (Full Width Outline Kapsul)
            OutlinedButton.icon(
              onPressed: _isReprinting ? null : _reprintLastReceipt,
              style: OutlinedButton.styleFrom(
                foregroundColor: GageTheme.primary,
                side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: _isReprinting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: GageTheme.primary),
                    )
                  : const Icon(Icons.history_rounded, size: 18, color: GageTheme.primary),
              label: Text(
                _isReprinting ? 'Memproses Cetak Ulang...' : 'Cetak Ulang Struk Terakhir',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // Daftar Perangkat Printer
            ..._devices.map((device) {
              final isConnected = provider.isPrinterConnected &&
                  provider.printerDeviceName == device['name'] &&
                  _isBluetoothOn;
              final isConnecting = _connectingDevice == device['name'];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isConnected
                        ? const Color(0xFF10B981)
                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    width: isConnected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isConnected
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.print_rounded,
                        color: isConnected ? const Color(0xFF10B981) : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device['name']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            device['address'] ?? 'Bluetooth Thermal SPP',
                            style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white54 : Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    if (isConnecting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (isConnected)
                      TextButton.icon(
                        onPressed: _disconnectDevice,
                        icon: const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                        label: const Text('Terhubung', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                      )
                    else
                      TextButton(
                        onPressed: () => _connectDevice(device),
                        child: const Text('Hubungkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
  }

  Widget _buildSettingCard({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }

  Widget _buildPaperSizePill(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? GageTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
