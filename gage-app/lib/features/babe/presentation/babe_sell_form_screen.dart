import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';

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
  int _markupFee = 0;
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
      // Markup 10% komisi resmi GAGE
      _markupFee = (numVal * 0.10).round();
      _finalListingPrice = _sellerPrice + _markupFee;
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Foto Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.add_photo_alternate_rounded, color: GageTheme.primary),
              title: const Text('Gunakan Template Foto Realistis'),
              subtitle: const Text('Tambahkan sampel sudut foto beresolusi tinggi'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _attachedPhotos.add('assets/images/babe_smart_tv.jpg');
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Foto multi-angle berhasil ditambahkan.'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap setujui ketentuan akad titip jual resmi GAGE BaBe.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_sellerPrice < 20000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harga minimal pengajuan titip jual adalah Rp 20.000'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_attachedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wajib lampirkan minimal 1 foto barang.'),
          behavior: SnackBarBehavior.floating,
        ),
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 26),
            SizedBox(width: 10),
            Text('Pengajuan Diterima!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Barang bekas Anda berhasil masuk antrean review kurasi Admin GAGE.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Produk: ${_nameCtrl.text.trim()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 4),
                    Text('Harga Bersih Diterima Anda: ${currencyFormatter.format(_sellerPrice)}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                    Text('Harga Listing Aplikasi (+10%): ${currencyFormatter.format(_finalListingPrice)}', style: const TextStyle(fontSize: 11.5, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text('Nomor WhatsApp: ${_phoneCtrl.text.trim()}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('Status: Menunggu Review Kurasi Admin GAGE', style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Konfirmasi lolos atau ditolak akan diproses tim kurator di Portal Admin GAGE. Admin kami akan menghubungi WhatsApp Anda dalam 1x24 jam untuk verifikasi foto dan janji inspeksi fisik barang.',
                style: TextStyle(fontSize: 11.5, color: Colors.black54, height: 1.35),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GageTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
            padding: const EdgeInsets.all(16.0),
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
                              'Titip Jual Resmi & Transparan via GAGE',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
                            ),
                            SizedBox(height: 3),
                            Text(
                              '• Anda menerima 100% penuh harga bersih yang diajukan.\n'
                              '• Komisi 10% otomatis ditambahkan ke harga pembeli untuk inspeksi fisik, garansi toko 48 jam, dan ongkir kurir lokal.\n'
                              '• Dana diteruskan ke rekening/e-wallet Anda melalui Rekening Escrow Resmi GAGE.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 1. Pilih Kategori
                const Text('Pilih Kategori Barang Bekas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
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

                const SizedBox(height: 16),

                // 2. Nama Barang
                const Text('Nama Lengkap Barang:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Contoh: iPhone 11 128GB Black / Polygon Heist 2.0',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib isi nama barang' : null,
                ),

                const SizedBox(height: 16),

                // 3. Form Field Spesifik Berdasarkan Kategori
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded, size: 16, color: GageTheme.primary),
                          const SizedBox(width: 6),
                          Text('Spesifikasi Khusus: $_selectedCategory', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_selectedCategory == 'Gadget & Elektronik') ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Merk & Model:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _gadgetBrandCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: Apple iPhone 11',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                  const Text('RAM / Internal:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _gadgetRamStorageCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: 4GB / 128GB',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                  const Text('Battery Health:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _gadgetBatteryCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: 87%',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                  const Text('Kelengkapan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    initialValue: _gadgetKelengkapan,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('IMEI Terdaftar Resmi / Sinyal All Operator Aman', style: TextStyle(fontSize: 11.5)),
                          value: _gadgetImeiAman,
                          onChanged: (v) => setState(() => _gadgetImeiAman = v ?? true),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ] else if (_selectedCategory == 'Sepeda & Otomotif') ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Merk & Seri:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _otoBrandCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: Polygon Heist 2.0',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                  const Text('Tahun Pembelian:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _otoTahunCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: 2022',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                  const Text('Ukuran Rangka / CC:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _otoFrameSizeCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: Size M 17"',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                  const Text('Groupset / Mesin:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _otoGroupsetCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: Shimano Altus',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                  const Text('Merk & Tipe Perkakas:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _perkakasBrandCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: Maktec MT80B',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                  const Text('Konsumsi Daya / Baterai:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _perkakasDayaCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: 500W / Baterai 18V',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ] else if (_selectedCategory == 'Perabotan') ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Bahan Kayu / Material:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _mebelBahanCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: Kayu Jati Belanda',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                  const Text('Dimensi PxLxT:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _mebelDimensiCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Misal: 120x60x75 cm',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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

                const SizedBox(height: 16),

                // 4. Deskripsi Minus / Riwayat Pemakaian
                const Text('Minus & Kondisi Fisik Riil:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _minusCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Jelaskan kondisi riil, goresan fisik, kelengkapan minus, atau riwayat servis pemakaian...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Nomor WhatsApp Wajib
                const Text('Nomor WhatsApp Penjual (Wajib):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('Untuk koordinasi kurasi kurir GAGE, tanya jawab customer (via proxy CS), dan pencairan transfer dana.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF16A34A)),
                    hintText: '08xxxxxxxxxx',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  validator: (v) => (v == null || v.trim().length < 9) ? 'Nomor WhatsApp wajib diisi & valid' : null,
                ),

                const SizedBox(height: 16),

                // 6. Input Harga & Kalkulator Otomatis Markup 10%
                const Text('Harga Harapan Penjual (Yang Anda Terima Bersih):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: _onPriceChanged,
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    hintText: '0',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib isi nominal harga bersih yang Anda inginkan' : null,
                ),

                const SizedBox(height: 12),

                // Card Kalkulator Transparan Markup 10%
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Harga Bersih Diterima Anda (100%):', style: TextStyle(fontSize: 12, color: Colors.black87)),
                          Text(
                            currencyFormatter.format(_sellerPrice),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Biaya Kurasi, Garansi & Escrow GAGE (+10%):', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          Text(
                            currencyFormatter.format(_markupFee),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Harga Listing Final di Aplikasi:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          Text(
                            currencyFormatter.format(_finalListingPrice),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: GageTheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 7. Foto Produk (Slide Multi-Image)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Foto Fisik Barang (Multi-Slide):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('${_attachedPhotos.length} Foto Terpilih', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),

                SizedBox(
                  height: 90,
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
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: GageTheme.primary, size: 24),
                                SizedBox(height: 4),
                                Text('Tambah', style: TextStyle(fontSize: 11, color: GageTheme.primary, fontWeight: FontWeight.bold)),
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
                              width: 80,
                              height: 90,
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
                                  padding: const EdgeInsets.all(2),
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

                const SizedBox(height: 18),

                // 8. Ketentuan Akad Titip Jual Resmi & Proteksi Anti-Curang
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
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
                        '2. Transaksi pembeli menggunakan rekening Escrow GAGE dan dana 100% diteruskan ke penjual setelah 48 jam garansi.\n'
                        '3. Konfirmasi lolos atau ditolak akan diputuskan di Portal Admin GAGE dalam kurun waktu 1x24 jam.',
                        style: TextStyle(fontSize: 10.5, color: Colors.black54, height: 1.35),
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),

                const SizedBox(height: 24),

                // Tombol Submit
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  onPressed: _submitForm,
                  child: const Text(
                    'Kirim Pengajuan Titip Jual',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
