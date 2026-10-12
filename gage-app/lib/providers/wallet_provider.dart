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
    notifyListeners();
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

  // Instant Top-Up Simulator (Langsung update D1 dan memori aplikasi)
  Future<bool> simulateTopup(String userId, int amount) async {
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
      debugPrint('Error simulating topup: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}
