import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Floating Bottom Sheet Penarikan Dana GagePay (Withdrawal)
/// - Menghubungkan ke Bank & E-Wallet di Indonesia yang 100% kompatibel dengan Flip:
///   E-Wallet: GoPay, DANA, OVO, ShopeePay, LinkAja, iSaku
///   Bank: BCA, Mandiri, BRI, BNI, BSI, CIMB Niaga, Permata, Danamon, SeaBank, Bank Jago, Blu, Mega, Panin, OCBC, BTN, BNC
/// - Bebas dari '2x UX' (Proses tunggal tanpa popup PIN bertingkat yang mengganggu)
/// - Pilihan Rekening Tujuan berbasis DROPDOWN modern (Rekening Tersimpan & Tambah Baru Inline)
/// - Biaya admin flat Rp 1.000 (arbitrase transfer via Flip, 100% net profit GAGE)
class GageWithdrawSheet extends StatefulWidget {
  const GageWithdrawSheet({super.key});

  static Future<void> show(BuildContext context) {
    return GageFloatingSheet.show(
      context: context,
      isScrollControlled: true,
      child: const GageWithdrawSheet(),
    );
  }

  @override
  State<GageWithdrawSheet> createState() => _GageWithdrawSheetState();
}

class _GageWithdrawSheetState extends State<GageWithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _accountNumberCtrl = TextEditingController();
  final TextEditingController _accountHolderCtrl = TextEditingController();

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  static const int adminFee = 1000;

  // Master Bank & E-Wallet Kompatibel Flip Indonesia
  final List<Map<String, dynamic>> _flipDestinations = [
    // E-Wallet
    {'name': 'GoPay', 'type': 'E-Wallet', 'color': Color(0xFF0D9488), 'label': 'GoPay E-Wallet'},
    {'name': 'DANA', 'type': 'E-Wallet', 'color': Color(0xFF118EEA), 'label': 'DANA Digital Wallet'},
    {'name': 'OVO', 'type': 'E-Wallet', 'color': Color(0xFF4C3494), 'label': 'OVO Cash'},
    {'name': 'ShopeePay', 'type': 'E-Wallet', 'color': Color(0xFFEE4D2D), 'label': 'ShopeePay'},
    {'name': 'LinkAja', 'type': 'E-Wallet', 'color': Color(0xFFE11931), 'label': 'LinkAja Indonesia'},
    {'name': 'iSaku', 'type': 'E-Wallet', 'color': Color(0xFF0072CE), 'label': 'iSaku Indomaret'},

    // Bank Konvensional & Syariah Utama
    {'name': 'BCA', 'type': 'Bank', 'color': Color(0xFF005BAC), 'label': 'Bank Central Asia (BCA)'},
    {'name': 'Mandiri', 'type': 'Bank', 'color': Color(0xFF003D79), 'label': 'Bank Mandiri'},
    {'name': 'BRI', 'type': 'Bank', 'color': Color(0xFF00529C), 'label': 'Bank Rakyat Indonesia (BRI)'},
    {'name': 'BNI', 'type': 'Bank', 'color': Color(0xFFE55300), 'label': 'Bank Negara Indonesia (BNI)'},
    {'name': 'BSI', 'type': 'Bank', 'color': Color(0xFF00A272), 'label': 'Bank Syariah Indonesia (BSI)'},
    {'name': 'CIMB Niaga', 'type': 'Bank', 'color': Color(0xFF7D0000), 'label': 'Bank CIMB Niaga'},
    {'name': 'Permata', 'type': 'Bank', 'color': Color(0xFF4A8424), 'label': 'Bank Permata'},
    {'name': 'Danamon', 'type': 'Bank', 'color': Color(0xFFE55A00), 'label': 'Bank Danamon'},
    {'name': 'Bank Mega', 'type': 'Bank', 'color': Color(0xFFF37023), 'label': 'Bank Mega'},
    {'name': 'Panin Bank', 'type': 'Bank', 'color': Color(0xFF007236), 'label': 'Panin Bank'},
    {'name': 'OCBC', 'type': 'Bank', 'color': Color(0xFFEE2E24), 'label': 'OCBC Indonesia'},
    {'name': 'BTN', 'type': 'Bank', 'color': Color(0xFF003366), 'label': 'Bank BTN'},

    // Bank Digital
    {'name': 'SeaBank', 'type': 'Bank Digital', 'color': Color(0xFFFF5722), 'label': 'SeaBank Indonesia'},
    {'name': 'Bank Jago', 'type': 'Bank Digital', 'color': Color(0xFF5B3482), 'label': 'Bank Jago'},
    {'name': 'Blu by BCA', 'type': 'Bank Digital', 'color': Color(0xFF00C3FF), 'label': 'Blu by BCA Digital'},
    {'name': 'Allobank', 'type': 'Bank Digital', 'color': Color(0xFF8B008B), 'label': 'Allobank'},
    {'name': 'Jenius', 'type': 'Bank Digital', 'color': Color(0xFF00A0E3), 'label': 'Jenius (BTPN)'},
    {'name': 'Bank Neo Commerce', 'type': 'Bank Digital', 'color': Color(0xFFFFD100), 'label': 'Bank Neo Commerce (BNC)'},
  ];

  late String _selectedFlipBank;
  String _selectedAccountOption = 'acc-bca'; // id rekening tersimpan atau '__NEW__'
  bool _saveAccount = true;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _savedAccounts = [
    {
      'id': 'acc-bca',
      'bank': 'BCA',
      'number': '5524 9910 4242',
      'holder': 'SITI RAHMAWATI',
    },
    {
      'id': 'acc-mandiri',
      'bank': 'Mandiri',
      'number': '9012 4432 8810',
      'holder': 'SITI RAHMAWATI',
    },
    {
      'id': 'acc-gopay',
      'bank': 'GoPay',
      'number': '0812 3456 7890',
      'holder': 'SITI RAHMAWATI',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedFlipBank = 'BCA';
    _applySelectedAccount();
    _loadCustomSavedAccounts();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountHolderCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('saved_bank_accounts') ?? [];
      for (final raw in list) {
        final parts = raw.split('||');
        if (parts.length >= 3) {
          final id = 'acc-custom-${parts[0]}-${parts[1]}';
          if (!_savedAccounts.any((a) => a['id'] == id)) {
            _savedAccounts.add({
              'id': id,
              'bank': parts[0],
              'number': parts[1],
              'holder': parts[2],
            });
          }
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _applySelectedAccount() {
    if (_selectedAccountOption == '__NEW__') {
      _accountNumberCtrl.clear();
      _accountHolderCtrl.text = 'SITI RAHMAWATI';
    } else {
      final acc = _savedAccounts.firstWhere(
        (a) => a['id'] == _selectedAccountOption,
        orElse: () => _savedAccounts.first,
      );
      _selectedFlipBank = acc['bank'] as String;
      _accountNumberCtrl.text = acc['number'] as String;
      _accountHolderCtrl.text = acc['holder'] as String;
    }
  }

  void _setPresetAmount(int amt) {
    HapticFeedback.lightImpact();
    setState(() {
      _amountCtrl.text = amt.toString();
    });
  }

  int get _parsedAmount {
    return int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  Future<void> _handleWithdraw() async {
    if (!_formKey.currentState!.validate()) return;

    final wallet = context.read<WalletProvider>();
    final amount = _parsedAmount;
    final totalDeduct = amount + adminFee;

    if (amount < 10000) {
      GageToast.show(context, 'Nominal penarikan minimal Rp 10.000', type: GageToastType.warning);
      return;
    }

    if (totalDeduct > wallet.balance) {
      GageToast.show(
        context,
        'Saldo tidak mencukupi! Total potong: ${currencyFormatter.format(totalDeduct)}',
        type: GageToastType.error,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final bankName = _selectedAccountOption == '__NEW__' ? _selectedFlipBank : _selectedFlipBank;
    final number = _accountNumberCtrl.text.trim();
    final holder = _accountHolderCtrl.text.trim();

    final success = await wallet.withdrawBalance(
      amount: amount,
      adminFee: adminFee,
      bankName: bankName,
      accountNumber: number,
      accountHolder: holder,
    );

    if (_selectedAccountOption == '__NEW__' && _saveAccount) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = '$bankName||$number||$holder';
        final list = prefs.getStringList('saved_bank_accounts') ?? [];
        if (!list.contains(raw)) {
          list.add(raw);
          await prefs.setStringList('saved_bank_accounts', list);
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        GageToast.show(
          context,
          'Penarikan ${currencyFormatter.format(amount)} ke $bankName ($number) berhasil diajukan via Flip!',
          type: GageToastType.success,
        );
      } else {
        GageToast.show(
          context,
          'Gagal memproses penarikan saldo. Silakan coba beberapa saat lagi.',
          type: GageToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amount = _parsedAmount;
    final totalDeduct = amount + (amount > 0 ? adminFee : 0);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.outbox_rounded, color: GageTheme.primary, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tarik Saldo GagePay',
                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Pencairan instan via Flip ke Rekening Bank & E-Wallet',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Saldo Aktif Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saldo Tersedia:',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                Text(
                  currencyFormatter.format(wallet.balance),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: GageTheme.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 1. Pilihan Rekening / E-Wallet Tujuan (DROPDOWN)
          const Text(
            'Rekening Tujuan Penarikan',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedAccountOption,
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            items: [
              ..._savedAccounts.map((acc) {
                return DropdownMenuItem<String>(
                  value: acc['id'] as String,
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card_rounded, size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${acc['bank']} • ${acc['number']} (${acc['holder']})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const DropdownMenuItem<String>(
                value: '__NEW__',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, size: 16, color: GageTheme.primary),
                    SizedBox(width: 8),
                    Text(
                      'Tambah Rekening / E-Wallet Baru',
                      style: TextStyle(color: GageTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _selectedAccountOption = val;
                _applySelectedAccount();
              });
            },
          ),

          // Formulir Tambah Rekening Baru (Muncul jika pilih Tambah Baru)
          if (_selectedAccountOption == '__NEW__') ...[
            const SizedBox(height: 10),
            // Dropdown Pilihan Bank / E-Wallet Kompatibel Flip
            DropdownButtonFormField<String>(
              initialValue: _selectedFlipBank,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Pilih Bank / E-Wallet (Didukung Flip)',
                labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                filled: true,
                fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              items: _flipDestinations.map((dest) {
                return DropdownMenuItem<String>(
                  value: dest['name'] as String,
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: dest['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${dest['name']} (${dest['type']})',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() => _selectedFlipBank = val);
              },
            ),

            const SizedBox(height: 10),

            // Nomor Rekening / HP
            TextFormField(
              controller: _accountNumberCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                labelText: 'Nomor Rekening / No. HP E-Wallet',
                labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                hintText: 'Contoh: 552499104242 atau 08123456789',
                filled: true,
                fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Nomor rekening wajib diisi';
                return null;
              },
            ),

            const SizedBox(height: 8),

            // Nama Pemilik
            TextFormField(
              controller: _accountHolderCtrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                labelText: 'Nama Lengkap Pemilik',
                labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                filled: true,
                fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Nama pemilik rekening wajib diisi';
                return null;
              },
            ),

            const SizedBox(height: 6),

            // Checkbox Simpan Rekening
            Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _saveAccount,
                    activeColor: GageTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => _saveAccount = val ?? true),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Simpan rekening ini untuk penarikan berikutnya',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // 2. Input Nominal Penarikan
          const Text(
            'Nominal Penarikan',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              hintText: 'Min. 10.000',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
              filled: true,
              fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
              ),
            ),
            onChanged: (_) => setState(() {}),
            validator: (val) {
              final amt = _parsedAmount;
              if (amt <= 0) return 'Masukkan nominal penarikan';
              if (amt < 10000) return 'Nominal minimal Rp 10.000';
              if (amt + adminFee > wallet.balance) return 'Saldo tidak mencukupi';
              return null;
            },
          ),

          const SizedBox(height: 8),

          // Quick Amount Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickAmountChip('Rp 20.000', 20000),
                const SizedBox(width: 6),
                _buildQuickAmountChip('Rp 50.000', 50000),
                const SizedBox(width: 6),
                _buildQuickAmountChip('Rp 100.000', 100000),
                const SizedBox(width: 6),
                _buildQuickAmountChip('Tarik Semua', wallet.balance > adminFee ? wallet.balance - adminFee : 0),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Rincian Biaya Box (Biaya Admin Flat Rp 1.000 via Flip)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nominal Dicairkan', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text(currencyFormatter.format(amount), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Biaya Admin Penarikan (via Flip)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text(currencyFormatter.format(adminFee), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estimasi Masuk Rekening', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text('Instan s/d Maks. 24 Jam', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  ],
                ),
                const Divider(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Potong Saldo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(
                      currencyFormatter.format(totalDeduct),
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: GageTheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tombol Tunggal Konfirmasi Penarikan (Tanpa 2x UX / Tanpa Popup PIN Berantai)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleWithdraw,
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Tarik Saldo Sekarang',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountChip(String label, int amt) {
    final isSelected = _parsedAmount == amt && amt > 0;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _setPresetAmount(amt);
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? GageTheme.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? GageTheme.primary : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
