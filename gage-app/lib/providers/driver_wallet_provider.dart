import 'package:flutter/foundation.dart';

/// Provider Dompet Saldo, Rekonsiliasi Komisi & Plafon COD Fleksibel GAGE Driver
class DriverWalletProvider extends ChangeNotifier {
  // Saldo dompet driver (Bisa minus hingga batas Plafon COD Rp -100.000)
  int _balance = 145000;
  int get balance => _balance;

  // Total pendapatan bersih driver hari ini (Eksak 80% dari tarif delivery)
  int _todayEarnings = 42500;
  int get todayEarnings => _todayEarnings;

  // Total trip order sukses diselesaikan hari ini
  int _todayTrips = 5;
  int get todayTrips => _todayTrips;

  // Akumulasi uang tunai yang diterima langsung di tangan dari pembeli (COD)
  int _todayCashInHand = 35000;
  int get todayCashInHand => _todayCashInHand;

  // Rating performa driver
  final double _rating = 4.96;
  double get rating => _rating;

  // ────────────────────────────────────────────────────────────────
  // SISTEM PLAFON COD FLEKSIBEL (PRACIMANTORO STANDARD)
  // Kurir bisa menerima order tunai sampai akumulasi komisi minus Rp 100.000
  // tanpa wajib setor uang muka / deposit di awal.
  // ────────────────────────────────────────────────────────────────
  static const int codCeilingLimit = -100000; // Batas minus saldo COD
  static const int maxCodOverdraft = 100000;  // Plafon fleksibel Rp 100.000

  /// Apakah driver memenuhi syarat menerima pesanan tunai (COD)
  bool get canAcceptCashOrder => _balance >= codCeilingLimit;

  /// Sisa batas plafon kredit COD yang masih bisa dipakai sebelum batas -Rp 100.000
  int get availableCodCredit {
    final available = _balance - codCeilingLimit;
    return available > 0 ? available : 0;
  }

  /// Rasio penggunaan plafon COD jika saldo sedang minus (0.0 - 1.0)
  double get codUsageRatio {
    if (_balance >= 0) return 0.0;
    return (-_balance / maxCodOverdraft).clamp(0.0, 1.0);
  }

  /// Riwayat transaksi dompet (Kredit upah bersih & debit bagi hasil platform)
  final List<Map<String, dynamic>> _transactions = [
    {
      'title': 'Upah Bersih 80% GAGE Food',
      'orderId': 'ORD-FOOD-881',
      'amount': 8000,
      'date': 'Hari ini, 13:45',
      'type': 'CREDIT_EARNING',
      'paymentMethod': 'GAGEPAY',
    },
    {
      'title': 'Bagi Hasil Platform 20% (Tunai COD)',
      'orderId': 'ORD-RIDE-512',
      'amount': -2000,
      'date': 'Hari ini, 12:15',
      'type': 'DEBIT_COD_FEE',
      'paymentMethod': 'CASH',
    },
    {
      'title': 'Tarik Saldo ke Rekening BRI',
      'orderId': 'WD-9921',
      'amount': -100000,
      'date': 'Kemarin, 19:30',
      'type': 'DEBIT_WITHDRAW',
      'paymentMethod': 'BANK_TRANSFER',
    },
  ];
  List<Map<String, dynamic>> get transactions => List.unmodifiable(_transactions);

  /// Riwayat detail trip harian untuk rekonsiliasi kurir
  final List<Map<String, dynamic>> _todayTripHistory = [
    {
      'id': 'ORD-88210',
      'service': 'GAGE Food',
      'serviceType': 'food',
      'store': 'Mie Ayam Bakso Pak Man',
      'pickup': 'Jl. Raya Pracimantoro No. 12',
      'dropoff': 'Dusun Sambiroto RT 02/03',
      'distance': 1.8,
      'driverEarnings': 8000, // Eksak 80%
      'platformFee': 2000,   // 20%
      'totalFare': 10000,
      'paymentMethod': 'GAGEPAY',
      'time': '13:45',
    },
    {
      'id': 'ORD-88194',
      'service': 'GAGE Ride',
      'serviceType': 'ride',
      'store': 'Terminal Bus Pracimantoro',
      'pickup': 'Terminal Bus Pracimantoro',
      'dropoff': 'SMK PGRI 8 Pracimantoro',
      'distance': 2.4,
      'driverEarnings': 8000, // Eksak 80%
      'platformFee': 2000,   // 20%
      'totalFare': 10000,
      'paymentMethod': 'CASH',
      'time': '12:15',
    },
    {
      'id': 'ORD-88182',
      'service': 'GAGE Send',
      'serviceType': 'send',
      'store': 'Kios Pupuk Sumber Rejeki',
      'pickup': 'Pasar Pracimantoro Blok B',
      'dropoff': 'Gedong RT 02/04, Pracimantoro',
      'distance': 3.2,
      'driverEarnings': 10400, // 80% dari Rp 13.000
      'platformFee': 2600,
      'totalFare': 13000,
      'paymentMethod': 'GAGEPAY',
      'time': '10:30',
    },
  ];
  List<Map<String, dynamic>> get todayTripHistory => List.unmodifiable(_todayTripHistory);

