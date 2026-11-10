// Legal & Landing Pages for GAGE by Halu Goods Indonesia

export const getLandingPageHtml = () => `<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Gage by Halu Goods Indonesia - Layanan Hyperlocal Delivery Pracimantoro</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
    body { background: #0B0F19; color: #F1F5F9; line-height: 1.6; }
    header { background: #0F172A; border-bottom: 1px solid #1E293B; padding: 1.25rem 2rem; display: flex; justify-content: space-between; align-items: center; }
    .brand { display: flex; align-items: center; gap: 12px; }
    .brand-badge { background: #DC2626; color: white; font-weight: 900; padding: 4px 10px; border-radius: 8px; font-size: 1.1rem; }
    .brand-title { font-size: 1.1rem; font-weight: 700; color: #FFFFFF; }
    .brand-sub { font-size: 0.8rem; color: #94A3B8; }
    .container { max-width: 900px; margin: 0 auto; padding: 3rem 1.5rem; }
    .hero { text-align: center; margin-bottom: 3rem; }
    .hero h1 { font-size: 2.25rem; font-weight: 800; color: #FFFFFF; margin-bottom: 1rem; }
    .hero p { font-size: 1.1rem; color: #94A3B8; max-width: 650px; margin: 0 auto; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1.5rem; margin-top: 2.5rem; }
    .card { background: #1E293B; border: 1px solid #334155; border-radius: 14px; padding: 1.5rem; }
    .card h3 { color: #38BDF8; font-size: 1.2rem; margin-bottom: 0.5rem; }
    .card p { font-size: 0.95rem; color: #CBD5E1; }
    footer { text-align: center; padding: 2rem; border-top: 1px solid #1E293B; color: #64748B; font-size: 0.85rem; }
    .footer-links { margin-top: 0.75rem; display: flex; justify-content: center; gap: 1.5rem; }
    .footer-links a { color: #38BDF8; text-decoration: none; }
    .footer-links a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <header>
    <div class="brand">
      <div class="brand-badge">GAGE</div>
      <div>
        <div class="brand-title">Gage by Halu Goods Indonesia</div>
        <div class="brand-sub">Holding Company: Halu Goods Indonesia</div>
      </div>
    </div>
  </header>
  <div class="container">
    <div class="hero">
      <h1>Layanan Pesan-Antar & Ekosistem Digital Pracimantoro</h1>
      <p>Solusi mobilitas, logistik instan, dan pemberdayaan kuliner lokal UMKM di wilayah Pracimantoro, Wonogiri dan sekitarnya.</p>
    </div>
    <div class="grid">
      <div class="card">
        <h3>🍔 GAGE Food</h3>
        <p>Pemesanan makanan dan minuman dari puluhan mitra resto & UMKM kuliner lokal dengan tarif transparan dan promo berkala.</p>
      </div>
      <div class="card">
        <h3>🛵 GAGE Ride & Car</h3>
        <p>Layanan transportasi motor dan mobil aman, nyaman, dan terpercaya dengan estimasi tarif langsung sebelum bepergian.</p>
      </div>
      <div class="card">
        <h3>📦 GAGE Send</h3>
        <p>Pengantaran paket, dokumen, dan barang belanja lokal dengan kurir instan flat rate terjangkau.</p>
      </div>
    </div>
  </div>
  <footer>
    <p>&copy; 2026 Halu Goods Indonesia. Seluruh hak cipta dilindungi undang-undang.</p>
    <div class="footer-links">
      <a href="/terms">Syarat & Ketentuan (Terms of Service)</a>
      <a href="/privacy">Kebijakan Privasi (Privacy Policy)</a>
    </div>
  </footer>
</body>
</html>`;

