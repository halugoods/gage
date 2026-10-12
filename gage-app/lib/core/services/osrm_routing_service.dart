import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmRouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final String summary;

  const OsrmRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.summary,
  });

  double get distanceKm => distanceMeters / 1000.0;
  int get durationMinutes => (durationSeconds / 60.0).ceil();
}

class OsrmRoutingService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Mengambil rute presisi mengikuti jalan raya menggunakan OSRM API (100% Gratis & Realtime)
  static Future<OsrmRouteResult> getRoute(LatLng origin, LatLng destination) async {
    final url = Uri.parse(
      '$_baseUrl/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'GageApp/1.0 (Ride-Hailing POS)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final List<LatLng> pts = coordinates.map((c) {
            final lon = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lon);
          }).toList();

          final double dist = (route['distance'] as num?)?.toDouble() ?? 1000.0;
          final double dur = (route['duration'] as num?)?.toDouble() ?? 300.0;
          final String summ = (route['weight_name'] as String?) ?? 'driving';

          return OsrmRouteResult(
            points: pts,
            distanceMeters: dist,
            durationSeconds: dur,
            summary: summ,
          );
        }
      }
    } catch (_) {
      // Fallback graceful jika offline / timeout
    }

    // Fallback rute terinterpolasi langsung (tidak pernah crash)
    return OsrmRouteResult(
      points: _createFallbackCurve(origin, destination),
      distanceMeters: _calculateDirectDistance(origin, destination),
      durationSeconds: 300.0,
      summary: 'fallback',
    );
  }

  static double _calculateDirectDistance(LatLng p1, LatLng p2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, p1, p2);
  }

  static List<LatLng> _createFallbackCurve(LatLng start, LatLng end) {
    final List<LatLng> list = [];
    const int steps = 10;
    final midLat = (start.latitude + end.latitude) / 2 + 0.002;
    final midLng = (start.longitude + end.longitude) / 2 + 0.002;

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      // Quadratic Bezier
      final lat = (1 - t) * (1 - t) * start.latitude + 2 * (1 - t) * t * midLat + t * t * end.latitude;
      final lng = (1 - t) * (1 - t) * start.longitude + 2 * (1 - t) * t * midLng + t * t * end.longitude;
      list.add(LatLng(lat, lng));
    }
    return list;
  }
}
