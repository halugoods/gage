import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_bottom_nav_bar.dart';

/// Screen Profil Kios & Pengaturan Operasional Merchant - Tab 4
/// Mengatur jam buka-tutup toko, printer bluetooth thermal, waktu masak, dan pusat bantuan.
class MerchantProfileScreen extends StatefulWidget {
  const MerchantProfileScreen({super.key});

  @override
  State<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends State<MerchantProfileScreen> {
  bool _isOpen = true;
  bool _autoPrint = true;
  int _cookingTime = 15;
  double _deliveryRadius = 7.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Text(
          'Kios & Pengaturan Mitra',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Profil Outlet Dimsum Sewu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: GageTheme.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.store_mall_directory_rounded, color: GageTheme.primary, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Dimsum Sewu',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: GageTheme.accentGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'TERVERIFIKASI',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: GageTheme.accentGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Jl. Raya Pracimantoro No. 14, Depan Pasar',
                          style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'ID Mitra: M-DIMSUM-SEWU • Owner: Mas Wahyu',
                          style: TextStyle(fontSize: 10.5, color: GageTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. Tiga Metrik Performa Resto
            Row(
              children: [
                Expanded(child: _buildStatTile('Rating Resto', '4.9 ★', '120+ Ulasan', isDark)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatTile('Tepat Waktu', '99.2%', 'Standar SOP', isDark)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatTile('Waktu Masak', '14 Mnt', 'Rata-rata', isDark)),
              ],
            ),

            const SizedBox(height: 18),

            // 3. Status Operasional Toko
            const Text(
              'Status & Jam Operasional',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Buka Kios untuk Pesanan Masuk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text(
                      _isOpen ? 'Outlet tampil aktif di katalog pelanggan GAGE' : 'Outlet ditandai tutup sementara',
                      style: const TextStyle(fontSize: 11.5, color: GageTheme.textSecondary),
                    ),
                    value: _isOpen,
                    activeThumbColor: GageTheme.accentGreen,
                    onChanged: (v) {
                      HapticFeedback.lightImpact();
                      setState(() => _isOpen = v);
                    },
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.access_time_rounded, color: GageTheme.primary, size: 20),
                    title: Text('Jam Buka Reguler', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('Setiap Hari: 09:00 - 21:00 WIB', style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimasi Waktu Masak Default:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('$_cookingTime Menit', style: const TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [10, 15, 20, 25].map((mins) {
                            final isSel = _cookingTime == mins;
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _cookingTime = mins);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSel ? GageTheme.primary : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$mins mnt',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4. Pengaturan Printer Kasir Bluetooth SPP
            const Text(
              'Printer Struk & Tiket Thermal',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.print_rounded, color: GageTheme.primary, size: 22),
                    title: Text('Printer SPP Bluetooth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text('Thermal 58mm (RPP02N / Iware / Panda)', style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
                    trailing: Text('TERHUBUNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: GageTheme.accentGreen)),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Auto-Print Tiket Dapur', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: const Text('Cetak tiket otomatis saat pesanan baru masuk', style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
                    value: _autoPrint,
                    activeThumbColor: GageTheme.primary,
                    onChanged: (v) => setState(() => _autoPrint = v),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: const Text('Uji Cetak Sample 58mm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test print 58mm dikirim ke printer bluetooth SPP.'),
                            backgroundColor: GageTheme.accentGreen,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 5. Radius Pengantaran Slider
            const Text(
              'Jangkauan Pesan Antar',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Radius Layanan:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${_deliveryRadius.toStringAsFixed(1)} KM', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: GageTheme.primary)),
                    ],
                  ),
                  Slider(
                    value: _deliveryRadius,
                    min: 2.0,
                    max: 12.0,
                    divisions: 10,
                    activeColor: GageTheme.primary,
                    label: '${_deliveryRadius.toStringAsFixed(1)} KM',
                    onChanged: (v) => setState(() => _deliveryRadius = v),
                  ),
                  const Text(
                    'Menjangkau seluruh pelosok desa di Pracimantoro dan sekitarnya.',
                    style: TextStyle(fontSize: 11, color: GageTheme.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 6. Pusat Bantuan & WhatsApp Center
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_rounded, color: Colors.green, size: 20),
                    ),
                    title: const Text('WhatsApp Layanan Mitra GAGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: const Text('Bantuan kendala pesanan, menu, atau settlement dana', style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    onTap: () async {
                      final uri = Uri.parse('https://wa.me/628111222333?text=Halo%20Admin%20GAGE,%20saya%20mitra%20Dimsum%20Sewu');
                      if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const MerchantBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildStatTile(String label, String value, String subtitle, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: GageTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: GageTheme.primary)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9.5, color: GageTheme.textSecondary)),
        ],
      ),
    );
  }
}
