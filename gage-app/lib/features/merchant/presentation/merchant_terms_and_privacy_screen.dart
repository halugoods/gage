import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Halaman Dokumen Resmi Layar Penuh: Kebijakan Privasi & Ketentuan Kemitraan GAGE
/// Memuat regulasi kemitraan usaha, bagi hasil 10% MDR, perlindungan data pribadi,
/// standar higienitas penyiapan menu, dan SOP sengketa / pengembalian dana.
class MerchantTermsAndPrivacyScreen extends StatelessWidget {
  const MerchantTermsAndPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: cardBg,
        title: const Text(
          'Kebijakan Privasi & Kemitraan',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner Dokumen Resmi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GageTheme.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GageTheme.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: GageTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perjanjian Kemitraan Resmi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Berlaku bagi seluruh mitra merchant terdaftar di wilayah Kecamatan Pracimantoro dan sekitarnya.',
                          style: TextStyle(fontSize: 11.5, color: subColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bagian 1: Skema Bagi Hasil & Komisi MDR
            _buildSectionCard(
              title: '1. Skema Bagi Hasil & Komisi Layanan (MDR)',
              icon: Icons.percent_rounded,
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subColor: subColor,
              content:
                  '• Komisi platform GAGE ditetapkan sebesar 10% (sepuluh persen) dari total nilai subtotal produk pada setiap pesanan yang telah berstatus Selesai.\n'
                  '• Komisi dialokasikan untuk pemeliharaan infrastruktur cloud, sistem dispatching kurir cerdas, subsidi promosi pelanggan, dan asuransi operasional.\n'
                  '• Pendapatan bersih toko dihitung secara transparan dan otomatis dapat dicairkan (settlement) ke rekening bank atau dompet digital terdaftar H+1 hari kerja tanpa potongan tersembunyi.',
            ),
            const SizedBox(height: 14),

            // Bagian 2: Kebijakan Privasi & Perlindungan Data Konsumen
            _buildSectionCard(
              title: '2. Privasi & Kerahasiaan Data Pelanggan',
              icon: Icons.lock_outline_rounded,
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subColor: subColor,
              content:
                  '• Mitra usaha dilarang keras menyimpan, menyalin, membagikan, atau memanfaatkan data nomor telepon, nama lengkap, dan alamat fisik pelanggan untuk keperluan di luar pemenuhan pesanan aktif.\n'
                  '• Seluruh komunikasi antara merchant dan pembeli terlindungi di dalam sistem perpesanan resmi aplikasi GAGE.\n'
                  '• Data koordinat kios dan jam operasional toko ditampilkan secara publik kepada pengguna aplikasi untuk mempermudah navigasi penjemputan armada driver.',
            ),
            const SizedBox(height: 14),

            // Bagian 3: Standar Mutu, Higienitas & Pengemasan
            _buildSectionCard(
              title: '3. Standar Mutu, Higienitas & Pengemasan',
              icon: Icons.sanitizer_rounded,
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subColor: subColor,
              content:
                  '• Mitra berkewajiban menjaga kebersihan dapur, kesegaran bahan baku, dan kehalalan makanan/minuman yang disajikan.\n'
                  '• Makanan berkuah, berminyak, atau minuman panas/dingin wajib menggunakan kemasan anti-tumpah dan disegel dengan kabel ties/stiker segel keamanan toko.\n'
                  '• Sambal, saus pelengkap, atau bumbu tambahan dipisahkan dalam wadah tersendiri untuk menjamin mutu rasa saat sampai di tangan pelanggan.',
            ),
            const SizedBox(height: 14),

            // Bagian 4: Pembatalan, Menu Habis & Pengembalian Dana
            _buildSectionCard(
              title: '4. Pembatalan, Menu Habis & Pengembalian Dana',
              icon: Icons.assignment_return_rounded,
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subColor: subColor,
              content:
                  '• Mitra wajib segera menonaktifkan sakelar stok menu pada menu Katalog Menu apabila persediaan bahan baku telah habis.\n'
                  '• Jika pesanan masuk saat menu terlanjur habis, merchant wajib mengabari pelanggan melalui chat internal dan melakukan koordinasi penggantian menu atau pembatalan tertib.\n'
                  '• Komplain pesanan tidak lengkap atau salah porsi yang terbukti karena kelalaian outlet menjadi tanggung jawab merchant untuk diganti atau di-refund sesuai nilai kerugian pelanggan.',
            ),
            const SizedBox(height: 14),

            // Bagian 5: Saluran Bantuan Legal & Lokasi
            _buildSectionCard(
              title: '5. Saluran Resmi & Kontak Kantor Operasional',
              icon: Icons.business_rounded,
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              subColor: subColor,
              content:
                  'GAGE Pracimantoro Tech & Dispatch Hub\n'
                  'Jl. Raya Pracimantoro No. 12, Wonogiri, Jawa Tengah\n'
                  'Hotline CS Mitra Usaha: +62 811-1222-333\n'
                  'Email Legal & Kemitraan: mitra@gagepracimantoro.com',
            ),
            const SizedBox(height: 24),

            // Tombol Salin Ringkasan Dokumen
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(const ClipboardData(
                    text: 'Ketentuan Kemitraan GAGE: Komisi MDR 10%, Privasi Data Pelanggan Terjamin, SOP Higienitas & Kemasan Rapi. Hotline: 08111222333',
                  ));
                  GageToast.show(context, 'Ringkasan ketentuan kemitraan berhasil disalin!');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: GageTheme.primary),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.copy_rounded, size: 16, color: GageTheme.primary),
                label: const Text(
                  'Salin Ringkasan Dokumen',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GageTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subColor,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: GageTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              height: 1.55,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }
}
