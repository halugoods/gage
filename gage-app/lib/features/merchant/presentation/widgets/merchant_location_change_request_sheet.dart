import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/full_screen_map_picker.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';

/// Bottom Sheet Formulir Pengajuan Perubahan Lokasi Toko ke Admin GAGE.
/// Mengadopsi arsitektur Shopee Partner: lokasi fisik toko dan titik GPS
/// tidak diubah sembarangan, melainkan diajukan untuk diverifikasi tim Admin.
class MerchantLocationChangeRequestSheet extends StatefulWidget {
  final String merchantId;
  final String currentAddress;
  final double currentLatitude;
  final double currentLongitude;
  final String markerImagePath;

  const MerchantLocationChangeRequestSheet({
    super.key,
    required this.merchantId,
    required this.currentAddress,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.markerImagePath,
  });

  static Future<MerchantLocationChangeRequest?> show(
    BuildContext context, {
    required String merchantId,
    required String currentAddress,
    required double currentLatitude,
    required double currentLongitude,
    required String markerImagePath,
  }) {
    return GageFloatingSheet.show<MerchantLocationChangeRequest>(
      context: context,
      title: 'Ajukan Pindah Lokasi Toko',
      builder: (_) => MerchantLocationChangeRequestSheet(
        merchantId: merchantId,
        currentAddress: currentAddress,
        currentLatitude: currentLatitude,
        currentLongitude: currentLongitude,
        markerImagePath: markerImagePath,
      ),
    );
  }

  @override
  State<MerchantLocationChangeRequestSheet> createState() => _MerchantLocationChangeRequestSheetState();
}

class _MerchantLocationChangeRequestSheetState extends State<MerchantLocationChangeRequestSheet> {
  final TextEditingController _newAddressCtrl = TextEditingController();
  final TextEditingController _newLandmarkCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();

  late double _selectedLat;
  late double _selectedLng;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.currentLatitude;
    _selectedLng = widget.currentLongitude;
    _latCtrl.text = _selectedLat.toStringAsFixed(6);
    _lngCtrl.text = _selectedLng.toStringAsFixed(6);
  }

  @override
  void dispose() {
    _newAddressCtrl.dispose();
    _newLandmarkCtrl.dispose();
    _reasonCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final newAddress = _newAddressCtrl.text.trim();
    final reason = _reasonCtrl.text.trim();

    if (newAddress.length < 5) {
      GageToast.show(context, 'Alamat baru toko wajib diisi dengan jelas (min. 5 karakter)', type: GageToastType.warning);
      return;
    }
    if (reason.length < 3) {
      GageToast.show(context, 'Harap sertakan alasan pemindahan lokasi toko', type: GageToastType.warning);
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

    if (mounted) {
      GageToast.show(
        context,
        'Pengajuan pindah lokasi toko terkirim! Menunggu verifikasi Admin GAGE.',
        type: GageToastType.success,
      );
      Navigator.of(context).pop(req);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_location_rounded, color: GageTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(
                        'Ditinjau & disetujui Admin GAGE sebelum update peta kurir',
                        style: TextStyle(fontSize: 11, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Alamat Sekarang (Read-Only Info)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, size: 20, color: GageTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokasi Toko Saat Ini (Aktif)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.currentAddress,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Alamat Baru
            Text(
              'Alamat Toko Baru (Kecamatan Pracimantoro)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _newAddressCtrl,
              style: TextStyle(fontSize: 13, color: textColor),
              decoration: InputDecoration(
                hintText: 'Misal: Jl. Raya Pracimantoro No. 88, Sebelah Kantor Pos',
                hintStyle: TextStyle(fontSize: 12, color: subColor),
                prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: GageTheme.primary),
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
            const SizedBox(height: 12),

            // Patokan Baru
            Text(
              'Patokan / Landmark Baru untuk Kurir',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _newLandmarkCtrl,
              style: TextStyle(fontSize: 13, color: textColor),
              decoration: InputDecoration(
                hintText: 'Misal: Tenda warna merah, samping minimarket',
                hintStyle: TextStyle(fontSize: 12, color: subColor),
                prefixIcon: const Icon(Icons.flag_outlined, size: 18, color: GageTheme.primary),
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
            const SizedBox(height: 12),

            // Titik GPS Baru
            Text(
              'Titik Koordinat Peta Baru',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
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
                    size: 54,
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
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pin: ${_selectedLat.toStringAsFixed(4)}, ${_selectedLng.toStringAsFixed(4)}',
                          style: TextStyle(fontSize: 11, color: subColor),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickLocationOnMap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GageTheme.primary,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                visualDensity: VisualDensity.compact,
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.map_rounded, size: 13),
                              label: const Text('Pilih Peta', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton.icon(
                              onPressed: _useCurrentGps,
                              style: OutlinedButton.styleFrom(
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.my_location_rounded, size: 13),
                              label: const Text('GPS Saya', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Alasan Pemindahan
            Text(
              'Alasan Pemindahan Toko',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              style: TextStyle(fontSize: 13, color: textColor),
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
            const SizedBox(height: 18),

            // Tombol Kirim Pengajuan
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _submitRequest,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Kirim Pengajuan ke Admin GAGE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
              ),
            ),
          ],
        ),
      );
  }

  Future<void> _pickLocationOnMap() async {
    HapticFeedback.lightImpact();
    final res = await FullScreenMapPicker.open(
      context,
      title: 'Tentukan Titik Toko Baru',
      initialLocation: LatLng(_selectedLat, _selectedLng),
      initialFullAddress: _newAddressCtrl.text,
    );
    if (res != null) {
      setState(() {
        _selectedLat = res.location.latitude;
        _selectedLng = res.location.longitude;
        _latCtrl.text = _selectedLat.toStringAsFixed(6);
        _lngCtrl.text = _selectedLng.toStringAsFixed(6);
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
      setState(() {
        _selectedLat = pos.latitude;
        _selectedLng = pos.longitude;
        _latCtrl.text = _selectedLat.toStringAsFixed(6);
        _lngCtrl.text = _selectedLng.toStringAsFixed(6);
      });
      if (mounted) {
        GageToast.show(context, 'Titik GPS berhasil disesuaikan dengan posisi Anda');
      }
    } catch (_) {
      if (mounted) {
        GageToast.show(context, 'Gagal mendeteksi sinyal GPS', type: GageToastType.warning);
      }
    }
  }
}
