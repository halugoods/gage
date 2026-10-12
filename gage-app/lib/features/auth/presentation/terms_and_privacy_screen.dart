// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// Halaman Resmi Syarat & Ketentuan Layanan dan Kebijakan Privasi GAGE
class TermsAndPrivacyScreen extends StatefulWidget {
  final int initialTabIndex; // 0: Ketentuan Tarif, 1: Syarat & Ketentuan, 2: Kebijakan Privasi
  final bool showAgreeButton;
  final VoidCallback? onAgreed;

  const TermsAndPrivacyScreen({
    super.key,
    this.initialTabIndex = 0,
    this.showAgreeButton = false,
    this.onAgreed,
  });

  @override
  State<TermsAndPrivacyScreen> createState() => _TermsAndPrivacyScreenState();
}

class _TermsAndPrivacyScreenState extends State<TermsAndPrivacyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Syarat & Ketentuan Layanan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: GageTheme.textPrimary,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: GageTheme.primary,
          unselectedLabelColor: GageTheme.textSecondary,
          indicatorColor: GageTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Ketentuan Tarif'),
            Tab(text: 'Syarat & Ketentuan'),
            Tab(text: 'Kebijakan Privasi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKetentuanTarifTab(),
          _buildKetentuanLayananTab(),
          _buildKebijakanPrivasiTab(),
        ],
      ),
      bottomNavigationBar: widget.showAgreeButton
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    widget.onAgreed?.call();
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    'Saya Memahami & Menyetujui Seluruh Ketentuan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 1: KETENTUAN TARIF & STRUKTUR LAYANAN
  // ─────────────────────────────────────────────────────────────
  Widget _buildKetentuanTarifTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Standar Layanan Resmi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF00880C), Colors.teal.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade900.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.verified_rounded, color: Colors.amberAccent, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Standar Layanan & Ketentuan Tarif',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Standar Layanan Resmi, Kepastian Tarif & Perlindungan Konsumen',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                ),
                const SizedBox(height: 6),
                const Text(
                  'GAGE Pracimantoro berkomitmen menghadirkan ekosistem logistik hyper-lokal yang profesional, tertib, dan andal bagi seluruh pelanggan, mitra pedagang, dan mitra pengemudi.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _buildSectionTitle('1. Standar dan Integritas Layanan'),
          _buildParagraph(
            'Layanan GAGE berlandaskan pada prinsip profesionalisme, kepastian informasi tarif, keadilan bagi mitra, dan perlindungan konsumen. Seluruh komponen biaya pengantaran dan layanan diinformasikan secara jelas sebelum konfirmasi pemesanan dilakukan oleh pengguna.',
          ),

          _buildSectionTitle('2. Struktur Perjanjian Layanan'),
          _buildBulletItem(
            'Perjanjian Layanan Pengantaran Mitra Pengemudi',
            'Berlaku pada layanan GAGE Ride, GAGE Car, dan GAGE Send. Pelanggan menggunakan jasa pengantaran Mitra Driver untuk perjalanan orang atau pengiriman barang dari titik penjemputan ke tujuan dengan tarif berdasarkan jarak kilometer riil yang disepakati.',
          ),
          _buildBulletItem(
            'Kuasa Pembelian Toko Resmi Mitra',
            'Berlaku pada layanan GAGE Food, GAGE Shop, dan GAGE Tani. Pelanggan memberikan kuasa kepada Mitra Driver untuk melakukan pemesanan, pembayaran di kasir toko, dan pengambilan barang di gerai mitra terdaftar atas nama Pelanggan, disertai biaya pengantaran yang disetujui.',
          ),
          _buildBulletItem(
            'Penyediaan Fasilitas & Infrastruktur Digital',
            'GAGE Indonesia bertindak sebagai penyedia platform teknologi digital yang memfasilitasi transaksi aman, pemrosesan pesanan otomatis, navigasi rute GPS real-time, dan layanan bantuan pelanggan.',
          ),

          _buildSectionTitle('3. Ketentuan Pembulatan Tarif Biaya Antar (Kelipatan Rp 500)'),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade400, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.amber.shade900, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Ketentuan Pembulatan Rp 500 & Subsidi Layanan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Untuk mempermudah transaksi lapangan, mempercepat transaksi tunai tanpa kendala kembalian uang pecahan kecil, serta standardisasi sistem pembukuan, total biaya pengantaran dibulatkan ke kelipatan Rp 500 ke atas (contoh: Rp 12.100 dibulatkan menjadi Rp 12.500; Rp 12.700 dibulatkan menjadi Rp 13.000).\n\n'
                  '• Selisih nilai pembulatan (antara Rp 1 hingga Rp 499) dialokasikan untuk program subsidi tarif voucher pelanggan, penunjang operasional, dan pemeliharaan performa teknologi aplikasi GAGE.\n\n'
                  '• Hak penghasilan Mitra Pengemudi (komisi riil) tetap dihitung dan disalurkan secara pasti dan akurat berdasarkan jarak tempuh riil (kilometer aktual) tanpa potongan terselubung.\n\n'
                  '• Dengan melanjutkan pemesanan, pengguna menyatakan telah membaca, memahami, dan menyetujui struktur perhitungan biaya pengantaran ini secara sadar dan mengikat.',
                  style: TextStyle(fontSize: 12, color: Colors.brown.shade900, height: 1.45),
                ),
              ],
            ),
          ),

          _buildSectionTitle('4. Klausul Pemesanan Multi-Merchant (Lebih dari 1 Toko)'),
          _buildParagraph(
            'Pelanggan diizinkan menggabungkan pesanan dari beberapa merchant/toko sekaligus dalam satu kali checkout. Untuk setiap merchant yang ditambahkan, dikenakan biaya administrasi & penanganan platform (Rp 1.000 per toko untuk metode non-tunai/GAGEPay/QRIS; atau base Rp 3.000 + Rp 1.000 per toko tambahan untuk tunai COD). Biaya ini dialokasikan untuk kompensasi multi-stop pickup mitra pengemudi serta jaminan koordinasi antar toko.',
          ),

          _buildSectionTitle('5. Standar Kelayakan & Keamanan Produk'),
          _buildParagraph(
            'Seluruh produk makanan, minuman, dan komoditas tani yang diperjualbelikan melalui platform GAGE wajib memenuhi standar higienis, layak konsumsi, serta mematuhi peraturan perundang-undangan Republik Indonesia. Dilarang keras memperjualbelikan barang terlarang, zat berbahaya, atau produk yang melanggar hukum. Mitra pengemudi dan platform berhak membatalkan pesanan yang melanggar ketentuan ini.',
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 2: SYARAT & KETENTUAN LAYANAN
  // ─────────────────────────────────────────────────────────────
  Widget _buildKetentuanLayananTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('1. Definisi dan Ruang Lingkup Layanan'),
          _buildParagraph(
            'GAGE Indonesia adalah platform aplikasi on-demand hyper-lokal yang melayani pemesanan transportasi (Ride & Car), pesan antar makanan (Food), belanja kebutuhan (Shop), hasil pertanian (Tani), dan kurir kilat (Send) dengan wilayah operasional utama di Kecamatan Pracimantoro, Kabupaten Wonogiri dan kecamatan sekitarnya (Giritontro, Eromoko, Giriwoyo, Baturetno, dsb).',
          ),

          _buildSectionTitle('2. Pendaftaran dan Akun Pengguna'),
          _buildBulletItem(
            'Kebenaran Data',
            'Pengguna wajib memberikan data yang benar, akurat, dan dapat dihubungi (nama lengkap, nomor telepon WhatsApp aktif, dan alamat pengiriman).',
          ),
          _buildBulletItem(
            'Kerahasiaan Akun',
            'Pengguna bertanggung jawab penuh atas keamanan akun, perangkat, dan transaksi yang dilakukan melalui akun terdaftar miliknya.',
          ),

          _buildSectionTitle('3. Pembayaran dan Batasan Transaksi COD'),
          _buildBulletItem(
            'Metode Pembayaran',
            'GAGE mendukung pembayaran Saldo GAGEPay (Closed Loop Wallet), QRIS Dinamis (semua bank & e-wallet), serta Tunai di Tempat (Cash on Delivery / COD).',
          ),
          _buildBulletItem(
            'Batas Maksimal Tunai (COD)',
            'Demi melindungi mitra pengemudi dan merchant dari risiko pesanan fiktif (fraud), transaksi Tunai / COD dibatasi maksimal Rp 75.000 per pesanan. Pesanan di atas nominal tersebut wajib diselesaikan melalui pembayaran non-tunai (GAGEPay / QRIS).',
          ),

          _buildSectionTitle('4. Kebijakan Pembatalan dan Ganti Rugi'),
          _buildParagraph(
            'Pesanan makanan/belanja yang telah diproses atau dimasak oleh merchant tidak dapat dibatalkan secara sepihak oleh pelanggan. Apabila terjadi pembatalan sepihak setelah driver membeli barang, akun pelanggan dapat dinonaktifkan sementara dan dikenakan kewajiban penyelesaian tagihan.',
          ),

          _buildSectionTitle('5. Batasan Tanggung Jawab Platform'),
          _buildParagraph(
            'GAGE senantiasa mengupayakan ketersediaan sistem dan akurasi terbaik. Namun GAGE tidak bertanggung jawab atas keterlambatan akibat kondisi kahar (force majeure) seperti cuaca ekstrem, bencana alam, penutupan jalan, atau gangguan jaringan telekomunikasi nasional.',
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 3: KEBIJAKAN PRIVASI (AMANAH DATA PRIBADI)
  // ─────────────────────────────────────────────────────────────
  Widget _buildKebijakanPrivasiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('1. Komitmen Amanah Perlindungan Data'),
          _buildParagraph(
            'GAGE Indonesia berkomitmen memegang amanah penuh atas kerahasiaan data pribadi Pengguna sesuai Undang-Undang Republik Indonesia No. 27 Tahun 2022 tentang Perlindungan Data Pribadi (UU PDP). Kami tidak pernah dan tidak akan pernah menjual, menyewakan, atau memperdagangkan data pribadi Anda kepada pihak ketiga mana pun.',
          ),

          _buildSectionTitle('2. Data yang Dikumpulkan'),
          _buildBulletItem(
            'Data Identitas & Kontak',
            'Nama, alamat email Google Sign-In, nomor telepon/WhatsApp, dan alamat pengantaran yang diinput oleh pengguna.',
          ),
          _buildBulletItem(
            'Data Lokasi Geografis (GPS)',
            'Lokasi koordinat GPS saat aplikasi aktif digunakan untuk menentukan titik penjemputan, menghitung estimasi jarak pengantaran secara akurat dalam radius Pracimantoro dan sekitarnya, serta menampilkan posisi real-time driver saat pengantaran berlangsung.',
          ),
          _buildBulletItem(
            'Data Riwayat Transaksi',
            'Catatan item belanja, waktu transaksi, metode pembayaran, dan status penyelesaian pesanan untuk keperluan riwayat dan audit.',
          ),

          _buildSectionTitle('3. Penggunaan dan Pembagian Data'),
          _buildParagraph(
            'Data Pengguna hanya dibagikan secara terbatas kepada Mitra Pengemudi (nama pemesan, nomor kontak untuk konfirmasi, dan alamat tujuan pengiriman) serta Mitra Merchant (rincian menu yang dipesan) semata-mata untuk kelancaran penyelesaian pesanan.',
          ),

          _buildSectionTitle('4. Keamanan dan Penyimpanan Data'),
          _buildParagraph(
            'Seluruh transmisi data transaksi dilindungi dengan protokol enkripsi modern (HTTPS/TLS) dan disimpan di infrastruktur terpercaya. Kami membatasi akses database hanya untuk tim operasional yang berwenang.',
          ),

          _buildSectionTitle('5. Hak Pengguna atas Data Pribadi'),
          _buildParagraph(
            'Pengguna berhak memeriksa, memperbarui, atau mengajukan permohonan penghapusan data akun sewaktu-waktu melalui menu Pengaturan Profil atau melalui layanan pelanggan resmi GAGE Indonesia.',
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // WIDGET HELPERS
  // ─────────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14.0, bottom: 6.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: GageTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          color: GageTheme.textSecondary,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildBulletItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0, right: 8.0),
            child: Icon(Icons.check_circle_rounded, color: GageTheme.accentGreen, size: 16),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12.5, color: GageTheme.textSecondary, height: 1.4),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: GageTheme.textPrimary),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
