import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/full_screen_map_picker.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';

/// Full Screen Page: Lokasi Toko & Pengajuan Pindah Alamat
/// Menggabungkan status peninjauan pengajuan pindah lokasi aktif dan formulir
/// pengajuan perubahan lokasi fisik beserta titik GPS ke Admin GAGE.
class MerchantLocationAndRequestsScreen extends StatefulWidget {
  final String merchantId;
  final String storeName;
  final String currentAddress;
  final String currentLandmark;
  final double currentLatitude;
  final double currentLongitude;
  final String markerImagePath;

  const MerchantLocationAndRequestsScreen({
    super.key,
    required this.merchantId,
    required this.storeName,
    required this.currentAddress,
    required this.currentLandmark,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.markerImagePath,
  });

  @override
  State<MerchantLocationAndRequestsScreen> createState() =>
      _MerchantLocationAndRequestsScreenState();
}

class _MerchantLocationAndRequestsScreenState extends State<MerchantLocationAndRequestsScreen> {
  final TextEditingController _newAddressCtrl = TextEditingController();
  final TextEditingController _newLandmarkCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();

  late double _selectedLat;
  late double _selectedLng;
  MerchantLocationChangeRequest? _activeRequest;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.currentLatitude;
    _selectedLng = widget.currentLongitude;
    _loadExistingRequest();
  }

  @override
  void dispose() {
    _newAddressCtrl.dispose();
    _newLandmarkCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRequest() async {
    final req = await MerchantStorefrontService.loadLocationChangeRequest(widget.merchantId);
    if (mounted) {
      setState(() => _activeRequest = req);
    }
  }

  Future<void> _pickLocationOnMap() async {
    HapticFeedback.lightImpact();
    final res = await FullScreenMapPicker.open(
      context,
      title: 'Tentukan Titik Toko Baru',
      initialLocation: LatLng(_selectedLat, _selectedLng),
      initialFullAddress: _newAddressCtrl.text,
    );
    if (res != null && mounted) {
      setState(() {
        _selectedLat = res.location.latitude;
        _selectedLng = res.location.longitude;
        if (_newAddressCtrl.text.trim().isEmpty) {
          _newAddressCtrl.text = res.fullAddress;
        }
      });
    }
  }

  Future<void> _useCurrentGps() async {
    HapticFeedback.lightImpact();
    try {
      final pos = await LocationService.getCurrentLocation(forceFresh: true);
      if (!mounted) return;
      setState(() {
        _selectedLat = pos.latitude;
        _selectedLng = pos.longitude;
      });
      GageToast.show(context, 'Titik GPS berhasil disesuaikan dengan posisi Anda');
    } catch (_) {
      if (mounted) {
        GageToast.show(context, 'Gagal mendeteksi sinyal GPS', type: GageToastType.warning);
      }
    }
  }

  Future<void> _submitRequest() async {
    final newAddress = _newAddressCtrl.text.trim();
    final reason = _reasonCtrl.text.trim();

    if (newAddress.length < 5) {
      GageToast.show(
        context,
        'Alamat baru toko wajib diisi dengan jelas (min. 5 karakter)',
        type: GageToastType.warning,
      );
      return;
    }
    if (reason.length < 3) {
      GageToast.show(
        context,
        'Harap sertakan alasan pemindahan lokasi toko',
        type: GageToastType.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final req = MerchantLocationChangeRequest(
      id: 'req-loc-${DateTime.now().millisecondsSinceEpoch}',
      merchantId: widget.merchantId,
      currentAddress: widget.currentAddress,
      newAddress: newAddress,
      newLandmark: _newLandmarkCtrl.text.trim(),
      newLatitude: _selectedLat,
      newLongitude: _selectedLng,
      reason: reason,
      status: 'PENDING',
      submittedAt: DateTime.now(),
    );

    await MerchantStorefrontService.saveLocationChangeRequest(req);
    if (!mounted) return;
    setState(() {
      _activeRequest = req;
      _isSubmitting = false;
      _newAddressCtrl.clear();
      _newLandmarkCtrl.clear();
      _reasonCtrl.clear();
    });
    GageToast.show(
      context,
      'Pengajuan pindah lokasi toko terkirim! Menunggu verifikasi Admin GAGE.',
      type: GageToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(_activeRequest),
        ),
        title: Text(
          'Lokasi Toko & Pengajuan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Status Pengajuan Aktif / Terverifikasi
            _buildSectionHeader('STATUS PENGAJUAN & LOKASI SAAT INI', subColor),
            const SizedBox(height: 8),

            if (_activeRequest != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Pindah Lokasi Toko Fisik',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textColor),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: isDark ? 0.25 : 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            _activeRequest!.status == 'PENDING'
                                ? 'MENUNGGU PERSETUJUAN ADMIN'
                                : _activeRequest!.status,
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Alamat Asal: ${_activeRequest!.currentAddress}', style: TextStyle(fontSize: 11.5, color: subColor)),
                    const SizedBox(height: 3),
                    Text('Alamat Baru: ${_activeRequest!.newAddress}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor)),
                    if (_activeRequest!.newLandmark.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Patokan: ${_activeRequest!.newLandmark}', style: TextStyle(fontSize: 11.5, color: subColor)),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Alasan: "${_activeRequest!.reason}"',
                      style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: subColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  MiniLocationPreviewMap(
                    location: LatLng(widget.currentLatitude, widget.currentLongitude),
                    size: 54,
                    borderRadius: 12,
                    markerImagePath: widget.markerImagePath,
                    useMerchantPin: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Lokasi Aktif Saat Ini',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: subColor),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: GageTheme.accentGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'TERVERIFIKASI',
                                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: GageTheme.accentGreen),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.currentAddress,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.currentLandmark.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Patokan: ${widget.currentLandmark}',
                            style: TextStyle(fontSize: 11, color: subColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. Formulir Pengajuan Pindah Lokasi
            _buildSectionHeader('FORM PENGAJUAN PINDAH LOKASI', subColor),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ditinjau oleh Admin GAGE sebelum titik penjemputan kurir diperbarui.',
                    style: TextStyle(fontSize: 11.5, color: subColor),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Alamat Toko Baru (Kecamatan Pracimantoro)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _newAddressCtrl,
                    style: TextStyle(fontSize: 13.5, color: textColor),
                    decoration: _inputDecoration(
                      hint: 'Misal: Jl. Raya Pracimantoro No. 88, Sebelah Kantor Pos',
                      icon: Icons.location_on_outlined,
                      inputBg: inputBg,
                      borderColor: borderColor,
                      subColor: subColor,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Patokan / Landmark Baru untuk Kurir',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _newLandmarkCtrl,
                    style: TextStyle(fontSize: 13.5, color: textColor),
                    decoration: _inputDecoration(
                      hint: 'Misal: Tenda warna merah, samping minimarket',
                      icon: Icons.flag_outlined,
                      inputBg: inputBg,
                      borderColor: borderColor,
                      subColor: subColor,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Titik Koordinat Peta Baru',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        MiniLocationPreviewMap(
                          location: LatLng(_selectedLat, _selectedLng),
                          size: 56,
                          borderRadius: 12,
                          markerImagePath: widget.markerImagePath,
                          useMerchantPin: true,
                          onTap: _pickLocationOnMap,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kecamatan Pracimantoro',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pin: ${_selectedLat.toStringAsFixed(4)}, ${_selectedLng.toStringAsFixed(4)}',
                                style: TextStyle(fontSize: 11, color: subColor),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _pickLocationOnMap,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: GageTheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      visualDensity: VisualDensity.compact,
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.map_rounded, size: 13),
                                    label: const Text('Pilih Peta', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    onPressed: _useCurrentGps,
                                    style: OutlinedButton.styleFrom(
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(Icons.my_location_rounded, size: 13),
                                    label: const Text('GPS Saya', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Alasan Pemindahan Toko',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _reasonCtrl,
                    maxLines: 3,
                    style: TextStyle(fontSize: 13.5, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Misal: Kontrak lapak lama habis / pindah ke lokasi lebih strategis',
                      hintStyle: TextStyle(fontSize: 12, color: subColor),
                      filled: true,
                      fillColor: inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
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
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? GageTheme.darkSurface : Colors.white,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Kirim Pengajuan ke Admin GAGE',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: color,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required Color inputBg,
    required Color borderColor,
    required Color subColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: subColor),
      prefixIcon: Icon(icon, size: 18, color: GageTheme.primary),
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
      ),
    );
  }
}
