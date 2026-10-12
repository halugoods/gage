import 'package:flutter/material.dart';
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: GageTheme.background,
        appBar: AppBar(
          title: const Text('Pesanan Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refresh,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: GageTheme.primary,
            labelColor: GageTheme.primary,
            unselectedLabelColor: GageTheme.textSecondary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Pesanan Aktif'),
              Tab(text: 'Riwayat'),
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
                      'Pesanan yang sedang disiapkan atau diantar akan tampil di sini secara real-time.',
                      icon: Icons.delivery_dining_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
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
                      padding: const EdgeInsets.all(16),
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

    return InkWell(
      onTap: () {
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
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? GageTheme.primaryLight : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: TextStyle(
                        color: isActive ? GageTheme.primary : Colors.green.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.merchantName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Text(
                order.items.isNotEmpty
                    ? '${order.items.first.quantity}x ${order.items.first.name}${order.items.length > 1 ? " dan ${order.items.length - 1} menu lainnya" : ""}'
                    : 'Pesanan Makanan',
                style: const TextStyle(color: GageTheme.textSecondary, fontSize: 13),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(fontSize: 11, color: GageTheme.textSecondary)),
                      Text(
                        currencyFormatter.format(order.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 15),
                      ),
                    ],
                  ),
                  if (isActive)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      icon: const Icon(Icons.navigation_rounded, size: 15),
                      label: const Text('Lacak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  else
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GageTheme.primary,
                        side: const BorderSide(color: GageTheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        ),
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
        merchantName: order.merchantName,
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        notes: item.notes,
      ));
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const CheckoutScreen()),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, {required IconData icon}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: GageTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
