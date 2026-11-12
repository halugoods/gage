import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/services/gage_permission_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/auth/presentation/terms_and_privacy_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/shared/widgets/gage_tap_scale.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Screen Otentikasi GAGE Pracimantoro (Masuk & Daftar)
/// - Tab Switch: Masuk | Daftar
/// - Jalur Utama: WhatsApp OTP & Google Sign-In
/// - Verifikasi Cold-Start: GPS Wajib Aktif & Permission Handshake
class GageAuthScreen extends StatefulWidget {
  final bool initialIsRegister;

  const GageAuthScreen({
    super.key,
    this.initialIsRegister = false,
  });

  @override
  State<GageAuthScreen> createState() => _GageAuthScreenState();
}

class _GageAuthScreenState extends State<GageAuthScreen> {
  late bool _isRegister;

  // Form Controllers
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _referralCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();

  // OTP State
  bool _isOtpStage = false;
  int _otpCooldown = 0;
  Timer? _timer;

  // Checkbox Syarat & Ketentuan
  bool _agreedToTerms = true;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialIsRegister;

    // Verifikasi GPS & Permintaan Izin Awal saat Pertama Kali Buka Layar
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await GagePermissionService.requestFirstInstallPermissions();
      if (mounted) {
        await GagePermissionService.checkAndEnforceGps(context);
      }
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _referralCtrl.dispose();
    _otpCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startOtpCooldown() {
    setState(() => _otpCooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_otpCooldown <= 1) {
        t.cancel();
        setState(() => _otpCooldown = 0);
      } else {
        setState(() => _otpCooldown--);
      }
    });
  }

  void _submitWhatsApp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      GageToast.show(context, 'Masukkan nomor HP yang valid', type: GageToastType.warning);
      return;
    }

    if (_isRegister && _nameCtrl.text.trim().isEmpty) {
      GageToast.show(context, 'Nama lengkap wajib diisi untuk pendaftaran', type: GageToastType.warning);
      return;
    }

    if (!_agreedToTerms) {
      GageToast.show(context, 'Harap setujui Syarat & Ketentuan Layanan', type: GageToastType.warning);
      return;
    }

    // Simulasi Pengiriman Kode OTP Nomor HP
    HapticFeedback.mediumImpact();
    setState(() {
      _isOtpStage = true;
    });
    _startOtpCooldown();
    GageToast.show(
      context,
      'Kode OTP 6-digit dikirim ke nomor +62 $phone',
      type: GageToastType.success,
    );
  }

  void _verifyOtpAndLogin() async {
    final auth = context.read<AuthProvider>();
    final otp = _otpCtrl.text.trim();

    if (otp.length != 6) {
      GageToast.show(context, 'Masukkan 6-digit kode OTP dengan benar', type: GageToastType.warning);
      return;
    }

    // Jalankan Login / Register via AuthProvider
    final success = await auth.signInWithPhone(
      phone: _phoneCtrl.text.trim(),
      name: _isRegister ? _nameCtrl.text.trim() : null,
      referralCode: _isRegister ? _referralCtrl.text.trim() : null,
    );

    if (!mounted) return;

    if (success) {
      GageToast.show(
        context,
        _isRegister ? 'Selamat bergabung di GAGE Pracimantoro!' : 'Selamat datang kembali di GAGE!',
        type: GageToastType.success,
      );
    } else {
      GageToast.show(context, auth.errorMessage ?? 'Verifikasi OTP gagal', type: GageToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // 1. Brand Logo Header & Tagline
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: GageTheme.primary,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: GageTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'GAGE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Center(
                child: Text(
                  'GAGE by Halu Goods Indonesia',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 2. Segmented Tab Switch: [ Masuk ] | [ Daftar ]
              if (!_isOtpStage)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          title: 'Masuk',
                          isSelected: !_isRegister,
                          onTap: () {
                            if (_isRegister) {
                              HapticFeedback.selectionClick();
                              setState(() => _isRegister = false);
                            }
                          },
                          isDark: isDark,
                        ),
                      ),
                      Expanded(
                        child: _buildTabButton(
                          title: 'Daftar Akun',
                          isSelected: _isRegister,
                          onTap: () {
                            if (!_isRegister) {
                              HapticFeedback.selectionClick();
                              setState(() => _isRegister = true);
                            }
                          },
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // 3. Form Input Container (Gaya Modern NUSA Kasir)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isOtpStage) ...[
                      // Mode Daftar: Nama Lengkap
                      if (_isRegister) ...[
                        _buildFieldLabel('Nama Lengkap', isDark),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: _nameCtrl,
                          hintText: 'Misal: Syams Djuhair',
                          icon: Icons.person_outline_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Field Nomor HP (+62 Prefix)
                      _buildFieldLabel('Nomor HP / Telepon', isDark),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text('🇮🇩', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  '+62',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: isDark ? Colors.white : GageTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInputField(
                              controller: _phoneCtrl,
                              hintText: '812-3456-7890',
                              icon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),

                      // Mode Daftar: Kode Referral Opsional
                      if (_isRegister) ...[
                        const SizedBox(height: 14),
                        _buildFieldLabel('Kode Referral (Opsional)', isDark),
                        const SizedBox(height: 6),
                        _buildInputField(
                          controller: _referralCtrl,
                          hintText: 'Misal: GAGEHEMAT',
                          icon: Icons.card_giftcard_rounded,
                          textCapitalization: TextCapitalization.characters,
                          isDark: isDark,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Tombol OTP Nomor HP Submit
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _submitWhatsApp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.sms_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _isRegister ? 'Daftar dengan Nomor HP' : 'Kirim Kode OTP',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ] else ...[
                      // STAGE OTP INPUT
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFieldLabel('Masukkan 6-Digit Kode OTP', isDark),
                          InkWell(
                            onTap: () => setState(() => _isOtpStage = false),
                            child: const Text(
                              'Ubah Nomor',
                              style: TextStyle(fontSize: 11.5, color: GageTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kode telah dikirim ke +62 ${_phoneCtrl.text.trim()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Input 6-Digit OTP Box
                      TextField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          letterSpacing: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : GageTheme.textPrimary,
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '••••••',
                          hintStyle: TextStyle(
                            letterSpacing: 12,
                            color: isDark ? Colors.white24 : Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: GageTheme.primary, width: 1.8),
                          ),
                        ),
                        onChanged: (val) {
                          if (val.length == 6) {
                            _verifyOtpAndLogin();
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _verifyOtpAndLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Verifikasi & Masuk',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Center(
                        child: TextButton(
                          onPressed: _otpCooldown > 0
                              ? null
                              : () {
                                  _startOtpCooldown();
                                  GageToast.show(context, 'Kode OTP baru telah dikirimkan ulang', type: GageToastType.info);
                                },
                          child: Text(
                            _otpCooldown > 0
                                ? 'Kirim ulang dalam ${_otpCooldown}s'
                                : 'Kirim Ulang Kode OTP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _otpCooldown > 0
                                  ? Colors.grey
                                  : GageTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Pembatas "atau masuk dengan"
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'atau masuk dengan',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                ],
              ),

              const SizedBox(height: 16),

              // 5. Tombol Google Sign-In Resmi
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        if (!_agreedToTerms) {
                          GageToast.show(context, 'Harap setujui Syarat & Ketentuan Layanan', type: GageToastType.warning);
                          return;
                        }
                        await auth.signInWithGoogle();
                      },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(
                      'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                      height: 20,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: Text(
                        'Lanjut dengan Akun Google',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 6. Fast Dev Login Button (Untuk Uji Coba Cepat di HP User)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                  side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        await auth.signInDev();
                      },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_on_rounded, size: 16, color: GageTheme.accentYellow),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '⚡ Akses Cepat Tamu / Demo',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 7. Persetujuan Syarat, Privasi & Tarif Layanan
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 22,
                    width: 22,
                    child: Checkbox(
                      value: _agreedToTerms,
                      activeColor: GageTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      children: [
                        Text(
                          'Saya menyetujui ',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TermsAndPrivacyScreen(initialTabIndex: 1)),
                          ),
                          child: const Text(
                            'Ketentuan Layanan',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: GageTheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          ', ',
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TermsAndPrivacyScreen(initialTabIndex: 2)),
                          ),
                          child: const Text(
                            'Kebijakan Privasi',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: GageTheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          ', dan ',
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TermsAndPrivacyScreen(initialTabIndex: 0)),
                          ),
                          child: const Text(
                            'Ketentuan Tarif',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          ' GAGE Pracimantoro.',
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GageTapScale(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      scaleDown: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? GageTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white70 : const Color(0xFF475569),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : GageTheme.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
        ),
        prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
        filled: true,
        fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
