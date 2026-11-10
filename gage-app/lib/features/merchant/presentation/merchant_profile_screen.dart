import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_bottom_nav_bar.dart';
import 'package:gage_app/features/merchant/presentation/merchant_menu_screen.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

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

  String _storeName = 'Dimsum Sewu';
  String _storeAddress = 'Jl. Raya Pracimantoro No. 14, Depan Pasar';
  String _storeBio = 'Spesialis Dimsum Kukus & Goreng Hangat Gurih';
  String _storeBanner = 'assets/images/resto_dimsum_sewu.png';
  String _storeLogo = 'assets/images/resto_dimsum_sewu.png';

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
            // 1. Profil Outlet & Banner Kios Mitra (Self-Managed)
            Container(
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
                  // Store Hero Banner with Edit Pill
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: _storeBanner.startsWith('http')
                            ? Image.network(_storeBanner, height: 110, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallbackBanner())
                            : Image.asset(_storeBanner, height: 110, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallbackBanner()),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: _showEditStoreProfileSheet,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Ganti Banner', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 14,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: ClipOval(
                            child: _storeLogo.startsWith('http')
                                ? Image.network(_storeLogo, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 28))
                                : Image.asset(_storeLogo, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 28)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _storeName,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
                        Text(
                          _storeAddress,
                          style: const TextStyle(fontSize: 11.5, color: GageTheme.textSecondary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _storeBio,
                          style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showEditStoreProfileSheet,
                                icon: const Icon(Icons.edit_note_rounded, size: 16),
                                label: const Text('Edit Profil & Banner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: GageTheme.primary,
                                  side: const BorderSide(color: GageTheme.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (ctx) => const MerchantMenuScreen()),
                                  );
                                },
                                icon: const Icon(Icons.restaurant_menu_rounded, size: 16),
                                label: const Text('Katalog Menu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GageTheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
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
  static Widget _fallbackBanner() => Container(
        height: 110,
        color: GageTheme.primaryLight,
        child: const Center(
          child: Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 36),
        ),
      );

  void _showEditStoreProfileSheet() {
    final nameCtrl = TextEditingController(text: _storeName);
    final addrCtrl = TextEditingController(text: _storeAddress);
    final bioCtrl = TextEditingController(text: _storeBio);
    String currentBanner = _storeBanner;
    String currentLogo = _storeLogo;

    final presetBanners = [
      {'label': 'Kuliner Resto', 'path': 'assets/images/resto_dimsum_sewu.png'},
      {'label': 'Sembako Shop', 'path': 'assets/images/resto_dimsum_sewu.png'},
      {'label': 'Pertanian Farm', 'path': 'assets/images/resto_dimsum_sewu.png'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              top: 16,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Kelola Profil & Banner Toko', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Perubahan otomatis tampil di halaman detail toko pelanggan.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Toko / Kios',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addrCtrl,
                    decoration: InputDecoration(
                      labelText: 'Alamat Lengkap Toko',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bioCtrl,
                    decoration: InputDecoration(
                      labelText: 'Bio / Deskripsi Singkat Toko',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Pilih Banner Toko:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: presetBanners.map((b) {
                        final isSel = currentBanner == b['path'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(b['label']!),
                            selected: isSel,
                            onSelected: (_) => setSheetState(() => currentBanner = b['path']!),
                            selectedColor: GageTheme.primary.withValues(alpha: 0.15),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: () {
                        setState(() {
                          _storeName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _storeName;
                          _storeAddress = addrCtrl.text.trim().isNotEmpty ? addrCtrl.text.trim() : _storeAddress;
                          _storeBio = bioCtrl.text.trim().isNotEmpty ? bioCtrl.text.trim() : _storeBio;
                          _storeBanner = currentBanner;
                          _storeLogo = currentLogo;
                        });
                        Navigator.pop(ctx);
                        GageToast.show(context, 'Profil & banner toko berhasil disimpan!', type: GageToastType.success);
                      },
                      child: const Text('Simpan Profil & Banner Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
}
