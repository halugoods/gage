import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/mock/gage_mock_registry.dart';

class GageProductCatalogSheet extends StatelessWidget {
  final String? merchantId;
  final String merchantName;
  final Function(String name, int price, String image) onProductSelected;

  const GageProductCatalogSheet({
    super.key,
    this.merchantId,
    this.merchantName = 'Merchant Toko',
    required this.onProductSelected,
  });

  static Future<void> show(
    BuildContext context, {
    String? merchantId,
    String merchantName = 'Toko Merchant',
    required Function(String name, int price, String image) onProductSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GageProductCatalogSheet(
        merchantId: merchantId,
        merchantName: merchantName,
        onProductSelected: onProductSelected,
      ),
    );
  }

  List<Map<String, dynamic>> _getMerchantProducts() {
    // Cari merchant sesuai ID atau fallback ke merchant pertama
    Map<String, dynamic>? target;
    if (merchantId != null && merchantId!.isNotEmpty) {
      target = GageMockRegistry.foodMerchants.firstWhere(
        (m) => m['id'] == merchantId,
        orElse: () => GageMockRegistry.foodMerchants.first,
      );
    } else {
      target = GageMockRegistry.foodMerchants.first;
    }

    final menus = target['menus'] as List<dynamic>?;
    if (menus != null && menus.isNotEmpty) {
      return menus.map((m) => m as Map<String, dynamic>).toList();
    }

    return [
      {
        'id': 'fallback-01',
        'name': 'Paket Spesial Pracimantoro',
        'price': 15000,
        'image': 'assets/images/resto_rocket_chicken.png',
        'category': 'Menu Utama',
      },
      {
        'id': 'fallback-02',
        'name': 'Es Teh Manis Jumbo',
        'price': 4000,
        'image': 'assets/images/resto_rocket_chicken.png',
        'category': 'Minuman',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final products = _getMerchantProducts();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grabber Bar
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: GageTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Katalog Produk $merchantName',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pilih menu di bawah untuk langsung ditanyakan di chat',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
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
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),

            // List Produk
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                shrinkWrap: true,
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final item = products[index];
                  final name = item['name'] as String? ?? 'Produk';
                  final price = (item['price'] as num?)?.toInt() ?? 0;
                  final image = item['image'] as String? ?? 'assets/images/resto_rocket_chicken.png';
                  final category = item['category'] as String? ?? 'Menu';

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Foto Produk 1:1 Rounded
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: Image.asset(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Center(
                                child: Icon(Icons.fastfood_rounded, color: Colors.grey, size: 28),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Detail Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: GageTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: GageTheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormatter.format(price),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: GageTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Tombol Tanyakan
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onProductSelected(name, price, image);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                          label: const Text(
                            'Tanya',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
