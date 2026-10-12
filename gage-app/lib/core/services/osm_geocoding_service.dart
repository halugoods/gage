import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:gage_app/core/services/pracimantoro_places_database.dart';
import 'package:gage_app/core/services/open_location_code_service.dart';

class OsmPlace {
  final String displayName;
  final String title;
  final LatLng location;
  final double? distanceMeters;

  const OsmPlace({
    required this.displayName,
    required this.title,
    required this.location,
    this.distanceMeters,
  });

  String get distanceText {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }
}

class OsmGeocodingService {
  static const Distance _distanceCalc = Distance();

  /// Algoritma Fundamental Pencarian Lokasi GAGE Pracimantoro:
  /// 1. TIER 1 (Lokal Knowledge Base Pracimantoro): Cek database titik-titik lokasi resmi di Kecamatan Pracimantoro.
  ///    - Prioritas tertinggi untuk fasilitas pendidikan (SD, SMP, SMA), kesehatan (RS, Puskesmas), kantor pemerintahan, pasar, dsb.
  /// 2. TIER 2 (Photon Geocoding Terikat Radius Fokus): Untuk alamat jalan/wilayah tetangga (Giritontro, Eromoko, dll)
  ///    dengan bounding box tertutup di sekitar Pracimantoro.
  static Future<List<OsmPlace>> searchPlaces(
    String query, {
    LatLng? proximityLocation,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // Pusat default: Pusat Kota Kecamatan Pracimantoro (-8.05517, 110.80889)
    final center = proximityLocation ?? PracimantoroPlacesDatabase.centerPracimantoro;

    final List<OsmPlace> finalResults = [];
    final Set<String> seenNames = {};

    // ─────────────────────────────────────────────────────────────
    // 1. TIER 1: PENCARIAN DATABASE LOKAL PRACIMANTORO (INSTANT & AKURAT)
    // ─────────────────────────────────────────────────────────────
    try {
      final localMatches = PracimantoroPlacesDatabase.searchLocalPlaces(
        cleanQuery,
        userLocation: center,
      );

      for (final place in localMatches) {
        final key = place.title.toLowerCase().trim();
        if (!seenNames.contains(key)) {
          seenNames.add(key);
          finalResults.add(place);
        }
      }
    } catch (_) {}

    // Jika query adalah pencarian spesifik sekolah yang sudah cocok sempurna di lokal, kita prioritaskan
    final isExactLocalHit = finalResults.isNotEmpty &&
        (cleanQuery.toLowerCase().contains('muhammadiyah') ||
         cleanQuery.toLowerCase().contains('maguan') ||
         cleanQuery.toLowerCase() == 'sd' ||
         cleanQuery.toLowerCase() == 'smp' ||
         cleanQuery.toLowerCase() == 'sma' ||
         cleanQuery.toLowerCase() == 'rs');

    // ─────────────────────────────────────────────────────────────
    // 2. TIER 2: PENCARIAN PHOTON OSM (RADIUS FOKUS PRACIMANTORO & TETANGGA)
    // ─────────────────────────────────────────────────────────────
    try {
      // Bounding Box fokus ~20 km di sekitar posisi aktif / Pracimantoro
      const double delta = 0.22;
      final minLon = (center.longitude - delta).toStringAsFixed(4);
      final minLat = (center.latitude - delta).toStringAsFixed(4);
      final maxLon = (center.longitude + delta).toStringAsFixed(4);
      final maxLat = (center.latitude + delta).toStringAsFixed(4);

      final urlStr = 'https://photon.komoot.io/api/?q=${Uri.encodeComponent(cleanQuery)}&limit=15'
          '&lat=${center.latitude}&lon=${center.longitude}'
          '&bbox=$minLon,$minLat,$maxLon,$maxLat';

      final res = await http.get(
        Uri.parse(urlStr),
        headers: {'User-Agent': 'GagePracimantoroApp/1.0'},
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final List features = data['features'] ?? [];
        final List<OsmPlace> remoteResults = [];

        for (final f in features) {
          final props = f['properties'] as Map<String, dynamic>? ?? {};
          final geom = f['geometry'] as Map<String, dynamic>? ?? {};
          final coords = geom['coordinates'] as List? ?? [0.0, 0.0];
          final lon = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();
          final point = LatLng(lat, lon);

          final country = (props['country'] as String? ?? '').toLowerCase();
          final countryCode = (props['countrycode'] as String? ?? '').toUpperCase();

          // Saring ketat: HANYA wilayah Indonesia
          if (country.isNotEmpty && country != 'indonesia') continue;
          if (countryCode.isNotEmpty && countryCode != 'ID') continue;

          final name = props['name'] as String? ?? props['street'] as String? ?? cleanQuery;
          final street = props['street'] as String? ?? '';
          final city = props['city'] as String? ?? props['county'] as String? ?? props['district'] as String? ?? props['state'] as String? ?? '';

          final parts = [name, street, city].where((s) => s.isNotEmpty).toSet().toList();
          final display = parts.join(', ');

          final dist = _distanceCalc.as(LengthUnit.Meter, center, point);

          final key = name.toLowerCase().trim();
          if (!seenNames.contains(key)) {
            seenNames.add(key);
            remoteResults.add(OsmPlace(
              title: name,
              displayName: display.isNotEmpty ? display : name,
              location: point,
              distanceMeters: dist,
            ));
          }
        }

        // Urutkan remote results dari yang terdekat
        remoteResults.sort((a, b) => (a.distanceMeters ?? 999999).compareTo(b.distanceMeters ?? 999999));

        // Jika ada pencarian umum seperti "sd", pastikan tempat lokal Pracimantoro tetap di posisi teratas
        if (isExactLocalHit) {
          finalResults.addAll(remoteResults);
        } else {
          // Gabungkan: tempat lokal tetap di Tier 1, disusul remote terdekat
          finalResults.addAll(remoteResults);
        }
      }
    } catch (_) {}

    // Fallback: Jika sama sekali tidak ada hasil, coba pencarian dengan nama kabupaten
    if (finalResults.isEmpty) {
      try {
        final fallbackUrl = 'https://photon.komoot.io/api/?q=${Uri.encodeComponent('$cleanQuery Pracimantoro Wonogiri')}&limit=8&lat=${center.latitude}&lon=${center.longitude}';
        final res = await http.get(
          Uri.parse(fallbackUrl),
          headers: {'User-Agent': 'GagePracimantoroApp/1.0'},
        ).timeout(const Duration(seconds: 3));

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final List features = data['features'] ?? [];
          for (final f in features) {
            final props = f['properties'] as Map<String, dynamic>? ?? {};
            final geom = f['geometry'] as Map<String, dynamic>? ?? {};
            final coords = geom['coordinates'] as List? ?? [0.0, 0.0];
            final point = LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble());
            final name = props['name'] as String? ?? cleanQuery;
            final display = [name, props['street'], props['city']].where((s) => s != null && s.toString().isNotEmpty).join(', ');
            final dist = _distanceCalc.as(LengthUnit.Meter, center, point);

            final key = name.toLowerCase().trim();
            if (!seenNames.contains(key)) {
              seenNames.add(key);
              finalResults.add(OsmPlace(
                title: name,
                displayName: display,
                location: point,
                distanceMeters: dist,
              ));
            }
          }
        }
      } catch (_) {}
    }

