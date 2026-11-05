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
// dari Merchant Portal (misal: tingkat kepedasan, pilihan rasa, topping tambahan).
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

class _ItemVariantSheetState extends State<ItemVariantSheet> {
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();

  // State Varian Rasa / Level Pedas (Pilih 1)
  int _selectedSpiceIndex = 1;
  final List<Map<String, dynamic>> _spiceLevels = [
    {'name': 'Level 0 - Tidak Pedas', 'price': 0},
    {'name': 'Level 1 - Sedang (Rekomendasi)', 'price': 0},
    {'name': 'Level 2 - Pedas Mantap', 'price': 1000},
    {'name': 'Level 3 - Extra Mercon', 'price': 2000},
  ];

  // State Topping / Add-on Tambahan (Multi-Select)
  final Map<String, int> _availableToppings = {
    'Telur Ceplok / Dadar': 3500,
    'Ekstra Keju Mozzarella': 4000,
    'Kerupuk & Pangsit Goreng': 2000,
    'Ekstra Sambal & Bawang Goreng': 1500,
  };
  final Set<String> _selectedToppings = {};

  @override
  void initState() {
    super.initState();
    if (widget.cartItem != null) {
      _quantity = widget.cartItem!.quantity;
      if (widget.cartItem!.notes != null && widget.cartItem!.notes!.isNotEmpty) {
        _notesController.text = widget.cartItem!.notes!;
      }
      for (int i = 0; i < _spiceLevels.length; i++) {
        if (widget.cartItem!.selectedVariants.contains(_spiceLevels[i]['name'])) {
          _selectedSpiceIndex = i;
          break;
        }
      }
      for (final top in _availableToppings.keys) {
        if (widget.cartItem!.selectedVariants.contains(top)) {
          _selectedToppings.add(top);
        }
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get _extraPricePerItem {
    int extra = _spiceLevels[_selectedSpiceIndex]['price'] as int;
    for (final top in _selectedToppings) {
      extra += _availableToppings[top] ?? 0;
    }
    return extra;
  }

  Future<void> _handleAddToCart(BuildContext context) async {
    HapticFeedback.lightImpact();
    final cart = context.read<CartProvider>();

    if (widget.cartItem != null) {
      final List<String> variants = [
        _spiceLevels[_selectedSpiceIndex]['name'] as String,
        ..._selectedToppings,
      ];
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
    final basePrice = (widget.menuItem?['gage_price'] ?? widget.menuItem?['offline_price'] ?? 0) as int;
    final category = widget.menuItem?['category'] ?? 'Makanan';
    final imageUrl = widget.menuItem?['image'] ?? widget.menuItem?['image_url'];

    // Kumpulkan ringkasan varian
    final List<String> variants = [
      _spiceLevels[_selectedSpiceIndex]['name'] as String,
      ..._selectedToppings,
    ];

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
      serviceType: 'food',
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

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = widget.cartItem?.name ?? widget.menuItem?['name'] ?? '';
    final description = widget.menuItem?['description'] as String?;
    final basePrice = widget.cartItem?.price ?? ((widget.menuItem?['gage_price'] ?? widget.menuItem?['offline_price'] ?? 0) as int);
    final offlinePrice = widget.menuItem?['offline_price'] as int?;

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
                    Row(
                      children: [
                        Text(
                          currencyFormatter.format(basePrice),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: GageTheme.primary),
                        ),
                        if (offlinePrice != null && offlinePrice != basePrice) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Offline: ${currencyFormatter.format(offlinePrice)}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough),
                          ),
                        ],
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

          // 1. OPSI PILIHAN LEVEL / VARIAN UTAMA (Pilih 1 - Wajib)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tingkat Pedas / Varian Rasa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isDark ? Colors.white : Colors.black87),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Wajib Pilih 1', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: GageTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: List.generate(_spiceLevels.length, (idx) {
              final sp = _spiceLevels[idx];
              final isSelected = _selectedSpiceIndex == idx;
              final extraCost = sp['price'] as int;

              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedSpiceIndex = idx);
                },
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
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? GageTheme.primary : Colors.grey,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sp['name'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (extraCost > 0)
                        Text(
                          '+${currencyFormatter.format(extraCost)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GageTheme.primary),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // 2. OPSI TOPPING / ADD-ON TAMBAHAN (Multi-Select)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Topping / Ekstra Tambahan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isDark ? Colors.white : Colors.black87),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Opsional', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: _availableToppings.entries.map((entry) {
              final isChecked = _selectedToppings.contains(entry.key);
              final cost = entry.value;

              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isChecked) {
                      _selectedToppings.remove(entry.key);
                    } else {
                      _selectedToppings.add(entry.key);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isChecked
                        ? (isDark ? GageTheme.primary.withValues(alpha: 0.15) : const Color(0xFFFEF2F2))
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isChecked ? GageTheme.primary : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      width: isChecked ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        color: isChecked ? GageTheme.primary : Colors.grey,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        '+${currencyFormatter.format(cost)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isChecked ? GageTheme.primary : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // 3. Catatan Masak / Pesanan Khusus (Capsule Pill Rounded 24px)
          Text('Catatan untuk Dapur (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            maxLength: 100,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Contoh: Jangan pedas, kuah dipisah, tambah saus...',
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

          // 4. Selector Jumlah (Capsule 24px) & Tombol Tambah (Stadium 28px)
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
