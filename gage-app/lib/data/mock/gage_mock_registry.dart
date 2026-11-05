// ============================================================================
// [DUMMY_PRODUCTION_TARGET]: GAGE PRACIMANTORO CENTRALIZED MOCK DATA REGISTRY
// ============================================================================
// PERHATIAN: Seluruh data di registry ini berstatus DUMMY untuk tahap
// pengembangan antarmuka (UI/UX) dan testing lokal Solo Developer.
//
// ARSITEKTUR MIGRASI KE PRODUCTION (Cloudflare D1 / Remote API):
// 1. Ganti flag `isProductionMode = true`.
// 2. Inject `GageApiClient` / REST Repository untuk mengambil data riil dari
//    database Cloudflare D1 / Supabase / PostgreSQL.
// 3. Setiap struktur `Map<String, dynamic>` di bawah ini dirancang 100% kompatibel
//    dengan skema tabel SQL production.
// ============================================================================

class GageMockRegistry {
  /// Toggle mode dummy vs production
  static const bool isProductionMode = false;

  // ══════════════════════════════════════════════════════════════════════════
  // 1. DATA MERCHANT FOOD (KULINER & RESTORAN) - [DUMMY_PRODUCTION_TARGET]
  // ══════════════════════════════════════════════════════════════════════════
  static final List<Map<String, dynamic>> foodMerchants = [
    {
      'id': 'mch-rc-01',
      'name': 'Rocket Chicken Pracimantoro',
      'category': 'Ayam Goreng Krispi & Aneka Burger',
      'rating': 4.9,
      'ratingCount': '240+',
      'distance': '1.2 km',
      'eta': '20-30 min',
      'ongkir': 'Rp 4.000',
      'image': 'assets/images/resto_rocket_chicken.png',
      'tier': 'exclusive',
      'isSponsored': true,
      'campaignBadge': '11.11 SUPER DEALS',
      'promoBadges': ['Diskon 50%', 'Diskon Ongkir'],
      'menus': [
        {
          'id': 'menu-rc-01',
          'name': 'Paket Rocket 1 (Ayam Goreng Paha/Dada + Nasi)',
          'price': 16000,
          'image': 'assets/images/resto_rocket_chicken.png',
          'description': 'Ayam goreng krispi bumbu resep rahasia + nasi pulen hangat + saus sambal.',
          'category': 'Paket Hemat',
          'isBestSeller': true,
        },
        {
          'id': 'menu-rc-02',
          'name': 'Ayam Geprek Sambal Bawang Pedas Nampol',
          'price': 17500,
          'image': 'assets/images/resto_rocket_chicken.png',
          'description': 'Ayam krispi digeprek dengan cabai rawit merah segar dan bawang gurih.',
          'category': 'Geprek',
          'isBestSeller': true,
        },
        {
          'id': 'menu-rc-03',
          'name': 'Burger Beef Cheese Special',
          'price': 14000,
          'image': 'assets/images/resto_rocket_chicken.png',
          'description': 'Roti wijen empuk dengan patty daging sapi dan keju cheddar leleh.',
          'category': 'Snack & Burger',
          'isBestSeller': false,
        },
      ],
    },
    {
      'id': 'mch-dimsum-01',
      'name': 'Dimsum Sewu, Alfamidi Pracimantoro',
      'category': 'Jajanan & Dimsum Hangat Aneka Varian',
      'rating': 4.9,
      'ratingCount': '85+',
      'distance': '1.8 km',
      'eta': '25-35 min',
      'ongkir': 'Rp 4.000',
      'image': 'assets/images/resto_dimsum_sewu.png',
      'tier': 'star',
      'isSponsored': false,
      'campaignBadge': null,
      'promoBadges': ['Diskon 35%', 'Diskon Ongkir'],
      'menus': [
        {
          'id': 'menu-dimsum-01',
          'name': 'Dimsum Mentai Mozarella Hangat (Isi 4)',
          'price': 14000,
          'image': 'assets/images/resto_dimsum_sewu.png',
          'description': 'Siomay ayam kukus disiram saus mentai gurih dengan lelehan mozarella bakar.',
          'category': 'Dimsum Kukus',
          'isBestSeller': true,
        },
        {
          'id': 'menu-dimsum-02',
          'name': 'Dimsum Ayam Jamur Original (Isi 4)',
          'price': 12000,
          'image': 'assets/images/resto_dimsum_sewu.png',
          'description': 'Siomay ayam lembut cincang jamur kuping disajikan dengan chili oil pedas gurih.',
          'category': 'Dimsum Kukus',
          'isBestSeller': true,
        },
      ],
    },
    {
      'id': 'mch-mie-01',
      'name': 'Mie Ayam Pak Kumis, Pracimantoro',
      'category': 'Mie & Bakso Urat Komplit',
      'rating': 4.8,
      'ratingCount': '64+',
      'distance': '2.1 km',
      'eta': '20-30 min',
      'ongkir': 'Rp 5.000',
      'image': 'assets/images/resto_mie_ayam.png',
      'tier': 'star',
      'isSponsored': false,
      'campaignBadge': null,
      'promoBadges': ['Diskon 30%', 'Diskon Ongkir'],
      'menus': [
        {
          'id': 'menu-mie-01',
          'name': 'Mie Ayam Bakso Pangsit Urat Komplit',
          'price': 14000,
          'image': 'assets/images/resto_mie_ayam.png',
          'description': 'Mie kenyal gurih topping ayam manis melimpah + 2 bakso urat + pangsit goreng renyah.',
          'category': 'Mie Ayam',
          'isBestSeller': true,
        },
      ],
    },
    {
      'id': 'mch-sate-01',
      'name': 'Warung Sate Kambing Bu Harti',
      'category': 'Sate Kambing Muda, Tongseng & Gule',
      'rating': 4.9,
      'ratingCount': '112+',
      'distance': '0.9 km',
      'eta': '15-25 min',
      'ongkir': 'Rp 3.000',
      'image': 'assets/images/hero_promo_1.png',
      'tier': 'star',
      'isSponsored': false,
      'campaignBadge': null,
      'promoBadges': ['Diskon 40%', 'Diskon Ongkir'],
      'menus': [
        {
          'id': 'menu-sate-01',
          'name': 'Sate Kambing Muda Bumbu Kecap (10 Tusuk)',
          'price': 32000,
          'image': 'assets/images/hero_promo_1.png',
          'description': 'Daging kambing muda empuk tanpa prengus dipanggang arang batok bumbu kecap bawang.',
          'category': 'Sate',
          'isBestSeller': true,
        },
      ],
    },
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // 2. DATA MERCHANT SHOP (SEMBAKO & KELONTONG) - [DUMMY_PRODUCTION_TARGET]
  // ══════════════════════════════════════════════════════════════════════════
  static final List<Map<String, dynamic>> shopMerchants = [
    {
      'id': 'shop-berkah-fajar',
      'name': 'Toko Sembako Berkah Fajar',
      'category': 'Sembako, Beras & Minyak Goreng',
      'rating': 4.9,
      'ratingCount': '110+',
      'distance': '0.7 km',
      'eta': '15-20 min',
      'ongkir': 'Rp 3.000',
      'image': 'assets/images/hero_banner_1.png',
      'tier': 'exclusive',
      'isSponsored': true,
      'campaignBadge': 'HARGA PASAR',
      'promoBadges': ['Diskon 20%', 'Diskon Ongkir'],
      'menus': [
        {
          'id': 'shop-item-01',
          'name': 'Beras C4 Super Delanggu 5kg',
          'price': 72000,
          'image': 'assets/images/hero_banner_1.png',
          'description': 'Beras putih pulen alami kualitas super langsung dari sentra Delanggu.',
          'category': 'Beras',
          'isBestSeller': true,
        },
        {
          'id': 'shop-item-02',
          'name': 'Minyak Goreng Sania Pouch 2 Liter',
          'price': 34500,
          'image': 'assets/images/hero_banner_1.png',
          'description': 'Minyak kelapa sawit higienis jernih, tahan panas untuk masakan renyah.',
          'category': 'Minyak Goreng',
          'isBestSeller': true,
        },
      ],
    },
    {
      'id': 'shop-telur-jaya',
      'name': 'Agen Telur & Sembako Jaya',
      'category': 'Telur Ayam Ras, Gula Pasir & Tepung',
      'rating': 4.9,
      'ratingCount': '95+',
      'distance': '1.3 km',
      'eta': '20-30 min',
      'ongkir': 'Rp 4.000',
      'image': 'assets/images/prod_telur.png',
      'tier': 'star',
      'isSponsored': false,
      'campaignBadge': null,
      'promoBadges': ['Diskon 20%', 'Diskon Ongkir'],
      'menus': [
        {
          'id': 'shop-item-03',
          'name': 'Telur Ayam Ras Segar Kiloan (1kg)',
          'price': 26500,
          'image': 'assets/images/prod_telur.png',
          'description': 'Telur ayam ras segar grade A cangkang tebal langsung dari peternak lokal.',
          'category': 'Telur',
          'isBestSeller': true,
        },
      ],
    },
    {
      'id': 'shop-lapak-siti',
      'name': 'Lapak Segar Sayur Mbak Siti',
      'category': 'Sayur Mayur & Bumbu Dapur Segar',
      'rating': 4.8,
      'ratingCount': '85+',
      'distance': '1.1 km',
      'eta': '15-25 min',
      'ongkir': 'Rp 3.500',
      'image': 'assets/images/hero_promo_1.png',
      'tier': 'star',
      'isSponsored': false,
      'campaignBadge': null,
      'promoBadges': ['Diskon 20%', 'Diskon Ongkir'],
      'menus': [
        {
          'id': 'shop-item-04',
          'name': 'Paket Sayur Sop Komplit + Bumbu Racik',
          'price': 8000,
          'image': 'assets/images/hero_promo_1.png',
          'description': 'Wortel, kentang, buncis, kubis, seledri, dan daun bawang segar siap masak.',
          'category': 'Sayur',
          'isBestSeller': true,
        },
      ],
    },
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // 3. DATA MERCHANT FARM (PERTANIAN & PETERNAKAN) - [DUMMY_PRODUCTION_TARGET]
  // ══════════════════════════════════════════════════════════════════════════
  static final List<Map<String, dynamic>> farmMerchants = [
    {
      'id': 'farm-kios-subur',
      'name': 'Kios Tani Subur Makmur',
      'category': 'Pupuk NPK & Urea, Benih Padi & Sayur',
      'rating': 4.9,
      'ratingCount': '140+',
      'distance': '0.8 km',
      'eta': '15-20 min',
      'ongkir': 'Rp 3.000',
      'image': 'assets/images/prod_pupuk.png',
      'tier': 'exclusive',
      'isSponsored': true,
      'campaignBadge': 'SUBSIDI TANI',
      'promoBadges': ['Diskon 15%', 'Diskon Ongkir'],
      'menus': [
        {
          'id': 'farm-item-01',
          'name': 'Pupuk NPK Mutiara 16-16-16 (1kg)',
          'price': 18000,
          'image': 'assets/images/prod_pupuk.png',
          'description': 'Pupuk majemuk seimbang untuk tanaman cabai, padi, dan sayur mayur.',
          'category': 'Pupuk',
          'isBestSeller': true,
        },
      ],
    },
    {
      'id': 'farm-sentra-mandiri',
      'name': 'Sentra Konsentrat Ternak Mandiri',
      'category': 'Pakan Sapi, Kambing & Vitamin Hewan',
      'rating': 4.9,
      'ratingCount': '92+',
      'distance': '0.9 km',
      'eta': '15-20 min',
      'ongkir': 'Rp 3.000',
      'image': 'assets/images/prod_pakan.png',
      'tier': 'star',
      'isSponsored': false,
      'campaignBadge': null,
      'promoBadges': ['Diskon 15%', 'Diskon Ongkir'],
      'menus': [
        {
          'id': 'farm-item-02',
          'name': 'Konsentrat Pakan Penggemukan Sapi (Sak 50kg)',
          'price': 185000,
          'image': 'assets/images/prod_pakan.png',
          'description': 'Konsentrat protein tinggi untuk booster bobot sapi potong dan perah.',
          'category': 'Pakan Ternak',
          'isBestSeller': true,
        },
      ],
    },
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // 4. DATA MERCHANT BUILD (BAHAN BANGUNAN) - [DUMMY_PRODUCTION_TARGET]
  // ══════════════════════════════════════════════════════════════════════════
  static final List<Map<String, dynamic>> buildMerchants = [
    {
      'id': 'build-tb-bangkit',
      'name': 'TB Pracimantoro Bangkit',
      'category': 'Semen Tiga Roda, Besi Beton & Pasir',
      'rating': 4.9,
      'ratingCount': '125+',
      'distance': '1.0 km',
      'eta': '20-30 min',
      'ongkir': 'Rp 5.000',
      'image': 'assets/icons/ic_build.png',
      'tier': 'exclusive',
      'isSponsored': true,
      'campaignBadge': 'PROMO PROYEK',
      'promoBadges': ['Diskon 10%', 'Diskon Ongkir'],
      'menus': [
        {
          'id': 'build-item-01',
          'name': 'Semen Tiga Roda 40kg',
          'price': 54000,
          'image': 'assets/icons/ic_build.png',
          'description': 'Semen Portland berkualitas tinggi kuat tekan tahan retak untuk cor dan plester.',
          'category': 'Semen',
          'isBestSeller': true,
        },
      ],
    },
    {
      'id': 'build-cat-indah',
      'name': 'Toko Cat Indah Bangunan',
      'category': 'Cat Tembok Dulux/Avian, Kuas & Plamir',
      'rating': 4.8,
      'ratingCount': '88+',
      'distance': '0.6 km',
      'eta': '10-15 min',
      'ongkir': 'Rp 3.000',
      'image': 'assets/icons/ic_build.png',
      'tier': 'star',
      'isSponsored': false,
      'campaignBadge': null,
      'promoBadges': ['Diskon 10%', 'Diskon Ongkir'],
      'menus': [
        {
          'id': 'build-item-02',
          'name': 'Cat Tembok Avitex Putih 5kg',
          'price': 85000,
          'image': 'assets/icons/ic_build.png',
          'description': 'Cat tembok interior cerah tahan jamur dan mudah dibersihkan.',
          'category': 'Cat',
          'isBestSeller': true,
        },
      ],
    },
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // 5. SMART SEARCH DIRECTORY TERPADU - [DUMMY_PRODUCTION_TARGET]
  // ══════════════════════════════════════════════════════════════════════════
  static List<Map<String, dynamic>> getUnifiedSearchDirectory() {
    final List<Map<String, dynamic>> dir = [];

    // 1. Tambahkan Menu Terlaris (Skor Relevansi Tertinggi: 100)
    for (final mch in foodMerchants) {
      final menus = mch['menus'] as List<Map<String, dynamic>>? ?? [];
      for (final m in menus) {
        dir.add({
          'type': 'menu',
          'title': m['name'],
          'category': 'Rp ${m['price']} • ${mch['name']}',
          'keywords': '${m['name']} ${m['description']} ${mch['name']} ${m['category']}',
          'image': m['image'],
          'target': 'menu_item',
          'merchant': mch,
          'menu': m,
        });
      }
    }

    // Menu Produk Toko Sembako, Tani, & Bangunan
    for (final shop in shopMerchants) {
      final menus = shop['menus'] as List<Map<String, dynamic>>? ?? [];
      for (final m in menus) {
        dir.add({
          'type': 'menu',
          'title': m['name'],
          'category': 'Rp ${m['price']} • ${shop['name']}',
          'keywords': '${m['name']} ${shop['name']} ${m['category']}',
          'image': m['image'],
          'target': 'menu_item',
          'store': shop,
          'menu': m,
        });
      }
    }
    for (final farm in farmMerchants) {
      final menus = farm['menus'] as List<Map<String, dynamic>>? ?? [];
      for (final m in menus) {
        dir.add({
          'type': 'menu',
          'title': m['name'],
          'category': 'Rp ${m['price']} • ${farm['name']}',
          'keywords': '${m['name']} ${farm['name']} ${m['category']}',
          'image': m['image'],
          'target': 'menu_item',
          'store': farm,
          'menu': m,
        });
      }
    }
    for (final bld in buildMerchants) {
      final menus = bld['menus'] as List<Map<String, dynamic>>? ?? [];
      for (final m in menus) {
        dir.add({
          'type': 'menu',
          'title': m['name'],
          'category': 'Rp ${m['price']} • ${bld['name']}',
          'keywords': '${m['name']} ${bld['name']} ${m['category']}',
          'image': m['image'],
          'target': 'menu_item',
          'store': bld,
          'menu': m,
        });
      }
    }

    // 2. Tambahkan Toko / Merchant (Skor Relevansi Menengah: 70)
    for (final mch in foodMerchants) {
      dir.add({
        'type': 'merchant',
        'title': mch['name'],
        'category': '${mch['category']} • ${mch['distance']}',
        'keywords': '${mch['name']} ${mch['category']} makanan kuliner resto',
        'image': mch['image'],
        'target': 'merchant_food',
        'merchant': mch,
      });
    }
    for (final shop in shopMerchants) {
      dir.add({
        'type': 'merchant',
        'title': shop['name'],
        'category': '${shop['category']} • ${shop['distance']}',
        'keywords': '${shop['name']} ${shop['category']} belanja sembako kelontong',
        'image': shop['image'],
        'target': 'merchant_shop',
        'store': shop,
      });
    }
    for (final farm in farmMerchants) {
      dir.add({
        'type': 'merchant',
        'title': farm['name'],
        'category': '${farm['category']} • ${farm['distance']}',
        'keywords': '${farm['name']} ${farm['category']} tani ternak pupuk pakan',
        'image': farm['image'],
        'target': 'merchant_farm',
        'store': farm,
      });
    }
    for (final bld in buildMerchants) {
      dir.add({
        'type': 'merchant',
        'title': bld['name'],
        'category': '${bld['category']} • ${bld['distance']}',
        'keywords': '${bld['name']} ${bld['category']} bahan bangunan semen cat',
        'image': bld['image'],
        'target': 'merchant_build',
        'store': bld,
      });
    }

    // 3. Tambahkan 8 Layanan Resmi (Icon 3D Clay Resmi)
    dir.addAll([
      {
        'type': 'service',
        'title': 'GAGE Ride',
        'category': 'Layanan Antar Jemput Motor',
        'keywords': 'ride ojek motor antar helm jalan transportasi ojek online',
        'iconAsset': 'assets/icons/ic_ride.png',
        'target': 'ride',
      },
      {
        'type': 'service',
        'title': 'GAGE Car',
        'category': 'Layanan Perjalanan Mobil',
        'keywords': 'car mobil taksi keluarga antar jemput sewa',
        'iconAsset': 'assets/icons/ic_car.png',
        'target': 'car',
      },
      {
        'type': 'service',
        'title': 'GAGE Food',
        'category': 'Pesan Aneka Makanan & Kuliner',
        'keywords': 'food makan kuliner resto restoran lapar jajanan camilan minum nasi',
        'iconAsset': 'assets/icons/ic_food.png',
        'target': 'food',
      },
      {
        'type': 'service',
        'title': 'GAGE Shop',
        'category': 'Belanja Sembako & Kelontong',
        'keywords': 'shop belanja sembako beras minyak gula telur sabun pasar kelontong minimarket',
        'iconAsset': 'assets/icons/ic_shop.png',
        'target': 'shop',
      },
      {
        'type': 'service',
        'title': 'GAGE Send',
        'category': 'Kirim Paket & Dokumen Instan',
        'keywords': 'send kirim paket dokumen kurir ekspedisi antar barang titip',
        'iconAsset': 'assets/icons/ic_send.png',
        'target': 'send',
      },
      {
        'type': 'service',
        'title': 'GAGE Farm',
        'category': 'Kebutuhan Tani & Pakan Ternak',
        'keywords': 'farm tani ternak pupuk urea npk benih bibit pakan sapi kambing konsentrat',
        'iconAsset': 'assets/icons/ic_farm.png',
        'target': 'farm',
      },
      {
        'type': 'service',
        'title': 'GAGE Build',
        'category': 'Bahan Bangunan & Alat Pertukangan',
        'keywords': 'build bangunan semen pasir batu cat besi baja tukang kayu paku triplek',
        'iconAsset': 'assets/icons/ic_build.png',
        'target': 'build',
      },
      {
        'type': 'service',
        'title': 'GAGE Cuan',
        'category': 'Affiliate Hub & Komisi 10%',
        'keywords': 'cuan koin poin bonus affiliate referensi teman komisi hadiah saldo dompet',
        'iconAsset': 'assets/icons/ic_bonus.png',
        'target': 'cuan',
      },
    ]);

    return dir;
  }
}