    return finalResults;
  }

  /// Daftar 17 Desa/Kelurahan Resmi di Kecamatan Pracimantoro beserta koordinat pusatnya
  static final List<Map<String, dynamic>> pracimantoroVillages = [
    {'name': 'Tubokarto', 'location': const LatLng(-8.02485, 110.82320)},
    {'name': 'Sambiroto', 'location': const LatLng(-8.07727, 110.84537)},
    {'name': 'Pracimantoro', 'location': const LatLng(-8.05517, 110.80889)},
    {'name': 'Gedong', 'location': const LatLng(-8.06401, 110.78632)},
    {'name': 'Joho', 'location': const LatLng(-8.09500, 110.79600)},
    {'name': 'Wonodadi', 'location': const LatLng(-8.02093, 110.79494)},
    {'name': 'Suci', 'location': const LatLng(-8.08507, 110.85177)},
    {'name': 'Gebangharjo', 'location': const LatLng(-8.04238, 110.76870)},
    {'name': 'Banaran', 'location': const LatLng(-8.04181, 110.85610)},
    {'name': 'Gambirmanis', 'location': const LatLng(-8.11170, 110.84658)},
    {'name': 'Petirsari', 'location': const LatLng(-8.12433, 110.82366)},
    {'name': 'Glinggang', 'location': const LatLng(-8.02620, 110.77880)},
    {'name': 'Trukan', 'location': const LatLng(-8.03050, 110.84200)},
    {'name': 'Sedayu', 'location': const LatLng(-8.04400, 110.81380)},
    {'name': 'Jimbar', 'location': const LatLng(-8.06000, 110.84500)},
    {'name': 'Lebak', 'location': const LatLng(-8.03850, 110.79820)},
    {'name': 'Sumberagung', 'location': const LatLng(-8.13500, 110.83500)},
  ];

  /// Menentukan nama desa terdekat di Kecamatan Pracimantoro
  static String getNearestVillage(LatLng location) {
    String closestName = 'Tubokarto';
    double minDistance = double.infinity;

    for (final v in pracimantoroVillages) {
      final dist = _distanceCalc.as(LengthUnit.Meter, location, v['location'] as LatLng);
      if (dist < minDistance) {
        minDistance = dist;
        closestName = v['name'] as String;
      }
    }
    return closestName;
  }

  /// Geocoding terbalik (Reverse Geocoding): Koordinat -> Format Google Plus Code Resmi
  /// Format output: `XR89+MHQ, Tubokarto, Kecamatan Pracimantoro, Wonogiri`
  static Future<String> reverseGeocode(LatLng location) async {
    final plusCode = OpenLocationCodeService.getShortPlusCode(location);
    final desa = getNearestVillage(location);

    // 1. Cek apakah sangat dekat dengan POI resmi Pracimantoro (< 40 meter)
    for (final p in PracimantoroPlacesDatabase.allPlaces) {
      final dist = _distanceCalc.as(LengthUnit.Meter, location, p.location);
      if (dist <= 40) {
        return '${p.name}, $plusCode, $desa';
      }
    }

    // 2. Query Photon untuk mendapatkan nama jalan (bukan mencaplok toko pihak ketiga)
    final urlStr = 'https://photon.komoot.io/reverse?lat=${location.latitude}&lon=${location.longitude}';
    try {
      final res = await http.get(
        Uri.parse(urlStr),
        headers: {'User-Agent': 'GagePracimantoroApp/1.0'},
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final List features = data['features'] ?? [];
        if (features.isNotEmpty) {
          final props = features[0]['properties'] as Map<String, dynamic>? ?? {};
          final geom = features[0]['geometry'] as Map<String, dynamic>? ?? {};
          final coords = geom['coordinates'] as List? ?? [0.0, 0.0];
          final featPoint = LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble());
          final featDist = _distanceCalc.as(LengthUnit.Meter, location, featPoint);

          final osmKey = (props['osm_key'] as String? ?? '').toLowerCase();
          final street = props['street'] as String? ?? '';
          final name = props['name'] as String? ?? '';

          // Jika node adalah toko/bengkel (misal Yanto Ban) dan berjarak > 30m, JANGAN dicaplok
          final isCommercialPOI = osmKey == 'shop' || osmKey == 'craft' || osmKey == 'amenity' || osmKey == 'tourism';

          if (!isCommercialPOI && name.isNotEmpty && featDist <= 35) {
            return '$name, $plusCode, $desa, Pracimantoro';
          }

          if (street.isNotEmpty) {
            return '$plusCode, Jl. $street, $desa, Pracimantoro';
          }
        }
      }
    } catch (_) {}

    // Standar baku alamat akurat Google Plus Code
    return '$plusCode, $desa, Kecamatan Pracimantoro, Kabupaten Wonogiri';
  }

  /// Detail alamat lengkap resmi (digunakan untuk deskripsi sub-header dan pengiriman)
  static String formatFullOfficialAddress(LatLng location) {
    final plusCode = OpenLocationCodeService.getShortPlusCode(location);
    final desa = getNearestVillage(location);
    return '$plusCode, $desa, Kecamatan Pracimantoro, Kabupaten Wonogiri, Jawa Tengah 57664, Indonesia';
  }
}
