import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/utils/luhn_algorithm.dart';

class WalletProvider extends ChangeNotifier {
  int _balance = 0;
  int _points = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  String? _activeUserId;

  int get balance => _balance;
  int get points => _points;
  List<Map<String, dynamic>> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get activeUserId => _activeUserId;

  /// Nomor rekening resmi GAGEPay 12 digit berbasis standar ISO/IEC 7812 (Algoritma LUHN Mod 10):
  /// - Prefix BIN: 8908 (89 = GAGE Ecosystem, 08 = Customer Wallet)
  /// - 7 digit entropi pengguna deterministik
  /// - 1 digit Luhn Check Digit
  String get accountNumber {
    final raw = (_activeUserId != null && _activeUserId!.isNotEmpty)
        ? _activeUserId!
        : 'usr-cust-01';

    // Hitung hash deterministik 7 digit dari user id
    int hash = 5381;
    for (int i = 0; i < raw.length; i++) {
      hash = ((hash << 5) + hash) + raw.codeUnitAt(i);
    }
    final entropy = (hash.abs() % 10000000).toString().padLeft(7, '8');
    final payload11 = '8908$entropy';
    return LuhnAlgorithm.generateWithCheckDigit(payload11);
  }

  /// Nomor rekening dalam format spasi (contoh: "8908 1234 5678")
  String get formattedAccountNumber => LuhnAlgorithm.formatWithSpaces(accountNumber);

  // Key SharedPreferences per userId
  static String _balanceKey(String userId) => 'gage_wallet_balance_$userId';
  static String _pointsKey(String userId) => 'gage_wallet_points_$userId';
  static String _txsKey(String userId) => 'gage_wallet_txs_$userId';

  // Memulihkan data saldo & transaksi dari SharedPreferences lokal
  Future<void> restoreCachedWallet(String userId) async {
    _activeUserId = userId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedBal = prefs.getInt(_balanceKey(userId));
      final cachedPts = prefs.getInt(_pointsKey(userId));
      final cachedTxsRaw = prefs.getString(_txsKey(userId));

      bool changed = false;
      if (cachedBal != null) {
        _balance = cachedBal;
        changed = true;
      }
      if (cachedPts != null) {
        _points = cachedPts;
        changed = true;
      }
      if (cachedTxsRaw != null && cachedTxsRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedTxsRaw);
          if (decoded is List) {
            _transactions = List<Map<String, dynamic>>.from(decoded);
            changed = true;
          }
        } catch (_) {}
      }
      if (changed) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error restoring cached wallet for $userId: $e');
    }
  }

  // Menyimpan data saldo & transaksi ke SharedPreferences per userId
  Future<void> _persistWallet(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_balanceKey(userId), _balance);
      await prefs.setInt(_pointsKey(userId), _points);
      await prefs.setString(_txsKey(userId), jsonEncode(_transactions));
    } catch (e) {
      debugPrint('Error persisting wallet for $userId: $e');
    }
  }

  // Refresh Saldo & Riwayat Transaksi dari Cloudflare D1
  Future<void> fetchWallet(String userId) async {
    _activeUserId = userId;
    // Pulihkan cache lokal terlebih dahulu agar UI responsif seketika
    await restoreCachedWallet(userId);

    _isLoading = true;
    notifyListeners();
    try {
      final res = await GageApiClient.getWallet(userId);
      if (res != null) {
        final walletData = res['wallet'];
        if (walletData != null) {
          _balance = int.tryParse(walletData['balance']?.toString().replaceAll(RegExp(r'[^0-9\-]'), '') ?? '') ?? 0;
          _points = int.tryParse(walletData['points']?.toString().replaceAll(RegExp(r'[^0-9\-]'), '') ?? '') ?? 0;
        }
        final txs = res['transactions'];
        if (txs is List) {
          _transactions = List<Map<String, dynamic>>.from(txs);
        }
        await _persistWallet(userId);
      }
    } catch (e) {
      debugPrint('Error fetching wallet: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update saldo lokal saat pembayaran berhasil
  void deductBalance(int amount) {
    if (_balance >= amount) {
      _balance -= amount;
      if (_activeUserId != null) {
        _persistWallet(_activeUserId!);
      }
      notifyListeners();
    }
  }

  // Transfer saldo ke sesama pengguna GAGEPay
  Future<bool> transferBalance({
    required String recipientAccount,
    required String recipientName,
    required int amount,
    String? note,
  }) async {
    if (_balance < amount) return false;
    _balance -= amount;
    final tx = {
      'id': 'tx-tf-${DateTime.now().millisecondsSinceEpoch}',
      'type': 'TRANSFER_OUT',
      'amount': amount,
      'description': 'Transfer ke $recipientName ($recipientAccount)${note != null && note.isNotEmpty ? ": $note" : ""}',
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'status': 'SUCCESS',
    };
    _transactions.insert(0, tx);
    if (_activeUserId != null) {
      _persistWallet(_activeUserId!);
    }
    notifyListeners();
    return true;
  }

  void topUp(int amount) {
    _balance += amount;
    if (_activeUserId != null) {
      _persistWallet(_activeUserId!);
    }
    notifyListeners();
  }

  // Tambah poin loyalti (hadiah login harian & cashback)
  void addPoints(int amount) {
    _points += amount;
    if (_activeUserId != null) {
      _persistWallet(_activeUserId!);
    }
    notifyListeners();
  }

  // Permintaan Top-up QRIS Dinamis Tag 54
  Future<Map<String, dynamic>?> requestTopupQris(String userId, int amount) async {
    return await GageApiClient.requestTopupQris(userId, amount);
  }

  // Konfirmasi Top-up Saldo Real-Time (Update D1 & Saldo Aplikasi)
  Future<bool> confirmTopupPayment(String userId, int amount) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await GageApiClient.simulateTopupSuccess(userId, amount);
      if (res != null && res['success'] == true) {
        _balance += amount;
        await _persistWallet(userId);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error confirming topup: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Permintaan Penarikan Dana (Withdrawal H+1)
  Future<bool> withdrawBalance({
    required int amount,
    required int adminFee,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) async {
    final totalDeduct = amount + adminFee;
    if (_balance < totalDeduct) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      _balance -= totalDeduct;

      final now = DateTime.now();
      _transactions.insert(0, {
        'id': 'wd-${now.millisecondsSinceEpoch}',
        'title': 'Tarik Saldo ke $bankName',
        'type': 'WITHDRAWAL',
        'amount': amount,
        'admin_fee': adminFee,
        'total': totalDeduct,
        'destination': '$bankName - $accountNumber ($accountHolder)',
        'status': 'PROSES_H1',
        'date': now.toIso8601String(),
      });

      if (_activeUserId != null) {
        await _persistWallet(_activeUserId!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error withdrawing: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Tambah riwayat transaksi manual
  void addTransaction(Map<String, dynamic> tx) {
    _transactions.insert(0, tx);
    if (_activeUserId != null) {
      _persistWallet(_activeUserId!);
    }
    notifyListeners();
  }

  // Kompatibilitas
  Future<bool> simulateTopup(String userId, int amount) => confirmTopupPayment(userId, amount);
}
