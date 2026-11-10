import re

# 1. Update gage_ticket_voucher_card.dart with compact support
card_path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\home\presentation\widgets\gage_ticket_voucher_card.dart'
with open(card_path, 'r', encoding='utf-8') as f:
    card_content = f.read()

# Add final bool compact; to fields and constructor
old_ctor = '''  final bool isApplied;
  final bool isEligible;
  final String? ineligibilityReason;

  const GageTicketVoucherCard({
    super.key,
    required this.voucher,
    required this.onApply,
    required this.onTermsTap,
    this.isApplied = false,
    this.isEligible = true,
    this.ineligibilityReason,
  });'''

new_ctor = '''  final bool isApplied;
  final bool isEligible;
  final String? ineligibilityReason;
  final bool compact;

  const GageTicketVoucherCard({
    super.key,
    required this.voucher,
    required this.onApply,
    required this.onTermsTap,
    this.isApplied = false,
    this.isEligible = true,
    this.ineligibilityReason,
    this.compact = false,
  });'''

card_content = card_content.replace(old_ctor, new_ctor)

old_dims = '''    const double stubWidth = 78.0;
    const double cardHeight = 102.0;'''

new_dims = '''    final double stubWidth = compact ? 62.0 : 78.0;
    final double cardHeight = compact ? 82.0 : 102.0;'''

card_content = card_content.replace(old_dims, new_dims)

with open(card_path, 'w', encoding='utf-8') as f:
    f.write(card_content)
print("gage_ticket_voucher_card.dart updated with compact mode!")

# 2. Update home_merchant_showcase_section.dart to use RestoDetailScreen
showcase_path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\home\presentation\widgets\home_merchant_showcase_section.dart'
with open(showcase_path, 'r', encoding='utf-8') as f:
    showcase_content = f.read()

showcase_content = showcase_content.replace('ShopStoreDetailScreen(store: s)', 'RestoDetailScreen(merchant: s)')
with open(showcase_path, 'w', encoding='utf-8') as f:
    f.write(showcase_content)
print("home_merchant_showcase_section.dart updated to use modern unified screen!")

# 3. Update gage_api_client.dart to provide comprehensive fallback catalogs for Farm, Shop, and Build
api_path = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\core\network\gage_api_client.dart'
with open(api_path, 'r', encoding='utf-8') as f:
    api_content = f.read()

old_shop_farm_build = '''    if (merchantId.contains('shop') || merchantId.contains('ret') || merchantId.contains('sembako')) {
      return [
        {
          'id': 'prod-beras-5kg',
          'name': 'Beras C4 Super Raja 5 Kg',
          'category': 'Sembako',
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
          'category': 'Sembako',
          'description': 'Gula tebu kristal premium murni manis alami',
          'offline_price': 17000,
          'gage_price': 18000,
          'image': 'assets/images/prod_gula.png',
          'is_available': 1,
        },
        {
          'id': 'prod-telur-1kg',
          'name': 'Telur Ayam Negeri Segar 1 Kg',
          'category': 'Sembako',
          'description': 'Telur ayam ras segar grade A langsung dari peternak lokal',
          'offline_price': 27000,
          'gage_price': 28500,
          'image': 'assets/images/prod_telur.png',
          'is_available': 1,
        },
      ];
    }

    if (merchantId.contains('farm') || merchantId.contains('tani') || merchantId.contains('ternak')) {
      return [
        {
          'id': 'prod-pupuk-urea',
          'name': 'Pupuk Urea Non-Subsidi 50 Kg',
          'category': 'Pupuk & Nutrisi',
          'description': 'Pupuk nitrogen tinggi 46% untuk pertumbuhan vegetatif daun tanaman',
          'offline_price': 320000,
          'gage_price': 335000,
          'image': 'assets/images/prod_pupuk.png',
          'is_available': 1,
        },
        {
          'id': 'prod-pakan-ayam',
          'name': 'Pakan Ayam Pedaging Pokphand 511 (50 Kg)',
          'category': 'Pakan Ternak',
          'description': 'Konsentrat crumble komplit nutrisi tinggi pembesar bibit ayam',
          'offline_price': 420000,
          'gage_price': 438000,
          'image': 'assets/images/prod_pakan.png',
          'is_available': 1,
        },
        {
          'id': 'prod-bibit-padi',
          'name': 'Benih Padi Inpari 32 Bersertifikat 5 Kg',
          'category': 'Benih & Bibit',
          'description': 'Benih padi varietas unggul tahan hama wereng dan anakan lebat',
          'offline_price': 75000,
          'gage_price': 80000,
          'image': 'assets/images/prod_benih.png',
          'is_available': 1,
        },
      ];
    }

    if (merchantId.contains('build') || merchantId.contains('tb') || merchantId.contains('bangun')) {
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
          'id': 'prod-besi-10',
          'name': 'Besi Beton Ulir 10mm SNI (12 Meter)',
          'category': 'Besi & Logam',
          'description': 'Besi beton tulangan bangunan standar SNI kuat tarik teruji',
          'offline_price': 72000,
          'gage_price': 76000,
          'image': 'assets/images/prod_besi.png',
          'is_available': 1,
        },
      ];
    }'''

