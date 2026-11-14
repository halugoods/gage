import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/utils/luhn_algorithm.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Model data rekening penerima tersimpan
class SavedGageAccount {
  final String accountNumber;
  final String name;
  final bool isFavorite;
  final int lastUsedTimestamp;

  SavedGageAccount({
    required this.accountNumber,
    required this.name,
    this.isFavorite = false,
    required this.lastUsedTimestamp,
  });

  SavedGageAccount copyWith({
    String? accountNumber,
    String? name,
    bool? isFavorite,
    int? lastUsedTimestamp,
  }) {
    return SavedGageAccount(
      accountNumber: accountNumber ?? this.accountNumber,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
      lastUsedTimestamp: lastUsedTimestamp ?? this.lastUsedTimestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'accountNumber': accountNumber,
    'name': name,
    'isFavorite': isFavorite,
    'lastUsedTimestamp': lastUsedTimestamp,
  };

  factory SavedGageAccount.fromJson(Map<String, dynamic> json) => SavedGageAccount(
    accountNumber: (json['accountNumber'] ?? '').toString(),
    name: (json['name'] ?? 'Pengguna GAGE').toString(),
    isFavorite: json['isFavorite'] == true,
    lastUsedTimestamp: json['lastUsedTimestamp'] as int? ?? 0,
  );
}

/// Layar Penuh Kirim Saldo GAGEPay
/// - Menggabungkan form transfer lengkap (Saldo, Input Rekening Tujuan + Cek, Input Nominal + Chips, Catatan, Kirim Sekarang)
/// - Dilengkapi section referensi Rekening Tersimpan (Tab Terakhir vs Favorit, Search Bar, dan bintang favorit tanpa batas)
/// - Menggunakan data riwayat transaksi asli pengguna (tanpa dummy hardcode palsu)
/// - Auto-fill saat memilih rekening dari riwayat tersimpan
/// - Auto-save nomor rekening tujuan baru saat transfer berhasil
class GagePayTransferScreen extends StatefulWidget {
  final String? initialAccount;
  final int? initialAmount;

  const GagePayTransferScreen({
    super.key,
    this.initialAccount,
    this.initialAmount,
  });

  @override
  State<GagePayTransferScreen> createState() => _GagePayTransferScreenState();
}

class _GagePayTransferScreenState extends State<GagePayTransferScreen> {
  final TextEditingController _accountCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  bool _isCheckingAccount = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _verifiedRecipient;
  String? _accountError;

  int _selectedTab = 0; // 0 = Terakhir, 1 = Favorit
  String _searchQuery = '';
  List<SavedGageAccount> _savedAccounts = [];

  final List<int> _quickNominals = [10000, 20000, 50000, 100000];

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();

    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amountCtrl.text = widget.initialAmount.toString();
    }

