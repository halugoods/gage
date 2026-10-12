import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static const LatLng defaultLocation = LatLng(-8.0834, 110.8454); // Sambiroto, Wonogiri

  static LatLng? _cachedLocation;

  static LatLng get cachedOrFallback => _cachedLocation ?? defaultLocation;

  /// Mendapatkan lokasi GPS riil perangkat saat ini
  static Future<LatLng> getCurrentLocation() async {
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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );

      final result = LatLng(position.latitude, position.longitude);
      _cachedLocation = result;
      return result;
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          final result = LatLng(last.latitude, last.longitude);
          _cachedLocation = result;
          return result;
        }
      } catch (_) {}
      return _cachedLocation ?? defaultLocation;
    }
  }
}
