import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/routing/portal_routes.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/auth/merchant_login_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Screen Pendaftaran Toko / Mitra Usaha Baru GAGE Pracimantoro
/// - Kategori: Food, Shop, Farm, Build
/// - Wilayah: Seluruh Desa di Kecamatan Pracimantoro
/// - Skema Komisi MDR 10% Transparan
class MerchantRegisterScreen extends StatefulWidget {
  const MerchantRegisterScreen({super.key});

  @override
  State<MerchantRegisterScreen> createState() => _MerchantRegisterScreenState();
}

class _MerchantRegisterScreenState extends State<MerchantRegisterScreen> {
  final TextEditingController _ownerNameCtrl = TextEditingController();
  final TextEditingController _storeNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();

  String _selectedCategory = 'Food';
  final List<String> _categories = ['Food', 'Shop', 'Farm', 'Build'];

  String _selectedVillage = 'Pracimantoro';
  final List<String> _villages = [
    'Pracimantoro',
    'Sedayu',
    'Glinggang',
    'Trukan',
    'Petirsari',
    'Joho',
    'Gebangharjo',
    'Banaran',
    'Gedong',
    'Sambiroto',
    'Sumberagung',
    'Suci',
    'Tubokarto',
    'Watangrejo',
    'Wonodadi',
    'Gambirmanis',
    'Lebak',
    'Bohar',
  ];

  bool _agreeToMdr = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _storeNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final owner = _ownerNameCtrl.text.trim();
    final store = _storeNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    if (owner.isEmpty) {
      GageToast.show(context, 'Nama lengkap pemilik wajib diisi', type: GageToastType.warning);
      return;
    }
    if (store.isEmpty) {
      GageToast.show(context, 'Nama toko / toko usaha wajib diisi', type: GageToastType.warning);
      return;
    }
    if (phone.isEmpty || phone.length < 8) {
      GageToast.show(context, 'Nomor WhatsApp toko wajib diisi dengan benar', type: GageToastType.warning);
      return;
    }
    if (address.isEmpty) {
      GageToast.show(context, 'Alamat lengkap toko wajib diisi', type: GageToastType.warning);
      return;
    }
    if (pin.length < 4) {
      GageToast.show(context, 'Buat PIN toko minimal 4-6 digit angka', type: GageToastType.warning);
      return;
    }
    if (!_agreeToMdr) {
      GageToast.show(context, 'Harap setujui ketentuan komisi platform MDR 10%', type: GageToastType.warning);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.signInWithPhone(
        phone: phone,
        name: owner,
      );

      if (!mounted) return;

      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
                SizedBox(width: 8),
                Text('Toko Siap Beroperasi!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
            content: Text(
              'Selamat bergabung di ekosistem GAGE Pracimantoro! Toko "$store" kategori GAGE $_selectedCategory di desa $_selectedVillage siap menerima pesanan pertama.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushReplacementNamed(MerchantRoutes.root);
                },
                child: const Text('Buka Kasir Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        GageToast.show(context, 'Pendaftaran belum berhasil', type: GageToastType.error);
      }
    } catch (e) {
      if (mounted) {
        GageToast.show(context, 'Kendala pendaftaran: $e', type: GageToastType.error);
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MerchantLoginScreen()),
            );
          },
        ),
        title: Text(
          'Daftar Mitra Usaha Baru',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Segmented Pill Switcher (Masuk | Daftar)
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
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const MerchantLoginScreen()),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Masuk Toko',
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
                          'Daftar Baru',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 2. Form Pendaftaran Lengkap
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
                    // Kategori Layanan (Segmented Chips)
                    Text(
                      'Pilih Kategori Usaha',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _categories.map((cat) {
                        final isSel = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(
                            'GAGE $cat',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                            ),
                          ),
                          selected: isSel,
                          selectedColor: GageTheme.primary,
                          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: isSel ? GageTheme.primary : borderColor,
                          ),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategory = cat);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Nama Pemilik
                    Text(
                      'Nama Pemilik Usaha',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _ownerNameCtrl,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textColor),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: GageTheme.primary),
                        hintText: 'Contoh: Budi Santoso',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: GageTheme.primary, width: 1.5)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Nama Toko / Toko
                    Text(
                      'Nama Toko / Toko',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _storeNameCtrl,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textColor),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.storefront_rounded, size: 20, color: GageTheme.primary),
                        hintText: 'Contoh: Dimsum Sewu, Pracimantoro',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: GageTheme.primary, width: 1.5)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Nomor WhatsApp Toko
                    Text(
                      'Nomor WhatsApp Aktif Toko',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textColor),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone_android_rounded, size: 20, color: GageTheme.primary),
                        hintText: 'Contoh: 085156955735',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: GageTheme.primary, width: 1.5)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Desa di Kecamatan Pracimantoro
                    Text(
                      'Desa / Kelurahan (Kecamatan Pracimantoro)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedVillage,
                          isExpanded: true,
                          dropdownColor: cardBg,
                          items: _villages.map((v) {
                            return DropdownMenuItem(
                              value: v,
                              child: Text('Desa $v', style: TextStyle(fontSize: 13.5, color: textColor)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedVillage = val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Alamat Lengkap
                    Text(
                      'Alamat Lengkap Toko / Toko',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: Icon(Icons.location_on_outlined, size: 20, color: GageTheme.primary),
                        ),
                        hintText: 'Nama jalan, nomor toko, atau patokan lokasi',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: GageTheme.primary, width: 1.5)),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // PIN Toko
                    Text(
                      'Buat PIN Keamanan Toko (4-6 Digit)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _pinCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textColor),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: GageTheme.primary),
                        hintText: 'Contoh: 123456',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: GageTheme.primary, width: 1.5)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Persetujuan MDR 10%
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _agreeToMdr = !_agreeToMdr),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreeToMdr,
                            activeColor: GageTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (v) => setState(() => _agreeToMdr = v ?? false),
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Saya menyetujui Ketentuan Layanan Mitra GAGE dan skema bagi hasil MDR 10% per pesanan selesai tanpa biaya langganan bulanan.',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey, height: 1.35),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tombol Submit
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
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Daftar Toko Sekarang',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
