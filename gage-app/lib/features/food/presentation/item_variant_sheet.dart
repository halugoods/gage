import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/switch_merchant_dialog.dart';

// [PRODUCTION_CONTRACT: Merchant Portal Variant & Add-on Synchronization]
// Komponen standar untuk menangani opsi varian dinamis dan add-on yang dikonfigurasi
// dari Merchant Portal (misal: tingkat kepedasan, pilihan rasa, kemasan, topping tambahan).
class ItemVariantSheet extends StatefulWidget {
  final Map<String, dynamic>? menuItem;
  final Map<String, dynamic>? merchant;
  final CartItemModel? cartItem;

  const ItemVariantSheet({
    super.key,
    this.menuItem,
    this.merchant,
    this.cartItem,
  });

  /// Menampilkan sheet varian item dengan standarisasi GageFloatingSheet
  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? menuItem,
    Map<String, dynamic>? merchant,
    CartItemModel? cartItem,
  }) {
    HapticFeedback.lightImpact();
    return GageFloatingSheet.show(
      context: context,
      isScrollControlled: true,
      child: ItemVariantSheet(
        menuItem: menuItem,
        merchant: merchant,
        cartItem: cartItem,
      ),
    );
  }

  @override
  State<ItemVariantSheet> createState() => _ItemVariantSheetState();
}

class _VariantOption {
  final String name;
  final int price;
  const _VariantOption({required this.name, this.price = 0});
}

class _VariantGroup {
  final String title;
  final bool isMultiSelect;
  final bool isRequired;
  final List<_VariantOption> options;
  const _VariantGroup({
    required this.title,
    required this.isMultiSelect,
    required this.isRequired,
    required this.options,
  });
}

class _ItemVariantSheetState extends State<ItemVariantSheet> {
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();

  String get _serviceDomain {
    if (widget.cartItem != null && widget.cartItem!.serviceType.isNotEmpty) {
      return widget.cartItem!.serviceType.toLowerCase();
    }
    if (widget.merchant?['domain'] != null && widget.merchant!['domain'].toString().isNotEmpty) {
      return widget.merchant!['domain'].toString().toLowerCase();
    }
    if (widget.merchant?['serviceType'] != null && widget.merchant!['serviceType'].toString().isNotEmpty) {
      return widget.merchant!['serviceType'].toString().toLowerCase();
    }
    final raw = (widget.merchant?['id'] ?? widget.merchant?['category'] ?? widget.merchant?['name'] ?? widget.menuItem?['id'] ?? '').toString().toLowerCase();
    if (raw.contains('build') || raw.contains('tb-') || raw.contains('bangun') || raw.contains('material') || raw.contains('besi') || raw.contains('cat-')) {
      return 'build';
    }
    if (raw.contains('farm') || raw.contains('tani') || raw.contains('ternak') || raw.contains('pupuk') || raw.contains('pakan')) {
      return 'farm';
    }
    if (raw.contains('shop') || raw.contains('sembako') || raw.contains('toko') || raw.contains('kelontong') || raw.contains('minimarket') || raw.contains('mart')) {
      return 'shop';
    }
    return 'food';
  }

  bool get _isFoodDomain => _serviceDomain == 'food';

  late final List<_VariantGroup> _groups;
  final Map<int, int> _selectedSingle = {};
  final Map<int, Set<String>> _selectedMulti = {};

  static const List<_VariantOption> _defaultFoodSpiceOptions = [
    _VariantOption(name: 'Level 0 - Tidak Pedas', price: 0),
    _VariantOption(name: 'Level 1 - Sedang (Rekomendasi)', price: 0),
    _VariantOption(name: 'Level 2 - Pedas Mantap', price: 1000),
    _VariantOption(name: 'Level 3 - Extra Mercon', price: 2000),
  ];

  static const List<_VariantOption> _defaultFoodToppingOptions = [
    _VariantOption(name: 'Telur Ceplok / Dadar', price: 3500),
    _VariantOption(name: 'Ekstra Keju Mozzarella', price: 4000),
    _VariantOption(name: 'Kerupuk & Pangsit Goreng', price: 2000),
    _VariantOption(name: 'Ekstra Sambal & Bawang Goreng', price: 1500),
  ];

  List<_VariantOption> _parseOptionsList(dynamic rawList) {
    if (rawList is! List) return const [];
    final out = <_VariantOption>[];
    for (final entry in rawList) {
      if (entry is Map) {
        final label = (entry['name'] ?? entry['label'] ?? entry['title'] ?? '').toString().trim();
        if (label.isEmpty) continue;
        final extra = _parseInt(entry['extra_price'] ?? entry['extraPrice'] ?? entry['price'], 0);
        out.add(_VariantOption(name: label, price: extra));
      } else {
        final label = entry.toString().trim();
        if (label.isNotEmpty) out.add(_VariantOption(name: label));
      }
    }
    return out;
  }

