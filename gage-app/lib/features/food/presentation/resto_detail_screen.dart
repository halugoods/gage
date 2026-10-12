import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';

class RestoDetailScreen extends StatefulWidget {
  final Map<String, dynamic> merchant;

  const RestoDetailScreen({
    super.key,
    required this.merchant,
  });

  @override
  State<RestoDetailScreen> createState() => _RestoDetailScreenState();
}

class _RestoDetailScreenState extends State<RestoDetailScreen> {
  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    final merchantId = widget.merchant['id'] ?? 'm-dimsum-sewu';
    final items = await GageApiClient.getMerchantMenu(merchantId);
    if (!mounted) return;
    setState(() {
      _menuItems = items;
      _isLoading = false;
    });
  }

  List<String> get _categories {
    final cats = {'Semua'};
    for (var m in _menuItems) {
      final c = m['category'];
      if (c != null && c.toString().isNotEmpty) {
        cats.add(c.toString());
      }
    }
    return cats.toList();
  }

  List<Map<String, dynamic>> get _filteredMenus {
    if (_selectedCategory == 'Semua') return _menuItems;
    return _menuItems.where((m) => m['category'] == _selectedCategory).toList();
  }

  Future<void> _openWhatsApp() async {
    final phone = widget.merchant['phone_wa'] ?? '081234567890';
    final uri = Uri.parse('https://wa.me/$phone?text=Halo%20${Uri.encodeComponent(widget.merchant['name'] ?? 'Resto')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getMenuItemImage(Map<String, dynamic> item) {
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
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final name = widget.merchant['name'] ?? 'Resto Mitra';
    final category = widget.merchant['category'] ?? 'Kuliner';
    final address = widget.merchant['address'] ?? 'Kecamatan';
    final id = widget.merchant['id'] ?? '';
    final String imageAsset = widget.merchant['image'] ?? 'assets/images/resto_dimsum_sewu.png';

    final isSameMerchantInCart = cart.merchantId == id && cart.items.isNotEmpty;

    return Scaffold(
      backgroundColor: GageTheme.background,
      body: CustomScrollView(
        slivers: [
          // Sliver App Bar dengan Banner Resto
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            backgroundColor: GageTheme.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: GageTheme.primaryLight),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black38, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tautan $name siap dibagikan!')),
                  );
                },
              ),
            ],
          ),

          // Detail Resto Card
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: GageTheme.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(color: GageTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'BUKA',
                          style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: GageTheme.accentGreen,
                          side: const BorderSide(color: GageTheme.accentGreen),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _openWhatsApp,
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: const Text('Chat WA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: GageTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(address, style: const TextStyle(color: GageTheme.textSecondary, fontSize: 12)),
                      ),
                      const Text('• 1.8 km (Ongkir Rp 4.000)', style: TextStyle(color: GageTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.local_offer_rounded, color: GageTheme.primary, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Voucher Resto Tersedia',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: GageTheme.textPrimary),
                      ),
                      const Spacer(),
                      Text(
                        'Bisa digabung saat bayar!',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Voucher 1: Diskon Menu
                  _buildVoucherCard(
                    context: context,
                    isFood: true,
                    code: 'DISKON50',
                    title: 'Diskon 50% Menu Makanan',
                    subtitle: 'Maks. diskon Rp 15.000',
                    isApplied: cart.foodPromoCode == 'DISKON50',
                    onToggle: () {
                      if (cart.foodPromoCode == 'DISKON50') {
                        cart.removeFoodPromo();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Voucher Diskon 50% dilepas.')),
                        );
                      } else {
                        cart.setPromoCode('DISKON50');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✓ Voucher Diskon 50% berhasil dipasang!')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  // Voucher 2: Subsidi Ongkir
                  _buildVoucherCard(
                    context: context,
                    isFood: false,
                    code: 'ONGKIRGRATIS',
                    title: 'Diskon Ongkir s.d. Rp 7.000',
                    subtitle: 'Pengantaran khusus Kec. Pracimantoro',
                    isApplied: cart.deliveryPromoCode == 'ONGKIRGRATIS',
                    onToggle: () {
                      if (cart.deliveryPromoCode == 'ONGKIRGRATIS') {
                        cart.removeDeliveryPromo();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Voucher Subsidi Ongkir dilepas.')),
                        );
                      } else {
                        cart.setDeliveryPromo('ONGKIRGRATIS', 7000);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✓ Voucher Diskon Ongkir berhasil dipasang!')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Tab Kategori Menu
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(cat),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : GageTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        selectedColor: GageTheme.primary,
                        backgroundColor: Colors.grey.shade100,
                        checkmarkColor: Colors.white,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Daftar Menu Makanan
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: GageTheme.primary)),
            )
          else if (_filteredMenus.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('Belum ada menu di kategori ini.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _filteredMenus[index];
                    final price = (item['gage_price'] ?? item['offline_price'] ?? 0) as int;
                    final isAvailable = (item['is_available'] ?? 1) == 1;
                    final menuId = (item['id'] ?? 'item-$index').toString();
                    final cartItem = cart.items.where((i) => i.menuId == menuId).firstOrNull;
                    final inCartQty = cartItem?.quantity ?? 0;

                    final menuImage = _getMenuItemImage(item);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kiri: Deskripsi & Harga Menu
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                  ),
                                  const SizedBox(height: 4),
                                  if (item['description'] != null && item['description'].toString().isNotEmpty)
                                    Text(
                                      item['description'],
                                      style: const TextStyle(color: GageTheme.textSecondary, fontSize: 11.5),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currencyFormatter.format(price),
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Kanan: Foto Makanan + Inline Stepper
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 78,
                                    height: 78,
                                    child: Image.asset(
                                      menuImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: GageTheme.primaryLight,
                                        child: const Icon(Icons.fastfood, color: GageTheme.primary),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                inCartQty > 0
                                    ? Container(
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: GageTheme.primary, width: 1.5),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () => cart.updateQuantity(menuId, -1),
                                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Icon(Icons.remove, color: GageTheme.primary, size: 16),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: Text(
                                                '$inCartQty',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GageTheme.primary),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => cart.updateQuantity(menuId, 1),
                                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Icon(Icons.add, color: GageTheme.primary, size: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : SizedBox(
                                        height: 32,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isAvailable ? GageTheme.primary : Colors.grey,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 14),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          onPressed: isAvailable
                                              ? () {
                                                  cart.addItem(
                                                    CartItemModel(
                                                      menuId: menuId,
                                                      name: item['name'] ?? '',
                                                      price: price,
                                                      quantity: 1,
                                                      merchantId: widget.merchant['id'] ?? 'm-dimsum-sewu',
                                                      merchantName: widget.merchant['name'] ?? 'Resto Mitra',
                                                      category: item['category'] ?? 'Makanan',
                                                      imageUrl: menuImage,
                                                    ),
                                                  );
                                                  if (cart.deliveryPromoCode == null) {
                                                    cart.setDeliveryPromo('ONGKIRGRATIS', 4000);
                                                  }
                                                  if (cart.merchantCount > 1) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        backgroundColor: GageTheme.accentGreen,
                                                        content: Text('Pesanan dari "${widget.merchant['name'] ?? 'Toko'}" digabung ke keranjang.'),
                                                        duration: const Duration(seconds: 1),
                                                      ),
                                                    );
                                                  }
                                                }
                                              : null,
                                          child: Text(
                                            isAvailable ? '+ Tambah' : 'Habis',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _filteredMenus.length,
                ),
              ),
            ),

          // Padding ekstra agar tidak tertutup sticky cart bar
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),

      // Sticky Bottom Cart Bar jika ada pesanan di keranjang
      bottomNavigationBar: isSameMerchantInCart
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cart.totalItemCount} Menu di Keranjang',
                          style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currencyFormatter.format(cart.subtotal),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: GageTheme.primary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const CheckoutScreen()),
                        );
                      },
                      child: const Row(
                        children: [
                          Text('Lihat Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildVoucherCard({
    required BuildContext context,
    required bool isFood,
    required String code,
    required String title,
    required String subtitle,
    required bool isApplied,
    required VoidCallback onToggle,
  }) {
    final themeColor = isFood ? GageTheme.primary : GageTheme.accentGreen;
    final bgTint = isFood ? const Color(0xFFFFF5F5) : const Color(0xFFF0FDF4);
    final borderTint = isFood ? const Color(0xFFFFCDD2) : const Color(0xFFBBF7D0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isApplied ? themeColor : borderTint,
          width: isApplied ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderTint),
            ),
            child: Icon(
              isFood ? Icons.local_offer_rounded : Icons.motorcycle_rounded,
              color: themeColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        code,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: themeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isApplied ? themeColor : Colors.white,
                foregroundColor: isApplied ? Colors.white : themeColor,
                side: BorderSide(color: themeColor, width: 1.2),
                elevation: isApplied ? 1 : 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: onToggle,
              child: Text(
                isApplied ? '✓ Dipakai' : 'Pakai',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
