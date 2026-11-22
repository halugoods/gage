import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/affiliate_commission_service.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

/// Screen Manajemen Katalog Menu & Stok Mitra Merchant
/// Unit: GAGE Pracimantoro (Halu Goods Indonesia)
/// Mendukung:
/// - Ketersediaan stok 1-tap (Tersedia / Habis)
/// - Harga Coret Promo (itemPromoPrices) dengan validasi MDR 10% & soft warning margin
/// - Pengaturan Urutan Kategori Katalog (categoryOrder Reorderable)
/// - Kalkulator Markup Afiliasi Dinamis (0% - 20%) via AffiliateCommissionService
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
  MerchantStorefrontData? _storefrontData;

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final List<String> _defaultFallbackCategories = [
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
    final merchantId = MerchantStorefrontService.defaultPortalMerchantId;

    try {
      final storefront = await MerchantStorefrontService.loadStorefront(merchantId);
      final menus = await GageApiClient.getMerchantMenu(merchantId);

      if (!mounted) return;
      setState(() {
        _storefrontData = storefront;
        _menuCatalog = menus;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// Kategori katalog yang diurutkan secara dinamis mengikuti kontrak categoryOrder
  List<String> get _categories {
    final categoriesSet = <String>{'Semua'};

    // 1. Prioritaskan urutan categoryOrder yang tersimpan
    if (_storefrontData?.categoryOrder != null && _storefrontData!.categoryOrder!.isNotEmpty) {
      for (final cat in _storefrontData!.categoryOrder!) {
        final trimmed = cat.trim();
        if (trimmed.isNotEmpty && trimmed != 'Semua') {
          categoriesSet.add(trimmed);
        }
      }
    }

    // 2. Tambahkan kategori aktif dari menu yang belum ada di categoryOrder
    for (final item in _menuCatalog) {
      final c = (item['category'] ?? '').toString().trim();
      if (c.isNotEmpty && c != 'Semua') {
        categoriesSet.add(c);
      }
    }

    // 3. Fallback jika katalog masih kosong
    if (categoriesSet.length == 1) {
      categoriesSet.addAll(_defaultFallbackCategories.skip(1));
    }

    return categoriesSet.toList();
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

  int _parsePrice(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^0-9\-]'), '');
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REORDER KATEGORI KATALOG (categoryOrder)
  // ─────────────────────────────────────────────────────────────────────────

  void _showCategoryReorderSheet() {
    HapticFeedback.selectionClick();
    final activeCategories = _categories.where((c) => c != 'Semua').toList();
    if (activeCategories.isEmpty) return;

    final reorderedList = List<String>.from(activeCategories);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Atur Urutan Kategori',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Tahan dan geser ikon ≡ untuk mengubah urutan kategori di aplikasi pelanggan.',
                style: TextStyle(fontSize: 12, color: GageTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: ReorderableListView(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  // ignore: deprecated_member_use
                  onReorder: (oldIndex, newIndex) {
                    setSheetState(() {
                      if (oldIndex < newIndex) newIndex -= 1;
                      final item = reorderedList.removeAt(oldIndex);
                      reorderedList.insert(newIndex, item);
                    });
                    HapticFeedback.selectionClick();
                  },
                  children: [
                    for (int i = 0; i < reorderedList.length; i++)
                      Container(
                        key: ValueKey(reorderedList[i]),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${i + 1}.',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GageTheme.textSecondary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                reorderedList[i],
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                            ),
                            const Icon(Icons.drag_handle_rounded, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final navigator = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    final merchantId = MerchantStorefrontService.defaultPortalMerchantId;

                    final currentStorefront = _storefrontData ??
                        await MerchantStorefrontService.loadStorefront(merchantId) ??
                        MerchantStorefrontData(merchantId: merchantId);
                    final updated = currentStorefront.copyWith(categoryOrder: reorderedList);
                    await MerchantStorefrontService.saveStorefront(updated);

                    if (!mounted) return;
                    setState(() {
                      _storefrontData = updated;
                    });
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Urutan kategori berhasil disimpan dan disinkronkan.')),
                    );
                  },
                  child: const Text(
                    'Simpan Urutan Kategori',
                    style: TextStyle(fontSize: 13.5, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ATUR PROMO HARGA CORET (itemPromoPrices & VALIDASI MARGIN MDR 10%)
  // ─────────────────────────────────────────────────────────────────────────

  void _showSetPromoDialog(Map<String, dynamic> item) {
    HapticFeedback.selectionClick();
    final itemId = item['id']?.toString() ?? '';
    final itemName = item['name']?.toString() ?? 'Menu';
    final offlinePrice = _parsePrice(item['offline_price'] ?? item['price']);
    final gagePrice = _parsePrice(item['gage_price'] ?? item['price']);

    final currentPromoOverride = _storefrontData?.itemPromoPrices?[itemId] ?? -1;
    final currentPromo = currentPromoOverride > 0
        ? currentPromoOverride
        : (item['promo_price'] != null ? _parsePrice(item['promo_price']) : 0);

    final promoCtrl = TextEditingController(text: currentPromo > 0 ? '$currentPromo' : '');
    int promoInput = currentPromo;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final netPayout = promoInput > 0 ? (promoInput * 0.90).round() : 0;
          final isBelowOffline = promoInput > 0 && offlinePrice > 0 && netPayout < offlinePrice;
          final isInvalid = promoInput > 0 && (promoInput >= gagePrice || promoInput <= 0);
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                  Text(
                    'Atur Promo Harga Coret: $itemName',
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Harga aplikasi normal: ${currencyFormatter.format(gagePrice)} | Harga warung fisik: ${currencyFormatter.format(offlinePrice)}',
                    style: const TextStyle(fontSize: 11.5, color: GageTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Harga Promo Baru (Harga Coret)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: promoCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Contoh: ${gagePrice > 2000 ? gagePrice - 2000 : gagePrice}',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                      ),
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: GageTheme.primary),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: GageTheme.primary,
                          width: 1.8,
                        ),
                      ),
                      helperText: 'Wajib lebih rendah dari harga normal (${currencyFormatter.format(gagePrice)})',
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        promoInput = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      });
                    },
                  ),
                  if (promoInput > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isBelowOffline
                            ? const Color(0xFFFEF3C7)
                            : (isInvalid ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isBelowOffline
                              ? const Color(0xFFF59E0B)
                              : (isInvalid ? const Color(0xFFEF4444) : const Color(0xFF22C55E)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Penerimaan Bersih Kasir (MDR 10%):', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              Text(
                                currencyFormatter.format(netPayout),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: isBelowOffline ? const Color(0xFFB45309) : (isInvalid ? Colors.red : const Color(0xFF15803D)),
                                ),
                              ),
                            ],
                          ),
                          if (isInvalid) ...[
                            const SizedBox(height: 4),
                            Text(
                              promoInput >= gagePrice
                                  ? '❌ Harga promo tidak boleh sama atau lebih tinggi dari harga normal (${currencyFormatter.format(gagePrice)}).'
                                  : '❌ Harga promo harus lebih besar dari 0.',
                              style: const TextStyle(fontSize: 10.5, color: Colors.red, fontWeight: FontWeight.w600),
                            ),
                          ] else if (isBelowOffline) ...[
                            const SizedBox(height: 4),
                            Text(
                              '⚠️ Peringatan Margin: Penerimaan bersih (${currencyFormatter.format(netPayout)}) lebih rendah dari harga warung fisik (${currencyFormatter.format(offlinePrice)}). Cocok untuk strategi bakar margin/umpan traffic.',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                            ),
                          ] else ...[
                            const SizedBox(height: 4),
                            const Text(
                              '✓ Margin aman! Penerimaan bersih warung tetap terjaga di atas atau setara harga offline.',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (currentPromo > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setModalState(() => isSaving = true);
                                    final messenger = ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(ctx);
                                    final merchantId = MerchantStorefrontService.defaultPortalMerchantId;

                                    final current = _storefrontData ??
                                        await MerchantStorefrontService.loadStorefront(merchantId) ??
                                        MerchantStorefrontData(merchantId: merchantId);
                                    final promos = Map<String, int>.from(current.itemPromoPrices ?? {});
                                    promos[itemId] = 0; // 0 menonaktifkan promo secara eksplisit

                                    final updated = current.copyWith(itemPromoPrices: promos);
                                    await MerchantStorefrontService.saveStorefront(updated);

                                    if (!mounted) return;
                                    setState(() {
                                      _storefrontData = updated;
                                      item['promo_price'] = null;
                                    });
                                    navigator.pop();
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Harga promo dinonaktifkan (kembali ke harga normal).')),
                                    );
                                  },
                            child: const Text('Hapus Promo', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: (isSaving || promoInput <= 0 || isInvalid)
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final navigator = Navigator.of(ctx);

                                  // Jika soft warning (bakar margin), tampilkan dialog konfirmasi
                                  if (isBelowOffline) {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text('Konfirmasi Bakar Margin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        content: Text(
                                          'Penerimaan bersih Anda (${currencyFormatter.format(netPayout)}) berada di bawah harga warung fisik (${currencyFormatter.format(offlinePrice)}).\n\nTetap terapkan harga promo ini sebagai promo diskon pembeli?',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: GageTheme.primary),
                                            onPressed: () => Navigator.pop(c, true),
                                            child: const Text('Tetap Terapkan', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm != true || !mounted) return;
                                  }

                                  setModalState(() => isSaving = true);
                                  final merchantId = MerchantStorefrontService.defaultPortalMerchantId;

                                  final current = _storefrontData ??
                                      await MerchantStorefrontService.loadStorefront(merchantId) ??
                                      MerchantStorefrontData(merchantId: merchantId);
                                  final promos = Map<String, int>.from(current.itemPromoPrices ?? {});
                                  promos[itemId] = promoInput;

                                  final updated = current.copyWith(itemPromoPrices: promos);
                                  await MerchantStorefrontService.saveStorefront(updated);

                                  if (!mounted) return;
                                  setState(() {
                                    _storefrontData = updated;
                                    item['promo_price'] = promoInput;
                                  });
                                  navigator.pop();
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Promo harga coret Rp ${currencyFormatter.format(promoInput)} berhasil diterapkan.')),
                                  );
                                },
                          child: const Text('Simpan Promo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAMBAH MENU BARU + IMAGE PICKER + KALKULATOR HARGA & MARGIN LANGSUNG
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMenuItemImage(dynamic imageVal, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    final img = imageVal?.toString() ?? '';
    if (img.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: GageTheme.primaryLight,
        child: const Icon(Icons.fastfood_rounded, color: GageTheme.primary, size: 26),
      );
    }
    if (img.startsWith('assets/')) {
      return Image.asset(
        img,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => Container(
          width: width,
          height: height,
          color: GageTheme.primaryLight,
          child: const Icon(Icons.fastfood_rounded, color: GageTheme.primary, size: 26),
        ),
      );
    }
    if (img.startsWith('http://') || img.startsWith('https://')) {
      return Image.network(
        img,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => Container(
          width: width,
          height: height,
          color: GageTheme.primaryLight,
          child: const Icon(Icons.fastfood_rounded, color: GageTheme.primary, size: 26),
        ),
      );
    }
    final file = File(img);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => Container(
          width: width,
          height: height,
          color: GageTheme.primaryLight,
          child: const Icon(Icons.fastfood_rounded, color: GageTheme.primary, size: 26),
        ),
      );
    }
    return Image.asset(
      'assets/images/dish_dimsum_original.png',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => Container(
        width: width,
        height: height,
        color: GageTheme.primaryLight,
        child: const Icon(Icons.fastfood_rounded, color: GageTheme.primary, size: 26),
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, bool isDark, {bool isDeduction = false, bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlight ? 12 : 11,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? Colors.white60 : GageTheme.textSecondary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 13.5 : 11,
            fontWeight: isHighlight ? FontWeight.w900 : (isDeduction ? FontWeight.w600 : FontWeight.bold),
            color: isHighlight
                ? GageTheme.primary
                : (isDeduction ? Colors.red.shade600 : (isDark ? Colors.white : const Color(0xFF0F172A))),
          ),
        ),
      ],
    );
  }

  void _showAddMenuDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final offlinePriceCtrl = TextEditingController();
    final gagePriceCtrl = TextEditingController();
    String category = _categories.firstWhere((c) => c != 'Semua', orElse: () => 'Dimsum Kukus');
    String? selectedImagePath;
    int offlinePrice = 0;
    int gagePrice = 0;
    double affiliateRate = 0.10; // Default 10% rekomendasi (Maks 20%)
    bool isAutoPricing = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          Future<void> pickPhoto(ImageSource source) async {
            try {
              HapticFeedback.selectionClick();
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: source, imageQuality: 85);
              if (picked != null) {
                setModalState(() {
                  selectedImagePath = picked.path;
                });
              }
            } catch (_) {}
          }

          return Padding(
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
                    'Lengkapi foto, nama, serta kalkulator harga jual transparan untuk aplikasi pelanggan.',
                    style: TextStyle(fontSize: 12, color: GageTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // FOTO MENU & IMAGE PICKER
                  Text(
                    'Foto Menu Makanan / Minuman',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (selectedImagePath != null && selectedImagePath!.isNotEmpty)
                    Container(
                      height: 130,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _buildMenuItemImage(selectedImagePath, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Material(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      pickPhoto(ImageSource.gallery);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(7),
                                      child: Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Material(
                                  color: Colors.red.withValues(alpha: 0.85),
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setModalState(() {
                                        selectedImagePath = null;
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(7),
                                      child: Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 12),
                                  SizedBox(width: 4),
                                  Text('Foto Terpasang', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.add_a_photo_rounded, size: 28, color: GageTheme.primary),
                          const SizedBox(height: 6),
                          Text(
                            'Upload Foto Menu Baru',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ambil langsung via kamera atau upload dari galeri perangkat',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : GageTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: const StadiumBorder(),
                                  side: const BorderSide(color: GageTheme.primary),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                onPressed: () => pickPhoto(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_rounded, size: 16, color: GageTheme.primary),
                                label: const Text('Kamera', style: TextStyle(fontSize: 12, color: GageTheme.primary, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GageTheme.primary,
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                onPressed: () => pickPhoto(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_rounded, size: 16, color: Colors.white),
                                label: const Text('Galeri HP', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          'Preset cepat: ',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : GageTheme.textSecondary),
                        ),
                        ...[
                          {'label': 'Dimsum Ori', 'img': 'assets/images/dish_dimsum_original.png'},
                          {'label': 'Dimsum Mentai', 'img': 'assets/images/dish_dimsum_mentai.png'},
                          {'label': 'Resto Kios', 'img': 'assets/images/resto_dimsum_sewu.png'},
                        ].map((p) {
                          final isSel = (selectedImagePath == p['img']);
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(p['label']!, style: TextStyle(fontSize: 10.5, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                              selected: isSel,
                              selectedColor: GageTheme.primary.withValues(alpha: 0.15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setModalState(() => selectedImagePath = p['img']!);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  Text(
                    'Nama Menu',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Misal: Dimsum Mozzarella Keju Lumer',
                      hintStyle: TextStyle(fontSize: 12.5, color: isDark ? Colors.white38 : Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.restaurant_menu_rounded, size: 18, color: GageTheme.primary),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: GageTheme.primary, width: 1.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Deskripsi Singkat',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Bahan, porsi isi berapa biji, atau level kepedasan',
                      hintStyle: TextStyle(fontSize: 12.5, color: isDark ? Colors.white38 : Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.description_outlined, size: 18, color: GageTheme.primary),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: GageTheme.primary, width: 1.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kategori Menu',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: GageTheme.primary, width: 1.8),
                      ),
                    ),
                    items: _categories
                        .where((c) => c != 'Semua')
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12.5))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),

                  // ─── KALKULATOR HARGA & MARGIN LANGSUNG ───
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calculate_rounded, size: 18, color: GageTheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Kalkulator Harga & Margin Dapur',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (!isAutoPricing)
                              InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    isAutoPricing = true;
                                    gagePrice = AffiliateCommissionService.calculateRecommendedOnlinePrice(
                                      offlinePrice,
                                      platformRate: 0.10,
                                      affiliateRate: affiliateRate,
                                    );
                                    gagePriceCtrl.text = gagePrice > 0 ? gagePrice.toString() : '';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: GageTheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_mode_rounded, size: 12, color: GageTheme.primary),
                                      SizedBox(width: 4),
                                      Text('Auto Anti-Rugi', style: TextStyle(fontSize: 10, color: GageTheme.primary, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Harga Warung (Offline)',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: offlinePriceCtrl,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                    decoration: InputDecoration(
                                      prefixText: 'Rp ',
                                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: GageTheme.primary),
                                      filled: true,
                                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: GageTheme.primary, width: 1.8),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final numVal = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                      setModalState(() {
                                        offlinePrice = numVal;
                                        if (isAutoPricing) {
                                          gagePrice = AffiliateCommissionService.calculateRecommendedOnlinePrice(
                                            offlinePrice,
                                            platformRate: 0.10,
                                            affiliateRate: affiliateRate,
                                          );
                                          gagePriceCtrl.text = gagePrice > 0 ? gagePrice.toString() : '';
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Harga Jual di GAGE',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: gagePriceCtrl,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                    decoration: InputDecoration(
                                      prefixText: 'Rp ',
                                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                      filled: true,
                                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: GageTheme.primary, width: 1.8),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final numVal = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                      setModalState(() {
                                        gagePrice = numVal;
                                        isAutoPricing = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Alokasi Komisi Afiliasi / Kreator Video (Maks 20%):',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [0.0, 0.05, 0.10, 0.15, 0.20].map((rate) {
                              final isSel = (affiliateRate == rate);
                              final label = rate == 0.0 ? '0%' : (rate == 0.10 ? '10% (Rekomendasi)' : '${(rate * 100).toInt()}%');
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                                  selected: isSel,
                                  selectedColor: GageTheme.primary.withValues(alpha: 0.15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                  onSelected: (_) {
                                    HapticFeedback.selectionClick();
                                    setModalState(() {
                                      affiliateRate = rate;
                                      if (isAutoPricing) {
                                        gagePrice = AffiliateCommissionService.calculateRecommendedOnlinePrice(
                                          offlinePrice,
                                          platformRate: 0.10,
                                          affiliateRate: affiliateRate,
                                        );
                                        gagePriceCtrl.text = gagePrice > 0 ? gagePrice.toString() : '';
                                      }
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // Live Breakdown Table
                        if (gagePrice > 0) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                            ),
                            child: Column(
                              children: [
                                _buildCalcRow('Harga Jual ke Pelanggan', currencyFormatter.format(gagePrice), isDark),
                                const SizedBox(height: 4),
                                _buildCalcRow('MDR Platform GAGE (10%)', '- ${currencyFormatter.format((gagePrice * 0.10).round())}', isDark, isDeduction: true),
                                const SizedBox(height: 4),
                                _buildCalcRow('Komisi Kreator (${(affiliateRate * 100).toInt()}%)', '- ${currencyFormatter.format((gagePrice * affiliateRate).round())}', isDark, isDeduction: true),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  child: Divider(height: 1),
                                ),
                                _buildCalcRow(
                                  'Estimasi Pencairan Bersih',
                                  currencyFormatter.format(gagePrice - (gagePrice * 0.10).round() - (gagePrice * affiliateRate).round()),
                                  isDark,
                                  isHighlight: true,
                                ),
                                const SizedBox(height: 6),
                                Builder(builder: (context) {
                                  final netPayout = gagePrice - (gagePrice * 0.10).round() - (gagePrice * affiliateRate).round();
                                  final margin = netPayout - offlinePrice;
                                  final isSafe = margin >= 0;
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSafe ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: isSafe ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)),
                                    ),
                                    child: Text(
                                      isSafe
                                          ? '✓ Margin Bersih Aman: +${currencyFormatter.format(margin)} di atas modal warung (Bebas Rugi!)'
                                          : '⚠ Margin Tipis: Estimasi bersih ${currencyFormatter.format(-margin)} di bawah harga warung fisik!',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: isSafe ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                              final finalGagePrice = gagePrice > 0 ? gagePrice : offlinePrice;
                              final res = await GageApiClient.createMerchantMenu(
                                merchantId: MerchantStorefrontService.defaultPortalMerchantId,
                                name: name,
                                description: descCtrl.text.trim(),
                                category: category,
                                offlinePrice: offlinePrice,
                                gagePrice: finalGagePrice,
                                image: selectedImagePath ?? 'assets/images/dish_dimsum_original.png',
                              );
                              if (!mounted) return;
                              setModalState(() => isSubmitting = false);
                              navigator.pop();
                              if (res != null) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Menu baru berhasil ditambahkan ke dapur.')),
                                );
                                _fetchMenuCatalog();
                              } else {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Gagal menambahkan menu.')),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Simpan Menu ke Dapur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Katalog Menu & Stok Toko'),
        centerTitle: false,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Perbarui Menu',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchMenuCatalog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Action & Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari nama menu dimsum...',
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: isDark ? Colors.white60 : GageTheme.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GageTheme.primary,
                      side: const BorderSide(color: GageTheme.primary),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    icon: const Icon(Icons.swap_vert_rounded, size: 16),
                    label: const Text('Urutan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _showCategoryReorderSheet,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text('Menu Baru', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: _showAddMenuDialog,
                  ),
                ],
              ),
            ),

            // Category Chips Bar (MANDATORY CAPSULE PILL 999)
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
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? GageTheme.primary
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? GageTheme.primary
                              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
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
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item, bool isDark) {
    final itemId = item['id']?.toString() ?? '';
    final isAvailable = (item['is_available'] == 1 || item['is_available'] == true);
    final offlinePrice = _parsePrice(item['offline_price'] ?? item['price']);
    final onlinePrice = _parsePrice(item['gage_price'] ?? item['price']);
    final desc = (item['description'] ?? '').toString();

    // Cek override promo dari MerchantStorefrontData atau item asli
    final promoOverride = _storefrontData?.itemPromoPrices?[itemId] ?? -1;
    final hasPromo = promoOverride > 0 || (item['promo_price'] != null && _parsePrice(item['promo_price']) > 0);
    final activePromoPrice = promoOverride > 0 ? promoOverride : _parsePrice(item['promo_price']);

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
              child: _buildMenuItemImage(item['image'], width: 58, height: 58, fit: BoxFit.cover),
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
                    if (hasPromo) ...[
                      Text(
                        currencyFormatter.format(activePromoPrice),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: GageTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currencyFormatter.format(onlinePrice),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ] else ...[
                      Text(
                        currencyFormatter.format(onlinePrice),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: GageTheme.primary,
                        ),
                      ),
                    ],
                    if (offlinePrice > 0 && offlinePrice != onlinePrice && !hasPromo) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Warung: ${currencyFormatter.format(offlinePrice)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
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
                const SizedBox(height: 6),
                // Tombol Aksi Set Promo
                InkWell(
                  onTap: () => _showSetPromoDialog(item),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: hasPromo ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: hasPromo ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_offer_rounded,
                          size: 11,
                          color: hasPromo ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasPromo ? 'Promo Aktif ✓' : 'Set Promo Coret',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: hasPromo ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
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
