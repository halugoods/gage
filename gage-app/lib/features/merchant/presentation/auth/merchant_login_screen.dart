import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/routing/portal_routes.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/auth/merchant_store_setup_wizard_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Screen Masuk & Pendaftaran Mitra Usaha GAGE Pracimantoro (Google-First).
/// - Masuk / Daftar cepat dengan Akun Google (Resmi Google Sign-In)
/// - Menghubungkan langsung ke Wizard Setup Toko untuk merchant baru
/// - Alternatif login nomor WhatsApp & PIN toko terdaftar
/// - Dev Quick-Login untuk pengujian cepat
class MerchantLoginScreen extends StatefulWidget {
  const MerchantLoginScreen({super.key});

  @override
  State<MerchantLoginScreen> createState() => _MerchantLoginScreenState();
}

class _MerchantLoginScreenState extends State<MerchantLoginScreen> {
  int _activeTab = 0; // 0 = Masuk Toko, 1 = Daftar Usaha Baru
  final TextEditingController _phoneCtrl = TextEditingController(text: '085156955735');
  final TextEditingController _pinCtrl = TextEditingController(text: '123456');
  bool _obscurePin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.signInWithGoogle();

      if (!mounted) return;

      if (success) {
        final userId = auth.currentUser?.id ?? '';
        final hasSetup = await MerchantStorefrontService.hasCompletedStoreSetup(userId);

        if (!mounted) return;

        if (_activeTab == 1 || !hasSetup) {
          // Arahkan ke Onboarding Wizard Setup Toko
          GageToast.show(context, 'Akun Google terhubung! Silakan lengkapi profil toko Anda.', type: GageToastType.success);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MerchantStoreSetupWizardScreen(
                initialEmail: auth.currentUser?.email,
                initialName: auth.currentUser?.name,
              ),
            ),
          );
        } else {
          // Toko sudah terdaftar -> langsung ke dashboard
          GageToast.show(context, 'Selamat datang kembali di Dapur & Kasir GAGE!', type: GageToastType.success);
          Navigator.of(context).pushReplacementNamed(MerchantRoutes.root);
        }
      } else {
        GageToast.show(
          context,
          auth.errorMessage ?? 'Gagal masuk dengan Google',
          type: GageToastType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        GageToast.show(context, 'Kendala masuk Google: $e', type: GageToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePhoneLogin() async {
    final phone = _phoneCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    if (phone.isEmpty || phone.length < 8) {
      GageToast.show(context, 'Masukkan nomor WhatsApp toko yang valid', type: GageToastType.warning);
      return;
    }

    if (pin.length < 4) {
      GageToast.show(context, 'PIN toko minimal 4-6 digit angka', type: GageToastType.warning);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.signInWithPhone(
        phone: phone,
        name: 'Mitra Usaha GAGE',
      );

      if (!mounted) return;

      if (success) {
        GageToast.show(context, 'Selamat datang kembali di Dapur & Kasir GAGE!', type: GageToastType.success);
        Navigator.of(context).pushReplacementNamed(MerchantRoutes.root);
      } else {
        GageToast.show(context, auth.errorMessage ?? 'Gagal masuk akun mitra', type: GageToastType.error);
      }
    } catch (e) {
      if (mounted) {
        GageToast.show(context, 'Kendala jaringan: $e', type: GageToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDevQuickLogin() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.signInDev(
        userId: 'm-dimsum-sewu',
        name: 'Dimsum Sewu (Mitra Food)',
        email: 'dimsumsewu@gage.id',
        phone: '085156955735',
      );

      if (!mounted) return;

      if (success) {
        GageToast.show(context, 'Masuk sebagai Dimsum Sewu (Pracimantoro)', type: GageToastType.success);
        Navigator.of(context).pushReplacementNamed(MerchantRoutes.root);
      } else {
        GageToast.show(context, 'Dev login gagal', type: GageToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Logo & Identitas Merchant Portal
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE52320), Color(0xFFB91C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: GageTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'GAGE Merchant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Portal Mitra Usaha & Kasir Pracimantoro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Segmented Pill Switcher (Masuk | Daftar)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _activeTab = 0);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _activeTab == 0 ? GageTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: _activeTab == 0
                                  ? [
                                      BoxShadow(
                                        color: GageTheme.primary.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'Masuk Toko',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _activeTab == 0 ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _activeTab = 1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _activeTab == 1 ? GageTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: _activeTab == 1
                                  ? [
                                      BoxShadow(
                                        color: GageTheme.primary.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'Daftar Baru',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _activeTab == 1 ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Tombol Google Sign-In Utama
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: _isLoading ? null : _handleGoogleSignIn,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGoogleLogo(),
                          const SizedBox(width: 12),
                          Text(
                            _activeTab == 0
                                ? 'Lanjutkan dengan Google'
                                : 'Daftar dengan Akun Google',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Divider Atau
                Row(
                  children: [
                    Expanded(child: Divider(color: borderColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'atau masuk dengan nomor HP',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500),
                      ),
                    ),
                    Expanded(child: Divider(color: borderColor)),
                  ],
                ),

                const SizedBox(height: 20),

                // 4. Form Alternatif Nomor WhatsApp & PIN
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nomor WhatsApp Toko',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(fontSize: 13.5, color: textColor, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: '085156955735',
                          hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.phone_android_rounded, size: 20, color: GageTheme.primary),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: GageTheme.primary, width: 1.8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        'PIN Akses Toko (6 Digit)',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _pinCtrl,
                        keyboardType: TextInputType.number,
                        obscureText: _obscurePin,
                        maxLength: 6,
                        style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w800, letterSpacing: 2),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '123456',
                          hintStyle: TextStyle(fontSize: 13, letterSpacing: 1, color: isDark ? Colors.white38 : Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: GageTheme.primary),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePin ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                            color: isDark ? Colors.white60 : Colors.grey.shade500,
                            onPressed: () => setState(() => _obscurePin = !_obscurePin),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: GageTheme.primary, width: 1.8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

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
                          onPressed: _isLoading ? null : _handlePhoneLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Masuk dengan Nomor WhatsApp',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 5. Dev Quick Login (Bypass Pengujian Cepat)
                if (GageApiClient.useDevSeedData) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GageTheme.primary,
                      side: const BorderSide(color: Color(0xFFFECACA), width: 1.2),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.bolt_rounded, size: 18, color: GageTheme.primary),
                    label: const Text(
                      'Masuk Cepat: Dimsum Sewu (Dev)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isLoading ? null : _handleDevQuickLogin,
                  ),
                  const SizedBox(height: 12),
                ],

                // Footer Bantuan
                Center(
                  child: Text(
                    'Kendala akses toko? Hubungi Layanan Mitra GAGE Pracimantoro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleLogo() {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Image.network(
        'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.g_mobiledata_rounded,
          size: 26,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}