  List<_VariantGroup> _resolveVariantGroups() {
    final rawGroups = widget.menuItem?['variant_groups'];
    if (rawGroups is List && rawGroups.isNotEmpty) {
      final parsed = <_VariantGroup>[];
      for (final g in rawGroups) {
        if (g is! Map) continue;
        final opts = _parseOptionsList(g['options'] ?? g['items']);
        if (opts.isEmpty) continue;
        final isMulti = g['multi_select'] == true || g['multiSelect'] == true || g['type'] == 'multi';
        parsed.add(_VariantGroup(
          title: (g['title'] ?? g['name'] ?? 'Pilihan Varian').toString(),
          isMultiSelect: isMulti,
          isRequired: !isMulti && g['required'] != false,
          options: opts,
        ));
      }
      if (parsed.isNotEmpty) return parsed;
    }

    final rawVariants = widget.menuItem?['variants'];
    if (rawVariants is List && rawVariants.isNotEmpty) {
      final opts = _parseOptionsList(rawVariants);
      if (opts.isNotEmpty) {
        return [
          _VariantGroup(
            title: (widget.menuItem?['variant_title'] ?? 'Pilihan Varian').toString(),
            isMultiSelect: false,
            isRequired: true,
            options: opts,
          ),
        ];
      }
    } else if (rawVariants is String && rawVariants.trim().isNotEmpty) {
      final opts = rawVariants
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((e) => _VariantOption(name: e))
          .toList();
      if (opts.isNotEmpty) {
        return [
          _VariantGroup(
            title: (widget.menuItem?['variant_title'] ?? 'Pilihan Varian').toString(),
            isMultiSelect: false,
            isRequired: true,
            options: opts,
          ),
        ];
      }
    }

    switch (_serviceDomain) {
      case 'shop':
        return const [
          _VariantGroup(
            title: 'Pilihan Ukuran / Kemasan',
            isMultiSelect: false,
            isRequired: true,
            options: [
              _VariantOption(name: 'Kemasan Standar', price: 0),
              _VariantOption(name: 'Kemasan Extra Rapi (Kardus / Segel)', price: 0),
            ],
          ),
        ];
      case 'farm':
        return const [
          _VariantGroup(
            title: 'Pilihan Kemasan / Satuan',
            isMultiSelect: false,
            isRequired: true,
            options: [
              _VariantOption(name: 'Kemasan Segel Pabrik', price: 0),
              _VariantOption(name: 'Pelindung Tambahan Anti Lembab', price: 0),
            ],
          ),
        ];
      case 'build':
        return const [
          _VariantGroup(
            title: 'Opsi Penanganan Material',
            isMultiSelect: false,
            isRequired: true,
            options: [
              _VariantOption(name: 'Standar Toko (Turun di Titik Antar)', price: 0),
              _VariantOption(name: 'Terpisah & Terikat Rapi per Unit', price: 0),
            ],
          ),
        ];
      default:
        return const [
          _VariantGroup(
            title: 'Tingkat Pedas / Varian Rasa',
            isMultiSelect: false,
            isRequired: true,
            options: _defaultFoodSpiceOptions,
          ),
          _VariantGroup(
            title: 'Topping / Ekstra Tambahan',
            isMultiSelect: true,
            isRequired: false,
            options: _defaultFoodToppingOptions,
          ),
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _groups = _resolveVariantGroups();

    final hasCustomVariants = widget.menuItem?['variant_groups'] != null || widget.menuItem?['variants'] != null;
    if (widget.cartItem != null) {
      _quantity = widget.cartItem!.quantity;
      if (widget.cartItem!.notes != null && widget.cartItem!.notes!.isNotEmpty) {
        _notesController.text = widget.cartItem!.notes!;
      }
    }

    for (int gIdx = 0; gIdx < _groups.length; gIdx++) {
      final group = _groups[gIdx];
      if (!group.isMultiSelect) {
        int matchedIdx = -1;
        if (widget.cartItem != null) {
          for (int oIdx = 0; oIdx < group.options.length; oIdx++) {
            if (widget.cartItem!.selectedVariants.contains(group.options[oIdx].name)) {
              matchedIdx = oIdx;
              break;
            }
          }
        }
        if (matchedIdx < 0 && group.isRequired && group.options.isNotEmpty) {
          matchedIdx = (_isFoodDomain && gIdx == 0 && !hasCustomVariants && group.options.length > 1) ? 1 : 0;
        }
        _selectedSingle[gIdx] = matchedIdx;
      } else {
        final chosen = <String>{};
        if (widget.cartItem != null) {
          for (final opt in group.options) {
            if (widget.cartItem!.selectedVariants.contains(opt.name)) {
              chosen.add(opt.name);
            }
          }
        }
        _selectedMulti[gIdx] = chosen;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^0-9\-]'), '');
      return int.tryParse(cleaned) ?? fallback;
    }
    return fallback;
  }

  int get _extraPricePerItem {
    int extra = 0;
    for (int gIdx = 0; gIdx < _groups.length; gIdx++) {
      final group = _groups[gIdx];
      if (!group.isMultiSelect) {
        final selIdx = _selectedSingle[gIdx] ?? -1;
        if (selIdx >= 0 && selIdx < group.options.length) {
          extra += group.options[selIdx].price;
        }
      } else {
        final selected = _selectedMulti[gIdx] ?? const {};
        for (final opt in group.options) {
          if (selected.contains(opt.name)) {
            extra += opt.price;
          }
        }
      }
    }
    return extra;
  }

  List<String> get _selectedVariantNames {
    final variants = <String>[];
    for (int gIdx = 0; gIdx < _groups.length; gIdx++) {
      final group = _groups[gIdx];
      if (!group.isMultiSelect) {
        final selIdx = _selectedSingle[gIdx] ?? -1;
        if (selIdx >= 0 && selIdx < group.options.length) {
          variants.add(group.options[selIdx].name);
        }
      } else {
        final selected = _selectedMulti[gIdx] ?? const {};
        for (final opt in group.options) {
          if (selected.contains(opt.name)) {
            variants.add(opt.name);
          }
        }
      }
    }
    return variants;
  }

  Future<void> _handleAddToCart(BuildContext context) async {
    HapticFeedback.lightImpact();
    final cart = context.read<CartProvider>();
    final variants = _selectedVariantNames;

    if (widget.cartItem != null) {
      cart.updateItemVariants(
        widget.cartItem!.menuId,
        variants: variants,
        variantPrice: _extraPricePerItem,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: GageTheme.accentGreen,
            content: Text('Varian berhasil diperbarui!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final merchantId = widget.merchant?['id'] ?? 'm-dimsum-sewu';
    final merchantName = widget.merchant?['name'] ?? 'Dimsum Sewu';
    final menuId = widget.menuItem?['id'] ?? '';
    final name = widget.menuItem?['name'] ?? '';
    final basePrice = _parseInt(widget.menuItem?['gage_price'] ?? widget.menuItem?['price'] ?? widget.menuItem?['offline_price'], 0);
    final category = widget.menuItem?['category'] ?? (_isFoodDomain ? 'Makanan' : 'Produk');
    final imageUrl = widget.menuItem?['image'] ?? widget.menuItem?['image_url'];

    final newItem = CartItemModel(
      menuId: menuId,
      merchantId: merchantId,
      merchantName: merchantName,
      name: name,
      price: basePrice,
      variantPrice: _extraPricePerItem,
      selectedVariants: variants,
      quantity: _quantity,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      category: category,
      imageUrl: imageUrl is String ? imageUrl : null,
      serviceType: _serviceDomain,
    );

    final added = cart.addItem(newItem);
    if (!added) {
      final currentStore = cart.merchantName ?? 'Toko Lain';
      final confirmed = await SwitchMerchantDialog.show(
        context,
        currentMerchantName: currentStore,
        newMerchantName: merchantName,
      );
      if (confirmed == true && context.mounted) {
        cart.addItem(newItem, forceReplace: true);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: GageTheme.accentGreen,
            content: Text('$_quantity x $name ditambahkan ke keranjang!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: GageTheme.accentGreen,
          content: Text('$_quantity x $name ditambahkan ke keranjang!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildVariantOptionTile({
    required String label,
    required int extraPrice,
    required bool isSelected,
    required bool isMultiSelect,
    required bool isDark,
    required NumberFormat currencyFormatter,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? GageTheme.primary.withValues(alpha: 0.15) : const Color(0xFFFEF2F2))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? GageTheme.primary : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isMultiSelect
                  ? (isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
                  : (isSelected ? Icons.radio_button_checked : Icons.radio_button_off),
              color: isSelected ? GageTheme.primary : Colors.grey,
              size: 19,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (extraPrice > 0)
              Text(
                '+${currencyFormatter.format(extraPrice)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected || !isMultiSelect ? GageTheme.primary : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantGroupSection(
    int gIdx,
    _VariantGroup group,
    bool isDark,
    NumberFormat currencyFormatter,
  ) {
    final badgeText = group.isMultiSelect
        ? 'Opsional'
        : (group.isRequired ? 'Wajib Pilih 1' : 'Opsional');
    final highlightBadge = !group.isMultiSelect && group.isRequired;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                group.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: highlightBadge
                    ? GageTheme.primary.withValues(alpha: 0.1)
                    : (isDark ? Colors.white10 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: highlightBadge ? FontWeight.bold : FontWeight.w600,
                  color: highlightBadge ? GageTheme.primary : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: List.generate(group.options.length, (oIdx) {
            final opt = group.options[oIdx];
            final isSelected = group.isMultiSelect
                ? (_selectedMulti[gIdx]?.contains(opt.name) ?? false)
                : (_selectedSingle[gIdx] == oIdx);

            return _buildVariantOptionTile(
              label: opt.name,
              extraPrice: opt.price,
              isSelected: isSelected,
              isMultiSelect: group.isMultiSelect,
              isDark: isDark,
              currencyFormatter: currencyFormatter,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (group.isMultiSelect) {
                    final set = _selectedMulti.putIfAbsent(gIdx, () => <String>{});
                    if (set.contains(opt.name)) {
                      set.remove(opt.name);
                    } else {
                      set.add(opt.name);
                    }
                  } else {
                    _selectedSingle[gIdx] = oIdx;
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = widget.cartItem?.name ?? widget.menuItem?['name'] ?? '';
    final description = widget.menuItem?['description'] as String?;
    final basePrice = widget.cartItem?.price ?? _parseInt(widget.menuItem?['gage_price'] ?? widget.menuItem?['price'] ?? widget.menuItem?['offline_price'], 0);
    final originalPrice = widget.menuItem?['original_price'] != null || widget.menuItem?['originalPrice'] != null
        ? _parseInt(widget.menuItem?['original_price'] ?? widget.menuItem?['originalPrice'], 0)
        : null;
    final offlinePrice = widget.menuItem?['offline_price'] != null ? _parseInt(widget.menuItem?['offline_price']) : null;
    final hasPromoOriginal = originalPrice != null && originalPrice > basePrice && basePrice > 0;
    final promoPct = hasPromoOriginal ? (((originalPrice - basePrice) * 100) / originalPrice).round() : null;

    final unitPrice = basePrice + _extraPricePerItem;
    final totalPrice = unitPrice * _quantity;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Item Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          currencyFormatter.format(basePrice),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: GageTheme.primary),
                        ),
                        if (hasPromoOriginal) ...[
                          Text(
                            currencyFormatter.format(originalPrice),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.grey.shade500,
                            ),
                          ),
                          if (promoPct != null && promoPct > 0)
                            Text(
                              '-$promoPct%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: GageTheme.primary),
                            ),
                        ] else if (offlinePrice != null && offlinePrice != basePrice)
                          Text(
                            'Offline: ${currencyFormatter.format(offlinePrice)}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough),
                          ),
                      ],
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(description, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B))),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          const SizedBox(height: 14),

          for (int gIdx = 0; gIdx < _groups.length; gIdx++) ...[
            _buildVariantGroupSection(gIdx, _groups[gIdx], isDark, currencyFormatter),
            const SizedBox(height: 12),
          ],

          // Catatan Masak / Pesanan Khusus (Capsule Pill Rounded 24px)
          Text(
            _isFoodDomain ? 'Catatan untuk Dapur (Opsional)' : 'Catatan untuk Toko / Penjual (Opsional)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            maxLength: 100,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: _isFoodDomain
                  ? 'Contoh: Jangan pedas, kuah dipisah, tambah saus...'
                  : 'Contoh: Warna/kemasan khusus, pastikan segel aman...',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Selector Jumlah (Capsule 24px) & Tombol Tambah (Stadium 28px)
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18, color: GageTheme.primary),
                      onPressed: _quantity > 1
                          ? () {
                              HapticFeedback.lightImpact();
                              setState(() => _quantity--);
                            }
                          : null,
                    ),
                    Text('$_quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18, color: GageTheme.primary),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() => _quantity++);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 0,
                    ),
                    onPressed: () => _handleAddToCart(context),
                    child: Text(
                      widget.cartItem != null
                          ? 'Simpan Perubahan Varian'
                          : 'Tambah • ${currencyFormatter.format(totalPrice)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
