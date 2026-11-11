import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/theme_provider.dart';
import 'package:gage_app/providers/language_provider.dart';
import 'package:gage_app/core/localization/gage_localization.dart';
import 'package:gage_app/core/services/gage_security_service.dart';
import 'package:gage_app/features/auth/presentation/terms_and_privacy_screen.dart';
import 'package:gage_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:gage_app/features/membership/presentation/membership_screen.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_bottom_nav_bar.dart';
import 'package:gage_app/features/home/presentation/home_screen.dart';

/// ProfileScreen - Authentic Account, Security & Preferences Center
/// Produk: GAGE Pracimantoro
/// Lini Usaha: GAGE by Halu Goods Indonesia
/// Holding Company: Halu Goods Indonesia
/// Zero duplicated shortcuts (no Pesanan/Riwayat/Voucher/Bank/Affiliate duplicates).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifOrders = true;
  bool _notifPromo = true;
  bool _hapticEnabled = true;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final bioOn = await GageSecurityService.instance.isBiometricsEnabled();
    if (mounted) {
      setState(() {
        _notifOrders = prefs.getBool('pref_notif_orders') ?? true;
        _notifPromo = prefs.getBool('pref_notif_promo') ?? true;
        _hapticEnabled = prefs.getBool('pref_haptic') ?? true;
        _biometricEnabled = bioOn;
      });
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _openWhatsAppSupport() async {
    HapticFeedback.lightImpact();
    const phone = '6281226001000';
    const message = 'Halo CS Resmi GAGE Pracimantoro (GAGE by Halu Goods Indonesia), saya butuh bantuan terkait akun dan transaksi saya.';
    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          GageToast.show(
            context,
            'Hubungi WhatsApp CS GAGE Pracimantoro: +$phone',
            type: GageToastType.info,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        GageToast.show(
          context,
          'Hubungi WhatsApp CS GAGE Pracimantoro: +$phone',
          type: GageToastType.info,
        );
      }
    }
  }

  void _showChangePinSheet(bool isDark) {
    HapticFeedback.lightImpact();
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    GageFloatingSheet.show(
      context: context,
      title: 'Ubah PIN GAGEPay 6 Digit',
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PIN 6 digit digunakan untuk otorisasi transaksi saldo GAGEPay, pembayaran QRIS, & penarikan tunai.',
                  style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.grey.shade700, height: 1.35),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  style: TextStyle(fontSize: 18, letterSpacing: 8, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'PIN Baru (6 Angka)',
                    labelStyle: TextStyle(fontSize: 13, letterSpacing: 0, color: isDark ? Colors.white70 : Colors.grey.shade700),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    counterText: '',
                    prefixIcon: const Icon(Icons.pin_rounded, size: 20, color: GageTheme.primary),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: confirmController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  style: TextStyle(fontSize: 18, letterSpacing: 8, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi PIN Baru',
                    labelStyle: TextStyle(fontSize: 13, letterSpacing: 0, color: isDark ? Colors.white70 : Colors.grey.shade700),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: GageTheme.primary),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final pin = pinController.text.trim();
                      final confirm = confirmController.text.trim();
                      if (pin.length != 6 || int.tryParse(pin) == null) {
                        GageToast.show(context, 'PIN harus terdiri dari 6 angka.', type: GageToastType.error);
                        return;
                      }
                      if (pin != confirm) {
                        GageToast.show(context, 'Konfirmasi PIN tidak cocok.', type: GageToastType.error);
                        return;
                      }
                      GageSecurityService.instance.setTransactionPin(pin);
                      Navigator.pop(sheetCtx);
                      GageToast.show(context, '✓ PIN transaksi GAGEPay berhasil disimpan.', type: GageToastType.success);
                    },
                    child: const Text('Simpan PIN Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickProfileAvatar(BuildContext context, AuthProvider auth, bool isDark) async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();

    GageFloatingSheet.show(
      context: context,
      title: 'Pilih Foto Profil',
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFEE2E2),
              child: Icon(Icons.camera_alt_rounded, color: GageTheme.primary),
            ),
            title: Text(
              'Ambil Foto dari Kamera',
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
            subtitle: Text(
              'Gunakan kamera HP langsung',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            onTap: () async {
              Navigator.pop(sheetCtx);
              try {
                final XFile? image = await picker.pickImage(source: ImageSource.camera, maxWidth: 800, maxHeight: 800, imageQuality: 85);
                if (image != null) {
                  await auth.updateProfile(avatarUrl: image.path);
                  if (mounted) {
                    GageToast.show(context, '✓ Foto profil berhasil diperbarui', type: GageToastType.success);
                  }
                }
              } catch (e) {
                if (mounted) {
                  GageToast.show(context, 'Gagal mengambil foto: $e', type: GageToastType.error);
                }
              }
            },
          ),
          const SizedBox(height: 4),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEFF6FF),
              child: Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB)),
            ),
            title: Text(
              'Pilih dari Galeri',
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
            subtitle: Text(
              'Pilih foto dari penyimpanan perangkat',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            onTap: () async {
              Navigator.pop(sheetCtx);
              try {
                final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
                if (image != null) {
                  await auth.updateProfile(avatarUrl: image.path);
                  if (mounted) {
                    GageToast.show(context, '✓ Foto profil berhasil diperbarui', type: GageToastType.success);
                  }
                }
              } catch (e) {
                if (mounted) {
                  GageToast.show(context, 'Gagal memilih foto: $e', type: GageToastType.error);
                }
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _handleBiometricToggle(bool val) async {
    HapticFeedback.lightImpact();
    if (val) {
      final isSupported = await GageSecurityService.instance.isDeviceSupported();
      if (!isSupported) {
        if (!mounted) return;
        GageToast.show(
          context,
          'Perangkat Anda belum mendukung sensor sidik jari/biometrik.',
          type: GageToastType.warning,
        );
        setState(() => _biometricEnabled = false);
        return;
      }

      final hasEnrolled = await GageSecurityService.instance.hasEnrolledBiometrics();
      if (!hasEnrolled) {
        if (!mounted) return;
        GageToast.show(
          context,
          'Belum ada sidik jari terdaftar di pengaturan sistem HP Anda.',
          type: GageToastType.warning,
        );
        setState(() => _biometricEnabled = false);
        return;
      }

      final authSuccess = await GageSecurityService.instance.authenticateWithBiometrics(
        localizedReason: 'Pindai sidik jari Anda untuk mengaktifkan proteksi transaksi GAGEPay',
      );

      if (authSuccess) {
        await GageSecurityService.instance.setBiometricsEnabled(true);
        if (!mounted) return;
        setState(() => _biometricEnabled = true);
        GageToast.show(
          context,
          '✓ Sidik jari berhasil diaktifkan untuk transaksi & top up!',
          type: GageToastType.success,
        );
      } else {
        if (!mounted) return;
        setState(() => _biometricEnabled = false);
        GageToast.show(
          context,
          'Verifikasi sidik jari dibatalkan.',
          type: GageToastType.info,
        );
      }
    } else {
      await GageSecurityService.instance.setBiometricsEnabled(false);
      setState(() => _biometricEnabled = false);
      GageToast.show(
        context,
        'Autentikasi sidik jari dinonaktifkan.',
        type: GageToastType.info,
      );
    }
  }

  void _showLanguagePickerSheet(bool isDark) {
    HapticFeedback.lightImpact();
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = langProvider.language;

    GageFloatingSheet.show(
      context: context,
      title: 'Pilih Bahasa Aplikasi',
      builder: (sheetCtx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: GageAppLanguage.values.map((lang) {
            final isSelected = lang == currentLang;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? GageTheme.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? GageTheme.primary : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(lang.flag, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                title: Text(
                  lang.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  lang.description,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: GageTheme.primary, size: 22)
                    : null,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  langProvider.setLanguage(lang);
                  Navigator.pop(sheetCtx);
                  GageToast.show(
                    context,
                    '✓ Bahasa diubah ke ${lang.label}',
                    type: GageToastType.success,
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showNotificationSettingsSheet(bool isDark) {
    HapticFeedback.lightImpact();
    GageFloatingSheet.show(
      context: context,
      title: 'Pengaturan Notifikasi',
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSwitchTile(
                  title: 'Notifikasi Pesanan & Driver',
                  subtitle: 'Update status pesanan makanan, antar barang & ojek',
                  value: _notifOrders,
                  isDark: isDark,
                  onChanged: (val) {
                    setState(() => _notifOrders = val);
                    setSheetState(() {});
                    _savePreference('pref_notif_orders', val);
                  },
                ),
                const SizedBox(height: 10),
                _buildSwitchTile(
                  title: 'Promo & Diskon Kilat',
                  subtitle: 'Info voucher gratis ongkir dan diskon merchant mitra',
                  value: _notifPromo,
                  isDark: isDark,
                  onChanged: (val) {
                    setState(() => _notifPromo = val);
                    setSheetState(() {});
                    _savePreference('pref_notif_promo', val);
                  },
                ),
                const SizedBox(height: 10),
                _buildSwitchTile(
                  title: 'Getaran Respon Haptik',
                  subtitle: 'Sentuhan getar lembut saat menekan tombol & kartu',
                  value: _hapticEnabled,
                  isDark: isDark,
                  onChanged: (val) {
                    setState(() => _hapticEnabled = val);
                    setSheetState(() {});
                    _savePreference('pref_haptic', val);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showThemePickerSheet(bool isDark) {
    HapticFeedback.lightImpact();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currentMode = themeProvider.themeMode;

    GageFloatingSheet.show(
      context: context,
      title: 'Pilih Tema Tampilan',
      builder: (sheetCtx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOptionTile(
              title: 'Mode Terang (Light)',
              subtitle: 'Tampilan bersih bernuansa putih cerah',
              icon: Icons.light_mode_rounded,
              iconColor: const Color(0xFFEA580C),
              isSelected: currentMode == ThemeMode.light,
              isDark: isDark,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.light);
                Navigator.pop(sheetCtx);
              },
            ),
            const SizedBox(height: 10),
            _buildThemeOptionTile(
              title: 'Mode Gelap (Dark)',
              subtitle: 'Nyaman untuk mata di malam hari & hemat baterai',
              icon: Icons.dark_mode_rounded,
              iconColor: const Color(0xFF6366F1),
              isSelected: currentMode == ThemeMode.dark,
              isDark: isDark,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.dark);
                Navigator.pop(sheetCtx);
              },
            ),
            const SizedBox(height: 10),
            _buildThemeOptionTile(
              title: 'Ikuti Pengaturan Sistem',
              subtitle: 'Otomatis menyesuaikan dengan mode ponsel Anda',
              icon: Icons.settings_brightness_rounded,
              iconColor: const Color(0xFF10B981),
              isSelected: currentMode == ThemeMode.system,
              isDark: isDark,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.system);
                Navigator.pop(sheetCtx);
              },
            ),
          ],
        );
      },
    );
  }

  void _showFaqSheet(bool isDark) {
    HapticFeedback.lightImpact();
    GageFloatingSheet.show(
      context: context,
      title: 'Pusat Bantuan & FAQ',
      builder: (ctx) {
        final faqs = [
          {
            'q': 'Bagaimana cara memesan makanan di GAGE Food?',
            'a': 'Buka menu Food di halaman utama, pilih resto mitra terdekat di Pracimantoro, tambahkan menu ke keranjang, lalu lanjutkan ke pembayaran.',
          },
          {
            'q': 'Bagaimana cara mengisi saldo GAGEPay?',
            'a': 'Pilih GAGEPay di kartu dompet atas atau di halaman pembayaran, masukkan nominal isi saldo melalui Horizontal Ruler, lalu bayar via QRIS resmi.',
          },
          {
            'q': 'Berapa radius pengantaran GAGE Send & Food?',
            'a': 'Layanan GAGE melayani seluruh kecamatan Pracimantoro dan perbatasan sekitarnya dengan tarif transparan mulai Rp 9.000.',
          },
          {
            'q': 'Bagaimana jika pesanan saya bermasalah?',
            'a': 'Hubungi Admin Layanan Pelanggan kami secara langsung melalui WhatsApp dengan menekan tombol Chat CS di menu Bantuan.',
          },
        ];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: faqs.map((faq) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faq['q']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    faq['a']!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showAboutSheet(bool isDark) {
    HapticFeedback.lightImpact();
    GageFloatingSheet.show(
      context: context,
      title: 'Tentang GAGE Pracimantoro',
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: GageTheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'GAGE Pracimantoro',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            Center(
              child: Text(
                'Produk Lini Usaha GAGE by Halu Goods Indonesia',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ),
            Center(
              child: Text(
                'Holding Company: Halu Goods Indonesia',
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'GAGE Pracimantoro adalah aplikasi layanan lokal terintegrasi yang menghadirkan kemudahan pesan antar makanan (GAGE Food), belanja toko mitra (GAGE Shop), ekspedisi kilat (GAGE Send), hasil tani (GAGE Farm), material bangunan (GAGE Build), serta transportasi motor dan mobil (GAGE Ride & Car) untuk memajukan perekonomian daerah Pracimantoro dan sekitarnya.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Versi 1.0.4+22 • Wilayah Operasional Pracimantoro',
                style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white38 : Colors.grey.shade500),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Keluar Akun?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun GAGE Pracimantoro di perangkat ini?',
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
                GageToast.show(context, 'Berhasil keluar dari akun', type: GageToastType.info);
              }
            },
            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    HapticFeedback.heavyImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Hapus Akun Permanen?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
          ],
        ),
        content: Text(
          'Tindakan ini tidak dapat dibatalkan. Seluruh riwayat transaksi, data profil, dan saldo GAGEPay Anda akan dihapus secara permanen sesuai regulasi perlindungan data pribadi.',
          style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              GageToast.show(context, 'Permintaan penghapusan akun telah dicatat. Tim kami akan memproses dalam 1x24 jam.', type: GageToastType.info);
            },
            child: const Text('Hapus Akun', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    final userName = (user?.name != null && user!.name.isNotEmpty) ? user.name : 'Siti Rahmawati';
    final userPhone = (user?.phone != null && user!.phone.isNotEmpty) ? user.phone : '+62 812-3456-7890';
    final userEmail = (user?.email != null && user!.email!.isNotEmpty) ? user.email! : 'siti.rahmawati@gmail.com';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Akun & Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF475569),
              size: 21,
            ),
            tooltip: 'Ganti Tema',
            onPressed: () => _showThemePickerSheet(isDark),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 300));
              if (mounted) setState(() {});
            },
            color: GageTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==========================================
                  // 1. KARTU IDENTITAS PENGGUNA (CUSTOMER CARD)
                  // ==========================================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar dengan Foto Real / Inisial + Tap Ganti Foto
                        GestureDetector(
                          onTap: () => _pickProfileAvatar(context, auth, isDark),
                          child: Stack(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _buildResolvedProfileAvatar(user?.avatarUrl, userName),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: GageTheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Nama, Nomor Telepon, Status Terverifikasi
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 6,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    userPhone,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 10),
                                        SizedBox(width: 3),
                                        Text(
                                          'WA Terverifikasi',
                                          style: TextStyle(
                                            color: Color(0xFF16A34A),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Tombol Ubah Data Diri
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: GageTheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded, color: GageTheme.primary, size: 16),
                          ),
                          tooltip: 'Edit Profil',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==========================================
                  // 2. LANGGANAN EKSKLUSIF VIP (GAGE Plus & Max)
                  // ==========================================
                  _buildSectionHeader('Langganan VIP', isDark),
                  const SizedBox(height: 8),
                  _buildLuxurySubscriptionCard(isDark),

                  const SizedBox(height: 18),

                  // ==========================================
                  // 3. KEAMANAN & TRANSAKSI
                  // ==========================================
                  _buildSectionHeader('Keamanan & Transaksi', isDark),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSeamlessMenuTile(
                          icon: Icons.lock_outline_rounded,
                          iconColor: const Color(0xFFDC2626),
                          title: 'Ubah PIN GAGEPay 6 Digit',
                          subtitle: 'PIN otorisasi pembayaran dompet & QRIS',
                          isDark: isDark,
                          onTap: () => _showChangePinSheet(isDark),
                        ),
                        _buildSoftCardDivider(isDark),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF0284C7), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Login Biometrik / Sidik Jari',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Masuk cepat aman tanpa ketik sandi',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _biometricEnabled,
                                activeThumbColor: GageTheme.primary,
                                onChanged: (val) => _handleBiometricToggle(val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==========================================
                  // 3. PREFERENSI APLIKASI
                  // ==========================================
                  _buildSectionHeader('Preferensi Aplikasi', isDark),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSeamlessMenuTile(
                          icon: Icons.palette_outlined,
                          iconColor: const Color(0xFF8B5CF6),
                          title: 'Tema Tampilan',
                          subtitle: isDark ? 'Mode Gelap Aktif' : 'Mode Terang Aktif',
                          isDark: isDark,
                          onTap: () => _showThemePickerSheet(isDark),
                        ),
                        _buildSoftCardDivider(isDark),
                        _buildSeamlessMenuTile(
                          icon: Icons.notifications_none_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Pengaturan Notifikasi',
                          subtitle: 'Status pesanan, diskon & respon haptik',
                          isDark: isDark,
                          onTap: () => _showNotificationSettingsSheet(isDark),
                        ),
                        _buildSoftCardDivider(isDark),
                        Builder(
                          builder: (tileCtx) {
                            final langProv = Provider.of<LanguageProvider?>(tileCtx);
                            final currentLabel = langProv?.language.label ?? 'Bahasa Indonesia';
                            final currentDesc = langProv?.language.description ?? 'Standar';
                            return _buildSeamlessMenuTile(
                              icon: Icons.language_rounded,
                              iconColor: const Color(0xFF0D9488),
                              title: 'Bahasa Aplikasi',
                              subtitle: '$currentLabel ($currentDesc)',
                              isDark: isDark,
                              onTap: () => _showLanguagePickerSheet(isDark),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==========================================
                  // 4. PUSAT BANTUAN & CS
                  // ==========================================
                  _buildSectionHeader('Pusat Bantuan & Layanan', isDark),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSeamlessMenuTile(
                          icon: Icons.support_agent_rounded,
                          iconColor: const Color(0xFF16A34A),
                          title: 'Chat CS WhatsApp Resmi',
                          subtitle: 'Bantuan instan admin GAGE Pracimantoro',
                          isDark: isDark,
                          badge: 'ONLINE',
                          badgeColor: const Color(0xFF16A34A),
                          onTap: _openWhatsAppSupport,
                        ),
                        _buildSoftCardDivider(isDark),
                        _buildSeamlessMenuTile(
                          icon: Icons.help_outline_rounded,
                          iconColor: const Color(0xFF0284C7),
                          title: 'Pertanyaan Umum (FAQ)',
                          subtitle: 'Panduan pemesanan, pengisian saldo & layanan',
                          isDark: isDark,
                          onTap: () => _showFaqSheet(isDark),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==========================================
                  // 5. TENTANG GAGE PRACIMANTORO
                  // ==========================================
                  _buildSectionHeader('Tentang & Legalitas', isDark),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSeamlessMenuTile(
                          icon: Icons.info_outline_rounded,
                          iconColor: const Color(0xFF0284C7),
                          title: 'Tentang GAGE Pracimantoro',
                          subtitle: 'GAGE by Halu Goods Indonesia',
                          isDark: isDark,
                          onTap: () => _showAboutSheet(isDark),
                        ),
                        _buildSoftCardDivider(isDark),
                        _buildSeamlessMenuTile(
                          icon: Icons.verified_user_outlined,
                          iconColor: const Color(0xFF475569),
                          title: 'Syarat & Kebijakan Privasi',
                          subtitle: 'Standar perlindungan data pribadi pengguna',
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsAndPrivacyScreen()));
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // 6. ZONA KELUAR & HAPUS AKUN
                  // ==========================================
                  InkWell(
                    onTap: () => _confirmLogout(context, auth),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Keluar dari Akun',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: TextButton(
                      onPressed: () => _confirmDeleteAccount(context),
                      child: Text(
                        'Hapus Akun Permanen',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'GAGE Pracimantoro • Halu Goods Indonesia',
                      style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white38 : Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Bottom Navigation Bar
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GageBottomNavBar(currentIndex: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: isDark ? Colors.white60 : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildSeamlessMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: badgeColor ?? GageTheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white30 : Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildSoftCardDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 14),
      child: Container(
        height: 0.8,
        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: GageTheme.primary,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              onChanged(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? GageTheme.primary.withValues(alpha: 0.08)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? GageTheme.primary : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: GageTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildResolvedProfileAvatar(String? avatarUrl, String userName) {
    final initials = userName.length >= 2 ? userName.substring(0, 2).toUpperCase() : 'SR';
    final initialWidget = Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );

    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return initialWidget;
    }

    final trimmed = avatarUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => initialWidget,
      );
    }

    if (trimmed.startsWith('assets/')) {
      return Image.asset(
        trimmed,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => initialWidget,
      );
    }

    final localFile = File(trimmed);
    if (localFile.existsSync()) {
      return Image.file(
        localFile,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => initialWidget,
      );
    }

    return initialWidget;
  }

  Widget _buildLuxurySubscriptionCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF18181B), // Zinc 900
            Color(0xFF27272A), // Zinc 800
            Color(0xFF231E12), // Deep gold tint
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFEAB308).withValues(alpha: 0.5), // Royal Gold border
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEAB308).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MembershipScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                // Icon Crown / Star Badge Mewah
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFDE047),
                        Color(0xFFCA8A04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEAB308).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFF422006),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Teks Penjelasan Mewah
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Langganan GAGE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'VIP PLUS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Akses 900 voucher hemat, diskon 50% & prioritas driver',
                        style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 11.5,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol Aksi Mewah 'Buka >'
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAB308).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEAB308).withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Buka',
                        style: TextStyle(
                          color: Color(0xFFFDE047),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, color: Color(0xFFFDE047), size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
