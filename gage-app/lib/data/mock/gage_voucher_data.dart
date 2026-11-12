/// Master Data Voucher & Promo Aplikasi GAGE Pracimantoro
/// Single source of truth untuk Menu Promo, Riwayat, dan Pemilihan Voucher Checkout
class GageVoucherData {
  static const List<Map<String, dynamic>> allVouchers = [
    // 1. KULINER (GAGE Food)
    {
      'id': 'v-food-50',
      'code': 'DISKON50',
      'service': 'GAGE Food',
      'type': 'order',
      'title': 'Diskon 50% s.d 15RB',
      'discountText': 'Diskon 50% s.d 15RB',
      'minOrder': 20000,
      'discountAmount': 15000,
      'discountPercentage': 0.5,
      'quantity': 3,
      'tag': 'Pengguna Baru',
      'expiry': '31 Des 2026',
      'terms': [
        'Diskon 50% hingga maksimal potongan Rp 15.000.',
        'Berlaku untuk semua resto kuliner mitra GAGE Food.',
        'Minimal transaksi pemesanan Rp 20.000.',
        'Dapat digabung dengan voucher gratis ongkir.',
      ],
      'howToUse': 'Klik "Pakai", potongan harga langsung otomatis memotong total belanja di keranjang.',
    },
    {
      'id': 'v-food-20',
      'code': 'KULINER20',
      'service': 'GAGE Food',
      'type': 'order',
      'title': 'Diskon 20% s.d 20RB',
      'discountText': 'Diskon 20% s.d 20RB',
      'minOrder': 50000,
      'discountAmount': 20000,
      'discountPercentage': 0.2,
      'quantity': 2,
      'tag': 'Diskon Terus',
      'expiry': '31 Des 2026',
      'terms': [
        'Diskon 20% hingga maksimal potongan Rp 20.000.',
        'Berlaku untuk pesanan makan siang dan malam.',
        'Minimal belanja Rp 50.000.',
      ],
      'howToUse': 'Otomatis terpasang di keranjang GAGE Food.',
    },
    {
      'id': 'v-ongkir-01',
      'code': 'ONGKIRGRATIS',
      'service': 'GAGE Food',
      'type': 'delivery',
      'title': 'Gratis Ongkir s.d 7RB',
      'discountText': 'Gratis Ongkir s.d 7RB',
      'minOrder': 25000,
      'discountAmount': 7000,
      'quantity': 5,
      'tag': 'Semua Resto',
      'expiry': '31 Des 2026',
      'terms': [
        'Potongan ongkir gratis hingga maksimal Rp 7.000.',
        'Berlaku untuk pengantaran kurir motor GAGE Food.',
        'Minimal transaksi pemesanan Rp 25.000.',
        'Dapat digunakan bersamaan dengan voucher diskon makanan.',
      ],
      'howToUse': 'Pilih voucher ini, dan biaya kurir antar otomatis terpotong di keranjang.',
    },
    {
      'id': 'v-ongkir-02',
      'code': 'ONGKIR5RB',
      'service': 'GAGE Food',
      'type': 'delivery',
      'title': 'Gratis Ongkir s.d 5RB',
      'discountText': 'Gratis Ongkir s.d 5RB',
      'minOrder': 20000,
      'discountAmount': 5000,
      'quantity': 2,
      'tag': 'Hemat Ongkir',
      'expiry': '31 Des 2026',
      'terms': [
        'Subsidi ongkir Rp 5.000 untuk pengantaran kuliner.',
        'Minimal belanja Rp 20.000.',
      ],
      'howToUse': 'Pilih voucher saat checkout pesanan.',
    },

    // 3. TRANSPORTASI (GAGE Ride)
    {
      'id': 'v-ride-01',
      'code': 'RIDEHEMAT',
      'service': 'GAGE Ride',
      'type': 'order',
      'title': 'Diskon 4RB',
      'discountText': 'Diskon 4RB',
      'minOrder': 10000,
      'discountAmount': 4000,
      'quantity': 1,
      'tag': 'GAGE Ride',
      'expiry': '31 Des 2026',
      'terms': [
        'Potongan Rp 4.000 untuk perjalanan ojek motor GAGE Ride.',
        'Minimal transaksi Rp 10.000.',
        'Berlaku di seluruh area operasional Pracimantoro.',
      ],
      'howToUse': 'Pilih saat memesan GAGE Ride sebelum klik pesan sekarang.',
    },
    {
      'id': 'v-ride-02',
      'code': 'GAGEHEMAT',
      'service': 'GAGE Ride',
      'type': 'order',
      'title': 'Diskon 2RB',
      'discountText': 'Diskon 2RB',
      'minOrder': 8000,
      'discountAmount': 2000,
      'quantity': 2,
      'tag': 'GAGE Ride',
      'expiry': '31 Des 2026',
      'terms': [
        'Diskon tarif perjalanan Rp 2.000.',
        'Minimal jarak atau tarif dasar Rp 8.000.',
      ],
      'howToUse': 'Pilih saat checkout perjalanan.',
    },
    {
      'id': 'v-ride-03',
      'code': 'PELAJARPRACI',
      'service': 'GAGE Ride',
      'type': 'order',
      'title': 'Diskon 1.5RB',
      'discountText': 'Diskon 1.5RB',
      'minOrder': 5000,
      'discountAmount': 1500,
      'quantity': 1,
      'tag': 'Pelajar',
      'expiry': '31 Des 2026',
      'terms': [
        'Tarif hemat antar jemput sekolah Pracimantoro.',
        'Potongan Rp 1.500 langsung di pemesanan.',
      ],
      'howToUse': 'Pilih saat checkout GAGE Ride.',
    },

    // 4. TRANSPORTASI (GAGE Car)
    {
      'id': 'v-car-01',
      'code': 'GAGECAR15',
      'service': 'GAGE Car',
      'type': 'order',
      'title': 'Diskon 15RB',
      'discountText': 'Diskon 15RB',
      'minOrder': 30000,
      'discountAmount': 15000,
      'quantity': 2,
      'tag': 'GAGE Car',
      'expiry': '31 Des 2026',
      'terms': [
        'Potongan langsung Rp 15.000 untuk armada GAGE Car.',
        'Minimal tarif perjalanan Rp 30.000.',
      ],
      'howToUse': 'Gunakan saat memesan armada GAGE Car.',
    },
    {
      'id': 'v-car-02',
      'code': 'PRACICAR',
      'service': 'GAGE Car',
      'type': 'order',
      'title': 'Diskon 3RB',
      'discountText': 'Diskon 3RB',
      'minOrder': 20000,
      'discountAmount': 3000,
      'quantity': 1,
      'tag': 'GAGE Car',
      'expiry': '31 Des 2026',
      'terms': [
        'Potongan Rp 3.000 untuk perjalanan armada mobil.',
        'Minimal transaksi Rp 20.000.',
      ],
      'howToUse': 'Gunakan saat memesan armada GAGE Car.',
    },

    // 5. PENGIRIMAN & LOGISTIK (GAGE Send)
    {
      'id': 'v-send-01',
      'code': 'KIRIMKILAT',
      'service': 'GAGE Send',
      'type': 'delivery',
      'title': 'Gratis Ongkir s.d 5RB',
      'discountText': 'Gratis Ongkir s.d 5RB',
      'minOrder': 12000,
      'discountAmount': 5000,
      'quantity': 3,
      'tag': 'GAGE Send',
      'expiry': '31 Des 2026',
      'terms': [
        'Subsidi ongkir Rp 5.000 untuk pengiriman barang dan paket kilat.',
        'Khusus wilayah Pracimantoro dan sekitarnya.',
      ],
      'howToUse': 'Gunakan di halaman pengiriman kurir GAGE Send.',
    },
    {
      'id': 'v-send-02',
      'code': 'GAGERATIH',
      'service': 'GAGE Send',
      'type': 'delivery',
      'title': 'Gratis Ongkir s.d 2RB',
      'discountText': 'Gratis Ongkir s.d 2RB',
      'minOrder': 5000,
      'discountAmount': 2000,
      'quantity': 2,
      'tag': 'GAGE Send',
      'expiry': '31 Des 2026',
      'terms': [
        'Minimal tarif pengiriman paket Rp 5.000.',
        'Potongan ongkir kurir Rp 2.000.',
      ],
      'howToUse': 'Gunakan saat memesan kurir barang.',
    },

    // 6. PERTANIAN & HASIL BUMI (GAGE Farm)
    {
      'id': 'v-farm-01',
      'code': 'SUBSIDITANI',
      'service': 'GAGE Farm',
      'type': 'order',
      'title': 'Diskon 10RB',
      'discountText': 'Diskon 10RB',
      'minOrder': 30000,
      'discountAmount': 10000,
      'quantity': 3,
      'tag': 'GAGE Farm',
      'expiry': '31 Des 2026',
      'terms': [
        'Potongan langsung Rp 10.000 untuk bibit, pupuk, dan produk tani.',
        'Minimal transaksi pemesanan Rp 30.000.',
      ],
      'howToUse': 'Pilih voucher saat checkout pesanan GAGE Farm.',
    },
    {
      'id': 'v-farm-02',
      'code': 'PETANISUKSES',
      'service': 'GAGE Farm',
      'type': 'order',
      'title': 'Diskon 15RB',
      'discountText': 'Diskon 15RB',
      'minOrder': 50000,
      'discountAmount': 15000,
      'quantity': 2,
      'tag': 'Petani Hebat',
      'expiry': '31 Des 2026',
      'terms': [
        'Potongan langsung Rp 15.000 untuk perlengkapan dan hasil pertanian.',
        'Minimal belanja Rp 50.000.',
      ],
      'howToUse': 'Pilih voucher saat checkout pesanan GAGE Farm.',
    },
    {
      'id': 'v-farm-03',
      'code': 'ONGKIRFREE-FARM',
      'service': 'GAGE Farm',
      'type': 'delivery',
      'title': 'Gratis Ongkir s.d 7RB',
      'discountText': 'Gratis Ongkir s.d 7RB',
      'minOrder': 25000,
      'discountAmount': 7000,
      'quantity': 5,
      'tag': 'Hemat Ongkir',
      'expiry': '31 Des 2026',
      'terms': [
        'Subsidi ongkir Rp 7.000 untuk pengantaran pesanan tani dan ternak.',
        'Minimal transaksi pemesanan Rp 25.000.',
      ],
      'howToUse': 'Pilih voucher saat checkout pesanan GAGE Farm.',
    },

    // 7. TOKO & KELONTONG (GAGE Shop)
    {
      'id': 'v-shop-01',
      'code': 'BELANJAHEMAT',
      'service': 'GAGE Shop',
      'type': 'order',
      'title': 'Diskon 8RB',
      'discountText': 'Diskon 8RB',
      'minOrder': 25000,
      'discountAmount': 8000,
      'quantity': 2,
      'tag': 'GAGE Shop',
      'expiry': '31 Des 2026',
      'terms': [
        'Potongan langsung Rp 8.000 di toko mitra resmi GAGE Shop.',
        'Minimal transaksi belanja Rp 25.000.',
      ],
      'howToUse': 'Pilih voucher saat checkout belanjaan toko.',
    },
    {
      'id': 'v-shop-02',
      'code': 'SEMBAKOMURAH',
      'service': 'GAGE Shop',
      'type': 'order',
      'title': 'Diskon 10RB',
      'discountText': 'Diskon 10RB',
      'minOrder': 40000,
      'discountAmount': 10000,
      'quantity': 2,
      'tag': 'Sembako Murah',
      'expiry': '31 Des 2026',
      'terms': [
        'Potongan belanja Rp 10.000 untuk sembako dan kebutuhan harian.',
        'Minimal transaksi belanja Rp 40.000.',
      ],
      'howToUse': 'Pilih voucher saat checkout belanjaan toko.',
    },
    {
      'id': 'v-shop-03',
      'code': 'ONGKIRFREE-SHOP',
      'service': 'GAGE Shop',
      'type': 'delivery',
      'title': 'Gratis Ongkir s.d 7RB',
      'discountText': 'Gratis Ongkir s.d 7RB',
      'minOrder': 20000,
      'discountAmount': 7000,
      'quantity': 3,
      'tag': 'Hemat Ongkir',
      'expiry': '31 Des 2026',
      'terms': [
        'Subsidi ongkir Rp 7.000 untuk pengiriman barang toko mitra.',
        'Minimal transaksi pemesanan Rp 20.000.',
      ],
      'howToUse': 'Pilih voucher saat checkout belanja toko.',
    },

    // 8. MATERIAL & KONSTRUKSI (GAGE Build)
    {
      'id': 'v-build-01',
      'code': 'PROYEKHEMAT',
      'service': 'GAGE Build',
      'type': 'order',
      'title': 'Diskon 15RB',
      'discountText': 'Diskon 15RB',
      'minOrder': 50000,
      'discountAmount': 15000,
      'quantity': 2,
      'tag': 'GAGE Build',
      'expiry': '31 Des 2026',
      'terms': [
        'Potongan langsung Rp 15.000 untuk material bangunan dan perkakas.',
        'Minimal transaksi belanja Rp 50.000.',
      ],
      'howToUse': 'Pilih voucher saat checkout pesanan GAGE Build.',
    },
    {
      'id': 'v-build-02',
      'code': 'BANGUNRUMAH',
      'service': 'GAGE Build',
      'type': 'order',
      'title': 'Diskon 25RB',
      'discountText': 'Diskon 25RB',
      'minOrder': 100000,
      'discountAmount': 25000,
      'quantity': 1,
      'tag': 'Bangun Rumah',
      'expiry': '31 Des 2026',
      'terms': [
        'Potongan langsung Rp 25.000 untuk proyek renovasi dan bangunan.',
        'Minimal transaksi belanja Rp 100.000.',
      ],
      'howToUse': 'Pilih voucher saat checkout pesanan GAGE Build.',
    },
    {
      'id': 'v-build-03',
      'code': 'ONGKIRFREE-BUILD',
      'service': 'GAGE Build',
      'type': 'delivery',
      'title': 'Gratis Ongkir s.d 10RB',
      'discountText': 'Gratis Ongkir s.d 10RB',
      'minOrder': 50000,
      'discountAmount': 10000,
      'quantity': 3,
      'tag': 'Gratis Ongkir',
      'expiry': '31 Des 2026',
      'terms': [
        'Subsidi ongkir Rp 10.000 untuk pengiriman material bangunan.',
        'Minimal transaksi belanja Rp 50.000.',
      ],
      'howToUse': 'Pilih voucher saat checkout pesanan GAGE Build.',
    },
  ];

