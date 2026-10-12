import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/providers/cart_provider.dart';

class ItemVariantSheet extends StatefulWidget {
  final Map<String, dynamic> menuItem;
  final Map<String, dynamic> merchant;

  const ItemVariantSheet({
    super.key,
    required this.menuItem,
    required this.merchant,
  });

  @override
  State<ItemVariantSheet> createState() => _ItemVariantSheetState();
}

class _ItemVariantSheetState extends State<ItemVariantSheet> {
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleAddToCart(BuildContext context) {
    final cart = context.read<CartProvider>();

    final merchantId = widget.merchant['id'] ?? 'm-dimsum-sewu';
    final merchantName = widget.merchant['name'] ?? 'Dimsum Sewu';
    final menuId = widget.menuItem['id'] ?? '';
    final name = widget.menuItem['name'] ?? '';
    final price = (widget.menuItem['gage_price'] ?? widget.menuItem['offline_price'] ?? 0) as int;
    final category = widget.menuItem['category'] ?? 'Makanan';

    final newItem = CartItemModel(
      menuId: menuId,
      merchantId: merchantId,
      merchantName: merchantName,
      name: name,
      price: price,
      quantity: _quantity,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      category: category,
    );

    // Tambahkan langsung ke keranjang (Mendukung Multi-Merchant / Gabung Toko)
    final isMulti = cart.items.isNotEmpty && !cart.merchantIds.contains(merchantId);
    cart.addItem(newItem);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: GageTheme.accentGreen,
        content: Text(
          isMulti
              ? '$_quantity x $name ditambahkan! (Digabung dari ${cart.merchantCount} toko)'
              : '$_quantity x $name ditambahkan ke keranjang!',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final name = widget.menuItem['name'] ?? '';
    final description = widget.menuItem['description'] as String?;
    final price = (widget.menuItem['gage_price'] ?? widget.menuItem['offline_price'] ?? 0) as int;
    final offlinePrice = widget.menuItem['offline_price'] as int?;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            currencyFormatter.format(price),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: GageTheme.primary),
                          ),
                          if (offlinePrice != null && offlinePrice != price) ...[
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
                        Text(description, style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Catatan Masak / Pesanan Khusus
            const Text('Catatan untuk Dapur (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: 'Contoh: Jangan pedas, kuah dipisah, tambah saus...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: GageTheme.primary)),
              ),
            ),

            const SizedBox(height: 16),

            // Selector Jumlah & Tombol Tambah
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18, color: GageTheme.primary),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      ),
                      Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18, color: GageTheme.primary),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _handleAddToCart(context),
                    child: Text(
                      'Tambah • ${currencyFormatter.format(price * _quantity)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
