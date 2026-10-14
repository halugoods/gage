// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/features/home/presentation/promo_screen.dart';
import 'package:gage_app/features/membership/presentation/membership_screen.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';
import 'package:gage_app/features/auth/presentation/terms_and_privacy_screen.dart';
import 'package:gage_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:gage_app/features/admin/presentation/admin_screen.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

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
    GageFloatingSheet.show(
      context: context,
      builder: (ctx) => _buildSimpleSheet(
        ctx,
        title: 'Keamanan Akun',
        icon: Icons.shield_outlined,
        children: [
          _buildModalTile(
            title: 'PIN Transaksi GAGE',
            subtitle: 'PIN 6-digit aktif untuk verifikasi transaksi',
            trailing: const Text('Ubah', style: TextStyle(color: GageTheme.primary, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(ctx);
              GageToast.show(
                context,
                'Tautan ubah PIN telah dikirimkan ke email terdaftar Anda.',
                type: GageToastType.info,
              );
            },
          ),
          const Divider(),
          _buildModalTile(
            title: 'Autentikasi Biometrik',
            subtitle: 'Gunakan sidik jari atau Face ID saat membuka aplikasi',
            trailing: Switch(
              value: true,
              activeColor: GageTheme.primary,
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
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    GageFloatingSheet.show(
      context: context,
      builder: (ctx) => _buildSimpleSheet(
        ctx,
        title: 'Metode Pembayaran',
        icon: Icons.account_balance_wallet_outlined,
        children: [
          _buildModalTile(
            title: 'GAGE Pay',
            subtitle: 'Saldo utama: ${currencyFormatter.format(wallet.balance)}',
            leadingIcon: Icons.account_balance_wallet_rounded,
            iconColor: GageTheme.primary,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
              child: const Text('Aktif', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
          const Divider(),
          _buildModalTile(
            title: 'QRIS Realtime',
            subtitle: 'ShopeePay, GoPay, OVO, Dana, BCA Mobile',
            leadingIcon: Icons.qr_code_2_rounded,
            iconColor: const Color(0xFF0284C7),
            trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
          ),
          const Divider(),
          _buildModalTile(
            title: 'Tunai (COD)',
            subtitle: 'Bayar langsung ke driver saat pesanan tiba',
            leadingIcon: Icons.payments_outlined,
            iconColor: const Color(0xFF16A34A),
            trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
          ),
        ],
      ),
    );
  }

  // 3. Alamat Tersimpan Modal (Persistent dengan SharedPreferences & LocationPickerSheet)
  Future<void> _showSavedAddressesModal() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList('saved_user_addresses') ?? [
      'Rumah (Tubokarto)||Dusun Tubokarto RT 02/RW 01, Tubokarto, Pracimantoro, Kab. Wonogiri',
      'Rumah Etan||WRFV+WCJ, Jl. Perumahan Kota Baru, Sumberjo, Sambiroto, Kec. Pracimantoro',
      'Kantor / Tempat Usaha||Jalan Raya Pracimantoro - Wonogiri KM 1, Pracimantoro',
    ];

    if (!mounted) return;

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setModalState) {
          return _buildSimpleSheet(
            ctx,
            title: 'Alamat Tersimpan',
            icon: Icons.bookmark_border_rounded,
            children: [
              ...list.asMap().entries.map((entry) {
                final idx = entry.key;
                final parts = entry.value.split('||');
                final title = parts.isNotEmpty ? parts[0] : 'Alamat';
                final addr = parts.length > 1 ? parts[1] : '';

                return Column(
                  children: [
                    _buildModalTile(
                      title: title,
                      subtitle: addr,
                      leadingIcon: title.toLowerCase().contains('rumah')
                          ? Icons.home_rounded
                          : (title.toLowerCase().contains('kantor') ? Icons.business_rounded : Icons.location_on_rounded),
                      iconColor: GageTheme.primary,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                        onPressed: () async {
                          list.removeAt(idx);
                          await prefs.setStringList('saved_user_addresses', list);
                          setModalState(() {});
                          if (mounted) {
                            GageToast.show(
                              context,
                              'Alamat "$title" telah dihapus',
                              type: GageToastType.info,
                            );
                          }
                        },
                      ),
                    ),
                    if (idx < list.length - 1) const Divider(),
                  ],
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    LocationPickerSheet.show(
                      context,
                      title: 'Pilih Alamat Baru',
                      onSelected: (title, fullAddress, latLng) async {
                        list.add('$title||$fullAddress');
                        await prefs.setStringList('saved_user_addresses', list);
                        if (mounted) {
                          GageToast.show(
                            context,
                            'Alamat "$title" berhasil disimpan!',
                            type: GageToastType.success,
                          );
                        }
                      },
                    );
                  },
                  icon: const Icon(Icons.add_location_alt_rounded, size: 18, color: GageTheme.primary),
                  label: const Text('Tambah Alamat Baru', style: TextStyle(color: GageTheme.primary, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: GageTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 5. Pusat Akun Terverifikasi Modal
  void _showKycModal() {
    GageFloatingSheet.show(
      context: context,
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
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Akun Anda 100% Terverifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF16A34A))),
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
            trailing: const Icon(Icons.check_rounded, color: GageTheme.primary),
          ),
          const Divider(),
          _buildModalTile(
            title: 'Alamat Email',
            subtitle: 'halugoods.indonesia@gmail.com (Terverifikasi)',
            leadingIcon: Icons.email_outlined,
            trailing: const Icon(Icons.check_rounded, color: GageTheme.primary),
          ),
          const Divider(),
          _buildModalTile(
            title: 'Identitas Diri (KTP)',
            subtitle: 'Data kependudukan terdaftar sah',
            leadingIcon: Icons.badge_outlined,
            trailing: const Icon(Icons.check_rounded, color: GageTheme.primary),
          ),
        ],
      ),
    );
  }

  // 6. Ikon Aplikasi Modal
  void _showAppIconModal() {
    final icons = ['GAGE Merah Klasik', 'GAGE Hitam Emas', 'GAGE Hijau Eco'];
    GageFloatingSheet.show(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (c, setDlgState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: GageTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone_android_rounded, color: GageTheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Pilih Ikon Aplikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(dlgCtx),
                ),
              ],
            ),
            const Divider(height: 18),
            ...icons.map((ic) {
              return RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                title: Text(ic, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                value: ic,
                groupValue: _selectedAppIcon,
                activeColor: GageTheme.primary,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedAppIcon = val);
                    setDlgState(() {});
                    Navigator.pop(dlgCtx);
                    GageToast.show(
                      context,
                      'Ikon aplikasi diatur ke: $val',
                      type: GageToastType.success,
                    );
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // 7. Bahasa Modal
  void _showLanguageModal() {
    final languages = ['Bahasa Indonesia', 'English (US)', 'Basa Jawa'];
    GageFloatingSheet.show(
      context: context,
      builder: (dlgCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.language_rounded, color: GageTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Pilih Bahasa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(dlgCtx),
              ),
            ],
          ),
          const Divider(height: 18),
          ...languages.map((lang) {
            return RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: Text(lang, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
              value: lang,
              groupValue: _selectedLanguage,
              activeColor: GageTheme.primary,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedLanguage = val);
                  Navigator.pop(dlgCtx);
                  GageToast.show(
                    context,
                    'Bahasa aplikasi diubah ke: $val',
                    type: GageToastType.success,
                  );
                }
              },
            );
          }),
        ],
      ),
    );
  }

  // 8. Notifikasi Modal
  void _showNotificationModal() {
    GageFloatingSheet.show(
      context: context,
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
                activeColor: GageTheme.primary,
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
                activeColor: GageTheme.primary,
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
                activeColor: GageTheme.primary,
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
    GageFloatingSheet.show(
      context: context,
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
                activeColor: GageTheme.primary,
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
                activeColor: GageTheme.primary,
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



  // 11. Gabung Mitra Driver Modal
  void _showDriverModal() {
    GageFloatingSheet.show(
      context: context,
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
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    GageFloatingSheet.show(
      context: context,
      builder: (dlgCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: GageTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Ajak Teman, Dapat Voucher', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(dlgCtx),
              ),
            ],
          ),
          const Divider(height: 18),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: GageTheme.primary),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Colors.black87),
                  tooltip: 'Salin Kode',
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: code));
                    GageToast.show(
                      context,
                      'Kode referral disalin ke clipboard!',
                      type: GageToastType.success,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // 13. Rating Modal
  void _showRatingModal() {
    int rating = 5;
    GageFloatingSheet.show(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (c, setDlgState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Beri Rating Aplikasi GAGE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(dlgCtx),
                ),
              ],
            ),
            const Divider(height: 18),
            const Center(
              child: Text(
                'Bagikan pengalaman Anda menggunakan GAGE Delivery',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
            ),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(dlgCtx);
                  GageToast.show(
                    context,
                    'Terima kasih atas bintang $rating dari Anda!',
                    type: GageToastType.success,
                  );
                },
                child: const Text('Kirim Rating', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 14. Atur Akun / Logout Modal
  void _showAccountSettingsModal(AuthProvider auth) {
    GageFloatingSheet.show(
      context: context,
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
              final confirm = await GageFloatingSheet.show<bool>(
                context: context,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Colors.red, size: 22),
                        SizedBox(width: 8),
                        Text('Konfirmasi Keluar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Apakah Anda yakin ingin keluar dari akun GAGE ini?', style: TextStyle(fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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
              GageToast.show(
                context,
                'Permintaan penghapusan akun memerlukan konfirmasi email.',
                type: GageToastType.warning,
              );
            },
          ),
        ],
      ),
    );
  }

  // 15. Tentang Aplikasi & Lisensi Data Modal
  void _showAboutAndDataLicensesModal() {
    GageFloatingSheet.show(
      context: context,
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
                Icon(Icons.location_on_rounded, color: GageTheme.primary, size: 26),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GAGE Pracimantoro v1.0.2+4',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GageTheme.primary),
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
            iconColor: GageTheme.primary,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: GageTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: GageTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        const Divider(height: 18),
        ...children,
      ],
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? GageTheme.darkBackground : const Color(0xFFF8F9FA),
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
                      colors: [GageTheme.primary, Color(0xFFC62828), Color(0xFFB71C1C)],
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
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Profilku',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                    color: Theme.of(context).brightness == Brightness.dark ? GageTheme.darkSurface : Colors.white,
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
                            children: [
                              Icon(Icons.star_rounded, color: Color(0xFF5D4037), size: 18),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Join GAGE Plus',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: Color(0xFF3E2723),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
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
                badgeColor: GageTheme.primary,
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
                icon: Icons.bookmark_border_rounded,
                title: 'Alamat tersimpan',
                onTap: _showSavedAddressesModal,
              ),
              _buildListRow(
                icon: Icons.verified_user_outlined,
                title: 'Pusat Akun Terverifikasi',
                badgeText: 'Baru',
                badgeColor: GageTheme.primary,
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
                badgeColor: GageTheme.primary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : const Color(0xFF4B5563),
        ),
      ),
    );
  }

  // White Grouped Card Container
  Widget _buildGroupedCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? GageTheme.darkBorder : Colors.grey.shade200),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(icon, size: 21, color: isDark ? Colors.white70 : Colors.black87),
                const SizedBox(width: 14),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: badgeColor ?? GageTheme.primary,
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
                  Text(trailingText, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                  const SizedBox(width: 4),
                ],
                Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white38 : Colors.black45),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 50, right: 16),
            child: Divider(height: 1, color: isDark ? GageTheme.darkBorder : Colors.grey.shade100),
          ),
      ],
    );
  }
}
