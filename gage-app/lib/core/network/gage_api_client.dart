import 'dart:convert';
import 'package:http/http.dart' as http;

class GageApiClient {
  // Alamat backend Cloudflare Hono (Live Worker)
  static String baseUrl = 'https://gage-cloud.gagebyhalugoodsindonesia.workers.dev';

  static void setBaseUrl(String url) {
    baseUrl = url;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. AUTHENTICATION & SESSIONS
  // ─────────────────────────────────────────────────────────────────────────

  // Login dengan Google ID Token (Official Standalone Google Sign-In)
  static Future<Map<String, dynamic>?> loginWithGoogle(String idToken, {String? phone}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': idToken,
          'phone': phone,
        }),
      ).timeout(const Duration(seconds: 8));

      final json = jsonDecode(res.body);
      return json;
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke Google Auth server: $e'};
    }
  }

  // Fast Dev Login Bypass (Testing cepat di ADB Wireless tanpa jeda)
  static Future<Map<String, dynamic>?> loginDev({
    String userId = 'usr-cust-01',
    String name = 'Pelanggan Setia Gage',
    String email = 'test-customer@gage.id',
    String phone = '081234567893',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/dev-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': name,
          'email': email,
          'phone': phone,
        }),
      ).timeout(const Duration(seconds: 5));

      final json = jsonDecode(res.body);
      return json;
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  // Mengambil Profil Pengguna
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/user/profile?user_id=$userId'),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          return json['data'];
        }
      }
    } catch (_) {}
    return null;
  }

  // Update Profil Pengguna
  static Future<bool> updateUserProfile(String userId, {String? name, String? phone}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': name,
          'phone': phone,
        }),
      ).timeout(const Duration(seconds: 4));

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. WALLET (GAGEPAY) & MUTASI
  // ─────────────────────────────────────────────────────────────────────────

  // Mengambil Saldo & Riwayat Transaksi Wallet
  static Future<Map<String, dynamic>?> getWallet(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/wallet/$userId'),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          return json['data'];
        }
      }
    } catch (_) {}
    return null;
  }

  // Permintaan Top-up via Dynamic QRIS Tag 54
  static Future<Map<String, dynamic>?> requestTopupQris(String userId, int amount) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/wallet/topup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'amount': amount,
        }),
      ).timeout(const Duration(seconds: 5));

      final json = jsonDecode(res.body);
      return json;
    } catch (e) {
      return {'success': false, 'message': 'Gagal generate QRIS top-up'};
    }
  }

  // Instant Top-Up Success Simulator (Langsung kredit D1 untuk testing)
  static Future<Map<String, dynamic>?> simulateTopupSuccess(String userId, int amount) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/wallet/topup-simulate-success'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'amount': amount,
        }),
      ).timeout(const Duration(seconds: 4));

      final json = jsonDecode(res.body);
      return json;
    } catch (e) {
      return {'success': false, 'message': 'Gagal top-up simulator: $e'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. CATALOG & MERCHANTS
  // ─────────────────────────────────────────────────────────────────────────

  // Mengambil daftar merchant aktif
  static Future<List<Map<String, dynamic>>> getMerchants() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/merchants')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true && json['data'] is List) {
          return List<Map<String, dynamic>>.from(json['data']);
        }
      }
    } catch (_) {}
    // Fallback data awal lokal (Katalog mitra resto resmi Pracimantoro)
    return [
      {
        'id': 'mch-rc-01',
        'name': 'Rocket Chicken Sambiroto, Pracimantoro',
        'category': 'Cepat saji, Ayam & Aneka nasi',
        'address': 'Sambiroto, Kec. Pracimantoro',
        'phone_wa': '081234567891',
        'rating': 5.0,
        'ratingCount': '120+',
        'distance': '1.2 km',
        'eta': '20-30 min',
        'ongkir': 'Rp 4.000',
        'diskonBadge': 'Diskon makanan s.d. 10rb',
        'image': 'assets/images/resto_rocket_chicken.png',
        'is_open': 1,
      },
      {
        'id': 'mch-dimsum-01',
        'name': 'Dimsum Sewu, Alfamidi Pracimantoro',
        'category': 'Jajanan & Dimsum hangat',
        'address': 'Depan Alfamidi Pracimantoro',
        'phone_wa': '081234567890',
        'rating': 4.9,
        'ratingCount': '85',
        'distance': '1.8 km',
        'eta': '25-35 min',
        'ongkir': 'Rp 4.000',
        'diskonBadge': 'Diskon 50% Pengguna Baru',
        'image': 'assets/images/resto_dimsum_sewu.png',
        'is_open': 1,
      },
      {
        'id': 'mch-mie-01',
        'name': 'Mie Ayam Pak Kumis, Pracimantoro',
        'category': 'Mie & Bakso Urat Komplit',
        'address': 'Pasar Pracimantoro Kios No. 4',
        'phone_wa': '081234567892',
        'rating': 4.8,
        'ratingCount': '64',
        'distance': '2.1 km',
        'eta': '20-30 min',
        'ongkir': 'Rp 5.000',
        'diskonBadge': 'Promo Ongkir Hemat',
        'image': 'assets/images/resto_mie_ayam.png',
        'is_open': 1,
      },
      {
        'id': 'mch-seblak-01',
        'name': 'Seblak Prasmanan Nyentrik Pracimantoro',
        'category': 'Seblak & Pedas Prasmanan',
        'address': 'Jl. Raya Pracimantoro - Giritontro',
        'phone_wa': '081234567894',
        'rating': 4.9,
        'ratingCount': '95',
        'distance': '1.5 km',
        'eta': '20-30 min',
        'ongkir': 'Rp 4.000',
        'diskonBadge': 'Diskon s.d. 5rb',
        'image': 'assets/images/resto_seblak.png',
        'is_open': 1,
      },
      {
        'id': 'mch-roti-01',
        'name': 'Roti Gembong Gedhe, Pracimantoro',
        'category': 'Roti & Bakery, Jajanan Manis',
        'address': 'Kompleks Ruko Barat Pasar Pracimantoro',
        'phone_wa': '081234567895',
        'rating': 4.9,
        'ratingCount': '42',
        'distance': '2.5 km',
        'eta': '25-35 min',
        'ongkir': 'Rp 5.000',
        'diskonBadge': 'Diskon makanan s.d. 5rb',
        'image': 'assets/images/resto_roti_gembong.png',
        'is_open': 1,
      },
    ];
  }

  // Mengambil detail merchant spesifik
  static Future<Map<String, dynamic>?> getMerchantDetail(String merchantId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/merchants/$merchantId')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true && json['data'] is Map) {
          return Map<String, dynamic>.from(json['data']);
        }
      }
    } catch (_) {}
    return null;
  }

  // Mengambil katalog menu merchant
  static Future<List<Map<String, dynamic>>> getMerchantMenu(String merchantId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/merchants/$merchantId/menu')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true && json['data'] is List) {
          return List<Map<String, dynamic>>.from(json['data']);
        }
      }
    } catch (_) {}

    if (merchantId.contains('rc')) {
      return [
        {
          'id': 'menu-rc-01',
          'name': 'Paket Rocket 1 (Nasi + Fried Chicken + Teh)',
          'category': 'Paket Hemat',
          'description': 'Ayam goreng krispi renyah + Nasi putih pulen + Teh manis dingin',
          'offline_price': 15000,
          'gage_price': 16000,
          'image': 'assets/images/dish_rocket_1.png',
          'is_available': 1,
        },
        {
          'id': 'menu-rc-02',
          'name': 'Chicken Burger Crispy Special',
          'category': 'Burger & Snack',
          'description': 'Burger roti wijen empuk dengan patty ayam krispi tebal saus mayo',
          'offline_price': 12000,
          'gage_price': 13000,
          'image': 'assets/images/dish_chicken_burger.png',
          'is_available': 1,
        },
        {
          'id': 'menu-rc-03',
          'name': 'French Fries Golden Crispy',
          'category': 'Burger & Snack',
          'description': 'Kentang goreng renyah bumbu tabur gurih spesial',
          'offline_price': 8000,
          'gage_price': 9000,
          'image': 'assets/images/dish_french_fries.png',
          'is_available': 1,
        },
        {
          'id': 'menu-rc-04',
          'name': 'Ayam Geprek Sambal Bawang Hot',
          'category': 'Makanan Utama',
          'description': 'Ayam krispi digeprek dengan sambal bawang segar pedas mantap',
          'offline_price': 13000,
          'gage_price': 14000,
          'image': 'assets/images/dish_ayam_geprek.png',
          'is_available': 1,
        },
        {
          'id': 'menu-rc-05',
          'name': 'Es Teh Manis Jumbo 22oz',
          'category': 'Minuman',
          'description': 'Es teh manis segar daun melati asli cup jumbo',
          'offline_price': 2500,
          'gage_price': 3000,
          'image': 'assets/images/dish_es_teh.png',
          'is_available': 1,
        },
      ];
    }

    if (merchantId.contains('mie')) {
      return [
        {
          'id': 'menu-mie-01',
          'name': 'Mie Ayam Bakso Urat Komplit',
          'category': 'Makanan Utama',
          'description': 'Mie kenyal gurih topping ayam cincang + 2 bakso urat sapi + pangsit',
          'offline_price': 13000,
          'gage_price': 14000,
          'image': 'assets/images/dish_mie_ayam.png',
          'is_available': 1,
        },
        {
          'id': 'menu-mie-02',
          'name': 'Bakso Urat Jumbo Kuah Tetelan Sapi',
          'category': 'Makanan Utama',
          'description': 'Bakso urat sapi jumbo dengan kuah kaldu sapi gurih dan tetelan',
          'offline_price': 14000,
          'gage_price': 15000,
          'image': 'assets/images/dish_bakso_urat.png',
          'is_available': 1,
        },
        {
          'id': 'menu-mie-03',
          'name': 'Mie Ayam Ceker Pedas Manis',
          'category': 'Makanan Utama',
          'description': 'Mie ayam dengan topping ceker empuk bumbu kecap pedas gurih',
          'offline_price': 11000,
          'gage_price': 12000,
          'image': 'assets/images/dish_mie_ayam.png',
          'is_available': 1,
        },
        {
          'id': 'menu-mie-04',
          'name': 'Es Jeruk Peras Segar Asli',
          'category': 'Minuman',
          'description': 'Jeruk peras manis dingin kaya vitamin C',
          'offline_price': 3500,
          'gage_price': 4000,
          'image': 'assets/images/dish_es_teh.png',
          'is_available': 1,
        },
      ];
    }

    if (merchantId.contains('seblak')) {
      return [
        {
          'id': 'menu-seb-01',
          'name': 'Seblak Komplit Ceker Sosis Dumpling',
          'category': 'Seblak Kuah',
          'description': 'Kerupuk seblak pedas kencur gurih + ceker empuk + sosis + dumpling keju',
          'offline_price': 12000,
          'gage_price': 13000,
          'image': 'assets/images/dish_seblak_komplit.png',
          'is_available': 1,
        },
        {
          'id': 'menu-seb-02',
          'name': 'Cimol Bojot Bumbu Bawang Pedas Nampol',
          'category': 'Cemilan',
          'description': 'Cimol kenyal tabur cabai kering kasar & minyak bawang wangi',
          'offline_price': 7000,
          'gage_price': 8000,
          'image': 'assets/images/dish_cimol_bojot.png',
          'is_available': 1,
        },
        {
          'id': 'menu-seb-03',
          'name': 'Es Teh Manis Jumbo',
          'category': 'Minuman',
          'description': 'Es teh manis segar pelepas dahaga pedas',
          'offline_price': 2500,
          'gage_price': 3000,
          'image': 'assets/images/dish_es_teh.png',
          'is_available': 1,
        },
      ];
    }

    if (merchantId.contains('roti')) {
      return [
        {
          'id': 'menu-roti-01',
          'name': 'Roti Gembong Cokelat Lumer Original',
          'category': 'Roti Gembong',
          'description': 'Roti sobek lembut khas dengan isian cokelat melimpah lumer di mulut',
          'offline_price': 15000,
          'gage_price': 16000,
          'image': 'assets/images/dish_roti_cokelat.png',
          'is_available': 1,
        },
        {
          'id': 'menu-roti-02',
          'name': 'Roti Gembong Keju Susu Spesial',
          'category': 'Roti Gembong',
          'description': 'Roti gembong lembut dengan parutan keju gurih berpadu susu kental manis',
          'offline_price': 16000,
          'gage_price': 17000,
          'image': 'assets/images/dish_roti_keju.png',
          'is_available': 1,
        },
        {
          'id': 'menu-roti-03',
          'name': 'Kopi Susu Gula Aren Fresh',
          'category': 'Minuman',
          'description': 'Espresso robusta lokal berpadu susu segar dan manis legit gula aren',
          'offline_price': 7000,
          'gage_price': 8000,
          'image': 'assets/images/dish_kopi_susu.png',
          'is_available': 1,
        },
      ];
    }

    // Default Dimsum Sewu
    return [
      {
        'id': 'menu-ds-01',
        'name': 'Combo Mentai Bakar 6 Pcs',
        'category': 'Dimsum Spesial',
        'description': 'Dimsum ayam bakar keju saus mentai gurih pedas khas Jepang',
        'offline_price': 13500,
        'gage_price': 15000,
        'image': 'assets/images/dish_dimsum_mentai.png',
        'is_available': 1,
      },
      {
        'id': 'menu-ds-02',
        'name': 'Dimsum Mozzarella Melted 4 Pcs',
        'category': 'Dimsum Kukus',
        'description': 'Dimsum ayam kukus leleh keju mozzarella asli super molor',
        'offline_price': 11000,
        'gage_price': 12000,
        'image': 'assets/images/dish_dimsum_original.png',
        'is_available': 1,
      },
      {
        'id': 'menu-ds-03',
        'name': 'Dimsum Goreng Crispy 4 Pcs',
        'category': 'Dimsum Goreng',
        'description': 'Dimsum goreng renyah kriuk dengan saus asam manis pedas',
        'offline_price': 9000,
        'gage_price': 10000,
        'image': 'assets/images/dish_dimsum_original.png',
        'is_available': 1,
      },
      {
        'id': 'menu-ds-04',
        'name': 'Siomay Ayam Udang Original 4 Pcs',
        'category': 'Dimsum Kukus',
        'description': 'Siomay ayam udang lembut disajikan hangat dalam kukusan bambu',
        'offline_price': 10000,
        'gage_price': 11000,
        'image': 'assets/images/dish_dimsum_original.png',
        'is_available': 1,
      },
      {
        'id': 'menu-ds-05',
        'name': 'Es Teh Manis Jumbo 22oz',
        'category': 'Minuman Segar',
        'description': 'Es teh seduh daun melati segar gelas 22oz',
        'offline_price': 2500,
        'gage_price': 3000,
        'image': 'assets/images/dish_es_teh.png',
        'is_available': 1,
      },
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. ORDER CREATION & CALCULATIONS
  // ─────────────────────────────────────────────────────────────────────────

  // Kalkulasi tarif pesanan dan subsidi ongkir
  static Future<Map<String, dynamic>?> calculateOrder({
    required int subtotal,
    required double distanceKm,
    required String paymentMethod,
    String? promoCode,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/orders/calculate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'items_subtotal': subtotal,
          'distance_km': distanceKm,
          'payment_method': paymentMethod,
          'promo_code': promoCode,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          return json['data'];
        }
      }
    } catch (_) {}

    // Hitung lokal jika offline
    final isCod = paymentMethod == 'CASH_COD';
    final adminFee = isCod ? 3000 : 1000;
    final rawShipping = (distanceKm * 3500).round().clamp(7000, 50000);
    int shippingDiscount = 0;
    if (subtotal >= 80000) {
      shippingDiscount = 5000;
    } else if (subtotal >= 50000) {
      shippingDiscount = 3000;
    } else if (subtotal >= 25000) {
      shippingDiscount = 1000;
    }
    if (promoCode == 'GAGERATIH') {
      shippingDiscount += 2000;
    }

    final finalShipping = (rawShipping - shippingDiscount).clamp(0, 50000);
    return {
      'items_subtotal': subtotal,
      'distance_km': distanceKm,
      'raw_shipping_fee': rawShipping,
      'shipping_discount': shippingDiscount,
      'final_shipping_fee': finalShipping,
      'admin_fee': adminFee,
      'total_amount': subtotal + finalShipping + adminFee,
      'breakdown': {
        'merchant_cut': (subtotal * 0.9).round(),
        'driver_cut': (distanceKm * 3000).round().clamp(6000, 40000),
      },
    };
  }

  // Membuat pesanan baru
  static Future<Map<String, dynamic>?> createOrder({
    required String userId,
    required String merchantId,
    required List<Map<String, dynamic>> items,
    required double distanceKm,
    required String paymentMethod,
    String? affiliatorId,
    String? promoCode,
    required String deliveryAddress,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'merchant_id': merchantId,
          'items': items,
          'distance_km': distanceKm,
          'payment_method': paymentMethod,
          'affiliator_id': affiliatorId,
          'promo_code': promoCode,
          'delivery_address': deliveryAddress,
        }),
      ).timeout(const Duration(seconds: 8));

      final json = jsonDecode(res.body);
      return json;
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung saat checkout: $e'};
    }
  }

  // Mengambil Riwayat Pesanan Pengguna
  static Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/orders/user/$userId'),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true && json['data'] is List) {
          return List<Map<String, dynamic>>.from(json['data']);
        }
      }
    } catch (_) {}
    return [];
  }

  // Detail Pesanan Tunggal untuk Live Tracker
  static Future<Map<String, dynamic>?> getOrderDetail(String orderId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/orders/$orderId'),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true && json['data'] is Map) {
          return Map<String, dynamic>.from(json['data']);
        }
      }
    } catch (_) {}
    return null;
  }

  // Simulasi Transisi Tahapan Pesanan (Testing status tracker)
  static Future<bool> simulateOrderStage(String orderId, String stage) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/orders/$orderId/simulate-stage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'stage': stage}),
      ).timeout(const Duration(seconds: 4));

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. AFFILIATE & UTILITIES
  // ─────────────────────────────────────────────────────────────────────────

  // Mengambil performa affiliator
  static Future<Map<String, dynamic>> getAffiliateStats(String code) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/affiliate/stats/$code')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true && json['data'] is Map) {
          return Map<String, dynamic>.from(json['data']);
        }
      }
    } catch (_) {}
    return {
      'affiliate_code': code,
      'total_clicks': 0,
      'total_orders': 0,
      'conversion_rate': 0.0,
      'total_commission_earned': 0,
    };
  }

  // Dynamic QRIS Generator
  static Future<String?> generateDynamicQris(int amount, String reference) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/qris/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount, 'reference': reference}),
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          return json['data']['qris_string'];
        }
      }
    } catch (_) {}
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. SHARED METHODS (MERCHANT & DRIVER CONTRACTS)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getMerchantOrders(String merchantId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/merchant/orders?merchant_id=$merchantId')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true && json['data'] is List) {
          return List<Map<String, dynamic>>.from(json['data']);
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> updateMerchantOrderStage(String orderId, String stage) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/merchant/orders/$orderId/update-stage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'stage': stage}),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> toggleMerchantStock(String itemId, bool isAvailable) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/merchant/menu/$itemId/toggle-stock'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'is_available': isAvailable}),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> createMerchantMenu({
    required String merchantId,
    required String name,
    String? description,
    required String category,
    required int offlinePrice,
    int? gagePrice,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/merchant/menu'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'merchant_id': merchantId,
          'name': name,
          'description': description,
          'category': category,
          'offline_price': offlinePrice,
          'gage_price': gagePrice,
        }),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true && json['data'] is Map) {
          return Map<String, dynamic>.from(json['data']);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>> getDriverAvailableOrders() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/driver/orders/available')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true && json['data'] is List) {
          return List<Map<String, dynamic>>.from(json['data']);
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> acceptDriverOrder(String orderId, String driverId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/driver/orders/$orderId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'driver_id': driverId}),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateDriverOrderStatus(String orderId, String status) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/driver/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> requestAffiliatePayout({
    required String affiliateCode,
    required int amount,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/affiliate/payout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'affiliate_code': affiliateCode,
          'amount': amount,
          'bank_name': bankName,
          'account_number': accountNumber,
          'account_holder': accountHolder,
        }),
      ).timeout(const Duration(seconds: 5));

      final json = jsonDecode(res.body);
      return json;
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. STANDALONE PER-SCREEN BANNER CRUD (D1 QUOTA SHIELD + EDGE CACHING)
  // ─────────────────────────────────────────────────────────────────────────

  // Mengambil banner aktif untuk target layar spesifik (dilayani dari Cloudflare Edge Cache)
  static Future<List<Map<String, dynamic>>> getBanners(String screenTarget) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/banners?screen_target=$screenTarget'),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true && json['data'] is List) {
          return List<Map<String, dynamic>>.from(json['data']);
        }
      }
    } catch (_) {}
    return [];
  }

  // Mengambil semua banner untuk dikelola oleh Admin (tanpa filter aktif)
  static Future<List<Map<String, dynamic>>> getAllBannersForAdmin({String? screenTarget}) async {
    try {
      final query = screenTarget != null && screenTarget.isNotEmpty
          ? '?screen_target=$screenTarget&admin=true'
          : '?admin=true';
      final res = await http.get(
        Uri.parse('$baseUrl/api/banners$query'),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true && json['data'] is List) {
          return List<Map<String, dynamic>>.from(json['data']);
        }
      }
    } catch (_) {}
    return [];
  }

  // Admin: Buat Banner Baru
  static Future<Map<String, dynamic>?> createBanner({
    required String screenTarget,
    required String title,
    String subtitle = '',
    required String imageUrl,
    String actionType = 'NONE',
    String actionUrl = '',
    String aspectRatio = '16:9',
    int widthPx = 1280,
    int heightPx = 720,
    int displayOrder = 0,
    int isActive = 1,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/banners'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'screen_target': screenTarget,
          'title': title,
          'subtitle': subtitle,
          'image_url': imageUrl,
          'action_type': actionType,
          'action_url': actionUrl,
          'aspect_ratio': aspectRatio,
          'width_px': widthPx,
          'height_px': heightPx,
          'display_order': displayOrder,
          'is_active': isActive,
        }),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return json;
      }
    } catch (_) {}
    return null;
  }

  // Admin: Update Banner
  static Future<bool> updateBanner(String id, Map<String, dynamic> updates) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/banners/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      ).timeout(const Duration(seconds: 5));

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Admin: Hapus Banner
  static Future<bool> deleteBanner(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/api/banners/$id'),
      ).timeout(const Duration(seconds: 4));

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
