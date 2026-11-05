import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

/// Service manajemen izin & verifikasi GPS wajib GAGE Pracimantoro.
class GagePermissionService {
  static const String _kPermissionsAskedKey = 'gage_permissions_asked_v1';

  /// Minta izin Android berurutan satu per satu saat pertama kali install
  static Future<void> requestFirstInstallPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyAsked = prefs.getBool(_kPermissionsAskedKey) ?? false;
      if (alreadyAsked) return;

      // Urutan request satu per satu agar tidak tumpang tindih
      if (Platform.isAndroid || Platform.isIOS) {
        await Permission.notification.request();
        await Permission.camera.request();
        if (Platform.isAndroid) {
          await Permission.photos.request();
        }
        await Permission.contacts.request();
      }

      await prefs.setBool(_kPermissionsAskedKey, true);
    } catch (e) {
      debugPrint('[GagePermissionService] requestFirstInstallPermissions error: $e');
    }
  }

  /// Verifikasi GPS: user wajib menyalakan GPS & memberi izin lokasi sebelum melanjutkan
  /// Mengembalikan true jika GPS aktif & diizinkan.
  static Future<bool> checkAndEnforceGps(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final isPermissionOk = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (serviceEnabled && isPermissionOk) {
      return true;
    }

    if (!context.mounted) return false;

    // Tampilkan Floating Sheet Wajib GPS (Tidak bisa ditutup swipe/tap luar jika belum aktif)
    final result = await GageFloatingSheet.show<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      child: const _GpsVerificationSheetContent(),
    );

    return result ?? false;
  }
}

class _GpsVerificationSheetContent extends StatefulWidget {
  const _GpsVerificationSheetContent();

  @override
  State<_GpsVerificationSheetContent> createState() => _GpsVerificationSheetContentState();
}

class _GpsVerificationSheetContentState extends State<_GpsVerificationSheetContent>
    with WidgetsBindingObserver {
  bool _isGpsServiceEnabled = false;
  bool _isPermissionGranted = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User kembali dari Pengaturan Android
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    final service = await Geolocator.isLocationServiceEnabled();
    final perm = await Geolocator.checkPermission();
    final permOk = perm == LocationPermission.always || perm == LocationPermission.whileInUse;

    if (mounted) {
      setState(() {
        _isGpsServiceEnabled = service;
        _isPermissionGranted = permOk;
        _isChecking = false;
      });

      if (service && permOk) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Visual
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GageTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: GageTheme.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'GPS Wajib Dinyalakan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : GageTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Aplikasi GAGE memerlukan lokasi GPS presisi untuk menentukan titik jemput, menghitung ongkos kirim lokal di Pracimantoro, dan pelacakan kurir secara live.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.grey.shade300 : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Checklist Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                _buildStatusRow(
                  label: 'GPS / Layanan Lokasi Perangkat',
                  isActive: _isGpsServiceEnabled,
                  isDark: isDark,
                ),
                const Divider(height: 16),
                _buildStatusRow(
                  label: 'Izin Lokasi Aplikasi GAGE',
                  isActive: _isPermissionGranted,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Tombol Tindakan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (!_isGpsServiceEnabled) {
                  await Geolocator.openLocationSettings();
                } else if (!_isPermissionGranted) {
                  final perm = await Geolocator.requestPermission();
                  if (perm == LocationPermission.deniedForever) {
                    await Geolocator.openAppSettings();
                  }
                }
                _checkStatus();
              },
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: Text(
                !_isGpsServiceEnabled
                    ? 'Buka Pengaturan GPS'
                    : (!_isPermissionGranted ? 'Izinkan Akses Lokasi' : 'Lanjutkan'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),

          TextButton(
            onPressed: _isChecking ? null : _checkStatus,
            child: _isChecking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Periksa Ulang Status',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required bool isActive,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ),
        Text(
          isActive ? 'Aktif' : 'Mati',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }
}
