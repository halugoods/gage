import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/routing/portal_routes.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_photo_picker_sheet.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/shared/widgets/full_screen_map_picker.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';
import 'package:gage_app/shared/widgets/storefront_image.dart';

/// Wizard Onboarding Pendaftaran & Setup Toko Mitra Usaha GAGE Pracimantoro.
/// Alur bertahap:
/// 1. Identitas Usaha & Nomor WhatsApp Operasional
/// 2. Foto Profil (1:1) & Banner Toko (16:9) via Image Picker
/// 3. Alamat Kios di Kecamatan Pracimantoro & Pin Peta
/// 4. Jam Operasional & Persetujuan Biaya Layanan MDR 10%
class MerchantStoreSetupWizardScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialName;

  const MerchantStoreSetupWizardScreen({
    super.key,
    this.initialEmail,
    this.initialName,
  });

  @override
  State<MerchantStoreSetupWizardScreen> createState() => _MerchantStoreSetupWizardScreenState();
}

class _MerchantStoreSetupWizardScreenState extends State<MerchantStoreSetupWizardScreen> {
  int _currentStep = 0; // 0, 1, 2, 3
  bool _isSubmitting = false;

  // Step 1: Identitas & WhatsApp
  final TextEditingController _storeNameCtrl = TextEditingController(text: 'Dimsum Sewu Pracimantoro');
  final TextEditingController _whatsappCtrl = TextEditingController(text: '085156955735');
  String _selectedCategory = 'food'; // 'food', 'shop', 'farm'

  // Step 2: Branding & Foto
  String _storeLogo = 'assets/images/resto_dimsum_sewu.png';
  String _storeBanner = 'assets/images/resto_dimsum_sewu.png';
  final TextEditingController _bioCtrl = TextEditingController(text: 'Spesialis Dimsum Kukus & Goreng Hangat Gurih');

  // Step 3: Alamat & Lokasi
  final TextEditingController _addressCtrl = TextEditingController(text: 'Jl. Raya Pracimantoro No. 14, Depan Pasar');
  final TextEditingController _landmarkCtrl = TextEditingController(text: 'Depan Pasar Pracimantoro, samping Alfamidi');
  double _latitude = MerchantStorefrontService.defaultPracimantoroCenter.latitude;
  double _longitude = MerchantStorefrontService.defaultPracimantoroCenter.longitude;

