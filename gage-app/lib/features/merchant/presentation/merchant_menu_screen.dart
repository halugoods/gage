import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_bottom_nav_bar.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

/// Screen Katalog Menu Mitra Merchant - Tab 1
/// Mengatur ketersediaan stok 1-tap (Tersedia / Habis) & sinkronisasi harga ke Cloudflare D1.
class MerchantMenuScreen extends StatefulWidget {
  const MerchantMenuScreen({super.key});

  @override
  State<MerchantMenuScreen> createState() => _MerchantMenuScreenState();
}

class _MerchantMenuScreenState extends State<MerchantMenuScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _menuCatalog = [];
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final List<String> _categories = [
    'Semua',
    'Dimsum Kukus',
    'Dimsum Goreng',
    'Minuman',
    'Paket Hemat',
  ];

  @override
  void initState() {
    super.initState();
    _fetchMenuCatalog();
  }

  Future<void> _fetchMenuCatalog() async {
    setState(() => _isLoading = true);
    final menus = await GageApiClient.getMerchantMenu('m-dimsum-sewu');
    if (!mounted) return;
    setState(() {
      _menuCatalog = menus;
      _isLoading = false;
    });
  }

  Future<void> _toggleStock(Map<String, dynamic> item) async {
    HapticFeedback.lightImpact();
    final itemId = item['id']?.toString() ?? '';
    final current = (item['is_available'] == 1 || item['is_available'] == true);
    final next = !current;
    setState(() {
      item['is_available'] = next ? 1 : 0;
    });
    await GageApiClient.toggleMerchantStock(itemId, next);
  }

  List<Map<String, dynamic>> get _filteredMenus {
    return _menuCatalog.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final cat = (item['category'] ?? '').toString();
      final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == 'Semua' || cat.toLowerCase().contains(_selectedCategory.toLowerCase());
      return matchesSearch && matchesCat;
    }).toList();
  }

  void _showAddMenuDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String category = 'Dimsum Kukus';
    int offlinePrice = 0;
    int suggestedGage = 0;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tambah Menu Baru Dapur',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Menu otomatis disinkronkan ke Cloudflare D1 Dimsum Sewu & aplikasi pelanggan.',
                  style: TextStyle(fontSize: 12, color: GageTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama Menu',
                    hintText: 'Misal: Dimsum Mozzarella Keju Lumer',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Singkat',
                    hintText: 'Bahan, porsi isi berapa biji, atau level kepedasan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: _categories
                            .where((c) => c != 'Semua')
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => category = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Harga Warung',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (val) {
                          final num = int.tryParse(val) ?? 0;
                          setModalState(() {
                            offlinePrice = num;
                            suggestedGage = num > 0 ? ((num / 0.9) / 1000).ceil() * 1000 : 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (suggestedGage > 0) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GageTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GageTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Harga Aplikasi (Potong 10% MDR):',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Penerimaan bersih Anda tetap sama seperti di warung fisik.',
                              style: TextStyle(fontSize: 10, color: GageTheme.textSecondary),
                            ),
                          ],
                        ),
                        Text(
                          currencyFormatter.format(suggestedGage),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: GageTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(ctx);
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty || offlinePrice <= 0) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Nama menu dan harga warung wajib diisi.')),
                              );
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            final res = await GageApiClient.createMerchantMenu(
                              merchantId: 'm-dimsum-sewu',
                              name: name,
                              description: descCtrl.text.trim(),
                              category: category,
                              offlinePrice: offlinePrice,
                              gagePrice: suggestedGage,
                            );
                            if (!mounted) return;
                            navigator.pop();
                            if (res != null) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Menu "$name" berhasil ditambahkan ke Cloudflare D1.'),
                                  backgroundColor: GageTheme.accentGreen,
                                ),
                              );
                              _fetchMenuCatalog();
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Gagal menambahkan menu ke server.')),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Simpan Menu ke D1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Text(
          'Katalog & Stok Menu',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Menu',
            onPressed: _fetchMenuCatalog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Search Bar & Tambah Menu Button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Cari nama menu dimsum...',
                          hintStyle: TextStyle(fontSize: 12.5, color: GageTheme.textSecondary),
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: GageTheme.textSecondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text('Menu Baru', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: _showAddMenuDialog,
                  ),
                ],
              ),
            ),

            // Category Chips Bar
            Container(
              height: 46,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final cat = _categories[idx];
                  final isSelected = _selectedCategory == cat;

                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? GageTheme.primary
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Content List
            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: 5,
                      itemBuilder: (ctx, idx) => const GageSkeletonMerchantMenuCard(),
                    )
                  : _filteredMenus.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.restaurant_menu_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('Menu Tidak Ditemukan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              const Text('Coba ubah kata kunci pencarian atau kategori.', style: TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchMenuCatalog,
                          color: GageTheme.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: _filteredMenus.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (ctx, idx) => _buildMenuItemCard(_filteredMenus[idx], isDark),
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MerchantBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item, bool isDark) {
    final isAvailable = (item['is_available'] == 1 || item['is_available'] == true);
    final offlinePrice = (item['offline_price'] ?? item['price'] ?? 0) as int;
    final onlinePrice = (item['gage_price'] ?? item['price'] ?? 0) as int;
    final desc = (item['description'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Foto Thumbnail
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: GageTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item['image'] != null && item['image'].toString().isNotEmpty
                  ? Image.asset(
                      item['image'].toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.fastfood_rounded,
                        color: GageTheme.primary,
                        size: 26,
                      ),
                    )
                  : const Icon(
                      Icons.fastfood_rounded,
                      color: GageTheme.primary,
                      size: 26,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Detail Teks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      currencyFormatter.format(onlinePrice),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: GageTheme.primary,
                      ),
                    ),
                    if (offlinePrice > 0 && offlinePrice != onlinePrice) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Warung: ${currencyFormatter.format(offlinePrice)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAvailable ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isAvailable ? 'Tersedia' : 'Habis',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? const Color(0xFF16A34A) : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Switch Ketersediaan Stok 1-tap
          Switch(
            value: isAvailable,
            activeThumbColor: GageTheme.accentGreen,
            onChanged: (_) => _toggleStock(item),
          ),
        ],
      ),
    );
  }
}
