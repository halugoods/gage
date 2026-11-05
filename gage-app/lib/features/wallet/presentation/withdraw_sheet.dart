import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Floating Bottom Sheet Penarikan Dana GagePay (Withdrawal)
/// - Menghubungkan ke Bank (BCA, BRI, Mandiri, BNI, Seabank) & E-Wallet (DANA, GoPay, ShopeePay, OVO)
/// - Biaya admin flat Rp 1.000 (arbitrase transfer gratis via Flip, 100% net profit GAGE)
/// - UI Modern: Full-rounded capsule input fields, Modern Bank Selector Card & Interactive Picker Sheet,
///   PIN verification in GageFloatingSheet, dan stadium action button.
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

  final List<Map<String, dynamic>> _banks = [
    {'name': 'BCA', 'type': 'bank', 'color': Color(0xFF005BAC), 'label': 'Bank Central Asia'},
    {'name': 'BRI', 'type': 'bank', 'color': Color(0xFF00529C), 'label': 'Bank Rakyat Indonesia'},
    {'name': 'Mandiri', 'type': 'bank', 'color': Color(0xFF003D79), 'label': 'Bank Mandiri'},
    {'name': 'BNI', 'type': 'bank', 'color': Color(0xFFE55300), 'label': 'Bank Negara Indonesia'},
    {'name': 'SeaBank', 'type': 'bank', 'color': Color(0xFFFF5722), 'label': 'SeaBank Indonesia'},
    {'name': 'DANA', 'type': 'ewallet', 'color': Color(0xFF118EEA), 'label': 'Dompet Digital DANA'},
    {'name': 'GoPay', 'type': 'ewallet', 'color': Color(0xFF00AED6), 'label': 'GoPay Wallet'},
    {'name': 'ShopeePay', 'type': 'ewallet', 'color': Color(0xFFEE4D2D), 'label': 'ShopeePay Balance'},
    {'name': 'OVO', 'type': 'ewallet', 'color': Color(0xFF4C3494), 'label': 'OVO Cash'},
  ];

  late String _selectedBank;
  bool _saveAccount = true;
  List<String> _savedAccounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedBank = _banks.first['name'] as String;
    _loadSavedAccounts();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountHolderCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('saved_bank_accounts') ?? [];
      if (mounted) {
        setState(() {
          _savedAccounts = list;
          if (_savedAccounts.isNotEmpty) {
            _fillFromSaved(_savedAccounts.first);
          }
        });
      }
    } catch (_) {}
  }

  void _fillFromSaved(String raw) {
    final parts = raw.split('||');
    if (parts.length >= 3) {
      setState(() {
        _selectedBank = parts[0];
        _accountNumberCtrl.text = parts[1];
        _accountHolderCtrl.text = parts[2];
      });
    }
  }

  void _setPresetAmount(int amt) {
    setState(() {
      _amountCtrl.text = amt.toString();
    });
  }

  int get _parsedAmount {
    return int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  Map<String, dynamic> get _currentBankObj {
    return _banks.firstWhere(
      (b) => b['name'] == _selectedBank,
      orElse: () => _banks.first,
    );
  }

  void _showBankSelectorSheet() {
    GageFloatingSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_rounded, color: GageTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pilih Rekening Tujuan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Transfer Bank',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          ..._banks.where((b) => b['type'] == 'bank').map((b) => _buildBankItem(b)),
          const SizedBox(height: 12),
          const Text(
            'E-Wallet',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          ..._banks.where((b) => b['type'] == 'ewallet').map((b) => _buildBankItem(b)),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBankItem(Map<String, dynamic> b) {
    final isSelected = _selectedBank == b['name'];
    return InkWell(
      onTap: () {
        setState(() => _selectedBank = b['name'] as String);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEBEE) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? GageTheme.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: b['color'] as Color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b['name'] as String,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? GageTheme.primary : Colors.black87,
                    ),
                  ),
                  Text(
                    b['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? GageTheme.primary.withValues(alpha: 0.8) : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: GageTheme.primary, size: 20),
          ],
        ),
      ),
    );
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

    // Tampilkan Verifikasi PIN Keamanan 6-Digit via GageFloatingSheet
    final pinConfirmed = await _showPinVerificationSheet();
    if (pinConfirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    final success = await wallet.withdrawBalance(
      amount: amount,
      adminFee: adminFee,
      bankName: _selectedBank,
      accountNumber: _accountNumberCtrl.text.trim(),
      accountHolder: _accountHolderCtrl.text.trim(),
    );

    if (_saveAccount) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = '$_selectedBank||${_accountNumberCtrl.text.trim()}||${_accountHolderCtrl.text.trim()}';
        if (!_savedAccounts.contains(raw)) {
          _savedAccounts.add(raw);
          await prefs.setStringList('saved_bank_accounts', _savedAccounts);
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        GageToast.show(
          context,
          'Penarikan ${currencyFormatter.format(amount)} berhasil diajukan! Dana diproses maks. 24 jam.',
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

  // Verifikasi PIN 6-Digit Berbasis GageFloatingSheet (Bukan Modal Kentang)
  Future<bool?> _showPinVerificationSheet() {
    String enteredPin = '';
    return GageFloatingSheet.show<bool>(
      context: context,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: GageTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline_rounded, color: GageTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Konfirmasi PIN GAGEPay',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan 6 digit PIN GagePay Anda untuk mengonfirmasi penarikan dana',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // 6 PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (idx) {
                  final isFilled = idx < enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isFilled ? GageTheme.primary : const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isFilled ? GageTheme.primary : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              // Modern Capsule Keypad
              Wrap(
                spacing: 16,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ...List.generate(9, (idx) {
                    final digit = '${idx + 1}';
                    return _buildCapsuleKeypadButton(digit, () {
                      if (enteredPin.length < 6) {
                        setSheetState(() => enteredPin += digit);
                        if (enteredPin.length == 6) {
                          Future.delayed(const Duration(milliseconds: 200), () {
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          });
                        }
                      }
                    });
                  }),
                  _buildCapsuleKeypadButton('Batal', () => Navigator.pop(ctx, false), isAction: true),
                  _buildCapsuleKeypadButton('0', () {
                    if (enteredPin.length < 6) {
                      setSheetState(() => enteredPin += '0');
                      if (enteredPin.length == 6) {
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        });
                      }
                    }
                  }),
                  _buildCapsuleKeypadButton('⌫', () {
                    if (enteredPin.isNotEmpty) {
                      setSheetState(() => enteredPin = enteredPin.substring(0, enteredPin.length - 1));
                    }
                  }, isAction: true),
                ],
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCapsuleKeypadButton(String label, VoidCallback onTap, {bool isAction = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 64,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isAction ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isAction ? 12.5 : 18,
            fontWeight: FontWeight.bold,
            color: isAction ? const Color(0xFF64748B) : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amount = _parsedAmount;
    final totalDeduct = amount + (amount > 0 ? adminFee : 0);
    final bankObj = _currentBankObj;

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
                      'Pencairan ke rekening bank & e-wallet',
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

          const SizedBox(height: 14),

          // Saldo Aktif Banner (Rounded 20px)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
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

          const SizedBox(height: 16),

          // 1. Input Nominal Penarikan (Capsule Pill Rounded 24px)
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
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

          // Quick Amount Chips (Capsule Pill)
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
                _buildQuickAmountChip('Semua Saldo', wallet.balance > adminFee ? wallet.balance - adminFee : 0),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Rekening Tersimpan (Jika Ada)
          if (_savedAccounts.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rekening Tersimpan',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  '${_savedAccounts.length} rekening',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _savedAccounts.length,
                separatorBuilder: (_, idx) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final raw = _savedAccounts[idx];
                  final parts = raw.split('||');
                  final bName = parts.isNotEmpty ? parts[0] : '';
                  final accNum = parts.length > 1 ? parts[1] : '';
                  final isSelected = _selectedBank == bName && _accountNumberCtrl.text == accNum;

                  return InkWell(
                    onTap: () => _fillFromSaved(raw),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFEBEE) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? GageTheme.primary : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_rounded, size: 14, color: isSelected ? GageTheme.primary : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            '$bName • $accNum',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? GageTheme.primary : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 3. Pilihan Bank / E-Wallet (Modern Selector Card)
          const Text(
            'Bank atau E-Wallet Tujuan',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _showBankSelectorSheet,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: bankObj['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${bankObj['name']} (${(bankObj['type'] as String).toUpperCase()}) - ${bankObj['label']}',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Nomor Rekening / No HP (Capsule Pill Rounded 24px)
          TextFormField(
            controller: _accountNumberCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              labelText: 'Nomor Rekening / No. HP E-Wallet',
              labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              hintText: 'Contoh: 1234567890 atau 0851...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true,
              fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Nomor rekening wajib diisi';
              return null;
            },
          ),

          const SizedBox(height: 10),

          // Nama Pemilik Rekening (Capsule Pill Rounded 24px)
          TextFormField(
            controller: _accountHolderCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              labelText: 'Nama Lengkap Pemilik Rekening',
              labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              hintText: 'Sesuai buku tabungan / akun e-wallet',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true,
              fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Nama pemilik rekening wajib diisi';
              return null;
            },
          ),

          const SizedBox(height: 8),

          // Checkbox Simpan Rekening
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _saveAccount,
                  activeColor: GageTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) => setState(() => _saveAccount = val ?? true),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Simpan rekening untuk penarikan berikutnya',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Rincian Biaya Box (Rounded 20px)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
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
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Biaya Layanan Admin', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text(currencyFormatter.format(adminFee), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estimasi Masuk Rekening', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text('Maks. 24 Jam (H+1)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pemotongan Saldo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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

          // Tombol Konfirmasi Penarikan (Full Stadium Pill 28px)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleWithdraw,
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Konfirmasi Penarikan Dana',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
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
      onTap: () => _setPresetAmount(amt),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEBEE) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? GageTheme.primary : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? GageTheme.primary : Colors.black87,
          ),
        ),
      ),
    );
  }
}
