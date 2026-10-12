import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

class MerchantScreen extends StatefulWidget {
  const MerchantScreen({super.key});

  @override
  State<MerchantScreen> createState() => _MerchantScreenState();
}

class _MerchantScreenState extends State<MerchantScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOpen = true;
  bool _isLoadingOrders = false;
  bool _isLoadingMenu = false;

  List<Map<String, dynamic>> _kitchenOrders = [];
  List<Map<String, dynamic>> _menuCatalog = [];

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _fetchKitchenOrders();
    _fetchMenuCatalog();
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

  Future<void> _fetchMenuCatalog() async {
    setState(() => _isLoadingMenu = true);
    final menus = await GageApiClient.getMerchantMenu('m-dimsum-sewu');
    if (!mounted) return;
    setState(() {
      _menuCatalog = menus;
      _isLoadingMenu = false;
    });
  }

  Future<void> _updateStage(Map<String, dynamic> order, String nextStage) async {
    final orderId = order['id']?.toString() ?? '';
    await GageApiClient.updateMerchantOrderStage(orderId, nextStage);
    _fetchKitchenOrders();
  }

  Future<void> _toggleStock(Map<String, dynamic> item) async {
    final itemId = item['id']?.toString() ?? '';
    final current = (item['is_available'] == 1 || item['is_available'] == true);
    final next = !current;
    setState(() {
      item['is_available'] = next ? 1 : 0;
    });
    await GageApiClient.toggleMerchantStock(itemId, next);
  }

  void _showPrintDialog(Map<String, dynamic> order) {
    final items = (order['items'] as List?) ?? [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cetak Tiket Dapur ESC/POS 58mm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: Text('=== TIKET DAPUR GAGE ===', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
              Center(child: Text('Pesanan: ${order['order_number'] ?? order['id']}', style: const TextStyle(fontFamily: 'monospace'))),
              const Divider(),
              for (var it in items)
                Text('${it['quantity'] ?? 1}x ${it['name']} (${currencyFormatter.format(it['price'] ?? 0)})', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              const Divider(),
              Text('Subtotal: ${currencyFormatter.format(order['items_subtotal'] ?? order['subtotal'] ?? 0)}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              Text('Alamat: ${order['delivery_address'] ?? '-'}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GageTheme.primary),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perintah cetak 58mm dikirim ke printer bluetooth.')));
            },
            child: const Text('Cetak Tiket', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GageTheme.background,
      appBar: AppBar(
        title: const Text('Portal Mitra Merchant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  _isOpen ? 'BUKA' : 'TUTUP',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _isOpen ? GageTheme.accentGreen : Colors.grey),
                ),
                const SizedBox(width: 6),
                Switch(
                  value: _isOpen,
                  activeThumbColor: GageTheme.accentGreen,
                  onChanged: (val) => setState(() => _isOpen = val),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: GageTheme.primary,
          unselectedLabelColor: GageTheme.textSecondary,
          indicatorColor: GageTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Pesanan Dapur'),
            Tab(text: 'Katalog Menu'),
            Tab(text: 'Kalkulator Harga'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKitchenOrdersTab(),
          _buildMenuCatalogTab(),
          _buildPricingCalculatorTab(),
        ],
      ),
    );
  }

  Widget _buildKitchenOrdersTab() {
    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_kitchenOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.soup_kitchen_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Dapur Bersih, Belum Ada Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                'Pesanan yang masuk dari pelanggan sekecamatan akan langsung tampil di layar ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: GageTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Segarkan Antrean'),
                onPressed: _fetchKitchenOrders,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _kitchenOrders.length,
      itemBuilder: (ctx, idx) {
        final order = _kitchenOrders[idx];
        final items = (order['items'] as List?) ?? [];
        final status = order['status']?.toString() ?? 'PAID';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order['order_number'] ?? order['id'] ?? 'Pesanan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'READY_FOR_PICKUP' ? Colors.green.shade50 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status == 'READY_FOR_PICKUP' ? 'SIAP DIAMBIL' : (status == 'COOKING' ? 'SEDANG DIMASAK' : 'PESANAN BARU'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: status == 'READY_FOR_PICKUP' ? GageTheme.accentGreen : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (var it in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text('${it['quantity'] ?? 1}x ${it['name']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 10),
                Text('Total: ${currencyFormatter.format(order['total_amount'] ?? order['subtotal'] ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                Row(
                  children: [
                    IconButton.outlined(
                      icon: const Icon(Icons.print, size: 18),
                      tooltip: 'Cetak Tiket',
                      onPressed: () => _showPrintDialog(order),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: GageTheme.primary),
                        onPressed: () {
                          if (status == 'PAID') {
                            _updateStage(order, 'COOKING');
                          } else if (status == 'COOKING') {
                            _updateStage(order, 'READY_FOR_PICKUP');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menunggu kurir mengambil pesanan.')));
                          }
                        },
                        child: Text(
                          status == 'PAID' ? 'Mulai Masak' : (status == 'COOKING' ? 'Siap Diambil Kurir' : 'Menunggu Kurir'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddMenuDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String category = 'Makanan';
    int offlinePrice = 0;
    int suggestedGage = 0;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                  'Menu akan langsung aktif di katalog Cloudflare D1 Dimsum Sewu.',
                  style: TextStyle(fontSize: 12, color: GageTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Menu',
                    border: OutlineInputBorder(),
                    hintText: 'Misal: Dimsum Rambutan Crispy',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Singkat',
                    border: OutlineInputBorder(),
                    hintText: 'Bahan, porsi, atau rasa',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Makanan', child: Text('Makanan')),
                          DropdownMenuItem(value: 'Minuman', child: Text('Minuman')),
                          DropdownMenuItem(value: 'Paket Hemat', child: Text('Paket Hemat')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => category = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga Warung Fisik',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          final num = int.tryParse(val) ?? 0;
                          setModalState(() {
                            offlinePrice = num;
                            suggestedGage = num > 0 ? ((num / 0.9) / 1000).ceil() * 1000 : 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (suggestedGage > 0) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Harga Aplikasi (Potong 10%):',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          currencyFormatter.format(suggestedGage),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: GageTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            final res = await GageApiClient.createMerchantMenu(
                              merchantId: 'm-dimsum-sewu',
                              name: name,
                              description: descCtrl.text.trim(),
                              category: category,
                              offlinePrice: offlinePrice,
                              gagePrice: suggestedGage,
                            );
                            if (!mounted) return;
                            navigator.pop();
                            if (res != null) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Menu "$name" berhasil ditambahkan ke Cloudflare D1.')),
                              );
                              _fetchMenuCatalog();
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Gagal menambahkan menu ke server.')),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Simpan Menu ke D1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCatalogTab() {
    if (_isLoadingMenu) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Katalog Menu (${_menuCatalog.length} Item)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Tambah Menu', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: _showAddMenuDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _menuCatalog.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final item = _menuCatalog[idx];
              final isAvailable = (item['is_available'] == 1 || item['is_available'] == true);

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              'Harga Online: ${currencyFormatter.format(item['gage_price'] ?? item['price'] ?? 0)}',
                              style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary),
                            ),
                            Text(
                              isAvailable ? 'Tersedia' : 'Habis Sementara',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isAvailable ? GageTheme.accentGreen : Colors.red),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isAvailable,
                        activeThumbColor: GageTheme.accentGreen,
                        onChanged: (_) => _toggleStock(item),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCalculatorTab() {
    int offlinePrice = 13500;
    int suggestedGage = 15000;
    int netPayout = 13500;

    return StatefulBuilder(
      builder: (ctx, setCalcState) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Kalkulator Harga Online UMKM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              'Hitung harga jual di aplikasi agar pendapatan bersih sama dengan harga warung fisik setelah potongan komisi 10%.',
              style: TextStyle(fontSize: 12, color: GageTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga Warung Offline (Rp)',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
              ),
              controller: TextEditingController(text: offlinePrice.toString()),
              onChanged: (val) {
                final num = int.tryParse(val) ?? 0;
                setCalcState(() {
                  offlinePrice = num;
                  suggestedGage = ((num / 0.9) / 1000).ceil() * 1000;
                  netPayout = (suggestedGage * 0.9).round();
                });
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rekomendasi Harga Gage', style: TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
                  Text(currencyFormatter.format(suggestedGage), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Penerimaan Bersih Resto (90%):', style: TextStyle(fontSize: 12)),
                      Text(currencyFormatter.format(netPayout), style: const TextStyle(fontWeight: FontWeight.bold, color: GageTheme.accentGreen)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
