import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';

class GroupOrderScreen extends StatefulWidget {
  const GroupOrderScreen({super.key});

  @override
  State<GroupOrderScreen> createState() => _GroupOrderScreenState();
}

class _GroupOrderScreenState extends State<GroupOrderScreen> {
  final String _roomCode = 'GAGE-MAKAN-7892';
  int _spendingLimit = 35000;

  final List<Map<String, dynamic>> _members = [
    {
      'name': 'Aji (Kamu - Host)',
      'avatar': 'assets/images/avatar_user.png',
      'itemsCount': 2,
      'total': 26000,
      'isHost': true,
      'status': 'Siap Pesan',
    },
    {
      'name': 'Rosi (Keluarga)',
      'avatar': 'assets/images/cat_dimsum.png',
      'itemsCount': 1,
      'total': 14000,
      'isHost': false,
      'status': 'Siap Pesan',
    },
    {
      'name': 'Budi Santoso',
      'avatar': 'assets/images/cat_mie.png',
      'itemsCount': 0,
      'total': 0,
      'isHost': false,
      'status': 'Sedang Memilih...',
    },
  ];

  Future<void> _shareGroupOrder() async {
    final text = 'Yuk gabung Group Order GAGE Food! Klik tautan ini atau masukkan kode: $_roomCode di aplikasi GAGE.';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grandTotal = _members.fold<int>(0, (sum, m) => sum + (m['total'] as int));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Group Order GAGE Food', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Info Room & Invite Link
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE52320), Color(0xFFB51614)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
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
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.group_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Group Room Aktif', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Text(
                        _roomCode,
                        style: const TextStyle(color: GageTheme.accentYellow, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pesan Barengan, 1 Ongkir Sekecamatan!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Semua teman bisa pilih menu sendiri di HP masing-masing.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: GageTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 42),
                    ),
                    onPressed: _shareGroupOrder,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Undang Teman via WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Pengaturan Batas Belanja per Orang
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, color: GageTheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Batas Belanja per Orang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Maks Rp $_spendingLimit / anggota', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    DropdownButton<int>(
                      value: _spendingLimit,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 20000, child: Text('Rp 20.000', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 35000, child: Text('Rp 35.000', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 50000, child: Text('Rp 50.000', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 100000, child: Text('Tanpa Batas', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _spendingLimit = val);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Daftar Anggota & Status Pesanan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Anggota Group (${3})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${_members.where((m) => m['status'] == 'Siap Pesan').length} Siap Checkout', style: const TextStyle(color: GageTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),

            ..._members.map((m) {
              final isReady = m['status'] == 'Siap Pesan';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: GageTheme.primaryLight,
                      child: Text((m['name'] as String)[0], style: const TextStyle(fontWeight: FontWeight.bold, color: GageTheme.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('${m['itemsCount']} menu • Rp ${(m['total'] as int)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isReady ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        m['status'],
                        style: TextStyle(
                          color: isReady ? Colors.green.shade700 : Colors.deepOrange,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Tombol Buka Menu Resto
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                // Buka Resto Favorit Rocket Chicken
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => const RestoDetailScreen(
                      merchant: {
                        'id': 'mch-rc-01',
                        'name': 'Rocket Chicken Sambiroto, Pracimantoro',
                        'category': 'Cepat saji, Fried Chicken & Nasi',
                        'address': 'Sambiroto, Pracimantoro, Wonogiri',
                        'image': 'assets/images/resto_rocket_chicken.png',
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.restaurant_menu_rounded),
              label: Text('Pilih Menu Resto Barengan (Total: Rp $grandTotal)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
