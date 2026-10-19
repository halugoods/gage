import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';

/// Screen Kurasi & Verifikasi Mitra - Tab 3
/// Standar iOS Inset Grouped & GoPartner:
/// 1. Kurasi Fisik Barang Bekas (BaBe) sebelum tayang ke katalog publik
/// 2. Verifikasi Pendaftaran Mitra Toko & Resto Baru di Pracimantoro
class AdminCurationScreen extends StatefulWidget {
  const AdminCurationScreen({super.key});

  @override
  State<AdminCurationScreen> createState() => _AdminCurationScreenState();
}

class _AdminCurationScreenState extends State<AdminCurationScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  int _curationTab = 0; // 0: Barang Bekas, 1: Mitra Toko & Resto
  String _statusFilter = 'Menunggu';

  // Data Pengajuan BaBe
  final List<Map<String, dynamic>> _babeSubmissions = [
    {
      'id': 'BABE-001',
      'name': 'iPad Gen 9 64GB Space Grey WiFi Mulus',
      'category': 'Gadget & Elektronik',
      'sellerName': 'Pak Joko Purnomo',
      'sellerPhone': '6281234567890',
      'netPrice': 3200000,
      'appPrice': 3550000,
      'status': 'Menunggu',
      'specs': 'Baterai Health 91%, layar jernih tanpa baret, tombol home normal, box + charger ori lengkap.',
      'location': 'Dusun Gedong RT 02/01 Pracimantoro',
      'surveyNote': 'Kurir terdekat: Mas Agus Setiawan siap cek fisik jam 14:00 WIB.',
    },
    {
      'name': 'Sepeda Lipat Pacific Noris 2.1 20 Inch 8 Speed',
      'id': 'BABE-002',
      'category': 'Sepeda & Hobi',
      'sellerName': 'Mas Budi Santoso',
      'sellerPhone': '6285712345678',
      'netPrice': 1600000,
      'appPrice': 1780000,
      'status': 'Menunggu',
      'specs': 'Warna hitam doff, lipatan presisi tidak goyang, ban Kenda 90%, sadel gel empuk.',
      'location': 'Ruko Depan Koramil Pracimantoro',
      'surveyNote': 'Unit disimpan di ruko, pemilik ada di tempat tiap jam kerja.',
    },
    {
      'name': 'Kompresor Angin Lakoni Imola 75 3/4 HP Silent',
      'id': 'BABE-003',
      'category': 'Alat Usaha & Bengkel',
      'sellerName': 'Bpk. Slamet Riyadi',
      'sellerPhone': '6289876543210',
      'netPrice': 750000,
      'appPrice': 835000,
      'status': 'Disetujui',
      'specs': 'Pengisian cepat 0-8 bar dalam 2 menit, oli mesin baru, bonus selang spiral 6 meter.',
      'location': 'Pasar Pracimantoro Blok B',
      'surveyNote': 'Sudah dicek fisik oleh kurir Budi Santoso. Mesin mulus dan berfungsi normal.',
    },
  ];

  // Data Pengajuan Pendaftaran Mitra Toko & Resto
  final List<Map<String, dynamic>> _merchantSubmissions = [
    {
      'id': 'MCH-REQ-101',
      'storeName': 'Ayam Geprek Sambal Korek Bu Sri',
      'category': 'GageFood • Kuliner Siap Saji',
      'ownerName': 'Ibu Sri Wahyuni',
      'phone': '6281322334455',
      'address': 'Jl. Lintas Selatan KM 1 (Dekat Alfamart)',
      'menuCount': 8,
      'status': 'Menunggu',
      'notes': 'Foto menu makanan sudah diupload, jam buka 09:00 - 20:00 WIB. Butuh aktivasi KDS.',
    },
    {
      'id': 'MCH-REQ-102',
      'storeName': 'Kios Pupuk & Bibit Tani Makmur',
      'category': 'GageTani • Saprotan & Bibit',
      'ownerName': 'Pak Wardoyo',
      'phone': '6285299887766',
      'address': 'Desa Sedayu RT 03/02 Pracimantoro',
      'menuCount': 14,
      'status': 'Menunggu',
      'notes': 'Menyediakan pupuk organik, bibit jagung hibrida & pestisida resmi. Siap kirim via GageSend.',
    },
    {
      'id': 'MCH-REQ-103',
      'storeName': 'Dimsum Sewu Mas Agus',
      'category': 'GageFood • Camilan & Frozen',
      'ownerName': 'Mas Agus Setiawan',
      'phone': '6289911223344',
      'address': 'Jl. Raya Pracimantoro No. 14',
      'menuCount': 12,
      'status': 'Disetujui',
      'notes': 'Printer bluetooth SPP 58mm sudah terpasang dan berhasil cetak struk pesanan.',
    },
  ];

  List<Map<String, dynamic>> get _currentFilteredList {
    final source = _curationTab == 0 ? _babeSubmissions : _merchantSubmissions;
    if (_statusFilter == 'Semua') return source;
    return source.where((item) => item['status'] == _statusFilter).toList();
  }

  void _approve(Map<String, dynamic> item) {
    HapticFeedback.mediumImpact();
    setState(() => item['status'] = 'Disetujui');
    final name = _curationTab == 0 ? item['name'] : item['storeName'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$name" berhasil disetujui & aktif di ekosistem GAGE.'),
        backgroundColor: const Color(0xFF00AA13),
      ),
    );
  }

  void _reject(Map<String, dynamic> item) {
    HapticFeedback.lightImpact();
    setState(() => item['status'] = 'Ditolak');
    final name = _curationTab == 0 ? item['name'] : item['storeName'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$name" ditolak.')),
    );
  }

  Future<void> _callWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
              'Kurasi & Verifikasi Mitra',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              'Verifikasi Barang Bekas & Pendaftaran Mitra',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Segmented Top Switcher (BaBe vs Mitra Toko)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _curationTab = 0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _curationTab == 0 ? GageTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _curationTab == 0
                                ? [BoxShadow(color: GageTheme.primary.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.recycling_rounded, size: 15, color: _curationTab == 0 ? Colors.white : Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  'Barang Bekas (${_babeSubmissions.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _curationTab == 0 ? FontWeight.bold : FontWeight.w600,
                                    color: _curationTab == 0 ? Colors.white : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _curationTab = 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _curationTab == 1 ? const Color(0xFF00AA13) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _curationTab == 1
                                ? [BoxShadow(color: const Color(0xFF00AA13).withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.storefront_rounded, size: 15, color: _curationTab == 1 ? Colors.white : Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  'Mitra Baru (${_merchantSubmissions.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _curationTab == 1 ? FontWeight.bold : FontWeight.w600,
                                    color: _curationTab == 1 ? Colors.white : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filter Status (Menunggu, Disetujui, Ditolak, Semua)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Menunggu', 'Disetujui', 'Ditolak', 'Semua'].map((status) {
                    final isSel = _statusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _statusFilter = status);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel
                                ? (_curationTab == 0 ? GageTheme.primary : const Color(0xFF00AA13))
                                : (isDark ? Colors.white10 : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Content List
            Expanded(
              child: _currentFilteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            'Tidak ada pengajuan $_statusFilter',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          const Text('Seluruh kurasi pada status ini telah selesai diproses.', style: TextStyle(fontSize: 11, color: GageTheme.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _currentFilteredList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final item = _currentFilteredList[i];
                        return _curationTab == 0
                            ? _buildBabeCard(item, isDark)
                            : _buildMerchantCard(item, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 3),
    );
  }

  // --- KARTU KURASI BABE ---
  Widget _buildBabeCard(Map<String, dynamic> item, bool isDark) {
    final status = item['status'] as String;
    final isPending = status == 'Menunggu';
    final isApproved = status == 'Disetujui';

    Color statusColor = isApproved ? const Color(0xFF00AA13) : (status == 'Ditolak' ? Colors.red.shade700 : Colors.orange.shade800);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item['category'] as String,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GageTheme.primary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item['name'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
          const SizedBox(height: 3),
          Text(
            item['specs'] as String,
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(height: 10),

          // Harga & Lokasi
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Harga Bersih Pemilik:', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                    Text(currencyFormatter.format(item['netPrice']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Harga Tayang Aplikasi (+10% Platform):', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
                    Text(
                      currencyFormatter.format(item['appPrice']),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Color(0xFF00AA13)),
                    ),
                  ],
                ),
                const Divider(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 13, color: GageTheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${item['location']} • Pemilik: ${item['sellerName']}',
                        style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00AA13),
                      side: const BorderSide(color: Color(0xFF00AA13)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.chat_rounded, size: 14),
                    label: const Text('Hubungi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _callWhatsApp(item['sellerPhone'] as String),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: const Text('Tolak', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _reject(item),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00AA13),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 15),
                    label: const Text('Setujui & Tayang', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: () => _approve(item),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- KARTU KURASI MITRA BARU ---
  Widget _buildMerchantCard(Map<String, dynamic> item, bool isDark) {
    final status = item['status'] as String;
    final isPending = status == 'Menunggu';
    final isApproved = status == 'Disetujui';

    Color statusColor = isApproved ? const Color(0xFF00AA13) : (status == 'Ditolak' ? Colors.red.shade700 : Colors.orange.shade800);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00AA13).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item['category'] as String,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00AA13)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item['storeName'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            'Pemilik: ${item['ownerName']} • ${item['menuCount']} Menu Terdaftar',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store_rounded, size: 13, color: Color(0xFF00AA13)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item['address'] as String,
                        style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['notes'] as String,
                  style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          ),

          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00AA13),
                      side: const BorderSide(color: Color(0xFF00AA13)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.chat_rounded, size: 14),
                    label: const Text('Hubungi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _callWhatsApp(item['phone'] as String),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: const Text('Tolak', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _reject(item),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00AA13),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.verified_rounded, size: 15),
                    label: const Text('Verifikasi & Buka', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: () => _approve(item),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
