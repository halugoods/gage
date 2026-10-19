import 'package:flutter/foundation.dart';

/// Provider Dompet Saldo & Penghasilan Pengemudi (GAGE Driver Wallet)
class DriverWalletProvider extends ChangeNotifier {
  int _balance = 145000; // Saldo dompet driver siap tarik
  int get balance => _balance;

  int _todayEarnings = 42500; // Pendapatan bersih hari ini
  int get todayEarnings => _todayEarnings;

  int _todayTrips = 5; // Jumlah order selesai hari ini
  int get todayTrips => _todayTrips;

  final double _rating = 4.96; // Rating performa driver
  double get rating => _rating;

  final List<Map<String, dynamic>> _transactions = [
    {
      'title': 'Komisi Bersih GAGE Food',
      'orderId': 'ORD-FOOD-881',
      'amount': 8500,
      'date': 'Hari ini, 13:45',
      'type': 'CREDIT',
    },
    {
      'title': 'Komisi Bersih GAGE Ride',
      'orderId': 'ORD-RIDE-512',
      'amount': 7500,
      'date': 'Hari ini, 12:15',
      'type': 'CREDIT',
    },
    {
      'title': 'Tarik Saldo ke Rekening BRI',
      'orderId': 'WD-9921',
      'amount': -100000,
      'date': 'Kemarin, 19:30',
      'type': 'DEBIT',
    },
  ];
  List<Map<String, dynamic>> get transactions => List.unmodifiable(_transactions);

  void addEarnings(int amount) {
    _balance += amount;
    _todayEarnings += amount;
    _todayTrips += 1;

    _transactions.insert(0, {
      'title': 'Komisi Bersih Order Selesai',
      'orderId': 'ORD-${DateTime.now().millisecondsSinceEpoch % 10000}',
      'amount': amount,
      'date': 'Baru saja',
      'type': 'CREDIT',
    });

    notifyListeners();
  }

  bool withdraw(int amount, String destination) {
    if (amount <= 0 || amount > _balance) return false;

    _balance -= amount;
    _transactions.insert(0, {
      'title': 'Pencairan ke $destination',
      'orderId': 'WD-${DateTime.now().millisecondsSinceEpoch % 10000}',
      'amount': -amount,
      'date': 'Baru saja',
      'type': 'DEBIT',
    });

    notifyListeners();
    return true;
  }
}
