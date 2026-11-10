import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

/// Reusable Floating Cart Sheet untuk GAGE SuperApp
/// Standarisasi floating sheet untuk melihat dan mengelola isi keranjang belanja
/// sebelum menuju ke CheckoutScreen.
class GageCartSheet extends StatelessWidget {
  const GageCartSheet({super.key});

  /// Tampilkan Cart Sheet dengan GageFloatingSheet
  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return GageFloatingSheet.show(
      context: context,
      isScrollControlled: true,
      child: const GageCartSheet(),
    );
  }

  String _resolveProductImage(CartItemModel item) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return item.imageUrl!;
    }
    final n = item.name.toLowerCase();
    if (n.contains('mentai')) return 'assets/images/dish_dimsum_mentai.png';
    if (n.contains('dimsum') || n.contains('siomay')) return 'assets/images/dish_dimsum_original.png';
    if (n.contains('teh')) return 'assets/images/dish_es_teh.png';
    if (n.contains('kopi')) return 'assets/images/dish_kopi_susu.png';
    if (n.contains('ayam') || n.contains('geprek')) return 'assets/images/dish_ayam_geprek.png';
    if (n.contains('mie') || n.contains('bakso')) return 'assets/images/dish_mie_ayam.png';
    if (n.contains('beras')) return 'assets/images/prod_beras.png';
    if (n.contains('minyak')) return 'assets/images/prod_minyak.png';
    if (n.contains('telur')) return 'assets/images/prod_telur.png';
    if (n.contains('pupuk')) return 'assets/images/prod_pupuk.png';
    if (n.contains('pakan')) return 'assets/images/prod_pakan.png';
    return 'assets/images/dish_dimsum_original.png';
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    if (cart.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: GageTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: GageTheme.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Keranjang Belanja Masih Kosong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Yuk jelajahi aneka kuliner dan produk favoritmu, lalu tambahkan ke keranjang!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.grey.shade400 : Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Mulai Pilih Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Sheet
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: GageTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_rounded, color: GageTheme.primary, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keranjang Belanja',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    cart.merchantName ?? 'Toko Mitra GAGE',
                    style: const TextStyle(
                      fontSize: 12,
                      color: GageTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),

        const SizedBox(height: 12),
        Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        const SizedBox(height: 12),

        // 2. Daftar Item dalam Keranjang
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.42),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: cart.items.length,
            separatorBuilder: (_, _) => Divider(height: 18, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
            itemBuilder: (ctx, idx) {
              final item = cart.items[idx];
              final itemUnitTotal = item.price + item.variantPrice;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail Foto Menu
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 54,
                      height: 54,
                      child: Image.asset(
                        _resolveProductImage(item),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          child: const Icon(Icons.fastfood_rounded, color: Colors.grey, size: 24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Detail Nama, Varian & Catatan
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cart.groupOrderId != null) ...[
                          Builder(builder: (c) {
                            String memberName = 'Kamu (Host)';
                            Color memberColor = GageTheme.primary;
                            if (item.menuId.contains('budi') || (item.notes != null && item.notes!.toLowerCase().contains('budi'))) {
                              memberName = 'Budi';
                              memberColor = const Color(0xFF2563EB);
                            } else if (item.menuId.contains('siti') || (item.notes != null && item.notes!.toLowerCase().contains('siti'))) {
                              memberName = 'Siti';
                              memberColor = const Color(0xFFD97706);
                            }
                            return Container(
                              margin: const EdgeInsets.only(bottom: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: memberColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                memberName,
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: memberColor),
                              ),
                            );
                          }),
                        ],
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormatter.format(itemUnitTotal),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: GageTheme.primary,
                          ),
                        ),
                        if (item.selectedVariants.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.selectedVariants.join(' • '),
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.edit_note_rounded, size: 12, color: Colors.grey),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  'Catatan: ${item.notes}',
                                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? Colors.grey.shade400 : Colors.black54),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Stepper Kapsul Full-Rounded 24px
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: GageTheme.primary, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            cart.updateQuantity(item.menuId, -1);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Icon(Icons.remove, color: GageTheme.primary, size: 15),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '${item.quantity}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            cart.updateQuantity(item.menuId, 1);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Icon(Icons.add, color: GageTheme.primary, size: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 14),
        Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        const SizedBox(height: 12),

        // 3. Ringkasan Total & Tombol Checkout (Stadium 28px)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Pembayaran',
                  style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
                ),
                Text(
                  currencyFormatter.format(cart.subtotal),
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: GageTheme.primary),
                ),
              ],
            ),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const CheckoutScreen(),
                    ),
                  );
                },
                child: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