new_shop_farm_build = '''    // Sembako, Sayur & Toko Kelontong
    if (merchantId.contains('shop') || merchantId.contains('ret') || merchantId.contains('sembako') ||
        merchantId.contains('lapak') || merchantId.contains('telur') || merchantId.contains('sayur') ||
        merchantId.contains('grosir') || merchantId.contains('siti') || merchantId.contains('fajar')) {
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
          'name': 'Telur Ayam Negeri Segar 1 Kg (~16 butir)',
          'category': 'Sembako & Beras',
          'description': 'Telur ayam ras segar grade A langsung dari peternak kandang',
          'offline_price': 27000,
          'gage_price': 28500,
          'image': 'assets/images/prod_telur.png',
          'is_available': 1,
        },
        {
          'id': 'prod-indomie-goreng',
          'name': 'Indomie Goreng Spesial 1 Dus (40 Pcs)',
          'category': 'Mie Instan & Snack',
          'description': 'Mie instan goreng favorit keluarga bumbu gurih lengkap bawang goreng',
          'offline_price': 115000,
          'gage_price': 118000,
          'image': 'assets/images/prod_indomie.png',
          'is_available': 1,
        },
        {
          'id': 'prod-cabai-rawit',
          'name': 'Cabai Rawit Merah Segar Petik Pagi 500gr',
          'category': 'Sayur & Bumbu Segar',
          'description': 'Cabai rawit segar pedas menyengat hasil panen petani lokal',
          'offline_price': 18000,
          'gage_price': 19500,
          'image': 'assets/images/prod_cabai.png',
          'is_available': 1,
        },
      ];
    }

    // Pertanian & Peternakan (Kios Tani, Pupuk & Pakan)
    if (merchantId.contains('farm') || merchantId.contains('tani') || merchantId.contains('ternak') ||
        merchantId.contains('kios') || merchantId.contains('mandiri') || merchantId.contains('lestari') ||
        merchantId.contains('rejeki') || merchantId.contains('subur')) {
      return [
        {
          'id': 'prod-pupuk-npk',
          'name': 'Pupuk NPK Mutiara 16-16-16 Kemasan 1 Kg',
          'category': 'Pupuk & Nutrisi',
          'description': 'Pupuk majemuk lengkap nutrisi nitrogen, fosfat dan kalium seimbang untuk kesuburan tanaman',
          'offline_price': 17000,
          'gage_price': 18000,
          'image': 'assets/images/prod_pupuk.png',
          'is_available': 1,
        },
        {
          'id': 'prod-pupuk-urea',
          'name': 'Pupuk Urea Nitrea Non-Subsidi 5 Kg',
          'category': 'Pupuk & Nutrisi',
          'description': 'Kandungan nitrogen tinggi 46% mempercepat anakan dan daun hijau royo-royo',
          'offline_price': 36000,
          'gage_price': 38000,
          'image': 'assets/images/prod_pupuk.png',
          'is_available': 1,
        },
        {
          'id': 'prod-benih-padi',
          'name': 'Benih Padi Unggul Inpari 32 Karung 5 Kg',
          'category': 'Benih & Bibit',
          'description': 'Benih padi bersertifikat resmi tahan wereng batang coklat dan anakan lebat',
          'offline_price': 72000,
          'gage_price': 75000,
          'image': 'assets/images/prod_benih.png',
          'is_available': 1,
        },
        {
          'id': 'prod-benih-cabai',
          'name': 'Benih Cabai Rawit Merah Unggul Ori 212 10gr',
          'category': 'Benih & Bibit',
          'description': 'Daya tumbuh 85% buah tegak lebat tahan layu bakteri dan antraknosa',
          'offline_price': 42000,
          'gage_price': 45000,
          'image': 'assets/images/prod_cabai.png',
          'is_available': 1,
        },
        {
          'id': 'prod-pakan-ayam',
          'name': 'Pakan Ayam Broiler BR-1 Pokphand Karung 5 Kg',
          'category': 'Pakan Ternak',
          'description': 'Pakan crumble masa starter ayam pedaging berprotein tinggi cepat besar sehat',
          'offline_price': 50000,
          'gage_price': 52000,
          'image': 'assets/images/prod_pakan.png',
          'is_available': 1,
        },
        {
          'id': 'prod-konsentrat-sapi',
          'name': 'Konsentrat Penggemukan Sapi Potong Karung 50 Kg',
          'category': 'Pakan Ternak',
          'description': 'Pakan konsentrat fermentasi kaya protein kasar untuk percepatan bobot sapi dan kambing',
          'offline_price': 215000,
          'gage_price': 225000,
          'image': 'assets/images/prod_pakan.png',
          'is_available': 1,
        },
        {
          'id': 'prod-sprayer-16l',
          'name': 'Tangki Sprayer Elektrik Pertanian Swan 16 Liter',
          'category': 'Alat Tani',
          'description': 'Semprotan hama elektrik baterai cas tahan 6 jam semburan kabut halus merata',
          'offline_price': 275000,
          'gage_price': 285000,
          'image': 'assets/images/prod_traktor.png',
          'is_available': 1,
        },
      ];
    }

    // Bahan Bangunan & Alat Pertukangan (TB & Toko Bangunan)
    if (merchantId.contains('build') || merchantId.contains('tb') || merchantId.contains('bangun') ||
        merchantId.contains('cat') || merchantId.contains('besi') || merchantId.contains('griya') ||
        merchantId.contains('jaya') || merchantId.contains('bangkit')) {
      return [
        {
          'id': 'prod-semen-gresik',
          'name': 'Semen Gresik Portland Composite 40 Kg',
          'category': 'Semen & Pasir',
          'description': 'Semen berkualitas tinggi daya rekat kuat dan hasil plesteran acian lebih halus kokoh',
          'offline_price': 52000,
          'gage_price': 54000,
          'image': 'assets/icons/ic_build.png',
          'is_available': 1,
        },
        {
          'id': 'prod-semen-tigaroda',
          'name': 'Semen Tiga Roda Master Portland 40 Kg',
          'category': 'Semen & Pasir',
          'description': 'Pilihan utama tukang bangunan untuk pasangan bata, cor beton, dan plester dinding',
          'offline_price': 51000,
          'gage_price': 53000,
          'image': 'assets/icons/ic_build.png',
          'is_available': 1,
        },
        {
          'id': 'prod-cat-dulux',
          'name': 'Cat Tembok Interior Dulux Catylac Putih 5 Kg',
          'category': 'Cat & Thinner',
          'description': 'Formula Chroma Brite warna cerah menawan tidak mudah pudar dan minim cipratan',
          'offline_price': 132000,
          'gage_price': 138000,
          'image': 'assets/icons/ic_build.png',
          'is_available': 1,
        },
        {
          'id': 'prod-cat-avian',
          'name': 'Cat Kayu & Besi Avian Super Glossy Hitam 1 Kg',
          'category': 'Cat & Thinner',
          'description': 'Cat minyak mengkilap daya tutup maksimal cepat kering dan tahan cuaca',
          'offline_price': 65000,
          'gage_price': 68000,
          'image': 'assets/icons/ic_build.png',
          'is_available': 1,
        },
        {
          'id': 'prod-besi-8mm',
          'name': 'Besi Beton Polos SNI 8mm (Panjang 12 Meter)',
          'category': 'Besi & Baja',
          'description': 'Besi tulangan cor standar SNI kuat tarik teruji untuk kolom dan balok bangunan',
          'offline_price': 47000,
          'gage_price': 49000,
          'image': 'assets/icons/ic_build.png',
          'is_available': 1,
        },
        {
          'id': 'prod-pipa-pvc',
          'name': 'Pipa PVC Rucika AW 3/4 Inch (Panjang 4 Meter)',
          'category': 'Pipa & Sanitasi',
          'description': 'Pipa instalasi saluran air bersih bertekanan tebal tidak mudah pecah atau berlumut',
          'offline_price': 32000,
          'gage_price': 34000,
          'image': 'assets/icons/ic_build.png',
          'is_available': 1,
        },
        {
          'id': 'prod-palu-baja',
          'name': 'Palu Martil Kambing Baja Gagang Karet Anti Slip',
          'category': 'Alat Pertukangan',
          'description': 'Kepala palu baja tempa padat dengan pencabut paku presisi dan pegangan karet ergonomis',
          'offline_price': 40000,
          'gage_price': 42000,
          'image': 'assets/icons/ic_build.png',
          'is_available': 1,
        },
        {
          'id': 'prod-kuas-3inch',
          'name': 'Kuas Cat Tembok Eterna Bulu Putih 3 Inch',
          'category': 'Alat Pertukangan',
          'description': 'Bulu kuas halus rapat tidak mudah rontok menghasilkan sapuan cat rata sempurna',
          'offline_price': 12000,
          'gage_price': 13000,
          'image': 'assets/icons/ic_build.png',
          'is_available': 1,
        },
      ];
    }'''

if old_shop_farm_build in api_content:
    api_content = api_content.replace(old_shop_farm_build, new_shop_farm_build)
    with open(api_path, 'w', encoding='utf-8') as f:
        f.write(api_content)
    print("gage_api_client.dart updated with comprehensive catalogs for Farm, Shop, and Build!")
else:
    print("WARNING: old_shop_farm_build not found in gage_api_client.dart")
