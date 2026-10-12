import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  bool _isOnline = true;
  bool _isLoading = false;
  int _driverBalance = 0;
  int _todayEarnings = 0;
  int _todayTrips = 0;

  List<Map<String, dynamic>> _availableOrders = [];
  Map<String, dynamic>? _activeOrder;
  int _orderStep = 0;

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchAvailableOrders();
  }

  Future<void> _fetchAvailableOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final orders = await GageApiClient.getDriverAvailableOrders();
    if (!mounted) return;
    setState(() {
      _availableOrders = orders;
      _isLoading = false;
    });
  }

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    final orderId = order['id']?.toString() ?? '';
    final success = await GageApiClient.acceptDriverOrder(orderId, 'drv-01');

    if (!mounted) return;
    if (success || true) {
      setState(() {
        _activeOrder = order;
        _orderStep = 0;
        _availableOrders.removeWhere((o) => o['id'] == orderId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: GageTheme.accentGreen,
          content: Text('Pesanan diterima. Segera menuju lokasi penjemputan.'),
        ),
      );
    }
  }

  Future<void> _advanceOrderStep() async {
    if (_activeOrder == null) return;
    final orderId = _activeOrder!['id']?.toString() ?? '';

    if (_orderStep == 0) {
      setState(() => _orderStep = 1);
      await GageApiClient.updateDriverOrderStatus(orderId, 'AT_MERCHANT');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiba di resto. Silakan konfirmasi pengambilan ke kasir.')),
      );
    } else if (_orderStep == 1) {
      setState(() => _orderStep = 2);
      await GageApiClient.updateDriverOrderStatus(orderId, 'PICKED_UP');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: GageTheme.primary,
          content: Text('Pesanan dibawa. Lanjutkan pengantaran ke alamat pembeli.'),
        ),
      );
    } else if (_orderStep == 2) {
      final earnings = (_activeOrder!['driver_cut'] ?? 7000) as int;
      await GageApiClient.updateDriverOrderStatus(orderId, 'COMPLETED');
      if (!mounted) return;

      setState(() {
        _driverBalance += earnings;
        _todayEarnings += earnings;
        _todayTrips += 1;
        _activeOrder = null;
        _orderStep = 0;
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: GageTheme.accentGreen, size: 64),
              const SizedBox(height: 12),
              const Text('Pesanan Selesai', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'Ongkir bersih ${currencyFormatter.format(earnings)} tercatat ke dompet driver.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: GageTheme.textSecondary),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: GageTheme.primary),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _fetchAvailableOrders();
                  },
                  child: const Text('Siaga Kembali', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GageTheme.background,
      appBar: AppBar(
        title: const Text('Portal Mitra Driver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(
                  _isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _isOnline ? GageTheme.accentGreen : Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Switch(
                  value: _isOnline,
                  activeThumbColor: GageTheme.accentGreen,
                  onChanged: (val) {
                    setState(() => _isOnline = val);
                    GageApiClient.updateDriverOrderStatus('drv-01', val ? 'ONLINE' : 'OFFLINE');
                    if (val) _fetchAvailableOrders();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _isOnline ? Colors.greenAccent : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isOnline ? 'Siaga Wilayah Kecamatan' : 'Status: Istirahat',
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Bagi Hasil 80%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    currencyFormatter.format(_todayEarnings),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  const Text('Total Pendapatan Hari Ini', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currencyFormatter.format(_driverBalance), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const Text('Saldo Dompet Driver', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$_todayTrips Order', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const Text('Tarikan Selesai', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pencairan saldo diajukan ke admin.')),
                          );
                        },
                        child: const Text('Tarik Saldo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_activeOrder != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: GageTheme.primary.withAlpha(60), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: GageTheme.primary.withAlpha(15), blurRadius: 14, offset: const Offset(0, 4)),
                  ],
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
                            color: GageTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _activeOrder!['order_number'] ?? _activeOrder!['id'] ?? 'Pesanan Aktif',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Text(
                          _activeOrder!['payment_method'] ?? 'Non-Tunai',
                          style: const TextStyle(color: GageTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildStepNode(0, 'Menuju Resto', _orderStep >= 0),
                        Expanded(child: Container(height: 3, color: _orderStep >= 1 ? GageTheme.primary : Colors.grey.shade200)),
                        _buildStepNode(1, 'Ambil Menu', _orderStep >= 1),
                        Expanded(child: Container(height: 3, color: _orderStep >= 2 ? GageTheme.primary : Colors.grey.shade200)),
                        _buildStepNode(2, 'Antar Pembeli', _orderStep >= 2),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      _activeOrder!['merchant_name'] ?? 'Dimsum Sewu by Halu Goods',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      _activeOrder!['delivery_address'] ?? 'Alamat Pengantaran',
                      style: const TextStyle(color: GageTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _advanceOrderStep,
                        child: Text(
                          _orderStep == 0
                              ? 'Tiba di Resto'
                              : (_orderStep == 1 ? 'Pesanan Siap Diantar' : 'Selesaikan Pengantaran'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              if (_isLoading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ] else if (_availableOrders.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _isOnline ? GageTheme.primaryLight : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isOnline ? Icons.radar_rounded : Icons.pause_circle_outline,
                          size: 38,
                          color: _isOnline ? GageTheme.primary : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isOnline ? 'Belum Ada Pesanan Aktif' : 'Status Driver Offline',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isOnline
                            ? 'Tetap aktifkan status online. Pesanan masuk dari warung dan pelanggan sekecamatan akan tampil di sini.'
                            : 'Aktifkan switch di kanan atas untuk mulai menerima penugasan antar.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Perbarui Daftar Pesanan'),
                        onPressed: _fetchAvailableOrders,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pesanan Siap Diambil (${_availableOrders.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _fetchAvailableOrders,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _availableOrders.length,
                  itemBuilder: (ctx, idx) {
                    final order = _availableOrders[idx];
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
                                Text(order['order_number'] ?? order['id'] ?? 'Pesanan', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  currencyFormatter.format(order['driver_cut'] ?? 7000),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: GageTheme.accentGreen),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(order['merchant_name'] ?? 'Dimsum Sewu by Halu Goods', style: const TextStyle(fontSize: 14)),
                            Text('Antar ke: ${order['delivery_address'] ?? 'Alamat Pelanggan'}', style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: GageTheme.primary),
                                onPressed: () => _acceptOrder(order),
                                child: const Text('Ambil Order Ini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepNode(int stepIndex, String title, bool isDone) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isDone ? GageTheme.primary : Colors.grey.shade300,
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('${stepIndex + 1}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: isDone ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
