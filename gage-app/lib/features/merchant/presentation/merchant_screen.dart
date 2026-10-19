import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_bottom_nav_bar.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/gage_standalone_banner.dart';

/// Screen Utama GAGE Merchant - Tab 0: Pesanan Dapur (Kitchen Display System / KDS)
/// Terinspirasi dari GoBiz & Kitchen Display Standar Industri F&B.
class MerchantScreen extends StatefulWidget {
  const MerchantScreen({super.key});

  @override
  State<MerchantScreen> createState() => _MerchantScreenState();
}

class _MerchantScreenState extends State<MerchantScreen> {
  bool _isOpen = true;
  bool _isLoadingOrders = false;
  String _selectedStage = 'SEMUA'; // 'SEMUA' | 'MASUK' | 'DIMASAK' | 'SIAP' | 'SELESAI'
  bool _printerConnected = true;

  List<Map<String, dynamic>> _kitchenOrders = [];
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchKitchenOrders();
  }

  Future<void> _fetchKitchenOrders() async {
    setState(() => _isLoadingOrders = true);
    final orders = await GageApiClient.getMerchantOrders('m-dimsum-sewu');
    if (!mounted) return;
    setState(() {
      _kitchenOrders = orders;
      _isLoadingOrders = false;
    });
  }

  Future<void> _updateStage(Map<String, dynamic> order, String nextStage) async {
    HapticFeedback.mediumImpact();
    final orderId = order['id']?.toString() ?? '';
    await GageApiClient.updateMerchantOrderStage(orderId, nextStage);
    _fetchKitchenOrders();
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedStage == 'SEMUA') return _kitchenOrders;
    if (_selectedStage == 'MASUK') {
      return _kitchenOrders.where((o) {
        final s = (o['status'] ?? '').toString().toUpperCase();
        return s == 'PAID' || s == 'NEW' || s == 'PENDING';
      }).toList();
    }
    if (_selectedStage == 'DIMASAK') {
      return _kitchenOrders.where((o) => (o['status'] ?? '').toString().toUpperCase() == 'COOKING').toList();
    }
    if (_selectedStage == 'SIAP') {
      return _kitchenOrders.where((o) => (o['status'] ?? '').toString().toUpperCase() == 'READY_FOR_PICKUP').toList();
    }
    if (_selectedStage == 'SELESAI') {
      return _kitchenOrders.where((o) {
        final s = (o['status'] ?? '').toString().toUpperCase();
        return s == 'COMPLETED' || s == 'DELIVERED';
      }).toList();
    }
    return _kitchenOrders;
  }

  void _showPrintDialog(Map<String, dynamic> order) {
    HapticFeedback.lightImpact();
    final items = (order['items'] as List?) ?? [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.print_rounded, color: GageTheme.primary, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Cetak Tiket Dapur 58mm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: Text('=== GAGE FOOD DAPUR ===', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13))),
              Center(child: Text('No: ${order['order_number'] ?? order['id']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
              Center(child: Text('Waktu: ${DateFormat('HH:mm:ss').format(DateTime.now())} WIB', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey))),
              const Divider(thickness: 1),
              for (var it in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('${it['quantity'] ?? 1}x ', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
                      Expanded(child: Text('${it['name']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                      Text(currencyFormatter.format((it['price'] ?? 0) * (it['quantity'] ?? 1)), style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                    ],
                  ),
                ),
              const Divider(thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('SUBTOTAL:', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(currencyFormatter.format(order['items_subtotal'] ?? order['subtotal'] ?? order['total_amount'] ?? 0), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Alamat: ${order['delivery_address'] ?? 'Pracimantoro'}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GageTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.print, size: 16, color: Colors.white),
            label: const Text('Kirim ke Thermal SPP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Perintah cetak tiket dapur dikirim ke printer bluetooth SPP.'),
                  backgroundColor: GageTheme.accentGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openChatWithDriver(Map<String, dynamic> order) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppChatScreen(
          orderId: order['order_number'] ?? order['id'] ?? 'ORD-9021',
          recipientName: 'Mas Budi (Kurir)',
          recipientRole: 'driver',
          recipientPhone: '6281234567890',
          currentRole: 'merchant',
        ),
      ),
    );
  }

  void _openChatWithCustomer(Map<String, dynamic> order) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppChatScreen(
          orderId: order['order_number'] ?? order['id'] ?? 'ORD-9021',
          recipientName: order['customer_name'] ?? 'Pelanggan GAGE',
          recipientRole: 'customer',
          recipientPhone: '6281987654321',
          currentRole: 'merchant',
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
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: GageTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.restaurant_rounded, color: GageTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Dimsum Sewu Pracimantoro',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _isOpen ? GageTheme.accentGreen : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isOpen ? 'Kios Buka • Siap Terima Pesanan' : 'Kios Tutup',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isOpen ? GageTheme.accentGreen : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Switch Buka / Tutup
          Switch(
            value: _isOpen,
            activeThumbColor: GageTheme.accentGreen,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              setState(() => _isOpen = val);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Pesanan',
            onPressed: _fetchKitchenOrders,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Sub-header: Status Thermal Printer & KDS Quick Stats
            _buildPrinterAndQuickStatsBar(isDark),

            // Standalone Merchant Info Banner (Managed via Cloudflare D1 Admin)
            const GageStandaloneBanner(
              screenTarget: 'merchant_home_info',
              margin: EdgeInsets.fromLTRB(16, 6, 16, 6),
            ),

            // KDS Stage Filter Chips
            _buildStageFilterChips(isDark),

            // Orders List
            Expanded(
              child: _isLoadingOrders
                  ? RefreshIndicator(
                      onRefresh: _fetchKitchenOrders,
                      color: GageTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 4,
                        itemBuilder: (ctx, idx) => const GageSkeletonKitchenOrderCard(),
                      ),
                    )
                  : _filteredOrders.isEmpty
                      ? _buildEmptyState(isDark)
                      : RefreshIndicator(
                          onRefresh: _fetchKitchenOrders,
                          color: GageTheme.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredOrders.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (ctx, idx) => _buildOrderCard(_filteredOrders[idx], isDark),
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MerchantBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildPrinterAndQuickStatsBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Printer thermal badge
          InkWell(
            onTap: () {
              setState(() => _printerConnected = !_printerConnected);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_printerConnected ? 'Thermal SPP 58mm Siap' : 'Thermal SPP Terputus'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _printerConnected
                    ? GageTheme.accentGreen.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _printerConnected
                      ? GageTheme.accentGreen.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.print_rounded,
                    size: 13,
                    color: _printerConnected ? GageTheme.accentGreen : Colors.orange.shade800,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _printerConnected ? 'SPP 58mm Terhubung' : 'Printer Offline',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _printerConnected ? GageTheme.accentGreen : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Total ringkasan antrean
          Row(
            children: [
              Text(
                '${_kitchenOrders.length} Pesanan Aktif',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageFilterChips(bool isDark) {
    final stages = [
      {'key': 'SEMUA', 'label': 'Semua', 'icon': Icons.all_inbox_rounded},
      {'key': 'MASUK', 'label': 'Masuk', 'icon': Icons.notifications_active_rounded},
      {'key': 'DIMASAK', 'label': 'Dimasak', 'icon': Icons.outdoor_grill_rounded},
      {'key': 'SIAP', 'label': 'Siap Diambil', 'icon': Icons.check_circle_rounded},
      {'key': 'SELESAI', 'label': 'Selesai', 'icon': Icons.task_alt_rounded},
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final stage = stages[idx];
          final isSelected = _selectedStage == stage['key'];

          return InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedStage = stage['key'] as String);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? GageTheme.primary
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? GageTheme.primary
                      : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    stage['icon'] as IconData,
                    size: 13,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    stage['label'] as String,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
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

  Widget _buildEmptyState(bool isDark) {
    return RefreshIndicator(
      onRefresh: _fetchKitchenOrders,
      color: GageTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(28.0),
        children: [
          const SizedBox(height: 60),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: GageTheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.soup_kitchen_rounded, size: 40, color: GageTheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedStage == 'SEMUA'
                      ? 'Dapur Bersih, Belum Ada Pesanan'
                      : 'Tidak Ada Pesanan di Tab "$_selectedStage"',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pesanan yang masuk dari pelanggan Pracimantoro akan langsung muncul secara instan di layar ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: GageTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Segarkan Antrean'),
                  onPressed: _fetchKitchenOrders,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isDark) {
    final status = (order['status'] ?? 'PAID').toString().toUpperCase();
    final items = (order['items'] as List?) ?? [];
    final orderNumber = order['order_number'] ?? order['id'] ?? 'ORD-9021';
    final customerName = order['customer_name'] ?? 'Pelanggan GAGE';
    final totalAmount = order['total_amount'] ?? order['subtotal'] ?? 0;
    final notes = order['notes']?.toString();

    // Stage tag styling
    Color badgeColor;
    Color badgeTextColor;
    String badgeText;

    if (status == 'COOKING') {
      badgeColor = Colors.orange.shade50;
      badgeTextColor = Colors.orange.shade800;
      badgeText = 'SEDANG DIMASAK';
    } else if (status == 'READY_FOR_PICKUP') {
      badgeColor = const Color(0xFFDCFCE7);
      badgeTextColor = const Color(0xFF16A34A);
      badgeText = 'SIAP DIAMBIL KURIR';
    } else if (status == 'COMPLETED' || status == 'DELIVERED') {
      badgeColor = const Color(0xFFEFF6FF);
      badgeTextColor = const Color(0xFF2563EB);
      badgeText = 'SELESAI';
    } else {
      badgeColor = Colors.amber.shade50;
      badgeTextColor = Colors.amber.shade900;
      badgeText = 'PESANAN BARU';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'PAID' || status == 'NEW'
              ? GageTheme.primary.withValues(alpha: 0.3)
              : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
          width: status == 'PAID' || status == 'NEW' ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Header: Nomor Order, Status Badge & Print Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeTextColor),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.print_outlined, size: 20, color: GageTheme.primary),
                tooltip: 'Cetak Tiket Dapur',
                onPressed: () => _showPrintDialog(order),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Pelanggan info & Action Chat Pelanggan
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: GageTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                customerName,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _openChatWithCustomer(order),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: GageTheme.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 12, color: GageTheme.primary),
                      SizedBox(width: 4),
                      Text('Chat Pelanggan', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 18),

          // Item List Dapur
          for (var it in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${it['quantity'] ?? 1}x',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${it['name']}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    currencyFormatter.format((it['price'] ?? 0) * (it['quantity'] ?? 1)),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note_alt_outlined, size: 14, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan: $notes',
                      style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Total & Kurir Status
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran:', style: TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
                    Text(
                      currencyFormatter.format(totalAmount),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: GageTheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Driver bar
                Row(
                  children: [
                    const Icon(Icons.two_wheeler_rounded, size: 16, color: GageTheme.accentGreen),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Kurir: Mas Budi • AB 4521 WZ',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    InkWell(
                      onTap: () => _openChatWithDriver(order),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: GageTheme.accentGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.chat_rounded, size: 11, color: GageTheme.accentGreen),
                            SizedBox(width: 4),
                            Text('Chat Driver', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GageTheme.accentGreen)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse('https://wa.me/6281234567890');
                        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.call_rounded, size: 14, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tombol Aksi KDS GoBiz
          Row(
            children: [
              if (status == 'PAID' || status == 'NEW') ...[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pesanan ditolak karena bahan habis.')),
                      );
                    },
                    child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _updateStage(order, 'COOKING'),
                    child: const Text('Terima & Mulai Masak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ] else if (status == 'COOKING') ...[
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.accentGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _updateStage(order, 'READY_FOR_PICKUP'),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Pesanan Siap Diambil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ] else if (status == 'READY_FOR_PICKUP') ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GageTheme.primary,
                      side: const BorderSide(color: GageTheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.notifications_active_rounded, size: 16),
                    label: const Text('Panggil Driver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifikasi siap ambil dikirimkan ke HP Driver.'),
                          backgroundColor: GageTheme.accentGreen,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _updateStage(order, 'COMPLETED'),
                    child: const Text('Driver Mengambil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Pesanan Selesai Diantar',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
