import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/order_model.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/features/order/presentation/order_tracking_screen.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/features/orders/presentation/order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id ?? 'usr-cust-01';
    await context.read<OrderProvider>().fetchUserOrders(userId);
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final activeOrders = orderProvider.activeOrders;
    final historyOrders = orderProvider.orderHistory;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? GageTheme.darkBackground : GageTheme.background,
        appBar: AppBar(
          title: const Text('Pesanan Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Segarkan',
              onPressed: _refresh,
            ),
          ],
          bottom: TabBar(
            indicatorColor: GageTheme.primary,
            labelColor: GageTheme.primary,
            unselectedLabelColor: isDark ? Colors.white60 : GageTheme.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Pesanan Aktif'),
              Tab(text: 'Riwayat Pesanan'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: GageTheme.primary,
          child: TabBarView(
            children: [
              // Tab 1: Pesanan Aktif
              activeOrders.isEmpty
                  ? _buildEmptyState(
                      'Belum Ada Pesanan Aktif',
                      'Pesanan yang sedang disiapkan resto atau diantar driver akan tampil di sini secara real-time.',
                      icon: Icons.delivery_dining_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: activeOrders.length,
                      itemBuilder: (ctx, idx) => _buildOrderCard(context, activeOrders[idx], isActive: true),
                    ),

              // Tab 2: Riwayat Pesanan
              historyOrders.isEmpty
                  ? _buildEmptyState(
                      'Belum Ada Riwayat Pesanan',
                      'Semua pesanan yang telah selesai atau dinikmati akan tersimpan di sini.',
                      icon: Icons.receipt_long_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: historyOrders.length,
                      itemBuilder: (ctx, idx) => _buildOrderCard(context, historyOrders[idx], isActive: false),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, {required bool isActive}) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final merchantNames = order.merchantNamesList;
    final merchantTitle = merchantNames.isNotEmpty ? merchantNames.join(', ') : order.merchantName;
    final isMultiMerchant = merchantNames.length > 1;

    // Kumpulkan daftar gambar untuk gallery scroll horizontal
    final imageList = <String>[];
    for (final it in order.items) {
      if (it.imageUrl != null && it.imageUrl!.trim().isNotEmpty) {
        if (!imageList.contains(it.imageUrl!.trim())) {
          imageList.add(it.imageUrl!.trim());
        }
      }
    }
    // Fallback jika item tidak ada gambar
    if (imageList.isEmpty) {
      if (order.merchantName.toLowerCase().contains('rocket')) {
        imageList.add('assets/images/resto_rocket_chicken.png');
      } else if (order.merchantName.toLowerCase().contains('dimsum')) {
        imageList.add('assets/images/resto_dimsum_sewu.png');
      } else if (order.merchantName.toLowerCase().contains('ride') || order.merchantName.toLowerCase().contains('car')) {
        imageList.add('assets/icons/ic_ride.png');
      } else {
        imageList.add('assets/images/dish_bakso_urat.png');
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : const Color(0x0A000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => OrderDetailScreen(order: order)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris 1: Chip Invoice Unik + Badge Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInvoiceChip(context, order.orderNumber),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? Icons.access_time_rounded : Icons.check_circle_rounded,
                            size: 13,
                            color: isActive ? const Color(0xFFB45309) : const Color(0xFF15803D),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.statusLabel,
                            style: TextStyle(
                              color: isActive ? const Color(0xFFB45309) : const Color(0xFF15803D),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Baris 2: Profil Toko & Hero Text (Multi-Merchant Supported) - Clean Pure Text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            merchantTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMultiMerchant) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: const Text(
                              'Multi Toko',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.merchantAddress,
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 11.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Baris 3: Scroll Horizontal Deretan Gambar dengan Efek Vignette / Faded Gradient
                _buildThumbnailGalleryWithVignette(imageList),
                const SizedBox(height: 10),

                // Rincian Singkat Menu
                Text(
                  order.items.isNotEmpty
                      ? '${order.items.first.quantity}x ${order.items.first.name}${order.items.length > 1 ? " dan ${order.items.length - 1} item lainnya" : ""}'
                      : 'Pesanan Layanan GAGE',
                  style: TextStyle(color: isDark ? Colors.white70 : GageTheme.textSecondary, fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                const SizedBox(height: 12),

                // Baris 4: Total Pembayaran & Tombol Aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Pembayaran', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : GageTheme.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormatter.format(order.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 15.5),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : Colors.black87,
                            side: BorderSide(color: isDark ? GageTheme.darkBorder : Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (ctx) => OrderDetailScreen(order: order)),
                            );
                          },
                          child: const Text('Rincian', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        if (isActive)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GageTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => OrderTrackingScreen(
                                    orderId: order.id,
                                    initialOrder: order,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.navigation_rounded, size: 14),
                            label: const Text('Lacak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GageTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              _reorder(context, order);
                            },
                            child: const Text('Pesan Lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Nomor Invoice Unik dengan Tombol Salin (Tanpa Card Wrap)
  Widget _buildInvoiceChip(BuildContext context, String invoice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: invoice));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nomor invoice disalin: $invoice'),
            backgroundColor: GageTheme.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                invoice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.copy_rounded, size: 13, color: GageTheme.primary),
          ],
        ),
      ),
    );
  }

  // Gallery Deretan Gambar dengan Efek Vignette / Faded Gradient pada Item ke-2 dan Seterusnya
  Widget _buildThumbnailGalleryWithVignette(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    Widget gallery = SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final img = images[idx];
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 52,
              height: 52,
              color: Colors.grey.shade100,
              child: _buildThumbnailImage(img),
            ),
          );
        },
      ),
    );

    // Jika gambar lebih dari 1, berikan ShaderMask vignette faded di sisi kanan
    if (images.length >= 2) {
      gallery = ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.black,
              Colors.black,
              Colors.black87,
              Colors.transparent,
            ],
            stops: [0.0, 0.65, 0.85, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: gallery,
      );
    }

    return gallery;
  }

  Widget _buildThumbnailImage(String img) {
    final clean = img.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Image.network(
        clean,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const Center(
          child: Icon(Icons.restaurant_rounded, color: GageTheme.primary, size: 22),
        ),
      );
    }
    return Image.asset(
      clean,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => const Center(
        child: Icon(Icons.restaurant_rounded, color: GageTheme.primary, size: 22),
      ),
    );
  }

  void _reorder(BuildContext context, OrderModel order) {
    final cart = context.read<CartProvider>();
    cart.clearCart();
    for (var item in order.items) {
      cart.addItem(CartItemModel(
        menuId: item.id,
        merchantId: order.merchantId,
        merchantName: item.merchantName ?? order.merchantName,
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        notes: item.notes,
        imageUrl: item.imageUrl,
      ));
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const CheckoutScreen()),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, {required IconData icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: isDark ? Colors.white30 : Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : GageTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
