import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';

/// Screen Order 3 Jalur & Manual Dispatch - Tab 1
/// Mengintegrasikan antrean pesanan dari 3 Kanal: Aplikasi, Web Toko, dan WhatsApp/Telepon.
class AdminOrderDispatchScreen extends StatefulWidget {
  const AdminOrderDispatchScreen({super.key});

  @override
  State<AdminOrderDispatchScreen> createState() => _AdminOrderDispatchScreenState();
}

class _AdminOrderDispatchScreenState extends State<AdminOrderDispatchScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  String _selectedChannel = 'Semua';

  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'ORD-9021',
      'channel': 'APP',
      'service': 'GageFood',
      'customer': 'Mba Siti Rahayu',
      'phone': '6281987654321',
      'merchant': 'Dimsum Sewu Pracimantoro',
      'pickup': 'Jl. Raya Pracimantoro No. 14',
      'dropoff': 'Dusun Gebang Kulon RT 02/04',
      'items': '2x Dimsum Siomay, 1x Es Teh Jumbo',
      'total': 35000,
      'status': 'Dalam Pengantaran',
      'driver': 'Mas Budi Santoso',
      'time': '12:45 WIB',
    },
    {
      'id': 'WA-8804',
      'channel': 'WHATSAPP',
      'service': 'GageSend',
      'customer': 'Pak Haji Marwan',
      'phone': '6281233445566',
      'merchant': 'Toko Bangunan Berkah Jaya',
      'pickup': 'Depan Koramil Pracimantoro',
      'dropoff': 'Desa Tubokarto RT 01',
      'items': 'Titip Antar 1 Sak Semen Gresik + Paku 5cm',
      'total': 68000,
      'status': 'Menunggu Driver',
      'driver': 'Belum Ditugaskan',
      'time': '12:38 WIB',
    },
    {
      'id': 'WEB-1049',
      'channel': 'WEB',
      'service': 'GageShop',
      'customer': 'Ibu Nurhayati',
      'phone': '6285788990011',
      'merchant': 'Kios Sayur Segar Bu Slamet',
      'pickup': 'Pasar Pracimantoro Los A',
      'dropoff': 'Perumahan Griya Praci Indah Blok B4',
      'items': '1kg Bawang Merah, 2 Ikat Bayam, 1kg Telur',
      'total': 48000,
      'status': 'Dalam Pengantaran',
      'driver': 'Mas Agus Setiawan',
      'time': '12:20 WIB',
    },
    {
      'id': 'WA-8803',
      'channel': 'WHATSAPP',
      'service': 'GageRide',
      'customer': 'Mas Wahyu Hidayat',
      'phone': '6289988776655',
      'merchant': '-',
      'pickup': 'Stasiun Kereta Solo (Jemput Luar Kota)',
      'dropoff': 'Pracimantoro Kota (Pulang Kampung)',
      'items': 'Carter Mobil Avanza 4 Penumpang + Koper',
      'total': 250000,
      'status': 'Driver Standby',
      'driver': 'Pak Joko Purnomo',
      'time': '11:55 WIB',
    },
  ];

  void _showManualOrderEntryModal() {
    HapticFeedback.lightImpact();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pickupCtrl = TextEditingController(text: 'Pracimantoro Kota');
    final dropoffCtrl = TextEditingController();
    final itemsCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    String service = 'GageFood';
    String assignedDriver = 'Mas Budi Santoso (Motor)';

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
                const Row(
                  children: [
                    Icon(Icons.chat_rounded, color: Colors.green, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Input Order Manual WhatsApp',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Masukkan pesanan yang masuk lewat chat WhatsApp atau telepon langsung dari pelanggan.',
                  style: TextStyle(fontSize: 12, color: GageTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // Form Fields
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nama Pemesan',
                          hintText: 'Misal: Pak Joko',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Nomor WhatsApp',
                          hintText: '08123456789',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: service,
                  decoration: InputDecoration(
                    labelText: 'Jenis Layanan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'GageFood', child: Text('GageFood (Makanan / Minuman)')),
                    DropdownMenuItem(value: 'GageRide', child: Text('GageRide (Ojek Motor)')),
                    DropdownMenuItem(value: 'GageCar', child: Text('GageCar (Antar Jemput Mobil)')),
                    DropdownMenuItem(value: 'GageSend', child: Text('GageSend (Titip Beli / Kirim Paket)')),
                    DropdownMenuItem(value: 'GageClean', child: Text('GageClean (Pengangkutan Sampah)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => service = val);
                  },
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: pickupCtrl,
                  decoration: InputDecoration(
                    labelText: 'Lokasi Jemput / Beli',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: dropoffCtrl,
                  decoration: InputDecoration(
                    labelText: 'Lokasi Antar / Rumah Pemesan',
                    hintText: 'Dusun, Desa, RT/RW di Pracimantoro',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: itemsCtrl,
                  decoration: InputDecoration(
                    labelText: 'Rincian Barang / Pesanan',
                    hintText: 'Catatan belanjaan atau barang yang dititipkan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: totalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Ongkir / Total Biaya',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: assignedDriver,
                        decoration: InputDecoration(
                          labelText: 'Tugaskan Driver',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Mas Budi Santoso (Motor)', child: Text('Budi (Motor)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Pak Joko Purnomo (Mobil)', child: Text('Joko (Mobil)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Mas Agus Setiawan (Motor)', child: Text('Agus (Motor)', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'Auto Dispatch (Broadcast)', child: Text('Auto Broadcast', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => assignedDriver = val);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final drop = dropoffCtrl.text.trim();
                      if (name.isEmpty || drop.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nama dan lokasi tujuan wajib diisi.')),
                        );
                        return;
                      }

                      final newOrder = {
                        'id': 'WA-${DateTime.now().millisecondsSinceEpoch % 10000}',
                        'channel': 'WHATSAPP',
                        'service': service,
                        'customer': name,
                        'phone': phoneCtrl.text.trim(),
                        'merchant': '-',
                        'pickup': pickupCtrl.text.trim(),
                        'dropoff': drop,
                        'items': itemsCtrl.text.trim().isNotEmpty ? itemsCtrl.text.trim() : 'Pesanan via WhatsApp',
                        'total': int.tryParse(totalCtrl.text) ?? 15000,
                        'status': 'Driver Ditugaskan',
                        'driver': assignedDriver,
                        'time': '${DateFormat('HH:mm').format(DateTime.now())} WIB',
                      };

                      setState(() {
                        _orders.insert(0, newOrder);
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Order WhatsApp "${newOrder['id']}" berhasil dibuat & didispatch ke $assignedDriver.'),
                          backgroundColor: GageTheme.accentGreen,
                        ),
                      );
                    },
                    child: const Text('Simpan & Dispatch ke Driver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedChannel == 'Semua') return _orders;
    return _orders.where((o) => o['channel'] == _selectedChannel).toList();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Transaksi',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              'Pantauan & Catatan Pesanan Seluruh Kanal',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Riwayat',
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Riwayat pesanan telah disegarkan.'), duration: Duration(seconds: 1)),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Sub-bar Kanal Metrics
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildChannelSummary(
                          name: 'Aplikasi',
                          percent: '72%',
                          color: GageTheme.primary,
                          icon: Icons.phone_android_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildChannelSummary(
                          name: 'Web Toko',
                          percent: '18%',
                          color: const Color(0xFF2563EB),
                          icon: Icons.language_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildChannelSummary(
                          name: 'WhatsApp',
                          percent: '10%',
                          color: Colors.green.shade700,
                          icon: Icons.chat_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.white),
                      label: const Text(
                        'Input Order Manual WhatsApp / Telepon',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      onPressed: _showManualOrderEntryModal,
                    ),
                  ),
                ],
              ),
            ),

            // Channel Filter Bar
            Container(
              height: 46,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: ['Semua', 'APP', 'WEB', 'WHATSAPP'].length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final ch = ['Semua', 'APP', 'WEB', 'WHATSAPP'][idx];
                  final isSelected = _selectedChannel == ch;

                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedChannel = ch);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? GageTheme.primary : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          ch == 'APP' ? 'Aplikasi Mobile' : (ch == 'WHATSAPP' ? 'WhatsApp Manual' : (ch == 'WEB' ? 'Web Storefront' : 'Semua Kanal')),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Order Stream
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: _filteredOrders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) => _buildOrderTile(_filteredOrders[idx], isDark),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildChannelSummary({
    required String name,
    required String percent,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: GageTheme.textSecondary), maxLines: 1),
                Text(percent, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTile(Map<String, dynamic> o, bool isDark) {
    final channel = o['channel'] as String;
    Color channelColor;
    String channelLabel;
    if (channel == 'WHATSAPP') {
      channelColor = Colors.green.shade700;
      channelLabel = 'WHATSAPP';
    } else if (channel == 'WEB') {
      channelColor = const Color(0xFF2563EB);
      channelLabel = 'WEB';
    } else {
      channelColor = GageTheme.primary;
      channelLabel = 'APP';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: channelColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(channelLabel, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(o['id'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  const SizedBox(width: 6),
                  Text('• ${o['service']}', style: const TextStyle(fontSize: 11, color: GageTheme.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
              Text(o['time'] as String, style: const TextStyle(fontSize: 10.5, color: GageTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 14, color: GageTheme.textSecondary),
              const SizedBox(width: 4),
              Text(o['customer'] as String, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(currencyFormatter.format(o['total']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: GageTheme.primary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            o['items'] as String,
            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.pin_drop_rounded, size: 12, color: Colors.red),
              const SizedBox(width: 4),
              Expanded(
                child: Text('Tujuan: ${o['dropoff']}', style: const TextStyle(fontSize: 11, color: GageTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.two_wheeler_rounded, size: 14, color: GageTheme.accentGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Driver: ${o['driver']}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (channel == 'WHATSAPP')
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse('https://wa.me/${o['phone']}');
                    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.chat_rounded, size: 11, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Hubungi Pemesan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
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
}
