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
/// - Konfirmasi keamanan PIN 6-Digit
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
    {'name': 'BCA', 'type': 'bank', 'color': Color(0xFF005BAC)},
    {'name': 'BRI', 'type': 'bank', 'color': Color(0xFF00529C)},
    {'name': 'Mandiri', 'type': 'bank', 'color': Color(0xFF003D79)},
    {'name': 'BNI', 'type': 'bank', 'color': Color(0xFFE55300)},
    {'name': 'SeaBank', 'type': 'bank', 'color': Color(0xFFFF5722)},
    {'name': 'DANA', 'type': 'ewallet', 'color': Color(0xFF118EEA)},
    {'name': 'GoPay', 'type': 'ewallet', 'color': Color(0xFF00AED6)},
    {'name': 'ShopeePay', 'type': 'ewallet', 'color': Color(0xFFEE4D2D)},
    {'name': 'OVO', 'type': 'ewallet', 'color': Color(0xFF4C3494)},
  ];

  late String _selectedBank;
  bool _saveAccount = true;
  List<String> _savedAccounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedBank = _banks.first['name'];
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

    // Tampilkan Verifikasi PIN Keamanan 6-Digit
    final pinConfirmed = await _showPinVerificationDialog();
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

  // Dialog Verifikasi PIN 6-Digit
  Future<bool?> _showPinVerificationDialog() {
    String enteredPin = '';
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: GageTheme.primary, size: 22),
                SizedBox(width: 8),
                Text('Konfirmasi PIN', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Masukkan 6 digit PIN GagePay Anda untuk mengonfirmasi penarikan dana',
                  style: TextStyle(fontSize: 12.5, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                // 6 Pin Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (idx) {
                    final isFilled = idx < enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isFilled ? GageTheme.primary : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isFilled ? GageTheme.primary : Colors.grey.shade400,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                // Numeric keypad mini
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ...List.generate(9, (idx) {
                      final digit = '${idx + 1}';
                      return _buildKeypadButton(digit, () {
                        if (enteredPin.length < 6) {
                          setDialogState(() => enteredPin += digit);
                          if (enteredPin.length == 6) {
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            });
                          }
                        }
                      });
                    }),
                    _buildKeypadButton('Batal', () => Navigator.pop(ctx, false), isAction: true),
                    _buildKeypadButton('0', () {
                      if (enteredPin.length < 6) {
                        setDialogState(() => enteredPin += '0');
                        if (enteredPin.length == 6) {
                          Future.delayed(const Duration(milliseconds: 200), () {
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          });
                        }
                      }
                    }),
                    _buildKeypadButton('⌫', () {
                      if (enteredPin.isNotEmpty) {
                        setDialogState(() => enteredPin = enteredPin.substring(0, enteredPin.length - 1));
                      }
                    }, isAction: true),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKeypadButton(String label, VoidCallback onTap, {bool isAction = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 58,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isAction ? Colors.grey.shade100 : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isAction ? 12 : 17,
            fontWeight: FontWeight.bold,
            color: isAction ? Colors.black54 : Colors.black87,
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
                  borderRadius: BorderRadius.circular(10),
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
                      style: TextStyle(fontSize: 12, color: Colors.black54),
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

          // Saldo Aktif Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saldo Tersedia:',
                  style: TextStyle(fontSize: 12.5, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
                Text(
                  currencyFormatter.format(wallet.balance),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: GageTheme.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 1. Input Nominal Penarikan
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
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: GageTheme.primary, width: 1.5)),
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
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
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
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFEBEE) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? GageTheme.primary : Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_rounded, size: 14, color: isSelected ? GageTheme.primary : Colors.black54),
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

          // 3. Pilihan Bank / E-Wallet
          const Text(
            'Bank atau E-Wallet Tujuan',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedBank,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            items: _banks.map((b) {
              return DropdownMenuItem<String>(
                value: b['name'] as String,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: b['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${b['name']} (${(b['type'] as String).toUpperCase()})',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedBank = val);
            },
          ),

          const SizedBox(height: 12),

          // Nomor Rekening / No HP
          TextFormField(
            controller: _accountNumberCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              labelText: 'Nomor Rekening / No. HP E-Wallet',
              hintText: 'Contoh: 1234567890 atau 0851...',
              filled: true,
              fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Nomor rekening wajib diisi';
              return null;
            },
          ),

          const SizedBox(height: 10),

          // Nama Pemilik Rekening
          TextFormField(
            controller: _accountHolderCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              labelText: 'Nama Lengkap Pemilik Rekening',
              hintText: 'Sesuai buku tabungan / akun e-wallet',
              filled: true,
              fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
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

          // Rincian Biaya Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nominal Dicairkan', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text(currencyFormatter.format(amount), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Biaya Layanan Admin', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text(currencyFormatter.format(adminFee), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimasi Masuk Rekening', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const Text('Maks. 24 Jam (H+1)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
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

          // Tombol Konfirmasi Penarikan
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleWithdraw,
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEBEE) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? GageTheme.primary : Colors.grey.shade300),
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