    if (widget.initialAccount != null && widget.initialAccount!.isNotEmpty) {
      _accountCtrl.text = widget.initialAccount!;
      _checkRecipientAccount();
    }
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getStorageKey() {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id ?? 'guest';
    return 'saved_gagepay_recipients_$userId';
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final key = _getStorageKey();
      final wallet = context.read<WalletProvider>();

      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(key);

      List<SavedGageAccount> loaded = [];
      if (rawJson != null && rawJson.isNotEmpty) {
        final List decoded = jsonDecode(rawJson);
        loaded = decoded.map((e) => SavedGageAccount.fromJson(e as Map<String, dynamic>)).toList();
      }

      // Gabungkan dengan transaksi transfer nyata dari wallet jika ada yang belum tercatat
      for (final tx in wallet.transactions) {
        if (tx['type'] == 'TRANSFER_OUT') {
          var dest = (tx['destination'] ?? '').toString();
          var rName = (tx['recipient_name'] ?? '').toString();
          if (dest.isEmpty || rName.isEmpty) {
            final desc = (tx['description'] ?? '').toString();
            final match = RegExp(r'Transfer ke (.*?) \((\d+)\)').firstMatch(desc);
            if (match != null) {
              if (rName.isEmpty) rName = match.group(1) ?? 'Penerima GAGEPay';
              if (dest.isEmpty) dest = match.group(2) ?? '';
            }
          }
          final ts = tx['timestamp'] is int
              ? (tx['timestamp'] as int) * 1000
              : (tx['created_at'] is int
                  ? (tx['created_at'] as int) * 1000
                  : DateTime.now().millisecondsSinceEpoch);

          if (dest.isNotEmpty && !loaded.any((a) => a.accountNumber == dest)) {
            loaded.add(SavedGageAccount(
              accountNumber: dest,
              name: rName.isNotEmpty ? rName : 'Penerima GAGEPay',
              isFavorite: false,
              lastUsedTimestamp: ts,
            ));
          }
        }
      }

      _sortAccounts(loaded);

      if (mounted) {
        setState(() {
          _savedAccounts = loaded;
        });
      }
    } catch (_) {}
  }

  void _sortAccounts(List<SavedGageAccount> list) {
    list.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return b.lastUsedTimestamp.compareTo(a.lastUsedTimestamp);
    });
  }

  Future<void> _persistAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey();
      final data = jsonEncode(_savedAccounts.map((e) => e.toJson()).toList());
      await prefs.setString(key, data);
    } catch (_) {}
  }

  /// Toggle status favorit tanpa batasan kuota (unlimited)
  void _toggleFavorite(SavedGageAccount account) {
    HapticFeedback.selectionClick();
    setState(() {
      final idx = _savedAccounts.indexWhere((a) => a.accountNumber == account.accountNumber);
      if (idx != -1) {
        final current = _savedAccounts[idx];
        _savedAccounts[idx] = current.copyWith(isFavorite: !current.isFavorite);
        _sortAccounts(_savedAccounts);
        _persistAccounts();
      }
    });
  }

  /// Memilih rekening dari riwayat untuk auto-fill form di atas
  void _selectSavedAccountToForm(SavedGageAccount account) {
    HapticFeedback.selectionClick();
    _accountCtrl.text = account.accountNumber;
    _checkRecipientAccount();
    // Scroll ke atas agar pengguna dapat langsung memasukkan nominal
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _checkRecipientAccount() async {
    final raw = _accountCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _accountError = 'Masukkan nomor rekening atau HP tujuan';
        _verifiedRecipient = null;
      });
      return;
    }

    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
    // Jika format nomor rekening 12 digit, validasi dengan Algoritma Luhn Mod 10
    if (digitsOnly.length == 12 && digitsOnly.startsWith('89') && !LuhnAlgorithm.validate(digitsOnly)) {
      setState(() {
        _accountError = 'Nomor rekening tidak valid (kesalahan digit check Luhn). Periksa kembali.';
        _verifiedRecipient = null;
        _isCheckingAccount = false;
      });
      return;
    }

    setState(() {
      _isCheckingAccount = true;
      _accountError = null;
      _verifiedRecipient = null;
    });

    try {
      final res = await GageApiClient.getGagePayAccount(raw);
      if (!mounted) return;
      if (res != null) {
        setState(() {
          _verifiedRecipient = res;
          _isCheckingAccount = false;
        });
        HapticFeedback.selectionClick();
      } else {
        setState(() {
          _accountError = 'Akun GAGEPay tidak ditemukan. Periksa kembali nomor tujuan.';
          _isCheckingAccount = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _accountError = 'Gagal memeriksa akun tujuan.';
        _isCheckingAccount = false;
      });
    }
  }

  Future<void> _submitTransfer(WalletProvider wallet, AuthProvider auth) async {
    HapticFeedback.mediumImpact();
    if (_verifiedRecipient == null) {
      await _checkRecipientAccount();
      if (!mounted) return;
      if (_verifiedRecipient == null) return;
    }

    final rawAmount = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (rawAmount < 1000) {
      GageToast.show(context, 'Nominal transfer minimal Rp 1.000', type: GageToastType.warning);
      return;
    }

    if (rawAmount > wallet.balance) {
      GageToast.show(context, 'Saldo GAGEPay tidak mencukupi', type: GageToastType.warning);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final fromUid = auth.currentUser?.id ?? (GageApiClient.useDevSeedData ? 'usr-cust-01' : '');
      final targetAccount = _verifiedRecipient!['account_number'] ?? _accountCtrl.text.trim();
      final targetName = _verifiedRecipient!['name'] ?? 'Penerima GAGEPay';
      final note = _noteCtrl.text.trim();

      // Panggil backend transfer API
      if (fromUid.isNotEmpty) {
        await GageApiClient.transferGagePay(
          fromUserId: fromUid,
          toAccount: targetAccount,
          amount: rawAmount,
          note: note,
        );
      }

      // Update provider lokal
      await wallet.transferBalance(
        recipientAccount: targetAccount,
        recipientName: targetName,
        amount: rawAmount,
        note: note,
      );

      // Auto-save rekening ke riwayat tersimpan lokal
      final now = DateTime.now().millisecondsSinceEpoch;
      final existingIdx = _savedAccounts.indexWhere((a) => a.accountNumber == targetAccount);
      if (existingIdx != -1) {
        _savedAccounts[existingIdx] = _savedAccounts[existingIdx].copyWith(lastUsedTimestamp: now);
      } else {
        _savedAccounts.insert(
          0,
          SavedGageAccount(
            accountNumber: targetAccount,
            name: targetName,
            isFavorite: false,
            lastUsedTimestamp: now,
          ),
        );
      }
      _sortAccounts(_savedAccounts);
      await _persistAccounts();

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      HapticFeedback.heavyImpact();

      // Tampilkan dialog sukses transfer
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Transfer Berhasil!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Saldo ${currencyFormatter.format(rawAmount)} berhasil dikirimkan ke $targetName (${LuhnAlgorithm.formatWithSpaces(targetAccount)}).',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  minimumSize: const Size.fromHeight(44),
                  elevation: 0,
                ),
                child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      GageToast.show(context, 'Transfer gagal diproses: $e', type: GageToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallet = context.watch<WalletProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Kirim Saldo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Kartu Saldo Pengirim
            _buildSenderBalanceCard(wallet, isDark),

            const SizedBox(height: 16),

            // 2. Card Input Rekening / HP Penerima + Tombol Cek
            _buildRecipientInputCard(isDark),

            const SizedBox(height: 16),

            // 3. Card Input Nominal & Catatan Transfer
            _buildNominalAndNoteCard(wallet, isDark),

            const SizedBox(height: 20),

            // 4. Tombol Kirim Sekarang
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _submitTransfer(wallet, auth),
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Kirim Sekarang',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
            ),

            const SizedBox(height: 28),

            // 5. Section Rekening Tersimpan (Referensi Tab Terakhir vs Favorit)
            _buildSavedRecipientsSection(isDark),
          ],
        ),
      ),
    );
  }

  /// 1. Kartu Saldo Pengirim
  Widget _buildSenderBalanceCard(WalletProvider wallet, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo GAGEPay Anda',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currencyFormatter.format(wallet.balance),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GageTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: GageTheme.primary, size: 22),
          ),
        ],
      ),
    );
  }

  /// 2. Card Input Rekening Penerima
  Widget _buildRecipientInputCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nomor Rekening / HP Penerima',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _accountCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    if (_verifiedRecipient != null) {
                      setState(() => _verifiedRecipient = null);
                    }
                  },
                  style: TextStyle(
                    fontSize: 14.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 8908 1234 5678 / 08123...',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isCheckingAccount ? null : _checkRecipientAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  elevation: 0,
                ),
                child: _isCheckingAccount
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Cek', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),

          if (_accountError != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: Colors.redAccent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _accountError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],

          // Tampilan Akun Terverifikasi
          if (_verifiedRecipient != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF16A34A),
                    child: Text(
                      (_verifiedRecipient!['name'] ?? 'G').toString()[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _verifiedRecipient!['name'] ?? 'Penerima GAGEPay',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: Color(0xFF14532D),
                          ),
                        ),
                        Text(
                          'GAGEPay: ${LuhnAlgorithm.formatWithSpaces((_verifiedRecipient!['account_number'] ?? _accountCtrl.text).toString())}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontFamily: 'monospace',
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 20),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 3. Card Input Nominal & Catatan
  Widget _buildNominalAndNoteCard(WalletProvider wallet, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nominal Transfer',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GageTheme.primary, width: 1.5),
            ),
            child: TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: GageTheme.primary),
                hintText: '0',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Quick Nominal Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickNominals.map((nom) {
              return ActionChip(
                backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                shape: const StadiumBorder(),
                side: BorderSide(
                  color: _amountCtrl.text == nom.toString()
                      ? GageTheme.primary
                      : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                label: Text(
                  currencyFormatter.format(nom),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _amountCtrl.text == nom.toString()
                        ? GageTheme.primary
                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _amountCtrl.text = nom.toString());
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Catatan Transfer (Opsional)
          Text(
            'Catatan (Opsional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLength: 60,
            decoration: InputDecoration(
              hintText: 'Contoh: Bayar makan siang',
              hintStyle: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
              counterText: '',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Section Rekening Tersimpan (Referensi Tab Terakhir vs Favorit)
  Widget _buildSavedRecipientsSection(bool isDark) {
    // Filter list berdasarkan tab
    List<SavedGageAccount> listToShow;
    if (_selectedTab == 0) {
      listToShow = List.of(_savedAccounts)
        ..sort((a, b) => b.lastUsedTimestamp.compareTo(a.lastUsedTimestamp));
    } else {
      listToShow = _savedAccounts.where((a) => a.isFavorite).toList()
        ..sort((a, b) => b.lastUsedTimestamp.compareTo(a.lastUsedTimestamp));
    }

    // Filter berdasarkan kolom pencarian
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      listToShow = listToShow.where((a) {
        return a.name.toLowerCase().contains(q) || a.accountNumber.contains(q);
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rekening Tersimpan',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            if (_savedAccounts.isNotEmpty)
              Text(
                '${_savedAccounts.length} Rekening',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        // Segmented Capsule Tab: "Terakhir" vs "Favorit"
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              _buildSegmentTab(index: 0, label: 'Terakhir', isSelected: _selectedTab == 0, isDark: isDark),
              _buildSegmentTab(index: 1, label: 'Favorit', isSelected: _selectedTab == 1, isDark: isDark),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Search Bar: "Cari penerima di sini"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              icon: Icon(
                Icons.search_rounded,
                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                size: 20,
              ),
              hintText: 'Cari penerima di sini',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                fontSize: 13,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // List Rekening Tersimpan
        if (listToShow.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(
                  _selectedTab == 1 ? Icons.star_outline_rounded : Icons.history_rounded,
                  size: 38,
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedTab == 1
                      ? 'Belum ada rekening favorit'
                      : 'Belum ada riwayat transfer',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedTab == 1
                      ? 'Ketuk ikon bintang pada rekening di tab Terakhir untuk menyimpannya sebagai favorit.'
                      : 'Lakukan transfer pertama Anda menggunakan formulir di atas untuk menyimpan riwayat otomatis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: listToShow.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 0.8,
              indent: 58,
              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
            ),
            itemBuilder: (ctx, idx) {
              final acc = listToShow[idx];
              return _buildSavedAccountTile(acc, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildSegmentTab({
    required int index,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? GageTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedAccountTile(SavedGageAccount acc, bool isDark) {
    final formatted = LuhnAlgorithm.formatWithSpaces(acc.accountNumber);
    final initial = acc.name.isNotEmpty ? acc.name[0].toUpperCase() : 'G';

    final colors = [
      const Color(0xFF0284C7),
      const Color(0xFFEA580C),
      const Color(0xFF16A34A),
      const Color(0xFF7C3AED),
      const Color(0xFF0D9488),
    ];
    final avatarColor = colors[acc.name.hashCode.abs() % colors.length];

    return InkWell(
      onTap: () => _selectSavedAccountToForm(acc),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: avatarColor,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    acc.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'GAGEPay: $formatted',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                acc.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: const Color(0xFFF59E0B),
                size: 24,
              ),
              onPressed: () => _toggleFavorite(acc),
            ),
          ],
        ),
      ),
    );
  }
}
