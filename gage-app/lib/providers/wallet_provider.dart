import 'package:flutter/foundation.dart';
import 'package:gage_app/core/network/gage_api_client.dart';

class WalletProvider extends ChangeNotifier {
  int _balance = 45000;
  int _points = 1500;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;

  int get balance => _balance;
  int get points => _points;
  List<Map<String, dynamic>> get transactions => _transactions;
  bool get isLoading => _isLoading;

  // Refresh Saldo & Riwayat Transaksi dari Cloudflare D1
  Future<void> fetchWallet(String userId) async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());
    try {
      final res = await GageApiClient.getWallet(userId);
      if (res != null) {
        final walletData = res['wallet'];
        if (walletData != null) {
          _balance = (walletData['balance'] ?? 0) as int;
          _points = (walletData['points'] ?? 0) as int;
        }
        final txs = res['transactions'];
        if (txs is List) {
          _transactions = List<Map<String, dynamic>>.from(txs);
        }
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
      notifyListeners();
    }
  }

  // Tambah poin loyalti (hadiah login harian & cashback)
  void addPoints(int amount) {
    _points += amount;
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
    notifyListeners();
  }

  // Kompatibilitas
  Future<bool> simulateTopup(String userId, int amount) => confirmTopupPayment(userId, amount);
}