export const getTermsHtml = () => `<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Terms of Service - Gage by Halu Goods Indonesia</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
    body { background: #0B0F19; color: #F1F5F9; line-height: 1.7; }
    header { background: #0F172A; border-bottom: 1px solid #1E293B; padding: 1.25rem 2rem; display: flex; justify-content: space-between; align-items: center; }
    .brand-title { font-size: 1.1rem; font-weight: 700; color: #FFFFFF; }
    .brand-sub { font-size: 0.8rem; color: #94A3B8; }
    .container { max-width: 850px; margin: 0 auto; padding: 3rem 1.5rem; background: #0F172A; border-radius: 16px; margin-top: 2rem; margin-bottom: 3rem; border: 1px solid #1E293B; }
    h1 { font-size: 2rem; font-weight: 800; color: #FFFFFF; margin-bottom: 0.5rem; }
    .last-updated { color: #64748B; font-size: 0.85rem; margin-bottom: 2rem; }
    h2 { font-size: 1.3rem; font-weight: 700; color: #38BDF8; margin-top: 2rem; margin-bottom: 0.75rem; }
    p, li { font-size: 0.95rem; color: #CBD5E1; margin-bottom: 0.75rem; }
    ul { padding-left: 1.5rem; margin-bottom: 1rem; }
    footer { text-align: center; padding: 2rem; border-top: 1px solid #1E293B; color: #64748B; font-size: 0.85rem; }
    a { color: #38BDF8; text-decoration: none; }
  </style>
</head>
<body>
  <header>
    <div>
      <div class="brand-title">Gage by Halu Goods Indonesia</div>
      <div class="brand-sub">Holding Company: Halu Goods Indonesia | Produk: GAGE Pracimantoro</div>
    </div>
    <a href="/">Kembali ke Beranda</a>
  </header>
  <div class="container">
    <h1>Syarat dan Ketentuan (Terms of Service)</h1>
    <div class="last-updated">Terakhir Diperbarui: 7 November 2026</div>

    <h2>1. Pendahuluan & Definisi</h2>
    <p>Selamat datang di platform <strong>Gage by Halu Goods Indonesia</strong> ("Aplikasi", "Kami"). Layanan ini diselenggarakan oleh <strong>Halu Goods Indonesia</strong> sebagai holding company, dengan produk operasional <strong>GAGE Pracimantoro</strong> yang melayani wilayah Pracimantoro dan sekitarnya.</p>
    <p>Dengan mengakses atau menggunakan aplikasi kami, Anda menyatakan bahwa Anda telah membaca, memahami, dan menyetujui untuk terikat oleh Syarat dan Ketentuan ini.</p>

    <h2>2. Akun Pengguna & Keamanan</h2>
    <ul>
      <li>Pengguna wajib memberikan informasi yang akurat saat pendaftaran akun maupun otentikasi melalui Google Sign-In.</li>
      <li>Pengguna bertanggung jawab penuh atas kerahasiaan nomor otorisasi, PIN GAGEPay 6 Digit, dan data autentikasi biometrik pada perangkat masing-masing.</li>
      <li>Segala aktivitas transaksi yang terverifikasi menggunakan PIN atau biometrik dianggap sah dilakukan oleh pemilik akun.</li>
    </ul>

    <h2>3. Layanan Pemesanan & Pengantaran</h2>
    <ul>
      <li><strong>GAGE Food</strong>: Menghubungkan pengguna dengan mitra merchant kuliner lokal. Ketersediaan menu dan estimasi waktu persiapan merupakan tanggung jawab mitra merchant.</li>
      <li><strong>GAGE Ride & Car</strong>: Menyediakan perkiraan tarif perjalanan berdasarkan jarak rute yang terukur secara transparan sebelum konfirmasi pemesanan.</li>
      <li><strong>GAGE Send</strong>: Layanan pengiriman barang lokal. Dilarang mengirimkan barang ilegal, berbahaya, atau yang melanggar hukum Republik Indonesia.</li>
    </ul>

    <h2>4. Integrasi Media & Konten Pihak Ketiga (TikTok)</h2>
    <p>Aplikasi menampilkan cuplikan promosi kuliner mitra melalui fitur pemutar resmi pihak ketiga (termasuk <em>TikTok Embed Player</em>). Seluruh hak cipta, merek dagang, dan konten video tetap menjadi hak milik masing-masing kreator dan penyedia konten pihak ketiga. Pemutaran konten tunduk pada pedoman komunitas dan ketentuan layanan pihak ketiga terkait.</p>

    <h2>5. Kontak & Layanan Pelanggan</h2>
    <p>Jika Anda memiliki pertanyaan mengenai Syarat dan Ketentuan ini, silakan hubungi kami melalui surel resmi: <strong>halugoodsindonesia@gmail.com</strong>.</p>
  </div>
  <footer>
    <p>&copy; 2026 Halu Goods Indonesia. Seluruh hak cipta dilindungi undang-undang.</p>
  </footer>
</body>
</html>`;

