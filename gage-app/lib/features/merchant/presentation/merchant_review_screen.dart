import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Halaman Layar Penuh (Full Screen Page) untuk Penilaian & Ulasan Mitra Usaha GAGE
/// Dilengkapi metrik rating 5.0, distribusi bintang, filter tags interaktif,
/// serta riwayat testimoni pelanggan lengkap dengan fitur balas ulasan toko.
class MerchantReviewScreen extends StatefulWidget {
  const MerchantReviewScreen({super.key});

  @override
  State<MerchantReviewScreen> createState() => _MerchantReviewScreenState();
}

class _MerchantReviewScreenState extends State<MerchantReviewScreen> {
  int _activeFilter = 0;
  final List<String> _filters = [
    'Semua (98)',
    'Dengan Foto (42)',
    'Rasa Enak (65)',
    'Porsi Pas (54)',
    'Kemasan Rapi (48)',
  ];

  final List<Map<String, dynamic>> _reviews = [
    {
      'id': 'rev-01',
      'name': 'Siti Rahmawati',
      'rating': 5,
      'date': '10 Nov 2026',
      'menu': 'Dimsum Mozzarella Keju Lumer (Isi 4)',
      'comment':
          'Dimsumnya mantap banget, pas sampai masih panas dan kejunya beneran lumer. Sambal dan saus dipisah rapi. Recommended!',
      'reply': 'Terima kasih banyak Kak Siti! Ditunggu pesanan berikutnya yaa 😊',
      'hasPhoto': true,
      'tags': ['Rasa Enak', 'Kemasan Rapi'],
    },
    {
      'id': 'rev-02',
      'name': 'Budi Santoso',
      'rating': 5,
      'date': '09 Nov 2026',
      'menu': 'Dimsum Siomay Ayam Jamur (Isi 4)',
      'comment':
          'Porsi pas, daging ayamnya kerasa banget bukan tepung doang. Driver pengantarnya juga cepat dan ramah.',
      'reply': 'Alhamdulillah, terima kasih banyak Mas Budi atas ulasan positifnya! 🙏',
      'hasPhoto': false,
      'tags': ['Rasa Enak', 'Porsi Pas'],
    },
    {
      'id': 'rev-03',
      'name': 'Linda Permata',
      'rating': 4,
      'date': '08 Nov 2026',
      'menu': 'Dimsum Hakau Udang Segar',
      'comment':
          'Kulit hakaunya lembut dan udangnya fresh manis. Cuma sambalnya kurang pedas dikit buat lidah saya.',
      'reply': 'Terima kasih masukannya Kak Linda! Next order bisa kasih catatan minta sambal ekstra pedas ya kak.',
      'hasPhoto': true,
      'tags': ['Porsi Pas'],
    },
    {
      'id': 'rev-04',
      'name': 'Agus Prabowo',
      'rating': 5,
      'date': '07 Nov 2026',
      'menu': 'Paket Hemat Dimsum Campur + Es Teh Jumbo',
      'comment':
          'Camilan wajib sore-sore di Pracimantoro. Pelayanan dapur cepat, 10 menit sudah ready diambil driver.',
      'reply': null,
      'hasPhoto': false,
      'tags': ['Kemasan Rapi', 'Rasa Enak'],
    },
  ];

  void _showReplyDialog(BuildContext context, Map<String, dynamic> review, bool isDark) {
    HapticFeedback.lightImpact();
    final replyCtrl = TextEditingController(text: review['reply'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Balas Ulasan ${review['name']}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '"${review['comment']}"',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Form Field Balasan Mewah Anti-Slop
              Text(
                'Tanggapan Resmi Toko',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: replyCtrl,
                maxLines: 3,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Tulis apresiasi atau tanggapan ramah dari resto...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: GageTheme.primary,
                      width: 1.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final text = replyCtrl.text.trim();
                    if (text.isNotEmpty) {
                      setState(() {
                        review['reply'] = text;
                      });
                      Navigator.pop(ctx);
                      GageToast.show(context, 'Balasan ulasan berhasil dipublikasikan');
                    }
                  },
                  child: const Text('Kirim Tanggapan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Penilaian & Ulasan Toko',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              'Dimsum Sewu Pracimantoro',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : GageTheme.textPrimary,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // 1. Hero Rating Card Ringkas & Elegan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Nilai Angka Besar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '4.9',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFF59E0B),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        5,
                        (i) => const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '98 Ulasan',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 20),
                Container(width: 1, height: 80, color: isDark ? Colors.white12 : Colors.grey.shade200),
                const SizedBox(width: 16),

                // Baris Distribusi Bintang 5 s/d 1
                Expanded(
                  child: Column(
                    children: [
                      _buildStarRow(5, 0.85, isDark),
                      const SizedBox(height: 3),
                      _buildStarRow(4, 0.12, isDark),
                      const SizedBox(height: 3),
                      _buildStarRow(3, 0.03, isDark),
                      const SizedBox(height: 3),
                      _buildStarRow(2, 0.00, isDark),
                      const SizedBox(height: 3),
                      _buildStarRow(1, 0.00, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Segmented Filter Chips Kapsul Penuh (999)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final isSelected = _activeFilter == i;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeFilter = i);
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GageTheme.primary
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? GageTheme.primary
                            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _filters[i],
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 3. Header Daftar Ulasan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Testimoni Pelanggan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Terverifikasi Transaksi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 4. Kartu Ulasan Pelanggan Lengkap
          ..._reviews.map((r) => _buildReviewCard(context, r, isDark)),
        ],
      ),
    );
  }

  Widget _buildStarRow(int star, double pct, bool isDark) {
    return Row(
      children: [
        Text(
          '$star',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star_rounded, size: 11, color: Color(0xFFF59E0B)),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, Map<String, dynamic> r, bool isDark) {
    final reply = r['reply'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Pelanggan & Bintang
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: GageTheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      r['name'][0],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: GageTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['name'],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        r['date'],
                        style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white54 : Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: List.generate(
                  r['rating'] as int,
                  (i) => const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Menu yang Dipesan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restaurant_rounded, size: 12, color: GageTheme.primary),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    r['menu'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Komentar Ulasan
          Text(
            r['comment'],
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),

          // Balasan Resmi Toko jika ada
          if (reply != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.storefront_rounded, size: 13, color: GageTheme.primary),
                          SizedBox(width: 6),
                          Text(
                            'Respon Dimsum Sewu',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: GageTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _showReplyDialog(context, r, isDark),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reply,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  side: BorderSide(color: GageTheme.primary.withValues(alpha: 0.6)),
                ),
                onPressed: () => _showReplyDialog(context, r, isDark),
                icon: const Icon(Icons.reply_rounded, size: 14, color: GageTheme.primary),
                label: const Text(
                  'Balas Ulasan',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
