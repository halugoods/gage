import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static const LatLng defaultLocation = LatLng(-8.0834, 110.8454); // Sambiroto, Wonogiri

  static LatLng? _cachedLocation;

  static LatLng? get cachedLocation => _cachedLocation;
  static LatLng get cachedOrFallback => _cachedLocation ?? defaultLocation;

  /// Mendapatkan lokasi GPS riil perangkat secara cepat dan bebas hambatan (0ms cache-first)
  static Future<LatLng> getCurrentLocation({bool forceFresh = false}) async {
    // 1. Cek cached memory lokasi terdahulu jika sudah ada dan tidak dipaksa fresh
    if (!forceFresh && _cachedLocation != null) {
      _updateBackgroundLocation();
      return _cachedLocation!;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _cachedLocation ?? defaultLocation;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _cachedLocation ?? defaultLocation;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _cachedLocation ?? defaultLocation;
      }

      // 2. Ambil getLastKnownPosition dari OS Android (0ms response instant jika ada)
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && !forceFresh) {
        final result = LatLng(last.latitude, last.longitude);
        _cachedLocation = result;
        return result;
      }

      // 3. Request GPS aktual dengan akurasi high dan timeout 5 detik
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        final result = LatLng(position.latitude, position.longitude);
        _cachedLocation = result;
        return result;
      } catch (_) {
        // Fallback cepat ke getLastKnownPosition jika satelit indoor timeout
        if (last != null) {
          final result = LatLng(last.latitude, last.longitude);
          _cachedLocation = result;
          return result;
        }
        return _cachedLocation ?? defaultLocation;
      }
    } catch (_) {
      return _cachedLocation ?? defaultLocation;
    }
  }

  static void _updateBackgroundLocation() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _cachedLocation = LatLng(last.latitude, last.longitude);
      }
    } catch (_) {}
  }
}