  static String serviceNameForType(String serviceType) {
    switch (serviceType.trim().toLowerCase()) {
      case 'ride':
        return 'GAGE Ride';
      case 'car':
        return 'GAGE Car';
      case 'send':
        return 'GAGE Send';
      case 'shop':
      case 'mart':
        return 'GAGE Shop';
      case 'farm':
        return 'GAGE Farm';
      case 'build':
        return 'GAGE Build';
      case 'food':
      default:
        return 'GAGE Food';
    }
  }

  static List<Map<String, dynamic>> vouchersForService(String serviceType) {
    final serviceName = serviceNameForType(serviceType);
    return allVouchers.where((v) => v['service'] == serviceName).toList();
  }

  static Map<String, dynamic>? findByCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    for (final v in allVouchers) {
      if ((v['code'] as String).toUpperCase() == normalized) {
        return v;
      }
    }
    return null;
  }

  static int minOrderFor(Map<String, dynamic> voucher) {
    return (voucher['minOrder'] as num?)?.toInt() ?? 0;
  }

  static bool isVoucherEligible(Map<String, dynamic> voucher, int orderAmount) {
    if (orderAmount <= 0) return false;
    return orderAmount >= minOrderFor(voucher);
  }

  static int calculateDiscount(Map<String, dynamic> voucher, int orderAmount) {
    if (orderAmount <= 0) return 0;
    final maxDiscount = (voucher['discountAmount'] as num?)?.toInt() ?? 0;
    final pct = (voucher['discountPercentage'] as num?)?.toDouble();
    if (pct != null && pct > 0) {
      return (orderAmount * pct).round().clamp(0, maxDiscount);
    }
    return maxDiscount.clamp(0, orderAmount);
  }

  static String? ineligibilityReason(Map<String, dynamic> voucher, int orderAmount) {
    if (isVoucherEligible(voucher, orderAmount)) return null;
    final minOrder = minOrderFor(voucher);
    if (minOrder <= 0) return 'Tambahkan transaksi terlebih dahulu';
    if (orderAmount <= 0) return 'Min. belanja Rp${_formatThousands(minOrder)}';
    final shortage = (minOrder - orderAmount).clamp(0, minOrder);
    return 'Min. Rp${_formatThousands(minOrder)} (kurang Rp${_formatThousands(shortage)})';
  }

  static String _formatThousands(int amount) {
    final raw = amount.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final revIndex = raw.length - i;
      buf.write(raw[i]);
      if (revIndex > 1 && revIndex % 3 == 1) {
        buf.write('.');
      }
    }
    return buf.toString();
  }

  static List<Map<String, dynamic>> orderVouchersForService(String serviceType) {
    final list = vouchersForService(serviceType).where((v) => v['type'] == 'order').toList();
    list.sort((a, b) => minOrderFor(a).compareTo(minOrderFor(b)));
    return list;
  }

  /// Picks the highest-value order voucher whose minimum order requirement
  /// is satisfied for [serviceType] and [subtotal].
  static Map<String, dynamic>? bestEligibleOrderVoucher({
    required String serviceType,
    required int subtotal,
  }) {
    if (subtotal <= 0) return null;
    final candidates = vouchersForService(serviceType).where((v) {
      return v['type'] == 'order' && isVoucherEligible(v, subtotal);
    }).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final da = calculateDiscount(a, subtotal);
      final db = calculateDiscount(b, subtotal);
      final cmp = db.compareTo(da);
      if (cmp != 0) return cmp;
      return minOrderFor(b).compareTo(minOrderFor(a));
    });
    return candidates.first;
  }

  /// Picks the highest-value delivery ("gratis ongkir") voucher whose minimum
  /// order requirement is satisfied for [serviceType] and [subtotal].
  static Map<String, dynamic>? bestEligibleDeliveryVoucher({
    required String serviceType,
    required int subtotal,
  }) {
    if (subtotal <= 0) return null;
    final candidates = vouchersForService(serviceType).where((v) {
      return v['type'] == 'delivery' && isVoucherEligible(v, subtotal);
    }).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final da = (a['discountAmount'] as num?)?.toInt() ?? 0;
      final db = (b['discountAmount'] as num?)?.toInt() ?? 0;
      final cmp = db.compareTo(da);
      if (cmp != 0) return cmp;
      return minOrderFor(b).compareTo(minOrderFor(a));
    });
    return candidates.first;
  }
}
