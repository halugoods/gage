path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\core\network\gage_api_client.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace the entire getMerchantMenu function
start_marker = "  static Future<List<Map<String, dynamic>>> getMerchantMenu(String merchantId) async {"
end_marker = "  // =========================================================================\n  // 4. ORDER CREATION & CALCULATIONS"

new_func = '''  static Future<List<Map<String, dynamic>>> getMerchantMenu(String merchantId) async {
    final lowerId = merchantId.toLowerCase();

    // 1. Build / Bangunan & Material (Prioritas tertinggi agar tidak tertimpa keyword mandiri/jaya)
    if (lowerId.startsWith('build') || lowerId.contains('build') || lowerId.contains('tb-') ||
        lowerId.contains('tb ') || lowerId.contains('bangun') || lowerId.contains('cat-') ||
        lowerId.contains('besi-') || lowerId.contains('baja') || lowerId.contains('material')) {
      return [
        {
          'id': 'prod-semen-gresik',
          'name': 'Semen Gresik Portland PCC 40 Kg',
          'category': 'Semen & Pasir',
          'description': 'Semen komposit serbaguna kuat tekan tinggi dan daya rekat kokoh',
          'offline_price': 52000,
          'gage_price': 55000,
          'image': 'assets/images/prod_semen.png',
          'is_available': 1,
        },
        {
          'id': 'prod-semen-tigaroda',
          'name': 'Semen Tiga Roda Serbaguna 40 Kg',
          'category': 'Semen & Pasir',
          'description': 'Semen Portland Komposit kokoh presisi tahan retak dan cuaca ekstrem',
          'offline_price': 53000,
          'gage_price': 56000,
          'image': 'assets/images/prod_semen.png',
          'is_available': 1,
        },
        {
          'id': 'prod-cat-tembok',
          'name': 'Cat Tembok Dulux Catylac Putih 5 Kg',
          'category': 'Cat & Finishing',
          'description': 'Cat dinding interior anti pudar dengan formula cerah tahan lama',
          'offline_price': 135000,
          'gage_price': 142000,
          'image': 'assets/images/prod_cat.png',
          'is_available': 1,
        },
        {
          'id': 'prod-cat-avian',
          'name': 'Cat Kayu & Besi Avian Hitam/Putih 1 Kg',
          'category': 'Cat & Finishing',
          'description': 'Cat enamel kilap maksimal cepat kering anti karat dan anti rayap',
          'offline_price': 68000,
          'gage_price': 72000,
          'image': 'assets/images/prod_cat.png',
          'is_available': 1,
        },
        {
          'id': 'prod-besi-10',
          'name': 'Besi Beton Ulir 10mm SNI (12 Meter)',
          'category': 'Besi & Baja',
          'description': 'Besi beton tulangan SNI sertifikasi kekuatan struktur bangunan',
          'offline_price': 78000,
          'gage_price': 82000,
          'image': 'assets/images/prod_besi.png',
          'is_available': 1,
        },
        {
          'id': 'prod-besi-8',
          'name': 'Besi Beton Polos 8mm SNI (12 Meter)',
          'category': 'Besi & Baja',
          'description': 'Besi begel tulangan SNI presisi daya lentur dan tarik standar konstruksi',
          'offline_price': 52000,
          'gage_price': 55000,
          'image': 'assets/images/prod_besi.png',
          'is_available': 1,
        },
        {
          'id': 'prod-pipa-pvc',
          'name': 'Pipa PVC Rucika D 3/4 Inch (4 Meter)',
          'category': 'Pipa & Sanitasi',
          'description': 'Pipa air uPVC tebal tanpa timbal kuat tekanan debit air tinggi',
          'offline_price': 34000,
          'gage_price': 36500,
          'image': 'assets/images/prod_traktor.png',
          'is_available': 1,
        },
        {
          'id': 'prod-kuas-eterna',
          'name': 'Kuas Cat Eterna 3 Inch Bulu Tebal',
          'category': 'Alat Pertukangan',
          'description': 'Bulu kuas halus rapat tidak mudah rontok menghasilkan sapuan cat rata sempurna',
          'offline_price': 12000,
          'gage_price': 13000,
          'image': 'assets/images/prod_traktor.png',
          'is_available': 1,
        },
      ];
    }

    // 2. Farm / Pertanian & Peternakan
    if (lowerId.startsWith('farm') || lowerId.contains('farm') || lowerId.contains('tani') ||
        lowerId.contains('ternak') || lowerId.contains('pupuk') || lowerId.contains('pakan') ||
        lowerId.contains('kios-subur') || lowerId.contains('sentra-mandiri') || lowerId.contains('poultry')) {
      return [
        {
          'id': 'prod-pupuk-npk',
          'name': 'Pupuk NPK Mutiara 16-16-16 Kemasan 1 Kg',
          'category': 'Pupuk & Nutrisi',
          'description': 'Pupuk majemuk lengkap nutrisi nitrogen, fosfat dan kalium seimbang untuk kesuburan',
          'offline_price': 18000,
          'gage_price': 19500,
          'image': 'assets/images/prod_pupuk.png',
          'is_available': 1,
        },
        {
          'id': 'prod-pupuk-urea',
          'name': 'Pupuk Urea Petrokimia Putih Prill 5 Kg',
          'category': 'Pupuk & Nutrisi',
          'description': 'Pupuk nitrogen tunggal penyubur daun dan percepat vegetatif tanaman',
          'offline_price': 42000,
          'gage_price': 45000,
          'image': 'assets/images/prod_pupuk.png',
          'is_available': 1,
        },
        {
          'id': 'prod-benih-padi',
          'name': 'Benih Padi Unggul Inpari 32 Bersertifikat 5 Kg',
          'category': 'Benih & Bibit',
          'description': 'Benih padi bersertifikat tahan wereng batang coklat dan hawar daun',
          'offline_price': 75000,
          'gage_price': 80000,
          'image': 'assets/images/prod_benih.png',
          'is_available': 1,
        },
        {
          'id': 'prod-benih-cabai',
          'name': 'Benih Cabai Rawit Ori 212 Kemasan 10 Gram',
          'category': 'Benih & Bibit',
          'description': 'Benih cabai rawit super lebat tahan patek buah padat berbobot',
          'offline_price': 38000,
          'gage_price': 41000,
          'image': 'assets/images/prod_cabai.png',
          'is_available': 1,
        },
        {
          'id': 'prod-pakan-ayam',
          'name': 'Pakan Ayam Broiler BR-1 Starter 5 Kg',
          'category': 'Pakan Ternak',
          'description': 'Pakan crumble protein tinggi pertumbuhan ayam pedaging maksimal',
          'offline_price': 52000,
          'gage_price': 55000,
          'image': 'assets/images/prod_pakan.png',
          'is_available': 1,
        },
        {
          'id': 'prod-konsentrat-sapi',
          'name': 'Pakan Konsentrat Penggemuk Sapi Potong 50 Kg',
          'category': 'Pakan Ternak',
          'description': 'Konsentrat formulasi ahli nutrisi ternak nafsu makan tinggi bobot melonjak',
          'offline_price': 240000,
          'gage_price': 255000,
          'image': 'assets/images/prod_pakan.png',
          'is_available': 1,
        },
        {
          'id': 'prod-obat-hama',
          'name': 'Insektisida Regent 50 SC Merah 100ml',
          'category': 'Pestisida & Obat',
          'description': 'Insektisida sistemik racun kontak dan lambung pembasmi hama sundep penggerek',
          'offline_price': 39000,
          'gage_price': 42000,
          'image': 'assets/images/prod_pupuk.png',
          'is_available': 1,
        },
        {
          'id': 'prod-sprayer-16l',
          'name': 'Tangki Sprayer Elektrik CBA 16 Liter 2in1',
          'category': 'Alat Pertanian',
          'description': 'Sprayer semprot baterai lithium awet semburan kabut halus merata',
          'offline_price': 380000,
          'gage_price': 395000,
          'image': 'assets/images/prod_traktor.png',
          'is_available': 1,
        },
      ];
    }

    // 3. Shop / Sembako, Sayur & Toko Kelontong
    if (lowerId.startsWith('shop') || lowerId.contains('shop') || lowerId.contains('ret') ||
        lowerId.contains('sembako') || lowerId.contains('lapak') || lowerId.contains('telur') ||
        lowerId.contains('sayur') || lowerId.contains('grosir') || lowerId.contains('kelontong') ||
        lowerId.contains('minimarket') || lowerId.contains('lancar')) {
      return [
        {
          'id': 'prod-beras-5kg',
          'name': 'Beras C4 Super Raja 5 Kg',
          'category': 'Sembako & Beras',
          'description': 'Beras pulen pilihan petani Wonogiri, putih alami tanpa pemutih',
          'offline_price': 70000,
          'gage_price': 72000,
          'image': 'assets/images/prod_beras.png',
          'is_available': 1,
        },
        {
          'id': 'prod-minyak-2l',
          'name': 'Minyak Goreng Bimoli Klasik 2 Liter',
          'category': 'Minyak & Bumbu',
          'description': 'Minyak sawit murni jernih dua kali penyaringan higienis',
          'offline_price': 36000,
          'gage_price': 38500,
          'image': 'assets/images/prod_minyak.png',
          'is_available': 1,
        },
        {
          'id': 'prod-gula-1kg',
          'name': 'Gula Pasir Gulaku Putih 1 Kg',
          'category': 'Sembako & Beras',
          'description': 'Gula tebu kristal premium murni manis alami',
          'offline_price': 17000,
          'gage_price': 18000,
          'image': 'assets/images/prod_gula.png',
          'is_available': 1,
        },
        {
          'id': 'prod-telur-1kg',
          'name': 'Telur Ayam Ras Segar Kandang 1 Kg',
          'category': 'Sembako & Beras',
          'description': 'Telur ayam negeri segar baru dipanen pagi hari tanpa cangkang retak',
          'offline_price': 26000,
          'gage_price': 28000,
          'image': 'assets/images/prod_telur.png',
          'is_available': 1,
        },
        {
          'id': 'prod-indomie-dus',
          'name': 'Indomie Goreng Spesial 1 Dus (40 Pcs)',
          'category': 'Makanan Instan',
          'description': 'Mie instan terlaris bumbu gurih lengkap bawang goreng kriuk',
          'offline_price': 118000,
          'gage_price': 122000,
          'image': 'assets/images/prod_indomie.png',
          'is_available': 1,
        },
        {
          'id': 'prod-terigu-1kg',
          'name': 'Tepung Terigu Segitiga Biru 1 Kg',
          'category': 'Sembako & Beras',
          'description': 'Tepung terigu serbaguna protein sedang lembut kalis',
          'offline_price': 12500,
          'gage_price': 13500,
          'image': 'assets/images/prod_beras.png',
          'is_available': 1,
        },
        {
          'id': 'prod-sayur-bayam',
          'name': 'Sayur Bayam Hijau & Kangkung Segar (2 Ikat)',
          'category': 'Sayuran Segar',
          'description': 'Sayuran daun segar petik subuh bebas ulat dan higienis',
          'offline_price': 5000,
          'gage_price': 6000,
          'image': 'assets/images/prod_cabai.png',
          'is_available': 1,
        },
        {
          'id': 'prod-cabai-rawit',
          'name': 'Cabai Rawit Merah Setan Segar 250g',
          'category': 'Bumbu Dapur',
          'description': 'Cabai rawit merah pedas mantap segar tangkai hijau',
          'offline_price': 12000,
          'gage_price': 14000,
          'image': 'assets/images/prod_cabai.png',
          'is_available': 1,
        },
      ];
    }

    // 4. Food / Kuliner Pilihan
    if (lowerId.contains('rc') || lowerId.contains('rocket') || lowerId.contains('chicken')) {
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
          'name': 'French Fries Crispy Shake',
          'category': 'Burger & Snack',
          'description': 'Kentang goreng renyah bumbu tabur gurih asin',
          'offline_price': 8000,
          'gage_price': 9000,
          'image': 'assets/images/dish_french_fries.png',
          'is_available': 1,
        },
        {
          'id': 'menu-rc-04',
          'name': 'Ayam Geprek Sambal Korek + Nasi',
          'category': 'Menu Geprek',
          'description': 'Ayam krispi digeprek pedas gurih dengan sambal bawang segar',
          'offline_price': 16000,
          'gage_price': 17500,
          'image': 'assets/images/dish_ayam_geprek.png',
          'is_available': 1,
        },
      ];
    }

    if (lowerId.contains('mie') || lowerId.contains('bakso')) {
      return [
        {
          'id': 'menu-mie-01',
          'name': 'Mie Ayam Spesial Pangsit Jumbo',
          'category': 'Mie Ayam',
          'description': 'Mie kenyal gurih topping ayam kecap cincang melimpah + pangsit basah & krispi',
          'offline_price': 12000,
          'gage_price': 13500,
          'image': 'assets/images/dish_mie_ayam.png',
          'is_available': 1,
        },
        {
          'id': 'menu-mie-02',
          'name': 'Mie Ayam Bakso Urat Mantap',
          'category': 'Mie Ayam',
          'description': 'Mie ayam khas Solo dengan topping bakso urat sapi asli kenyal berdaging',
          'offline_price': 15000,
          'gage_price': 17000,
          'image': 'assets/images/dish_bakso_urat.png',
          'is_available': 1,
        },
        {
          'id': 'menu-mie-03',
          'name': 'Bakso Urat Kuah Kaldu Sapi',
          'category': 'Bakso',
          'description': 'Semangkuk bakso urat & bakso halus dengan kuah kaldu sapi sumsum gurih panas',
          'offline_price': 14000,
          'gage_price': 15500,
          'image': 'assets/images/dish_bakso_urat.png',
          'is_available': 1,
        },
        {
          'id': 'menu-mie-04',
          'name': 'Es Teh Manis Melati Jumbo',
          'category': 'Minuman Segar',
          'description': 'Es teh manis wangi melati pelepas dahaga porsi jumbo 22oz',
          'offline_price': 2500,
          'gage_price': 3000,
          'image': 'assets/images/dish_es_teh.png',
          'is_available': 1,
        },
      ];
    }

    if (lowerId.contains('seblak') || lowerId.contains('cimol')) {
      return [
        {
          'id': 'menu-seb-01',
          'name': 'Seblak Prasmanan Komplit Ceker Sosis',
          'category': 'Seblak Juara',
          'description': 'Seblak kuah kencur pedas berlevel dengan topping ceker empuk, sosis & kerupuk aci',
          'offline_price': 13000,
          'gage_price': 15000,
          'image': 'assets/images/dish_seblak_komplit.png',
          'is_available': 1,
        },
        {
          'id': 'menu-seb-02',
          'name': 'Cimol Bojot Garut Bumbu Basah',
          'category': 'Camilan Pedas',
          'description': 'Cimol kenyal kopong khas Garut dengan bumbu minyak bawang gurih cabe rawit melimpah',
          'offline_price': 8000,
          'gage_price': 9000,
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

    if (lowerId.contains('roti')) {
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

    // Default Dimsum Sewu Pracimantoro
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
  }'''

idx_start = text.find(start_marker)
idx_end = text.find(end_marker)

if idx_start == -1 or idx_end == -1:
    print(f"Error: markers not found! start={idx_start}, end={idx_end}")
else:
    new_text = text[:idx_start] + new_func + "\n\n" + text[idx_end:]
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_text)
    print("Updated getMerchantMenu in gage_api_client.dart successfully!")