  // Step 4: Operasional & MDR
  String _openTime = '08:00';
  String _closeTime = '21:00';
  bool _agreedToTerms = true;

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _whatsappCtrl.dispose();
    _bioCtrl.dispose();
    _addressCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_currentStep == 0) {
      if (_storeNameCtrl.text.trim().isEmpty) {
        GageToast.show(context, 'Nama usaha / toko wajib diisi', type: GageToastType.warning);
        return;
      }
      if (_whatsappCtrl.text.trim().length < 9) {
        GageToast.show(context, 'Nomor WhatsApp toko minimal 9 digit', type: GageToastType.warning);
        return;
      }
    } else if (_currentStep == 2) {
      if (_addressCtrl.text.trim().isEmpty) {
        GageToast.show(context, 'Alamat kios toko di Pracimantoro wajib diisi', type: GageToastType.warning);
        return;
      }
    }
    setState(() => _currentStep = (_currentStep + 1).clamp(0, 3));
  }

  void _previousStep() {
    HapticFeedback.lightImpact();
    setState(() => _currentStep = (_currentStep - 1).clamp(0, 3));
  }

  Future<void> _completeStoreSetup() async {
    if (!_agreedToTerms) {
      GageToast.show(context, 'Harap setujui ketentuan biaya bagi hasil kemitraan 10%', type: GageToastType.warning);
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.currentUser?.id ?? 'usr-m-${DateTime.now().millisecondsSinceEpoch}';

      final storefrontData = MerchantStorefrontData(
        merchantId: userId,
        name: _storeNameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        landmark: _landmarkCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        bannerPhoto: _storeBanner,
        logoPhoto: _storeLogo,
        locationPhoto: _storeLogo,
        latitude: _latitude,
        longitude: _longitude,
        isOpen: true,
      );

      await MerchantStorefrontService.saveStorefront(storefrontData);
      await MerchantStorefrontService.markStoreSetupCompleted(userId);

      if (!mounted) return;
      GageToast.show(context, 'Selamat! Toko berhasil dibuat dan siap berjualan di GAGE', type: GageToastType.success);
      Navigator.of(context).pushReplacementNamed(MerchantRoutes.root);
    } catch (e) {
      if (mounted) {
        GageToast.show(context, 'Gagal menyimpan setup toko: $e', type: GageToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          'Setup Lapak Toko (${_currentStep + 1}/4)',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stepper Progress Indicators
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Row(
                children: List.generate(4, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: isActive ? GageTheme.primary : (isDark ? Colors.white12 : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Step Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_currentStep == 0) _buildStep1(isDark, cardBg, textColor, borderColor),
                    if (_currentStep == 1) _buildStep2(isDark, cardBg, textColor, borderColor),
                    if (_currentStep == 2) _buildStep3(isDark, cardBg, textColor, borderColor),
                    if (_currentStep == 3) _buildStep4(isDark, cardBg, textColor, borderColor),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Actions
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  top: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                      ),
                      child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : (_currentStep == 3 ? _completeStoreSetup : _nextStep),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _currentStep == 3 ? 'Buka Toko & Mulai Jualan' : 'Lanjutkan',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Identitas & Kontak WhatsApp ──
  Widget _buildStep1(bool isDark, Color cardBg, Color textColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Identitas Usaha & Kontak',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
        ),
        const SizedBox(height: 4),
        Text(
          'Masukkan nomor WhatsApp aktif kios Anda untuk menerima notifikasi order dan koordinasi kurir GAGE.',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
        ),
        const SizedBox(height: 20),

        _buildLabel('Nama Kios / Usaha', isDark),
        const SizedBox(height: 6),
        _buildTextField(_storeNameCtrl, 'Misal: Dimsum Sewu Pracimantoro', Icons.storefront_rounded, isDark),
        const SizedBox(height: 16),

        _buildLabel('Nomor WhatsApp Toko (Koordinasi Order)', isDark),
        const SizedBox(height: 6),
        _buildTextField(_whatsappCtrl, '085156955735', Icons.phone_android_rounded, isDark, keyboardType: TextInputType.phone),
        const SizedBox(height: 16),

        _buildLabel('Kategori Bidang Usaha', isDark),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildCategoryChip('Kuliner (Food)', 'food', isDark),
            const SizedBox(width: 8),
            _buildCategoryChip('Kelontong (Shop)', 'shop', isDark),
            const SizedBox(width: 8),
            _buildCategoryChip('Tani (Farm)', 'farm', isDark),
          ],
        ),
      ],
    );
  }

  // ── Step 2: Branding & Foto Toko ──
  Widget _buildStep2(bool isDark, Color cardBg, Color textColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto Profil & Banner Toko',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
        ),
        const SizedBox(height: 4),
        Text(
          'Unggah foto produk terbaik atau logo lapak Anda agar menarik minat pembeli di katalog GAGE.',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
        ),
        const SizedBox(height: 20),

        // Logo Toko 1:1
        _buildLabel('Foto Profil / Logo Lapak (Rasio 1:1)', isDark),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: StorefrontImage(
                    path: _storeLogo,
                    fit: BoxFit.cover,
                    fallback: Container(color: Colors.grey.shade200, child: const Icon(Icons.storefront_rounded)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Logo Toko Persegi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 2),
                    Text('Tampil di daftar resto & checkout', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final path = await MerchantPhotoPickerSheet.show(context, aspectRatio: 1.0);
                  if (path != null) {
                    setState(() => _storeLogo = path);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 0,
                ),
                icon: const Icon(Icons.camera_alt_rounded, size: 14),
                label: const Text('Pilih Foto', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Banner Toko 16:9
        _buildLabel('Banner / Sampul Toko (Rasio 16:9)', isDark),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: StorefrontImage(
                    path: _storeBanner,
                    fit: BoxFit.cover,
                    fallback: Container(color: Colors.grey.shade200, child: const Icon(Icons.image_rounded)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Header visual lapak', style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.grey.shade600)),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final path = await MerchantPhotoPickerSheet.show(context, aspectRatio: 16 / 9);
                      if (path != null) {
                        setState(() => _storeBanner = path);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    ),
                    icon: const Icon(Icons.crop_rotate_rounded, size: 14),
                    label: const Text('Ganti Banner (16:9)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildLabel('Slogan / Bio Singkat Toko', isDark),
        const SizedBox(height: 6),
        _buildTextField(_bioCtrl, 'Misal: Dimsum kukus dan goreng hangat gurih', Icons.info_outline_rounded, isDark),
      ],
    );
  }

  // ── Step 3: Alamat & Titik Lokasi Peta ──
  Widget _buildStep3(bool isDark, Color cardBg, Color textColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lokasi Kios di Pracimantoro',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
        ),
        const SizedBox(height: 4),
        Text(
          'Pastikan titik koordinat peta tepat di lokasi kios fisik Anda agar kurir GAGE tidak tersesat saat mengambil pesanan.',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
        ),
        const SizedBox(height: 20),

        _buildLabel('Alamat Lengkap Toko', isDark),
        const SizedBox(height: 6),
        _buildTextField(_addressCtrl, 'Jl. Raya Pracimantoro No. 14', Icons.location_on_outlined, isDark),
        const SizedBox(height: 16),

        _buildLabel('Patokan / Landmark Kurir', isDark),
        const SizedBox(height: 6),
        _buildTextField(_landmarkCtrl, 'Depan mushola, samping Alfamidi', Icons.flag_outlined, isDark),
        const SizedBox(height: 16),

        _buildLabel('Titik Pin Peta (GPS Akurat)', isDark),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              MiniLocationPreviewMap(
                location: LatLng(_latitude, _longitude),
                size: 64,
                borderRadius: 12,
                markerImagePath: _storeLogo,
                useMerchantPin: true,
                onTap: _openMapPicker,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wilayah Pracimantoro', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 2),
                    Text('Navigasi kurir otomatis terkoneksi', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _openMapPicker,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            visualDensity: VisualDensity.compact,
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.map_rounded, size: 13),
                          label: const Text('Buka Peta', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton.icon(
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            final pos = await LocationService.getCurrentLocation(forceFresh: true);
                            setState(() {
                              _latitude = pos.latitude;
                              _longitude = pos.longitude;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.my_location_rounded, size: 13),
                          label: const Text('GPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 4: Operasional & MDR ──
  Widget _buildStep4(bool isDark, Color cardBg, Color textColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jam Buka & Ketentuan Layanan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
        ),
        const SizedBox(height: 4),
        Text(
          'Atur jadwal penerimaan order serta pelajari skema transparansi bagi hasil kemitraan GAGE.',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
        ),
        const SizedBox(height: 20),

        // Jam Operasional
        _buildLabel('Jam Buka - Tutup Normal', isDark),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 8, minute: 0),
                  );
                  if (picked != null) {
                    setState(() {
                      _openTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(
                    children: [
                      const Text('Buka Pukul ✎', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(_openTime, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 32, color: borderColor),
              InkWell(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 21, minute: 0),
                  );
                  if (picked != null) {
                    setState(() {
                      _closeTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(
                    children: [
                      const Text('Tutup Pukul ✎', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(_closeTime, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Kartu Transparansi MDR 10%
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified_rounded, color: Color(0xFF1D4ED8), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Bagi Hasil Platform GAGE 10%',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Mitra menerima 90% bersih dari setiap item pesanan yang terjual. Biaya layanan 10% digunakan untuk pemeliharaan server Cloudflare, operasional kurir, dan garansi layanan belanja.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Persetujuan Checkbox
        CheckboxListTile(
          value: _agreedToTerms,
          onChanged: (val) => setState(() => _agreedToTerms = val ?? true),
          activeColor: GageTheme.primary,
          title: const Text(
            'Saya menyetujui ketentuan kemitraan dan siap memproses pesanan pelanggan di Pracimantoro.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    bool isDark, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade400),
        prefixIcon: Icon(icon, size: 18, color: GageTheme.primary),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: GageTheme.primary, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value, bool isDark) {
    final isSelected = _selectedCategory == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedCategory = value);
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? GageTheme.primary : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? GageTheme.primary : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMapPicker() async {
    HapticFeedback.lightImpact();
    final res = await FullScreenMapPicker.open(
      context,
      title: 'Tentukan Titik Kios Toko',
      initialLocation: LatLng(_latitude, _longitude),
      initialFullAddress: _addressCtrl.text,
    );
    if (res != null) {
      setState(() {
        _latitude = res.location.latitude;
        _longitude = res.location.longitude;
        if (_addressCtrl.text.trim().isEmpty) {
          _addressCtrl.text = res.fullAddress;
        }
      });
    }
  }
}
