import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/routing/portal_routes.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/auth/merchant_register_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Screen Masuk Mitra Usaha GAGE Pracimantoro
/// - Login via Nomor WhatsApp Toko & PIN 6-Digit
/// - Segmented Pill Switcher (Masuk | Daftar Usaha) dengan Full-Rounded Capsule
/// - Dev Quick Login (Dimsum Sewu) untuk pengujian cepat
class MerchantLoginScreen extends StatefulWidget {
  const MerchantLoginScreen({super.key});

  @override
  State<MerchantLoginScreen> createState() => _MerchantLoginScreenState();
}

class _MerchantLoginScreenState extends State<MerchantLoginScreen> {
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

  Future<void> _handleLogin() async {
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

                const SizedBox(height: 28),

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
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: GageTheme.primary,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: GageTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Masuk Toko',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const MerchantRegisterScreen()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Daftar Baru',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Form Input Card
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
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.phone_android_rounded, size: 20, color: GageTheme.primary),
                          hintText: 'Contoh: 085156955735',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'PIN Keamanan Toko (6 Digit)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _pinCtrl,
                        obscureText: _obscurePin,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: GageTheme.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(() => _obscurePin = !_obscurePin),
                          ),
                          hintText: 'Masukkan PIN toko Anda',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tombol Masuk Utama
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Masuk ke Dapur & Kasir',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Dev Fast Login Bypass (GageApiClient.useDevSeedData)
                if (GageApiClient.useDevSeedData) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFF6EE7B7)),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.fast_forward_rounded, size: 18),
                    label: const Text(
                      'Masuk Cepat Demo: Dimsum Sewu',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                    onPressed: _isLoading ? null : _handleDevQuickLogin,
                  ),
                  const SizedBox(height: 16),
                ],

                // 5. Footer Bantuan
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      GageToast.show(context, 'Menghubungi Pusat Bantuan Mitra GAGE via WhatsApp...');
                    },
                    icon: const Icon(Icons.help_outline_rounded, size: 16, color: GageTheme.textSecondary),
                    label: const Text(
                      'Butuh Bantuan Masuk Akun?',
                      style: TextStyle(fontSize: 12, color: GageTheme.textSecondary, fontWeight: FontWeight.w600),
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
}
