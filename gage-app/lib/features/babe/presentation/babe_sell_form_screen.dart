import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Layar Penuh Formulir Pengajuan Titip Jual GAGE BaBe (Bukan Modal Drawer)
/// Dilengkapi Field Dinamis per Kategori, Validasi Nomor WhatsApp,
/// Multi-Image Thumbnail Carousel Slider, Kalkulator Transparan Markup 10%,
/// & Ketentuan Akad Anti-Curang Transaksi Gelap.
class BabeSellFormScreen extends StatefulWidget {
  const BabeSellFormScreen({super.key});

  @override
  State<BabeSellFormScreen> createState() => _BabeSellFormScreenState();
}

class _BabeSellFormScreenState extends State<BabeSellFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = 'Gadget & Elektronik';
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _minusCtrl = TextEditingController();

  // Field Khusus Gadget
  final TextEditingController _gadgetBrandCtrl = TextEditingController();
  final TextEditingController _gadgetRamStorageCtrl = TextEditingController();
  final TextEditingController _gadgetBatteryCtrl = TextEditingController(text: '85%');
  String _gadgetKelengkapan = 'Fullset Box Original';
  bool _gadgetImeiAman = true;

  // Field Khusus Otomotif & Sepeda
  final TextEditingController _otoBrandCtrl = TextEditingController();
  final TextEditingController _otoTahunCtrl = TextEditingController();
  final TextEditingController _otoFrameSizeCtrl = TextEditingController();
  final TextEditingController _otoGroupsetCtrl = TextEditingController();
  String _otoKelengkapanSurat = 'Lengkap BPKB & STNK';

  // Field Khusus Perkakas
  final TextEditingController _perkakasBrandCtrl = TextEditingController();
  String _perkakasTipeDaya = 'Listrik AC (Colokan 220V)';
  final TextEditingController _perkakasDayaCtrl = TextEditingController();
  final TextEditingController _perkakasKondisiMesinCtrl = TextEditingController();
  final TextEditingController _perkakasKelengkapanCtrl = TextEditingController();

  // Field Khusus Mebel & Perabotan
  final TextEditingController _mebelBahanCtrl = TextEditingController(text: 'Kayu Jati Solid');
  final TextEditingController _mebelDimensiCtrl = TextEditingController(text: '120 x 60 x 75 cm');
  final TextEditingController _mebelFinishingCtrl = TextEditingController(text: 'Vernis Natural Clear');
  String _mebelKekokohan = 'Sangat Kokoh Anti Goyang';

  // Akad Checkbox
  bool _agreedToTerms = true;

  final List<String> _attachedPhotos = [
    'assets/images/babe_iphone_11.jpg',
    'assets/images/hero_promo_1.png',
  ];

  final ImagePicker _picker = ImagePicker();
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  int _sellerPrice = 0;
  int _finalListingPrice = 0;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    _phoneCtrl.text = user?.phone ?? '081234567890';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _phoneCtrl.dispose();
    _minusCtrl.dispose();
    _gadgetBrandCtrl.dispose();
    _gadgetRamStorageCtrl.dispose();
    _gadgetBatteryCtrl.dispose();
    _otoBrandCtrl.dispose();
    _otoTahunCtrl.dispose();
    _otoFrameSizeCtrl.dispose();
    _otoGroupsetCtrl.dispose();
    _perkakasBrandCtrl.dispose();
    _perkakasDayaCtrl.dispose();
    _perkakasKondisiMesinCtrl.dispose();
    _perkakasKelengkapanCtrl.dispose();
    _mebelBahanCtrl.dispose();
    _mebelDimensiCtrl.dispose();
    _mebelFinishingCtrl.dispose();
    super.dispose();
  }

  void _onPriceChanged(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    final numVal = int.tryParse(clean) ?? 0;
    setState(() {
      _sellerPrice = numVal;
      _finalListingPrice = numVal;
    });
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedList = await _picker.pickMultiImage();
      if (pickedList.isNotEmpty) {
        setState(() {
          for (final f in pickedList) {
            _attachedPhotos.add(f.path);
          }
        });
      }
    } catch (_) {
      // Fallback jika di environment desktop/emulator tanpa direct picker
      _showPresetPhotoPicker();
    }
  }

  void _showPresetPhotoPicker() {
    GageFloatingSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilih Foto Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GageTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_photo_alternate_rounded, color: GageTheme.primary),
            ),
            title: const Text('Gunakan Template Foto Realistis', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Tambahkan sampel sudut foto beresolusi tinggi', style: TextStyle(fontSize: 12, color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _attachedPhotos.add('assets/images/babe_smart_tv.jpg');
              });
              GageToast.show(
                context,
                'Foto multi-angle berhasil ditambahkan.',
                type: GageToastType.success,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      GageToast.show(
        context,
        'Harap setujui ketentuan akad titip jual resmi GAGE BaBe.',
        type: GageToastType.warning,
      );
      return;
    }

    if (_sellerPrice < 20000) {
      GageToast.show(
        context,
        'Harga minimal pengajuan titip jual adalah Rp 20.000',
        type: GageToastType.warning,
      );
      return;
    }

    if (_attachedPhotos.isEmpty) {
      GageToast.show(
        context,
        'Wajib lampirkan minimal 1 foto barang.',
        type: GageToastType.warning,
      );
      return;
    }

    HapticFeedback.mediumImpact();

    // Persist submission to SharedPreferences
    final subId = 'SUB-BABE-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    try {
      final prefs = await SharedPreferences.getInstance();
      final histList = prefs.getStringList('gage_babe_history') ?? [];
      final submission = {
        'id': subId,
        'type': 'titip_jual',
        'title': _nameCtrl.text.trim(),
        'category': _selectedCategory,
        'price': _finalListingPrice,
        'netPrice': _sellerPrice,
        'phone': _phoneCtrl.text.trim(),
        'status': 'Menunggu Review Admin',
        'timestamp': DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
        'photosCount': _attachedPhotos.length,
        'note': 'Pengajuan titip jual baru. Menunggu konfirmasi lolos listing di Portal Admin GAGE.',
      };
      histList.insert(0, jsonEncode(submission));
      await prefs.setStringList('gage_babe_history', histList);
    } catch (_) {}

    if (!mounted) return;

    GageFloatingSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 26),
              SizedBox(width: 10),
              Expanded(
                child: Text('Pengajuan Diterima!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Barang bekas Anda berhasil masuk antrean review kurasi Admin GAGE.',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Produk: ${_nameCtrl.text.trim()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Text('Harga Bersih Diterima: ${currencyFormatter.format(_sellerPrice)}', style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Nomor WhatsApp: ${_phoneCtrl.text.trim()}', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                const SizedBox(height: 4),
                Text('Status: Menunggu Review Kurasi Admin GAGE', style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Konfirmasi lolos atau ditolak akan diproses tim kurator di Portal Admin GAGE. Admin kami akan menghubungi WhatsApp Anda dalam 1x24 jam untuk verifikasi foto dan janji inspeksi fisik barang.',
            style: TextStyle(fontSize: 11.5, color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajukan Titip Jual BaBe',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner Edukasi Sistem BaBe & Anti-Curang
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Titip Jual Resmi via GAGE BaBe',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
                            ),
                            SizedBox(height: 3),
                            Text(
                              '• Anda menerima penuh nominal harga bersih yang Anda tentukan.\n'
                              '• Barang dicek tim kurasi sebelum ditayangkan ke calon pembeli.\n'
                              '• Dana ditransfer langsung ke rekening/e-wallet Anda setelah transaksi selesai.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 1. TOP HERO: Foto Fisik Barang (Top Upload Card)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
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
                            child: const Icon(Icons.camera_alt_outlined, size: 18, color: GageTheme.primary),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Foto Fisik Barang',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_attachedPhotos.length} Foto Terpilih',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Lampirkan foto fisik asli dari berbagai sudut (depan, belakang, kelengkapan, minus bila ada).',
                        style: TextStyle(fontSize: 11.5, color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 96,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachedPhotos.length + 1,
                          separatorBuilder: (context, index) => const SizedBox(width: 10),
                          itemBuilder: (ctx, idx) {
                            if (idx == _attachedPhotos.length) {
                              return InkWell(
                                onTap: _pickImages,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 86,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: GageTheme.primary.withValues(alpha: 0.4), width: 1.2),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: GageTheme.primary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add_a_photo_outlined, color: GageTheme.primary, size: 20),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text('Upload', style: TextStyle(fontSize: 11, color: GageTheme.primary, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final photo = _attachedPhotos[idx];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                children: [
                                  SizedBox(
                                    width: 86,
                                    height: 96,
                                    child: photo.startsWith('assets/')
                                        ? Image.asset(photo, fit: BoxFit.cover)
                                        : Image.network(photo, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200)),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _attachedPhotos.removeAt(idx)),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 2. iOS Inset Group: Informasi Barang
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Informasi Barang',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      const Text('Kategori Barang:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCategory,
                            items: const [
                              DropdownMenuItem(value: 'Gadget & Elektronik', child: Text('Gadget & Elektronik')),
                              DropdownMenuItem(value: 'Sepeda & Otomotif', child: Text('Sepeda & Otomotif')),
                              DropdownMenuItem(value: 'Perkakas & Alat Rumah', child: Text('Perkakas & Alat Pertukangan')),
                              DropdownMenuItem(value: 'Perabotan', child: Text('Perabotan & Mebel')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text('Nama Lengkap Barang:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Contoh: iPhone 11 128GB Black / Polygon Heist 2.0',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib isi nama barang' : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 3. iOS Inset Group: Spesifikasi Khusus Kategori
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF059669)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Spesifikasi: $_selectedCategory',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (_selectedCategory == 'Gadget & Elektronik') ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Merk & Model:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _gadgetBrandCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Apple iPhone 11',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('RAM / Internal:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _gadgetRamStorageCtrl,
                                    decoration: InputDecoration(
                                      hintText: '4GB / 128GB',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Battery Health:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _gadgetBatteryCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: 87%',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Kelengkapan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    initialValue: _gadgetKelengkapan,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Fullset Box Original', child: Text('Fullset Box')),
                                      DropdownMenuItem(value: 'Unit + Charger OEM', child: Text('Unit + Charger')),
                                      DropdownMenuItem(value: 'Batangan / Unit Only', child: Text('Batangan')),
                                    ],
                                    onChanged: (v) => setState(() => _gadgetKelengkapan = v ?? 'Fullset Box Original'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Material(
                          color: Colors.transparent,
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('IMEI Terdaftar Resmi / Sinyal All Operator Aman', style: TextStyle(fontSize: 11.5)),
                            value: _gadgetImeiAman,
                            onChanged: (v) => setState(() => _gadgetImeiAman = v ?? true),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                      ] else if (_selectedCategory == 'Sepeda & Otomotif') ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Merk & Seri:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _otoBrandCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Polygon Heist 2.0',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Tahun Pembelian:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _otoTahunCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: 2022',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ukuran Rangka / CC:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _otoFrameSizeCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: Size M 17"',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Groupset / Mesin:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _otoGroupsetCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: Shimano Altus',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _otoKelengkapanSurat,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Kelengkapan Surat / Dokumen:',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Lengkap BPKB & STNK', child: Text('BPKB & STNK Lengkap (Motor)')),
                            DropdownMenuItem(value: 'Nota Pembelian Toko Sepeda', child: Text('Nota Toko Pembelian (Sepeda)')),
                            DropdownMenuItem(value: 'Non-Surat (Sepeda Gowes/Aksesoris)', child: Text('Non-Surat (Sepeda Gowes/Aksesoris)')),
                          ],
                          onChanged: (v) => setState(() => _otoKelengkapanSurat = v ?? 'Lengkap BPKB & STNK'),
                        ),
                      ] else if (_selectedCategory == 'Perkakas & Alat Rumah') ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Merk & Tipe Perkakas:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _perkakasBrandCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: Maktec MT80B',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Konsumsi Daya / Baterai:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _perkakasDayaCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: 500W / Baterai 18V',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _perkakasTipeDaya,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Tipe Sumber Daya:',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Listrik AC (Colokan 220V)', child: Text('Listrik AC (Colokan 220V)')),
                            DropdownMenuItem(value: 'Cordless (Baterai Isi Ulang)', child: Text('Cordless (Baterai Isi Ulang)')),
                            DropdownMenuItem(value: 'Manual / Mekanik', child: Text('Manual / Mekanik')),
                          ],
                          onChanged: (v) => setState(() => _perkakasTipeDaya = v ?? 'Listrik AC (Colokan 220V)'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _perkakasKelengkapanCtrl,
                          decoration: InputDecoration(
                            labelText: 'Kelengkapan Aksesoris / Box Koper:',
                            hintText: 'Misal: Koper box asli + 5 bonus mata bor',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                        ),
                      ] else if (_selectedCategory == 'Perabotan') ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Bahan Kayu / Material:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _mebelBahanCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: Kayu Jati Belanda',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Dimensi PxLxT:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _mebelDimensiCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: 120x60x75 cm',
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _mebelFinishingCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Finishing / Cat:',
                                  hintText: 'Misal: Vernis Natural',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _mebelKekokohan,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Kekokohan Rangka:',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Sangat Kokoh Anti Goyang', child: Text('Anti Goyang')),
                                  DropdownMenuItem(value: 'Kokoh Normal', child: Text('Kokoh Normal')),
                                ],
                                onChanged: (v) => setState(() => _mebelKekokohan = v ?? 'Sangat Kokoh Anti Goyang'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 4. iOS Inset Group: Deskripsi Minus & Kondisi Riil
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.assignment_outlined, size: 18, color: Color(0xFFD97706)),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Minus & Kondisi Fisik Riil',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _minusCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Jelaskan kondisi riil, goresan fisik, kelengkapan minus, atau riwayat servis pemakaian...',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 5. iOS Inset Group: Kontak Penjual (WhatsApp)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.phone_android_rounded, size: 18, color: Color(0xFF16A34A)),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Nomor WhatsApp Penjual (Wajib)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Untuk koordinasi kurasi kurir GAGE dan pencairan transfer dana ke rekening Anda.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF16A34A)),
                          hintText: '08xxxxxxxxxx',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        validator: (v) => (v == null || v.trim().length < 9) ? 'Nomor WhatsApp wajib diisi & valid' : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 6. iOS Inset Group: Input Harga & Nominal Bersih
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.payments_outlined, size: 18, color: Color(0xFF7C3AED)),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Harga Harapan Penjual',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: _onPriceChanged,
                        decoration: InputDecoration(
                          prefixText: 'Rp ',
                          prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          hintText: '0',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib isi nominal harga bersih yang Anda inginkan' : null,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF16A34A), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nominal Bersih yang Anda Terima:',
                                    style: TextStyle(fontSize: 11, color: Colors.black54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currencyFormatter.format(_sellerPrice),
                                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('100% Utuh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 7. iOS Inset Group: Akad Titip Jual Resmi
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: GageTheme.primary,
                      value: _agreedToTerms,
                      onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                      title: const Text(
                        'Saya menyetujui Ketentuan Akad Titip Jual Resmi GAGE BaBe:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                      subtitle: const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          '1. Penjual dilarang menjual barang yang sedang aktif listing di BaBe secara sepihak di luar sistem GAGE.\n'
                          '2. Transaksi pembeli dilindungi Garansi Keamanan Transaksi GAGE dan dana 100% diteruskan ke penjual setelah 48 jam garansi.\n'
                          '3. Konfirmasi lolos atau ditolak akan diputuskan di Portal Admin GAGE dalam kurun waktu 1x24 jam.',
                          style: TextStyle(fontSize: 10.5, color: Colors.black54, height: 1.35),
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Tombol Submit (BorderRadius.circular(10))
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                    ),
                    onPressed: _submitForm,
                    child: const Text(
                      'Kirim Pengajuan Titip Jual',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
