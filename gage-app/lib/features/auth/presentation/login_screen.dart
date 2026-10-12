// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/features/auth/presentation/terms_and_privacy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _referralController = TextEditingController();
  bool _showReferralField = false;
  bool _agreedToTerms = true;

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo & Identitas Brand GAGE
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: GageTheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: GageTheme.primary.withOpacity(0.35),
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
                        fontSize: 24,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Gage-Gage Tekan!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: GageTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Layanan pesan antar makanan & kurir instan terpercaya. Cepat, hemat, dan praktis.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: GageTheme.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 40),

              if (auth.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: GageTheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(color: GageTheme.primary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Form Input Kode Referral (Pendaftaran User Baru)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showReferralField = !_showReferralField;
                        });
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.card_giftcard_rounded, color: GageTheme.accentGreen, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Punya Kode Referral Teman?',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: GageTheme.textPrimary),
                            ),
                          ),
                          Icon(
                            _showReferralField ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    if (_showReferralField) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Masukkan kode referral untuk klaim bonus voucher & saldo reward saat mendaftar:',
                        style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _referralController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Misal: GAGERATIH',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: GageTheme.primary)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Persetujuan Syarat & Ketentuan Layanan
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _agreedToTerms ? Colors.green.shade50 : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _agreedToTerms ? Colors.green.shade200 : Colors.amber.shade300,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        activeColor: GageTheme.accentGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() {
                            _agreedToTerms = val ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Saya menyetujui ',
                            style: TextStyle(fontSize: 11.5, color: GageTheme.textPrimary),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermsAndPrivacyScreen(initialTabIndex: 1),
                                ),
                              );
                            },
                            child: const Text(
                              'Ketentuan Layanan',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: GageTheme.primary, decoration: TextDecoration.underline),
                            ),
                          ),
                          const Text(
                            ', ',
                            style: TextStyle(fontSize: 11.5, color: GageTheme.textPrimary),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermsAndPrivacyScreen(initialTabIndex: 2),
                                ),
                              );
                            },
                            child: const Text(
                              'Kebijakan Privasi',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: GageTheme.primary, decoration: TextDecoration.underline),
                            ),
                          ),
                          const Text(
                            ', & ',
                            style: TextStyle(fontSize: 11.5, color: GageTheme.textPrimary),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermsAndPrivacyScreen(initialTabIndex: 0),
                                ),
                              );
                            },
                            child: const Text(
                              'Ketentuan Tarif Layanan',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: GageTheme.accentGreen, decoration: TextDecoration.underline),
                            ),
                          ),
                          const Text(
                            ' (termasuk pembulatan ongkir Rp 500 & multi-merchant).',
                            style: TextStyle(fontSize: 11.5, color: GageTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tombol Utama: Google Sign-In Resmi
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 2,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        if (!_agreedToTerms) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('Harap centang persetujuan Syarat & Ketentuan Layanan terlebih dahulu.'),
                            ),
                          );
                          return;
                        }
                        final referral = _referralController.text.trim();
                        final success = await auth.signInWithGoogle();
                        if (!mounted) return;
                        if (success && referral.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: GageTheme.accentGreen,
                              content: Text('Kode referral $referral berhasil diterapkan!'),
                            ),
                          );
                        }
                      },
                child: auth.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: GageTheme.primary),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                            height: 22,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Masuk dengan Akun Google',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 14),

              // Tombol Fast Dev Login (Uji Coba Cepat di ADB Wireless)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: GageTheme.primary,
                  side: const BorderSide(color: GageTheme.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        if (!_agreedToTerms) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('Harap centang persetujuan Syarat & Ketentuan Layanan terlebih dahulu.'),
                            ),
                          );
                          return;
                        }
                        final referral = _referralController.text.trim();
                        await auth.signInDev();
                        if (!mounted) return;
                        if (referral.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: GageTheme.accentGreen,
                              content: Text('Kode referral $referral berhasil diterapkan!'),
                            ),
                          );
                        }
                      },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flash_on_rounded, color: GageTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Mode Testing Cepat (1-Klik Masuk)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsAndPrivacyScreen(initialTabIndex: 0),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book_rounded, size: 16, color: GageTheme.accentGreen),
                  label: const Text(
                    'Baca Lengkap Ketentuan & Kebijakan Privasi',
                    style: TextStyle(fontSize: 12, color: GageTheme.accentGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