export const getPrivacyHtml = () => `<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Privacy Policy - Gage by Halu Goods Indonesia</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
    body { background: #0B0F19; color: #F1F5F9; line-height: 1.7; }
    header { background: #0F172A; border-bottom: 1px solid #1E293B; padding: 1.25rem 2rem; display: flex; justify-content: space-between; align-items: center; }
    .brand-title { font-size: 1.1rem; font-weight: 700; color: #FFFFFF; }
    .brand-sub { font-size: 0.8rem; color: #94A3B8; }
    .container { max-width: 850px; margin: 0 auto; padding: 3rem 1.5rem; background: #0F172A; border-radius: 16px; margin-top: 2rem; margin-bottom: 3rem; border: 1px solid #1E293B; }
    h1 { font-size: 2rem; font-weight: 800; color: #FFFFFF; margin-bottom: 0.5rem; }
    .last-updated { color: #64748B; font-size: 0.85rem; margin-bottom: 2rem; }
    h2 { font-size: 1.3rem; font-weight: 700; color: #38BDF8; margin-top: 2rem; margin-bottom: 0.75rem; }
    p, li { font-size: 0.95rem; color: #CBD5E1; margin-bottom: 0.75rem; }
    ul { padding-left: 1.5rem; margin-bottom: 1rem; }
    footer { text-align: center; padding: 2rem; border-top: 1px solid #1E293B; color: #64748B; font-size: 0.85rem; }
    a { color: #38BDF8; text-decoration: none; }
  </style>
</head>
<body>
  <header>
    <div>
      <div class="brand-title">Gage by Halu Goods Indonesia</div>
      <div class="brand-sub">Holding Company: Halu Goods Indonesia | Produk: GAGE Pracimantoro</div>
    </div>
    <a href="/">Kembali ke Beranda</a>
  </header>
  <div class="container">
    <h1>Kebijakan Privasi (Privacy Policy)</h1>
    <div class="last-updated">Terakhir Diperbarui: 7 November 2026</div>

    <h2>1. Komitmen Privasi Kami</h2>
    <p><strong>Halu Goods Indonesia</strong> berkomitmen penuh untuk melindungi privasi dan keamanan data pengguna aplikasi <strong>Gage by Halu Goods Indonesia</strong> dan produk <strong>GAGE Pracimantoro</strong>. Kebijakan ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan melindungi informasi pribadi Anda.</p>

    <h2>2. Informasi yang Kami Kumpulkan</h2>
    <ul>
      <li><strong>Data Identitas & Profil</strong>: Nama lengkap, alamat surel, nomor telepon WhatsApp, dan foto profil pengguna yang diperoleh saat otentikasi Google Sign-In atau unggahan mandiri.</li>
      <li><strong>Data Alamat & Lokasi</strong>: Koordinat lokasi pengantaran untuk memproses pengiriman pesanan dan estimasi jarak kurir secara akurat.</li>
      <li><strong>Data Transaksi Finansial</strong>: Riwayat transaksi GAGEPay dan QRIS (PIN transaksi dienkripsi dan diproses secara aman, tidak pernah disimpan dalam format teks terbuka).</li>
    </ul>

    <h2>3. Penggunaan Informasi</h2>
    <p>Kami menggunakan informasi yang dikumpulkan semata-mata untuk:</p>
    <ul>
      <li>Memproses pesanan makanan, perjalanan, dan pengiriman barang.</li>
      <li>Menghubungkan pengguna dengan mitra driver dan merchant lokal secara real-time.</li>
      <li>Mengirimkan notifikasi status pemesanan dan verifikasi keamanan akun.</li>
      <li>Meningkatkan kualitas layanan dan keamanan ekosistem aplikasi.</li>
    </ul>

    <h2>4. Penyedia Layanan Pihak Ketiga & Integrasi API</h2>
    <p>Aplikasi dapat menggunakan API resmi pihak ketiga seperti:</p>
    <ul>
      <li><strong>Google Sign-In</strong>: Untuk otentikasi identitas yang aman.</li>
      <li><strong>TikTok Embed Player / Display API</strong>: Untuk memutar video promosi kuliner resmi tanpa mengumpulkan data rahasia pengguna aplikasi ke pihak ketiga tanpa persetujuan.</li>
    </ul>

    <h2>5. Keamanan Data</h2>
    <p>Data pribadi Anda disimpan dan diamankan menggunakan enkripsi standar industri (TLS/HTTPS) dan infrastruktur Cloudflare berkeamanan tinggi. Kami tidak pernah menjual, menyewakan, atau menyalahgunakan data pribadi Anda kepada pihak mana pun.</p>

    <h2>6. Hubungi Kami</h2>
    <p>Untuk pertanyaan, koreksi, atau permintaan penghapusan data akun, silakan hubungi tim privasi kami di: <strong>halugoodsindonesia@gmail.com</strong>.</p>
  </div>
  <footer>
    <p>&copy; 2026 Halu Goods Indonesia. Seluruh hak cipta dilindungi undang-undang.</p>
  </footer>
</body>
</html>`;
