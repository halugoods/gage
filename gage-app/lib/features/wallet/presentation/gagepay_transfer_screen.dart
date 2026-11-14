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
/// - Mengadopsi tata letak referensi transaksi (Tab Terakhir vs Favorit + Search Bar)
/// - Segmented capsule switch penuh (BorderRadius.circular(999), merah aktif GageTheme.primary)
/// - Search Bar "Cari penerima di sini"
/// - List kontak penerima dengan Avatar inisial, Nama, "GAGEPay: 8908 XXXX XXXX", dan Bintang Favorit
/// - Bintang favorit tanpa batasan kuota (unlimited)
/// - Auto-save rekening baru saat transaksi berhasil
/// - Mendukung prefill `initialAccount` dan `initialAmount` dari Universal Scanner (QR dinamis)
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
  int _selectedTab = 0; // 0 = Terakhir, 1 = Favorit
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Step 2 Controller
  SavedGageAccount? _selectedRecipient;
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  bool _isCheckingAccount = false;
  bool _isSubmitting = false;

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
      _checkAndSetInitialAccount(widget.initialAccount!);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _getStorageKey() {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id ?? 'guest';
    return 'saved_gagepay_recipients_$userId';
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey();
      final rawJson = prefs.getString(key);

      List<SavedGageAccount> loaded = [];
      if (rawJson != null && rawJson.isNotEmpty) {
        final List decoded = jsonDecode(rawJson);
        loaded = decoded.map((e) => SavedGageAccount.fromJson(e as Map<String, dynamic>)).toList();
      } else if (GageApiClient.useDevSeedData) {
        // Seed default kontak dev agar daftar langsung terisi menyerupai referensi
        loaded = [
          SavedGageAccount(
            accountNumber: '890811223348',
            name: 'Dnid Selvi Agus',
            isFavorite: true,
            lastUsedTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
          SavedGageAccount(
            accountNumber: '890855667780',
            name: 'Dnid Dwi Purwanto',
            isFavorite: true,
            lastUsedTimestamp: DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
          ),
          SavedGageAccount(
            accountNumber: '890899887765',
            name: 'Heri Susanto',
            isFavorite: false,
            lastUsedTimestamp: DateTime.now().subtract(const Duration(hours: 8)).millisecondsSinceEpoch,
          ),
          SavedGageAccount(
            accountNumber: '890825812191',
            name: 'Indah Lestari',
            isFavorite: false,
            lastUsedTimestamp: DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch,
          ),
          SavedGageAccount(
            accountNumber: '890818840100',
            name: 'Aan Adhi Pratama',
            isFavorite: false,
            lastUsedTimestamp: DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
          ),
        ];
        await prefs.setString(key, jsonEncode(loaded.map((e) => e.toJson()).toList()));
      }

      if (mounted) {
        setState(() {
          _savedAccounts = loaded;
        });
      }
    } catch (_) {}
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
        _persistAccounts();
      }
    });
  }

  Future<void> _checkAndSetInitialAccount(String rawAccount) async {
    setState(() => _isCheckingAccount = true);
    try {
      final res = await GageApiClient.getGagePayAccount(rawAccount);
      if (!mounted) return;
      if (res != null) {
        final accNum = (res['account_number'] ?? rawAccount).toString();
        final name = (res['name'] ?? 'Penerima GAGEPay').toString();
        setState(() {
          _selectedRecipient = SavedGageAccount(
            accountNumber: accNum,
            name: name,
            lastUsedTimestamp: DateTime.now().millisecondsSinceEpoch,
          );
          _isCheckingAccount = false;
        });
      } else {
        setState(() {
          _isCheckingAccount = false;
        });
        GageToast.show(context, 'Akun GAGEPay tujuan tidak ditemukan.', type: GageToastType.error);
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingAccount = false);
    }
  }

  Future<void> _selectCustomAccount(String raw) async {
    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 12 && digitsOnly.startsWith('89') && !LuhnAlgorithm.validate(digitsOnly)) {
      GageToast.show(
        context,
        'Nomor rekening tidak valid (kesalahan digit check Luhn).',
        type: GageToastType.warning,
      );
      return;
    }

    setState(() => _isCheckingAccount = true);
    try {
      final res = await GageApiClient.getGagePayAccount(raw);
      if (!mounted) return;
      if (res != null) {
        final accNum = (res['account_number'] ?? raw).toString();
        final name = (res['name'] ?? 'Penerima GAGEPay').toString();
        HapticFeedback.selectionClick();
        setState(() {
          _selectedRecipient = SavedGageAccount(
            accountNumber: accNum,
            name: name,
            lastUsedTimestamp: DateTime.now().millisecondsSinceEpoch,
          );
          _isCheckingAccount = false;
          _searchCtrl.clear();
          _searchQuery = '';
        });
      } else {
        setState(() => _isCheckingAccount = false);
        GageToast.show(context, 'Akun GAGEPay tidak ditemukan.', type: GageToastType.error);
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingAccount = false);
      GageToast.show(context, 'Gagal memeriksa akun.', type: GageToastType.error);
    }
  }

  void _selectSavedRecipient(SavedGageAccount account) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedRecipient = account;
    });
  }

  Future<void> _submitTransfer(WalletProvider wallet, AuthProvider auth) async {
    if (_selectedRecipient == null) return;
    HapticFeedback.mediumImpact();

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
      final targetAccount = _selectedRecipient!.accountNumber;
      final targetName = _selectedRecipient!.name;
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

      // Auto-save rekening ke persistent storage
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
      await _persistAccounts();

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      HapticFeedback.heavyImpact();

      // Dialog sukses transfer
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
        title: const Text(
          'Kirim Saldo',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_selectedRecipient != null) {
              setState(() => _selectedRecipient = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _selectedRecipient != null
          ? _buildStep2Nominal(wallet, auth, isDark)
          : _buildStep1RecipientList(isDark),
    );
  }

  /// Step 1: Daftar Rekening Tersimpan (Sesuai Referensi Gambar)
  Widget _buildStep1RecipientList(bool isDark) {
    // Filter berdasarkan tab
    List<SavedGageAccount> listToShow;
    if (_selectedTab == 0) {
      // Tab Terakhir: Urutkan berdasarkan waktu terakhir digunakan
      listToShow = List.of(_savedAccounts)
        ..sort((a, b) => b.lastUsedTimestamp.compareTo(a.lastUsedTimestamp));
    } else {
      // Tab Favorit: Hanya yang berbintang
      listToShow = _savedAccounts.where((a) => a.isFavorite).toList()
        ..sort((a, b) => b.lastUsedTimestamp.compareTo(a.lastUsedTimestamp));
    }

    // Filter pencarian
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      listToShow = listToShow.where((a) {
        return a.name.toLowerCase().contains(q) || a.accountNumber.contains(q);
      }).toList();
    }

    return Column(
      children: [
        // 1. Segmented Capsule Tab: "Terakhir" vs "Favorit"
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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

        // 2. Search Bar: "Cari penerima di sini"
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            style: TextStyle(
              fontSize: 14,
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
                fontSize: 13.5,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
        ),

        const SizedBox(height: 6),

        // 3. Opsi Transfer ke Nomor Rekening Baru (Jika Sedang Mencari)
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Material(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _isCheckingAccount ? null : () => _selectCustomAccount(_searchQuery),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: GageTheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: GageTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kirim ke "$_searchQuery"',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ketik nomor rekening GAGEPay (12 digit)',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isCheckingAccount)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 4. Daftar Penerima (Sesuai Referensi Gambar)
        Expanded(
          child: listToShow.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: listToShow.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 0.8,
                    indent: 62,
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  ),
                  itemBuilder: (ctx, idx) {
                    final acc = listToShow[idx];
                    return _buildRecipientTile(acc, isDark);
                  },
                ),
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
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? GageTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
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

  Widget _buildRecipientTile(SavedGageAccount acc, bool isDark) {
    final formatted = LuhnAlgorithm.formatWithSpaces(acc.accountNumber);
    final initial = acc.name.isNotEmpty ? acc.name[0].toUpperCase() : 'G';

    // Warna avatar berganti dinamis berdasarkan nama
    final colors = [
      const Color(0xFF0284C7),
      const Color(0xFFEA580C),
      const Color(0xFF16A34A),
      const Color(0xFF7C3AED),
      const Color(0xFF0D9488),
    ];
    final avatarColor = colors[acc.name.hashCode.abs() % colors.length];

    return InkWell(
      onTap: () => _selectSavedRecipient(acc),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            // Avatar inisial bulat
            CircleAvatar(
              radius: 21,
              backgroundColor: avatarColor,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Nama & Nomor Rekening
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    acc.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'GAGEPay: $formatted',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            // Tombol Bintang Favorit (Emas) - Tanpa batas kuota
            IconButton(
              icon: Icon(
                acc.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: const Color(0xFFF59E0B),
                size: 26,
              ),
              onPressed: () => _toggleFavorite(acc),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTab == 1 ? Icons.star_outline_rounded : Icons.history_rounded,
              size: 54,
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedTab == 1
                  ? 'Belum ada penerima favorit'
                  : 'Belum ada riwayat penerima',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedTab == 1
                  ? 'Ketuk ikon bintang pada penerima untuk menandai kontak favorit tanpa batas.'
                  : 'Gunakan kolom pencarian di atas untuk mulai mengirim ke rekening GAGEPay baru.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Step 2: Input Nominal & Konfirmasi Pengiriman Saldo
  Widget _buildStep2Nominal(WalletProvider wallet, AuthProvider auth, bool isDark) {
    final acc = _selectedRecipient!;
    final formatted = LuhnAlgorithm.formatWithSpaces(acc.accountNumber);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Penerima Terpilih
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: GageTheme.primary,
                  child: Text(
                    acc.name.isNotEmpty ? acc.name[0].toUpperCase() : 'G',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        acc.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'GAGEPay: $formatted',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedRecipient = null),
                  style: TextButton.styleFrom(
                    foregroundColor: GageTheme.primary,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: const Text('Ganti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Saldo Dompet Pengirim
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo GAGEPay Anda',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  currencyFormatter.format(wallet.balance),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Input Nominal
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: GageTheme.primary, width: 1.5),
            ),
            child: TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: GageTheme.primary),
                hintText: '0',
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Quick Nominal Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickNominals.map((nom) {
              return ActionChip(
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: const StadiumBorder(),
                side: BorderSide(
                  color: _amountCtrl.text == nom.toString()
                      ? GageTheme.primary
                      : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                label: Text(
                  currencyFormatter.format(nom),
                  style: TextStyle(
                    fontSize: 12,
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

          const SizedBox(height: 20),

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
            ),
            child: TextField(
              controller: _noteCtrl,
              maxLength: 60,
              decoration: const InputDecoration(
                hintText: 'Contoh: Bayar makan siang',
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Tombol Kirim Sekarang
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
        ],
      ),
    );
  }
}