  /// Menambah pendapatan bersih (backward-compatible)
  void addEarnings(int amount) {
    _balance += amount;
    _todayEarnings += amount;
    _todayTrips += 1;

    _transactions.insert(0, {
      'title': 'Upah Bersih Order Selesai (80%)',
      'orderId': 'ORD-${DateTime.now().millisecondsSinceEpoch % 10000}',
      'amount': amount,
      'date': 'Baru saja',
      'type': 'CREDIT_EARNING',
      'paymentMethod': 'GAGEPAY',
    });

    notifyListeners();
  }

  /// Rekonsiliasi penyelesaian order trip riil (COD vs Non-Tunai)
  void recordTripCompletion({
    required String tripId,
    required String serviceName,
    required String serviceType,
    required String storeName,
    required String pickupAddress,
    required String dropoffAddress,
    required double distanceKm,
    required int driverEarnings, // Eksak 80% tarif murni OSRM
    required int totalDeliveryFare, // 100% tarif murni OSRM
    required String paymentMethod, // 'CASH' / 'COD' or 'GAGEPAY'
  }) {
    _todayTrips += 1;
    _todayEarnings += driverEarnings;

    final isCash = paymentMethod.toUpperCase().contains('CASH') ||
        paymentMethod.toUpperCase().contains('COD');

    final platformFee = totalDeliveryFare - driverEarnings;
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (isCash) {
      // Driver menerima uang tunai penuh dari pembeli di lapangan (uang masuk kantong kurir).
      // Dompet driver hanya didebit komisi bagi hasil platform 20%.
      // Plafon COD fleksibel mengizinkan saldo minus hingga -Rp 100.000 tanpa wajib setor deposit awal.
      _balance -= platformFee;
      _todayCashInHand += totalDeliveryFare;

      _transactions.insert(0, {
        'title': 'Bagi Hasil Platform 20% (Tunai COD)',
        'orderId': tripId,
        'amount': -platformFee,
        'date': 'Baru saja',
        'type': 'DEBIT_COD_FEE',
        'paymentMethod': 'CASH',
        'store': storeName,
        'cashReceived': totalDeliveryFare,
        'netEarning': driverEarnings,
      });
    } else {
      // Non-tunai (GagePay) -> Upah bersih driver (80%) masuk ke saldo dompet driver
      _balance += driverEarnings;

      _transactions.insert(0, {
        'title': 'Upah Bersih 80% ($serviceName)',
        'orderId': tripId,
        'amount': driverEarnings,
        'date': 'Baru saja',
        'type': 'CREDIT_EARNING',
        'paymentMethod': 'GAGEPAY',
        'store': storeName,
        'cashReceived': 0,
        'netEarning': driverEarnings,
      });
    }

    _todayTripHistory.insert(0, {
      'id': tripId,
      'service': serviceName,
      'serviceType': serviceType,
      'store': storeName,
      'pickup': pickupAddress,
      'dropoff': dropoffAddress,
      'distance': distanceKm,
      'driverEarnings': driverEarnings,
      'platformFee': platformFee,
      'totalFare': totalDeliveryFare,
      'paymentMethod': isCash ? 'CASH' : 'GAGEPAY',
      'time': timeStr,
    });

    notifyListeners();
  }

  /// Top up saldo dompet driver (Pelunasan akumulasi komisi COD)
  void topUp(int amount, String method) {
    if (amount <= 0) return;
    _balance += amount;

    _transactions.insert(0, {
      'title': 'Pelunasan Komisi COD via $method',
      'orderId': 'TOP-${DateTime.now().millisecondsSinceEpoch % 10000}',
      'amount': amount,
      'date': 'Baru saja',
      'type': 'CREDIT_TOPUP',
      'paymentMethod': method,
    });

    notifyListeners();
  }

  /// Tarik saldo dompet kurir ke rekening / e-wallet
  bool withdraw(int amount, String destination) {
    if (amount <= 0 || amount > _balance) return false;

    _balance -= amount;
    _transactions.insert(0, {
      'title': 'Pencairan ke $destination',
      'orderId': 'WD-${DateTime.now().millisecondsSinceEpoch % 10000}',
      'amount': -amount,
      'date': 'Baru saja',
      'type': 'DEBIT_WITHDRAW',
      'paymentMethod': 'BANK_TRANSFER',
    });

    notifyListeners();
    return true;
  }
}
