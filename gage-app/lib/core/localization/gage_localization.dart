/// GageAppLanguage
enum GageAppLanguage {
  indonesia('id', 'Bahasa Indonesia', 'Standar Resmi', '🇮🇩'),
  english('en', 'English', 'Global Language', '🇬🇧'),
  jawa('jv', 'Basa Jawa', 'Basa Jawa Ngoko', '🇮🇩');

  final String code;
  final String label;
  final String description;
  final String flag;

  const GageAppLanguage(this.code, this.label, this.description, this.flag);

  static GageAppLanguage fromCode(String code) {
    switch (code) {
      case 'en':
        return GageAppLanguage.english;
      case 'jv':
        return GageAppLanguage.jawa;
      case 'id':
      default:
        return GageAppLanguage.indonesia;
    }
  }
}

/// GageLocalization Dictionary
class GageLocalization {
  static const Map<String, Map<String, String>> _values = {
    // Nav Bar
    'nav_home': {
      'id': 'Beranda',
      'en': 'Home',
      'jv': 'Kaca Ngarep',
    },
    'nav_orders': {
      'id': 'Pesanan',
      'en': 'Orders',
      'jv': 'Pesenan',
    },
    'nav_promo': {
      'id': 'Promo',
      'en': 'Promos',
      'jv': 'Diskonan',
    },
    'nav_video': {
      'id': 'Video',
      'en': 'Videos',
      'jv': 'Video Kuliner',
    },
    'nav_profile': {
      'id': 'Profil',
      'en': 'Profile',
      'jv': 'Profilku',
    },

    // Header & Search
    'search_hint': {
      'id': 'Cari layanan, toko, atau menu...',
      'en': 'Search services, stores, or dishes...',
      'jv': 'Golek layanan, toko, utawa menu...',
    },
    'official_hub': {
      'id': 'Lini Usaha GAGE by Halu Goods Indonesia',
      'en': 'GAGE Business Unit by Halu Goods Indonesia',
      'jv': 'Lini Usaha GAGE by Halu Goods Indonesia',
    },
    'holding_company': {
      'id': 'Holding Company: Halu Goods Indonesia',
      'en': 'Holding Company: Halu Goods Indonesia',
      'jv': 'Holding Company: Halu Goods Indonesia',
    },

    // Wallet
    'topup': {
      'id': 'Isi Saldo',
      'en': 'Top Up',
      'jv': 'Isi Saldo',
    },
    'pay': {
      'id': 'Bayar',
      'en': 'Pay',
      'jv': 'Mbayar',
    },
    'withdraw': {
      'id': 'Tarik Tunai',
      'en': 'Withdraw',
      'jv': 'Tarik Dhuwit',
    },
    'wallet_balance': {
      'id': 'Saldo GAGEPay',
      'en': 'GAGEPay Balance',
      'jv': 'Saldo GAGEPay',
    },
    'points_reward': {
      'id': 'Koin Cuan',
      'en': 'Cuan Points',
      'jv': 'Koin Cuan',
    },

    // Profile Screen
    'profile_title': {
      'id': 'Akun & Profil',
      'en': 'Account & Profile',
      'jv': 'Akun & Profilku',
    },
    'verified_wa': {
      'id': 'WA Terverifikasi',
      'en': 'WA Verified',
      'jv': 'WA Wis Sah',
    },
    'security_section': {
      'id': 'Keamanan & Transaksi',
      'en': 'Security & Transactions',
      'jv': 'Keamanan & Transaksi',
    },
    'change_pin': {
      'id': 'Ubah PIN GAGEPay 6 Digit',
      'en': 'Change 6-Digit GAGEPay PIN',
      'jv': 'Ganti PIN GAGEPay 6 Angka',
    },
    'change_pin_sub': {
      'id': 'PIN otorisasi pembayaran dompet & QRIS',
      'en': 'Authorization PIN for wallet & QRIS payments',
      'jv': 'PIN kanggo mbayar dompet & QRIS',
    },
    'biometric_title': {
      'id': 'Autentikasi Sidik Jari',
      'en': 'Fingerprint Authentication',
      'jv': 'Sidik Driji (Biometrik)',
    },
    'biometric_sub': {
      'id': 'Verifikasi saat transaksi pembayaran & top up GAGEPay',
      'en': 'Verify during payments & GAGEPay top up',
      'jv': 'Pindai driji pas bayar & isi saldo GAGEPay',
    },
    'pref_section': {
      'id': 'Preferensi Aplikasi',
      'en': 'App Preferences',
      'jv': 'Setelan Aplikasi',
    },
    'theme_title': {
      'id': 'Pengaturan Tema Tampilan',
      'en': 'Appearance Theme',
      'jv': 'Setelan Tema Tampilan',
    },
    'notif_title': {
      'id': 'Pengaturan Notifikasi',
      'en': 'Notification Settings',
      'jv': 'Setelan Notifikasi',
    },
    'lang_title': {
      'id': 'Bahasa Aplikasi',
      'en': 'App Language',
      'jv': 'Basa Aplikasi',
    },
    'help_section': {
      'id': 'Pusat Bantuan & Layanan',
      'en': 'Help & Support Center',
      'jv': 'Pusat Pitulungan & Layanan',
    },
    'cs_whatsapp': {
      'id': 'Chat Pusat Bantuan Resmi',
      'en': 'Official Support Chat',
      'jv': 'Chat Pusat Pitulungan Resmi',
    },
    'faq_title': {
      'id': 'Pertanyaan Umum (FAQ)',
      'en': 'Frequently Asked Questions',
      'jv': 'Pitakon Umum (FAQ)',
    },
    'about_title': {
      'id': 'Tentang GAGE Pracimantoro',
      'en': 'About GAGE Pracimantoro',
      'jv': 'Babagan GAGE Pracimantoro',
    },
    'terms_service': {
      'id': 'Syarat & Ketentuan Layanan',
      'en': 'Terms of Service',
      'jv': 'Syarat & Katentuan Layanan',
    },
    'privacy_policy': {
      'id': 'Kebijakan Privasi',
      'en': 'Privacy Policy',
      'jv': 'Kawicaksanan Privasi',
    },
    'danger_zone': {
      'id': 'Zona Tindakan Akun',
      'en': 'Account Action Zone',
      'jv': 'Zona Tindakan Akun',
    },
    'logout': {
      'id': 'Keluar dari Akun',
      'en': 'Log Out',
      'jv': 'Metu saka Akun',
    },
    'delete_account': {
      'id': 'Hapus Akun Permanen',
      'en': 'Delete Account Permanently',
      'jv': 'Busak Akun Langgeng',
    },

    // Services
    'ride': {
      'id': 'GAGE Ride',
      'en': 'GAGE Ride',
      'jv': 'GAGE Ojek Motor',
    },
    'car': {
      'id': 'GAGE Car',
      'en': 'GAGE Car',
      'jv': 'GAGE Mobil',
    },
    'food': {
      'id': 'GAGE Food',
      'en': 'GAGE Food',
      'jv': 'GAGE Panganan',
    },
    'send': {
      'id': 'GAGE Send',
      'en': 'GAGE Send',
      'jv': 'GAGE Kirim Paket',
    },
    'shop': {
      'id': 'GAGE Shop',
      'en': 'GAGE Shop',
      'jv': 'GAGE Blonjo Toko',
    },

    // Daily Login Reward
    'daily_reward_title': {
      'id': 'Hadiah Login Harian',
      'en': 'Daily Login Reward',
      'jv': 'Hadiah Mlebu Saben Dina',
    },
    'daily_reward_sub': {
      'id': 'Check-in tiap hari, kumpulkan Koin GAGE Cuan!',
      'en': 'Check-in daily, collect GAGE Cuan Coins!',
      'jv': 'Mlebu saben dina, kumpulno Koin GAGE Cuan!',
    },
    'claim_reward_btn': {
      'id': 'Klaim Hadiah Hari Ini (+100 Koin)',
      'en': 'Claim Today\'s Reward (+100 Coins)',
      'jv': 'Klaim Hadiah Dina Iki (+100 Koin)',
    },
    'claimed_today': {
      'id': 'Sudah Klaim Hari Ini',
      'en': 'Already Claimed Today',
      'jv': 'Wis Klaim Dina Iki',
    },

    // Action buttons & Common UI
    'order_now': {
      'id': 'Pesan Sekarang',
      'en': 'Order Now',
      'jv': 'Pesen Saiki',
    },
    'add_to_cart': {
      'id': 'Tambah ke Keranjang',
      'en': 'Add to Cart',
      'jv': 'Lebokne Keranjang',
    },
    'apply': {
      'id': 'Pakai',
      'en': 'Apply',
      'jv': 'Pasang',
    },
    'cancel': {
      'id': 'Batal',
      'en': 'Cancel',
      'jv': 'Batal',
    },
    'save': {
      'id': 'Simpan',
      'en': 'Save',
      'jv': 'Simpen',
    },
    'checkout': {
      'id': 'Lanjut Pembayaran',
      'en': 'Proceed to Payment',
      'jv': 'Mbayar Saiki',
    },
  };

  static String get(String key, String langCode) {
    if (_values.containsKey(key)) {
      final langMap = _values[key]!;
      if (langMap.containsKey(langCode)) {
        return langMap[langCode]!;
      }
      return langMap['id'] ?? key;
    }
    return key;
  }
}
