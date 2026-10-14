import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/order_model.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/features/order/presentation/order_tracking_screen.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateStr = order.createdAt > 0
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(order.createdAt * 1000))
        : DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    return Scaffold(
      backgroundColor: GageTheme.background,
      appBar: AppBar(
        title: const Text('Rincian Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Bagikan',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Nomor Invoice ${order.orderNumber} siap dibagikan.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Invoice & Status Header
            _buildInvoiceStatusCard(context, dateStr),
            const SizedBox(height: 14),

            // Card 2: Status Timeline
            _buildStatusTimeline(),
            const SizedBox(height: 14),

            // Card 3: Toko / Merchant Info
            _buildMerchantSection(),
            const SizedBox(height: 14),

            // Card 4: Rincian Produk / Menu
            _buildItemsSection(currencyFormatter),
            const SizedBox(height: 14),

            // Card 5: Pengantaran & Alamat
            _buildDeliverySection(),
            const SizedBox(height: 14),

            // Card 6: Info Pengemudi / Driver (jika ada)
            if (order.driverName != null && order.driverName!.isNotEmpty) ...[
              _buildDriverSection(context),
              const SizedBox(height: 14),
            ],

            // Card 7: Rincian Pembayaran
            _buildPaymentSummaryCard(currencyFormatter),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildInvoiceStatusCard(BuildContext context, String dateStr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.isActive ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      order.isActive ? Icons.access_time_rounded : Icons.check_circle_rounded,
                      size: 14,
                      color: order.isActive ? const Color(0xFFB45309) : const Color(0xFF15803D),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      order.statusLabel,
                      style: TextStyle(
                        color: order.isActive ? const Color(0xFFB45309) : const Color(0xFF15803D),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Nomor Invoice Unik', style: TextStyle(fontSize: 11, color: GageTheme.textSecondary)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.black87),
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: order.orderNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nomor invoice disalin: ${order.orderNumber}'),
                      backgroundColor: GageTheme.primary,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 13, color: GageTheme.primary),
                      SizedBox(width: 4),
                      Text('Salin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    final stages = [
      {'title': 'Dipesan', 'done': true},
      {'title': 'Disiapkan', 'done': order.status != 'PAYMENT_PENDING'},
      {'title': 'Diantar', 'done': ['ON_DELIVERY', 'COMPLETED'].contains(order.status)},
      {'title': 'Selesai', 'done': order.status == 'COMPLETED'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Pengantaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(stages.length, (idx) {
              final s = stages[idx];
              final isDone = s['done'] as bool;
              final isLast = idx == stages.length - 1;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone ? GageTheme.primary : Colors.grey.shade300,
                            ),
                            child: Icon(
                              isDone ? Icons.check : Icons.circle,
                              color: Colors.white,
                              size: isDone ? 14 : 8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s['title'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                              color: isDone ? Colors.black87 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 20,
                        height: 2,
                        color: (stages[idx + 1]['done'] as bool) ? GageTheme.primary : Colors.grey.shade300,
                        margin: const EdgeInsets.only(bottom: 18),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantSection() {
    final merchants = order.merchantNamesList;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                merchants.length > 1 ? 'Mitra Toko (${merchants.length} Toko)' : 'Mitra Toko',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              if (merchants.length > 1) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text('Multi-Merchant', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ...merchants.map((mName) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: GageTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.restaurant_rounded, color: GageTheme.primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(order.merchantAddress, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildItemsSection(NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daftar Menu / Produk (${order.items.fold<int>(0, (prev, e) => prev + e.quantity)} Item)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade100,
                      child: _buildItemImage(item.imageUrl),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        if (item.merchantName != null && item.merchantName!.isNotEmpty)
                          Text(item.merchantName!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        if (item.notes != null && item.notes!.isNotEmpty)
                          Text('Catatan: ${item.notes!}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54)),
                        const SizedBox(height: 4),
                        Text('${item.quantity}x @ ${formatter.format(item.price)}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                  Text(
                    formatter.format(item.subtotal > 0 ? item.subtotal : item.price * item.quantity),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildItemImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return const Center(child: Icon(Icons.fastfood_rounded, color: GageTheme.primary, size: 24));
    }
    final clean = imageUrl.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Image.network(
        clean,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const Center(child: Icon(Icons.fastfood_rounded, color: GageTheme.primary, size: 24)),
      );
    }
    return Image.asset(
      clean,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => const Center(child: Icon(Icons.fastfood_rounded, color: GageTheme.primary, size: 24)),
    );
  }

  Widget _buildDeliverySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alamat & Info Pengantaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tujuan Pengantaran', style: TextStyle(fontSize: 11, color: GageTheme.textSecondary)),
                    const SizedBox(height: 2),
                    Text(order.deliveryAddress, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.route_rounded, color: GageTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text('Estimasi Jarak: ${order.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: GageTheme.primaryLight,
            radius: 22,
            child: const Icon(Icons.delivery_dining_rounded, color: GageTheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.driverName ?? 'Driver GAGE', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                Text(order.driverPlate ?? 'Plat Motor Driver', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: GageTheme.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Menghubungi driver ${order.driverName ?? ""}...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rincian Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          const SizedBox(height: 12),
          _buildRowDetail('Subtotal Pesanan', formatter.format(order.itemsSubtotal)),
          const SizedBox(height: 6),
          _buildRowDetail('Biaya Ongkos Kirim', formatter.format(order.shippingFee)),
          if (order.shippingDiscount > 0) ...[
            const SizedBox(height: 6),
            _buildRowDetail('Diskon Ongkir', '- ${formatter.format(order.shippingDiscount)}', isDiscount: true),
          ],
          const SizedBox(height: 6),
          _buildRowDetail('Biaya Layanan & Admin', formatter.format(order.adminFee)),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text(
                formatter.format(order.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payment_rounded, size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      'Metode: ${_formatPaymentMethod(order.paymentMethod)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  order.paymentStatus == 'PAID' ? 'LUNAS' : 'BELUM BAYAR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: order.paymentStatus == 'PAID' ? Colors.green.shade700 : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowDetail(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDiscount ? const Color(0xFF16A34A) : Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GAGEPAY':
        return 'GAGE Pay';
      case 'QRIS':
        return 'QRIS Dinamis';
      case 'CASH_COD':
        return 'Tunai (COD)';
      default:
        return method;
    }
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: order.isActive
          ? SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text('Lacak Posisi Pesanan Real-time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GageTheme.primary,
                      side: const BorderSide(color: GageTheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      _reorder(context, order);
                    },
                    child: const Text('Pesan Lagi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bantuan CS WhatsApp GAGE siap melayani Anda 24/7.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Bantuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ),
              ],
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
}
