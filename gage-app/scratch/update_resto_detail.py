p = r'c:\Users\ertyui\ZCodeProject\gage\gage-app\lib\features\food\presentation\resto_detail_screen.dart'
with open(p, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Update _getMenuItemImage and add _getFallbackIcon & _buildServiceVouchers
old_func = """  String _getMenuItemImage(Map<String, dynamic> item) {
    if (item['image'] != null && item['image'].toString().isNotEmpty) {
      return item['image'].toString();
    }
    final name = (item['name'] ?? '').toString().toLowerCase();
    final cat = (item['category'] ?? '').toString().toLowerCase();

    if (name.contains('mentai')) return 'assets/images/dish_dimsum_mentai.png';
    if (name.contains('burger')) return 'assets/images/dish_chicken_burger.png';
    if (name.contains('kentang') || name.contains('fries')) return 'assets/images/dish_french_fries.png';
    if (name.contains('seblak')) return 'assets/images/dish_seblak_komplit.png';
    if (name.contains('cimol')) return 'assets/images/dish_cimol_bojot.png';
    if (name.contains('roti') && name.contains('keju')) return 'assets/images/dish_roti_keju.png';
    if (name.contains('roti')) return 'assets/images/dish_roti_cokelat.png';
    if (name.contains('kopi')) return 'assets/images/dish_kopi_susu.png';
    if (name.contains('sate')) return 'assets/images/dish_sate_ayam.png';
    if (name.contains('bakso')) return 'assets/images/dish_bakso_urat.png';
    if (name.contains('mie') || name.contains('pangsit')) return 'assets/images/dish_mie_ayam.png';
    if (name.contains('ayam') || name.contains('geprek') || name.contains('rocket') || name.contains('chicken')) {
      return 'assets/images/dish_rocket_1.png';
    }
    if (name.contains('teh') || name.contains('es') || name.contains('jeruk') || name.contains('minum') || cat.contains('minum')) {
      return 'assets/images/dish_es_teh.png';
    }
    return 'assets/images/dish_dimsum_original.png';
  }"""

new_func = """  IconData _getFallbackIcon(dynamic categoryVal) {
    final cat = (categoryVal ?? '').toString().toLowerCase();
    final mCat = (widget.merchant['category'] ?? '').toString().toLowerCase();
    final mId = (widget.merchant['id'] ?? '').toString().toLowerCase();
    if (cat.contains('bangun') || cat.contains('semen') || cat.contains('cat') || cat.contains('besi') ||
        mCat.contains('bangun') || mId.contains('build') || mId.contains('tb-')) {
      return Icons.construction_rounded;
    }
    if (cat.contains('tani') || cat.contains('pupuk') || cat.contains('benih') || cat.contains('pakan') ||
        mCat.contains('tani') || mCat.contains('ternak') || mId.contains('farm')) {
      return Icons.agriculture_rounded;
    }
    if (cat.contains('sembako') || cat.contains('beras') || cat.contains('kelontong') ||
        mCat.contains('sembako') || mId.contains('shop')) {
      return Icons.storefront_rounded;
    }
    return Icons.restaurant_rounded;
  }

  String _getMenuItemImage(Map<String, dynamic> item) {
    if (item['image'] != null && item['image'].toString().isNotEmpty) {
      return item['image'].toString();
    }
    final name = (item['name'] ?? '').toString().toLowerCase();
    final cat = (item['category'] ?? '').toString().toLowerCase();
    final mCat = (widget.merchant['category'] ?? '').toString().toLowerCase();
    final mId = (widget.merchant['id'] ?? '').toString().toLowerCase();

    // 1. Bahan Bangunan
    if (name.contains('semen')) return 'assets/images/prod_semen.png';
    if (name.contains('cat')) return 'assets/images/prod_cat.png';
    if (name.contains('besi') || name.contains('baja')) return 'assets/images/prod_besi.png';
    if (name.contains('pipa') || name.contains('kuas') || name.contains('pertukangan')) {
      return 'assets/images/prod_traktor.png';
    }

    // 2. Pertanian & Peternakan
    if (name.contains('pupuk') || name.contains('urea') || name.contains('npk')) return 'assets/images/prod_pupuk.png';
    if (name.contains('benih') || name.contains('bibit')) return 'assets/images/prod_benih.png';
    if (name.contains('pakan') || name.contains('konsentrat')) return 'assets/images/prod_pakan.png';
    if (name.contains('sprayer') || name.contains('insektisida')) return 'assets/images/prod_traktor.png';

    // 3. Sembako & Belanja
    if (name.contains('beras')) return 'assets/images/prod_beras.png';
    if (name.contains('minyak')) return 'assets/images/prod_minyak.png';
    if (name.contains('gula')) return 'assets/images/prod_gula.png';
    if (name.contains('telur')) return 'assets/images/prod_telur.png';
    if (name.contains('indomie') || name.contains('mie instan') || name.contains('terigu')) return 'assets/images/prod_indomie.png';
    if (name.contains('cabai') || name.contains('cabe') || name.contains('sayur') || name.contains('bayam')) {
      return 'assets/images/prod_cabai.png';
    }

    // 4. Makanan & Minuman
    if (name.contains('mentai')) return 'assets/images/dish_dimsum_mentai.png';
    if (name.contains('burger')) return 'assets/images/dish_chicken_burger.png';
    if (name.contains('kentang') || name.contains('fries')) return 'assets/images/dish_french_fries.png';
    if (name.contains('seblak')) return 'assets/images/dish_seblak_komplit.png';
    if (name.contains('cimol')) return 'assets/images/dish_cimol_bojot.png';
    if (name.contains('roti') && name.contains('keju')) return 'assets/images/dish_roti_keju.png';
    if (name.contains('roti')) return 'assets/images/dish_roti_cokelat.png';
    if (name.contains('kopi')) return 'assets/images/dish_kopi_susu.png';
    if (name.contains('sate')) return 'assets/images/dish_sate_ayam.png';
    if (name.contains('bakso')) return 'assets/images/dish_bakso_urat.png';
    if (name.contains('mie') || name.contains('pangsit')) return 'assets/images/dish_mie_ayam.png';
    if (name.contains('ayam') || name.contains('geprek') || name.contains('rocket') || name.contains('chicken')) {
      return 'assets/images/dish_rocket_1.png';
    }
    if (name.contains('teh') || name.contains('es') || name.contains('jeruk') || name.contains('minum') || cat.contains('minum')) {
      return 'assets/images/dish_es_teh.png';
    }

    // 5. Merchant Category Fallback (Tanpa Fallback Dimsum di Luar Resto Food)
    if (mId.contains('build') || mCat.contains('bangun')) return 'assets/images/prod_semen.png';
    if (mId.contains('farm') || mCat.contains('tani') || mCat.contains('ternak')) return 'assets/images/prod_pupuk.png';
    if (mId.contains('shop') || mCat.contains('sembako')) return 'assets/images/prod_beras.png';

    return 'assets/images/dish_dimsum_original.png';
  }

  List<Widget> _buildServiceVouchers(BuildContext context, CartProvider cart, bool isDark) {
    final mCat = (widget.merchant['category'] ?? '').toString().toLowerCase();
    final mId = (widget.merchant['id'] ?? '').toString().toLowerCase();

    if (mId.contains('build') || mCat.contains('bangun')) {
      return [
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'PROYEKHEMAT',
          title: 'Diskon material Rp 15.000',
          sub: 'Min. pembelian Rp 50.000',
          discount: 15000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'BANGUNRUMAH',
          title: 'Diskon material Rp 25.000',
          sub: 'Min. pembelian Rp 100.000',
          discount: 25000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'ONGKIRFREE',
          title: 'Gratis ongkir s/d 10rb',
          sub: 'Min. pembelian Rp 50.000',
          discount: 10000,
          isFood: false,
          isDark: isDark,
        ),
      ];
    } else if (mId.contains('farm') || mCat.contains('tani') || mCat.contains('ternak')) {
      return [
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'SUBSIDITANI',
          title: 'Diskon tani Rp 10.000',
          sub: 'Min. pembelian Rp 30.000',
          discount: 10000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'PETANISUKSES',
          title: 'Diskon tani Rp 15.000',
          sub: 'Min. pembelian Rp 50.000',
          discount: 15000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'ONGKIRFREE',
          title: 'Gratis ongkir s/d 7rb',
          sub: 'Min. pembelian Rp 25.000',
          discount: 7000,
          isFood: false,
          isDark: isDark,
        ),
      ];
    } else if (mId.contains('shop') || mCat.contains('sembako') || mCat.contains('kelontong')) {
      return [
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'BELANJAHEMAT',
          title: 'Diskon belanja Rp 8.000',
          sub: 'Min. pembelian Rp 25.000',
          discount: 8000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'SEMBAKOMURAH',
          title: 'Diskon sembako Rp 10.000',
          sub: 'Min. pembelian Rp 40.000',
          discount: 10000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'ONGKIRFREE',
          title: 'Gratis ongkir s/d 7rb',
          sub: 'Min. pembelian Rp 20.000',
          discount: 7000,
          isFood: false,
          isDark: isDark,
        ),
      ];
    } else {
      return [
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'GAGEHEMAT',
          title: 'Diskon makanan Rp 8.000',
          sub: 'Min. pembelian Rp 15.000',
          discount: 8000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'KULINER10',
          title: 'Diskon makanan Rp 10.000',
          sub: 'Min. pembelian Rp 30.000',
          discount: 10000,
          isFood: true,
          isDark: isDark,
        ),
        _buildInteractiveVoucherCard(
          context: context,
          cart: cart,
          code: 'ONGKIRFREE',
          title: 'Gratis ongkir s/d 7rb',
          sub: 'Min. pembelian Rp 20.000',
          discount: 7000,
          isFood: false,
          isDark: isDark,
        ),
      ];
    }
  }"""

assert old_func in text, "old_func not found"
text = text.replace(old_func, new_func)

# 2. Update Row of vouchers
old_row = """                      child: Row(
                        children: [
                          _buildInteractiveVoucherCard(
                            context: context,
                            cart: cart,
                            code: 'GAGEHEMAT',
                            title: 'Diskon makanan Rp 8.000',
                            sub: 'Min. pembelian Rp 15.000',
                            discount: 8000,
                            isFood: true,
                            isDark: isDark,
                          ),
                          _buildInteractiveVoucherCard(
                            context: context,
                            cart: cart,
                            code: 'KULINER10',
                            title: 'Diskon makanan Rp 10.000',
                            sub: 'Min. pembelian Rp 30.000',
                            discount: 10000,
                            isFood: true,
                            isDark: isDark,
                          ),
                          _buildInteractiveVoucherCard(
                            context: context,
                            cart: cart,
                            code: 'ONGKIRFREE',
                            title: 'Gratis ongkir s/d 7rb',
                            sub: 'Min. pembelian Rp 20.000',
                            discount: 7000,
                            isFood: false,
                            isDark: isDark,
                          ),
                        ],
                      ),"""

new_row = """                      child: Row(
                        children: _buildServiceVouchers(context, cart, isDark),
                      ),"""

assert old_row in text, "old_row not found"
text = text.replace(old_row, new_row)

# 3. Update errorBuilder icons to use _getFallbackIcon
old_err1 = """                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: GageTheme.primaryLight,
                                              child: const Icon(Icons.fastfood, color: GageTheme.primary),
                                            ),"""

new_err1 = """                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: GageTheme.primaryLight,
                                              child: Icon(_getFallbackIcon(item['category']), color: GageTheme.primary),
                                            ),"""

assert old_err1 in text, "old_err1 not found"
text = text.replace(old_err1, new_err1)

old_err2 = """                            errorBuilder: (context, error, stackTrace) => Container(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                              child: const Icon(Icons.fastfood, size: 48, color: GageTheme.primary),
                            ),"""

new_err2 = """                            errorBuilder: (context, error, stackTrace) => Container(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                              child: Icon(_getFallbackIcon(item['category']), size: 48, color: GageTheme.primary),
                            ),"""

assert old_err2 in text, "old_err2 not found"
text = text.replace(old_err2, new_err2)

with open(p, 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: Updated resto_detail_screen.dart!")
