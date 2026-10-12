// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/features/home/presentation/promo_screen.dart';
import 'package:gage_app/features/membership/presentation/membership_screen.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';
import 'package:gage_app/features/auth/presentation/terms_and_privacy_screen.dart';
import 'package:gage_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:gage_app/features/admin/presentation/admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedLanguage = 'Bahasa Indonesia';
  String _selectedAppIcon = 'GAGE Merah Klasik';
  bool _notifPromo = true;
  bool _notifOrders = true;
  bool _notifChat = true;
  bool _highContrast = false;
  bool _hapticEnabled = true;

  static const String _keyNotifOrders = 'pref_notif_orders';
  static const String _keyNotifPromo = 'pref_notif_promo';
  static const String _keyNotifChat = 'pref_notif_chat';
  static const String _keyHighContrast = 'pref_high_contrast';
  static const String _keyHapticEnabled = 'pref_haptic_enabled';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _notifOrders = prefs.getBool(_keyNotifOrders) ?? true;
          _notifPromo = prefs.getBool(_keyNotifPromo) ?? true;
          _notifChat = prefs.getBool(_keyNotifChat) ?? true;
          _highContrast = prefs.getBool(_keyHighContrast) ?? false;
          _hapticEnabled = prefs.getBool(_keyHapticEnabled) ?? true;
        });
      }
    } catch (_) {}
  }

  Future<void> _updateSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  Future<void> _launchWaCs() async {
    final uri = Uri.parse('https://wa.me/6281234567890?text=Halo%20Admin%20GAGE%2C%20saya%20butuh%20bantuan');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const EditProfileScreen()),
    );
  }


  // 1. Keamanan Akun Modal
  void _showSecurityModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSimpleSheet(
        ctx,
        title: 'Keamanan Akun',
        icon: Icons.shield_outlined,
        children: [
          _buildModalTile(
            title: 'PIN Transaksi GAGE',
            subtitle: 'PIN 6-digit aktif untuk verifikasi transaksi',
            trailing: const Text('Ubah', style: TextStyle(color: Color(0xFF00880C), fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tautan ubah PIN telah dikirimkan ke email terdaftar Anda.')),
              );
            },
          ),
          const Divider(),
          _buildModalTile(
            title: 'Autentikasi Biometrik',
            subtitle: 'Gunakan sidik jari atau Face ID saat membuka aplikasi',
            trailing: Switch(
              value: true,
              activeColor: const Color(0xFF00880C),
              onChanged: (val) {},
            ),
          ),
          const Divider(),
          _buildModalTile(
            title: 'Perangkat Tertaut',
            subtitle: '1 perangkat terverifikasi aktif saat ini (Android)',
            trailing: const Icon(Icons.devices_rounded, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // 2. Metode Pembayaran Modal
  void _showPaymentModal() {
    final wallet = context.read<WalletProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSimpleSheet(
        ctx,
        title: 'Metode Pembayaran',
        icon: Icons.credit_card_rounded,
        children: [
          _buildModalTile(
            title: 'GAGE Pay',
            subtitle: 'Saldo utama: Rp ${wallet.balance}',
            leadingIcon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF00880C),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
              child: const Text('Utama', style: TextStyle(color: Color(0xFF00880C), fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
          const Divider(),
          _buildModalTile(
            title: 'GoPay / QRIS',
            subtitle: 'Tersambung otomatis',
            leadingIcon: Icons.qr_code_2_rounded,
            trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF00880C), size: 18),
          ),
          const Divider(),
          _buildModalTile(
            title: 'ShopeePay',
            subtitle: 'Tersambung',
            leadingIcon: Icons.shopping_bag_outlined,
            trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF00880C), size: 18),
          ),
          const Divider(),
          _buildModalTile(
            title: 'Tunai (COD)',
            subtitle: 'Bayar langsung ke driver saat pesanan tiba',
            leadingIcon: Icons.payments_outlined,
            trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF00880C), size: 18),
          ),
        ],
      ),
    );
  }

  // 3. Akun Keluarga Modal
  void _showFamilyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSimpleSheet(
        ctx,
        title: 'Akun Keluarga GAGE',
        icon: Icons.people_outline_rounded,
        children: [
          const Text(
            'Bagikan metode pembayaran dan kelola pesanan bersama hingga 5 anggota keluarga Anda dengan mudah.',
            style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.3),
          ),
          const SizedBox(height: 14),
          _buildModalTile(
            title: 'Syams Djuhair (Penyelenggara)',
            subtitle: 'Admin Akun Keluarga • Metode GAGE Pay Aktif',
            leadingIcon: Icons.admin_panel_settings_rounded,
            iconColor: const Color(0xFF00880C),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur undangan keluarga siap digunakan!')),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Undang Anggota Keluarga', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00880C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Alamat Tersimpan Modal
  void _showSavedAddressesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSimpleSheet(
        ctx,
        title: 'Alamat Tersimpan',
        icon: Icons.bookmark_border_rounded,
        children: [
          _buildModalTile(
            title: 'Rumah (Tubokarto)',
            subtitle: 'Dusun Tubokarto RT 02/RW 01, Tubokarto, Pracimantoro, Kab. Wonogiri',
            leadingIcon: Icons.home_rounded,
            iconColor: const Color(0xFF00880C),
            trailing: const Icon(Icons.more_horiz),
          ),
          const Divider(),
          _buildModalTile(
            title: 'rumah etan',
            subtitle: 'WRFV+WCJ, Jl. Perumahan Kota Baru, Sumberjo, Sambiroto, Kec. Pracimantoro',
            leadingIcon: Icons.home_outlined,
            trailing: const Icon(Icons.more_horiz),
          ),
          const Divider(),
          _buildModalTile(
            title: 'ugm',
            subtitle: 'Jalan Prof. Drs Notonagoro, Caturtunggal, Sleman, DIY',
            leadingIcon: Icons.school_outlined,
            trailing: const Icon(Icons.more_horiz),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Buka form penambahan alamat baru.')),
                );
              },
              icon: const Icon(Icons.add_location_alt_rounded, size: 18, color: Color(0xFF00880C)),
              label: const Text('Tambah Alamat Baru', style: TextStyle(color: Color(0xFF00880C), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00880C)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Pusat Akun Terverifikasi Modal
  void _showKycModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSimpleSheet(
        ctx,
        title: 'Pusat Akun Terverifikasi',
        icon: Icons.verified_user_outlined,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF00880C), size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Akun Anda 100% Terverifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00880C))),
                      SizedBox(height: 2),
                      Text('Semua fitur belanja, dompet, dan pesanan aktif penuh.', style: TextStyle(fontSize: 11.5, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildModalTile(
            title: 'Nomor WhatsApp',
            subtitle: '+6285156955735 (Terverifikasi OTP)',
            leadingIcon: Icons.phone_android_rounded,
            trailing: const Icon(Icons.check_rounded, color: Color(0xFF00880C)),
          ),
          const Divider(),
          _buildModalTile(
            title: 'Alamat Email',
            subtitle: 'halugoods.indonesia@gmail.com (Terverifikasi)',
            leadingIcon: Icons.email_outlined,
            trailing: const Icon(Icons.check_rounded, color: Color(0xFF00880C)),
          ),
          const Divider(),
          _buildModalTile(
            title: 'Identitas Diri (KTP)',
            subtitle: 'Data kependudukan terdaftar sah',
            leadingIcon: Icons.badge_outlined,
            trailing: const Icon(Icons.check_rounded, color: Color(0xFF00880C)),
          ),
        ],
      ),
    );
  }

  // 6. Ikon Aplikasi Modal
  void _showAppIconModal() {
    final icons = ['GAGE Merah Klasik', 'GAGE Hitam Emas', 'GAGE Hijau Eco'];
    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (c, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Pilih Ikon Aplikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: icons.map((ic) {
              return RadioListTile<String>(
                title: Text(ic, style: const TextStyle(fontSize: 13.5)),
                value: ic,
                groupValue: _selectedAppIcon,
                activeColor: const Color(0xFF00880C),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedAppIcon = val);
                    setDlgState(() {});
                    Navigator.pop(dlgCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ikon aplikasi diatur ke: $val')),
                    );
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // 7. Bahasa Modal
  void _showLanguageModal() {
    final languages = ['Bahasa Indonesia', 'English (US)', 'Basa Jawa'];
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pilih Bahasa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            return RadioListTile<String>(
              title: Text(lang, style: const TextStyle(fontSize: 13.5)),
              value: lang,
              groupValue: _selectedLanguage,
              activeColor: const Color(0xFF00880C),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedLanguage = val);
                  Navigator.pop(dlgCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Bahasa aplikasi diubah ke: $val')),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // 8. Notifikasi Modal
  void _showNotificationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setSheetState) => _buildSimpleSheet(
          ctx,
          title: 'Pengaturan Notifikasi',
          icon: Icons.notifications_none_rounded,
          children: [
            _buildModalTile(
              title: 'Status Pesanan & Pengantaran',
              subtitle: 'Update saat resto menyiapkan dan driver berjalan',
              trailing: Switch(
                value: _notifOrders,
                activeColor: const Color(0xFF00880C),
                onChanged: (v) {
                  setState(() => _notifOrders = v);
                  _updateSetting(_keyNotifOrders, v);
                  setSheetState(() {});
                },
              ),
            ),
            const Divider(),
            _buildModalTile(
              title: 'Promo, Voucher & Diskon',
              subtitle: 'Pemberitahuan voucher hemat harian',
              trailing: Switch(
                value: _notifPromo,
                activeColor: const Color(0xFF00880C),
                onChanged: (v) {
                  setState(() => _notifPromo = v);
                  _updateSetting(_keyNotifPromo, v);
                  setSheetState(() {});
                },
              ),
            ),
            const Divider(),
            _buildModalTile(
              title: 'Chat Driver & Merchant',
              subtitle: 'Pesan langsung mengenai detail pesanan',
              trailing: Switch(
                value: _notifChat,
                activeColor: const Color(0xFF00880C),
                onChanged: (v) {
                  setState(() => _notifChat = v);
                  _updateSetting(_keyNotifChat, v);
                  setSheetState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 9. Aksesibilitas Modal
  void _showAccessibilityModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setSheetState) => _buildSimpleSheet(
          ctx,
          title: 'Aksesibilitas',
          icon: Icons.accessibility_new_rounded,
          children: [
            _buildModalTile(
              title: 'Mode Kontras Tinggi',
              subtitle: 'Pertegas garis dan kontras warna elemen teks',
              trailing: Switch(
                value: _highContrast,
                activeColor: const Color(0xFF00880C),
                onChanged: (v) {
                  setState(() => _highContrast = v);
                  _updateSetting(_keyHighContrast, v);
                  setSheetState(() {});
                },
              ),
            ),
            const Divider(),
            _buildModalTile(
              title: 'Getaran / Haptic Feedback',
              subtitle: 'Getaran halus saat menekan tombol & memilih menu',
              trailing: Switch(
                value: _hapticEnabled,
                activeColor: const Color(0xFF00880C),
                onChanged: (v) {
                  setState(() => _hapticEnabled = v);
                  _updateSetting(_keyHapticEnabled, v);
                  setSheetState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 10. Profil Bisnis Modal
  void _showBusinessModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSimpleSheet(
        ctx,
        title: 'Profil Bisnis GAGE',
        icon: Icons.business_center_outlined,
        children: [
          const Text(
            'Pisahkan pengeluaran perjalanan dan pesanan konsumsi kantor dari akun pribadi Anda. Dapatkan e-faktur dan laporan pengeluaran bulanan otomatis.',
            style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.3),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil Bisnis berhasil diaktifkan untuk akun Anda.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00880C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              child: const Text('Aktifkan Mode Bisnis Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // 11. Gabung Mitra Driver Modal
  void _showDriverModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSimpleSheet(
        ctx,
        title: 'Pendaftaran Mitra Driver',
        icon: Icons.electric_moped_rounded,
        children: [
          const Text(
            'Bergabunglah bersama ribuan mitra driver GAGE Delivery di wilayah Pracimantoro & Wonogiri. Penghasilan harian fleksibel dan bonus mingguan!',
            style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.3),
          ),
          const SizedBox(height: 14),
          _buildModalTile(title: 'Syarat: KTP, SIM C/A Aktif, STNK Motor/Mobil', subtitle: 'Proses verifikasi kilat 1x24 jam', leadingIcon: Icons.verified_outlined),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _launchWaCs();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00880C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              ),
              child: const Text('Daftar via WhatsApp Admin Driver', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // 12. Ajak Teman Modal
  void _showReferralModal() {
    const code = 'GAGEAJI2026';
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: Color(0xFF00880C)),
            SizedBox(width: 8),
            Text('Ajak Teman, Dapat Voucher', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bagikan kode referral Anda ke teman. Saat mereka mendaftar dan memesan, Anda berdua mendapatkan voucher potongan Rp 15.000!',
              style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.3),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    code,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFF00880C)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Colors.black87),
                    tooltip: 'Salin Kode',
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kode referral disalin ke clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  // 13. Rating Modal
  void _showRatingModal() {
    int rating = 5;
    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (c, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Beri Rating Aplikasi GAGE', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bagikan pengalaman Anda menggunakan GAGE Delivery', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: Colors.black54)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (idx) {
                  return IconButton(
                    icon: Icon(
                      idx < rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFFFB300),
                      size: 34,
                    ),
                    onPressed: () => setDlgState(() => rating = idx + 1),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00880C), foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(dlgCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Terima kasih atas bintang $rating dari Anda!')),
                );
              },
              child: const Text('Kirim Rating'),
            ),
          ],
        ),
      ),
    );
  }

  // 14. Atur Akun / Logout Modal
  void _showAccountSettingsModal(AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSimpleSheet(
        ctx,
        title: 'Atur Akun',
        icon: Icons.manage_accounts_outlined,
        children: [
          _buildModalTile(
            title: 'Keluar dari Akun',
            subtitle: 'Keluar dari sesi saat ini di perangkat ini',
            leadingIcon: Icons.logout_rounded,
            iconColor: Colors.red,
            onTap: () async {
              Navigator.pop(ctx);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Konfirmasi Keluar'),
                  content: const Text('Apakah Anda yakin ingin keluar dari akun GAGE ini?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await auth.signOut();
              }
            },
          ),
          const Divider(),
          _buildModalTile(
            title: 'Hapus / Nonaktifkan Akun',
            subtitle: 'Hapus data profil, riwayat, dan akun secara permanen',
            leadingIcon: Icons.delete_forever_rounded,
            iconColor: Colors.red.shade800,
            onTap: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permintaan penghapusan akun memerlukan konfirmasi email.')),
              );
            },
          ),
        ],
      ),
    );
  }

  // 15. Tentang Aplikasi & Lisensi Data Modal
  void _showAboutAndDataLicensesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSimpleSheet(
        ctx,
        title: 'Tentang Aplikasi & Lisensi Data',
        icon: Icons.verified_outlined,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.location_on_rounded, color: Color(0xFF00880C), size: 26),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GAGE Pracimantoro v1.0.2+4',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00880C)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Platform Digital Hyper-Lokal UMKM & Transportasi',
                        style: TextStyle(fontSize: 11.5, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildModalTile(
            title: 'Data Peta & Geolokasi: OpenStreetMap (ODbL)',
            subtitle:
                'Peta dan geolokasi rute menggunakan basis data terbuka OpenStreetMap, © Kontributor OpenStreetMap dengan lisensi Open Database License (ODbL).',
            leadingIcon: Icons.map_rounded,
            iconColor: const Color(0xFF00880C),
          ),
          const Divider(),
          _buildModalTile(
            title: 'Basis Data Fasilitas Pendidikan: Kemendikbudristek RI',
            subtitle:
                'Titik lokasi dan penamaan fasilitas sekolah (SD, SMP, SMA, SMK, MI) diverifikasi berdasarkan basis data pokok pendidikan resmi Kemendikbudristek RI.',
            leadingIcon: Icons.school_rounded,
            iconColor: const Color(0xFF1976D2),
          ),
          const Divider(),
          _buildModalTile(
            title: 'Hak Cipta & Ekosistem Digital Lokal',
            subtitle:
                'Dikembangkan secara mandiri untuk memberdayakan UMKM pedagang, warung makan, petani, dan mitra pengemudi di Pracimantoro, Kab. Wonogiri.',
            leadingIcon: Icons.storefront_rounded,
            iconColor: const Color(0xFFE65100),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('assets/')) {
        return Image.asset(avatarUrl, fit: BoxFit.cover);
      }
      if (avatarUrl.startsWith('/') || avatarUrl.contains('\\')) {
        final f = File(avatarUrl);
        if (f.existsSync()) {
          return Image.file(f, fit: BoxFit.cover);
        }
      }
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Image.asset('assets/images/avatar_user.png', fit: BoxFit.cover),
      );
    }
    return Image.asset('assets/images/avatar_user.png', fit: BoxFit.cover);
  }

  // Helper Sheet Container
  Widget _buildSimpleSheet(
    BuildContext ctx, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(icon, color: const Color(0xFF00880C), size: 22),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModalTile({
    required String title,
    String? subtitle,
    IconData? leadingIcon,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, color: iconColor ?? Colors.black87, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final String userName = (user?.name != null && user!.name.isNotEmpty) ? user.name : 'Syams Djuhair Hibatullah';
    final String userEmail = (user?.email != null && user!.email!.isNotEmpty) ? user.email! : 'halugoods.indonesia@gmail.com';
    final String userPhone = (user?.phone != null && user!.phone.isNotEmpty) ? user.phone : '+6285156955735';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Header Gojek-Style Nature Illustration Background + "Profilku" AppBar
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Nature Green Illustration Background
                Container(
                  height: 190,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF81C784), Color(0xFF4CAF50), Color(0xFF388E3C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative Nature Hill Graphic
                      Positioned(
                        right: -30,
                        top: 20,
                        child: Opacity(
                          opacity: 0.25,
                          child: Icon(Icons.phone_android_rounded, size: 140, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        right: 80,
                        top: 40,
                        child: Opacity(
                          opacity: 0.35,
                          child: Icon(Icons.security_rounded, size: 48, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // Top Bar: Back button & Title "Profilku"
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.maybePop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Profilku',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Floating User Info Card + Membership Bar (Persis Gojek Layout)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 95, 16, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // User Info Row
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            // Avatar
                            ClipOval(
                              child: Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey.shade200,
                                child: _buildProfileAvatar(user?.avatarUrl),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Name & Contact
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Colors.black87),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    userEmail,
                                    style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    userPhone,
                                    style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),

                            // Pencil Edit Button
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.black87),
                              tooltip: 'Ubah Profil',
                              onPressed: _openEditProfile,
                            ),
                          ],
                        ),
                      ),

                      // Yellow Gold Membership Bar ("Join GoStar / GAGE Star - Ada reward eksklusif ->")
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => const MembershipScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD54F), // Gold yellow GoStar
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.star_rounded, color: Color(0xFF5D4037), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Join GAGE Plus',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: Color(0xFF3E2723),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Ada reward eksklusif',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      color: Color(0xFF4E342E),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF4E342E)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // SECTION 1: PREFERENSI (Grouped Card)
            _buildSectionHeader('Preferensi'),
            _buildGroupedCard([
              _buildListRow(
                icon: Icons.shield_outlined,
                title: 'Keamanan akun',
                onTap: _showSecurityModal,
              ),
              _buildListRow(
                icon: Icons.event_repeat_rounded,
                title: 'Langganan',
                badgeText: 'Promo terbatas 🔥',
                badgeColor: const Color(0xFF00880C),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const MembershipScreen()),
                  );
                },
              ),
              _buildListRow(
                icon: Icons.credit_card_rounded,
                title: 'Metode Pembayaran',
                onTap: _showPaymentModal,
              ),
              _buildListRow(
                icon: Icons.people_outline_rounded,
                title: 'Akun Keluarga',
                badgeText: 'Baru',
                badgeColor: const Color(0xFF00880C),
                onTap: _showFamilyModal,
              ),
              _buildListRow(
                icon: Icons.bookmark_border_rounded,
                title: 'Alamat tersimpan',
                onTap: _showSavedAddressesModal,
              ),
              _buildListRow(
                icon: Icons.verified_user_outlined,
                title: 'Pusat Akun Terverifikasi',
                badgeText: 'Baru',
                badgeColor: const Color(0xFF00880C),
                isLast: true,
                onTap: _showKycModal,
              ),
            ]),

            const SizedBox(height: 16),

            // SECTION 2: AKTIVITAS DI GAGE (Grouped Card)
            _buildSectionHeader('Aktivitas di GAGE'),
            _buildGroupedCard([
              _buildListRow(
                icon: Icons.receipt_long_outlined,
                title: 'Aktivitas',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const OrdersScreen()),
                  );
                },
              ),
              _buildListRow(
                icon: Icons.local_offer_outlined,
                title: 'Promo & voucher',
                isLast: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const PromoScreen()),
                  );
                },
              ),
            ]),

            const SizedBox(height: 16),

            // SECTION 3: PENGATURAN APLIKASI (Grouped Card)
            _buildSectionHeader('Pengaturan aplikasi'),
            _buildGroupedCard([
              _buildListRow(
                icon: Icons.phone_android_rounded,
                title: 'Ikon aplikasi',
                onTap: _showAppIconModal,
              ),
              _buildListRow(
                icon: Icons.language_rounded,
                title: 'Bahasa',
                trailingText: _selectedLanguage,
                onTap: _showLanguageModal,
              ),
              _buildListRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notifikasi',
                onTap: _showNotificationModal,
              ),
              _buildListRow(
                icon: Icons.accessibility_new_rounded,
                title: 'Aksesibilitas',
                isLast: true,
                onTap: _showAccessibilityModal,
              ),
            ]),

            const SizedBox(height: 16),

            // SECTION 4: LEBIH BANYAK DARI GAGE (Grouped Card)
            _buildSectionHeader('Lebih banyak dari GAGE'),
            _buildGroupedCard([
              _buildListRow(
                icon: Icons.business_center_outlined,
                title: 'Profil bisnis',
                onTap: _showBusinessModal,
              ),
              _buildListRow(
                icon: Icons.electric_moped_rounded,
                title: 'Gabung jadi Mitra Driver',
                onTap: _showDriverModal,
              ),
              _buildListRow(
                icon: Icons.auto_awesome_rounded,
                title: 'Studio Kreator Afiliasi',
                badgeText: 'Cuan',
                badgeColor: const Color(0xFFEA580C),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const AffiliateHubScreen()),
                  );
                },
              ),
              _buildListRow(
                icon: Icons.group_add_outlined,
                title: 'Ajak teman, dapat voucher',
                isLast: true,
                onTap: _showReferralModal,
              ),
            ]),

            const SizedBox(height: 16),

            // SECTION 5: LAINNYA (Grouped Card)
            _buildSectionHeader('Lainnya'),
            _buildGroupedCard([
              _buildListRow(
                icon: Icons.help_outline_rounded,
                title: 'Bantuan & laporan',
                onTap: _launchWaCs,
              ),
              _buildListRow(
                icon: Icons.verified_user_outlined,
                title: 'Syarat & Ketentuan Layanan',
                badgeText: 'Resmi',
                badgeColor: const Color(0xFF00880C),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const TermsAndPrivacyScreen(initialTabIndex: 0),
                    ),
                  );
                },
              ),
              _buildListRow(
                icon: Icons.info_outline_rounded,
                title: 'Tentang Aplikasi & Lisensi Data',
                onTap: _showAboutAndDataLicensesModal,
              ),
              _buildListRow(
                icon: Icons.star_outline_rounded,
                title: 'Beri rating',
                onTap: _showRatingModal,
              ),
              _buildListRow(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Portal Admin & Pengaturan Biaya',
                badgeText: 'Admin',
                badgeColor: const Color(0xFFE52320),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const AdminScreen(),
                    ),
                  );
                },
              ),
              _buildListRow(
                icon: Icons.delete_outline_rounded,
                title: 'Atur akun',
                isLast: true,
                onTap: () => _showAccountSettingsModal(auth),
              ),
            ]),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // Section Header Label
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  // White Grouped Card Container
  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // Standard Row Item in Gojek Style
  Widget _buildListRow({
    required IconData icon,
    required String title,
    String? badgeText,
    Color? badgeColor,
    String? trailingText,
    bool isLast = false,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(icon, size: 21, color: Colors.black87),
                const SizedBox(width: 14),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: badgeColor ?? const Color(0xFF00880C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingText != null) ...[
                  Text(trailingText, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(width: 4),
                ],
                const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.black45),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 50, right: 16),
            child: Divider(height: 1, color: Colors.grey.shade100),
          ),
      ],
    );
  }
}
