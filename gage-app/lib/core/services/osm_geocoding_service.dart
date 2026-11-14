import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:gage_app/core/services/pracimantoro_places_database.dart';
import 'package:gage_app/core/services/open_location_code_service.dart';

class OsmPlace {
  final String displayName;
  final String title;
  final LatLng location;
  final double? distanceMeters;
  final String? category;

  const OsmPlace({
    required this.displayName,
    required this.title,
    required this.location,
    this.distanceMeters,
    this.category,
  });

  String get distanceText {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }
}

class _CachedSearchEntry {
  final DateTime createdAt;
  final List<OsmPlace> results;

  const _CachedSearchEntry(this.createdAt, this.results);
}

class OsmGeocodingService {
  static const Distance _distanceCalc = Distance();

  /// Batas geografis resmi wilayah operasional Kecamatan Pracimantoro, Kab. Wonogiri
  static const double minLat = -8.165;
  static const double maxLat = -8.002;
  static const double minLon = 110.745;
  static const double maxLon = 110.882;

  static final LatLngBounds pracimantoroBounds = LatLngBounds(
    const LatLng(minLat, minLon),
    const LatLng(maxLat, maxLon),
  );

  static const Set<String> _excludedNeighborSubdistricts = {
    'giritontro',
    'eromoko',
    'giriwoyo',
    'baturetno',
    'paranggupito',
    'ponjong',
    'rongkop',
    'semin',
    'prambanan',
  };

  static final Map<String, _CachedSearchEntry> _searchCache = {};

  static bool isWithinPracimantoro(LatLng point) {
    return point.latitude >= minLat &&
        point.latitude <= maxLat &&
        point.longitude >= minLon &&
        point.longitude <= maxLon;
  }

  static bool _isAllowedAdministrativeArea(String textLower) {
    if (textLower.contains('pracimantoro')) return true;
    for (final other in _excludedNeighborSubdistricts) {
      if (textLower.contains(other)) return false;
    }
    return true;
  }

  /// Pencarian lokal instan (<1ms, tanpa jaringan) agar daftar saran langsung muncul saat mengetik.
  /// Mencakup Google Plus Code, database POI Kecamatan Pracimantoro, dan seluruh 17 Desa/Kelurahan.
  static List<OsmPlace> searchLocalInstant(
    String query, {
    LatLng? proximityLocation,
  }) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];
    if (!_isAllowedAdministrativeArea(cleanQuery.toLowerCase())) return const [];

    final center = proximityLocation != null && isWithinPracimantoro(proximityLocation)
        ? proximityLocation
        : PracimantoroPlacesDatabase.centerPracimantoro;

    final results = <OsmPlace>[];
    final seen = <String>{};

    // 1. Plus Code lookup (mis. XR89+MHQ atau 6P3GXR89+MHQ)
    final plusPoint = OpenLocationCodeService.tryDecode(cleanQuery, referencePoint: center);
    if (plusPoint != null && isWithinPracimantoro(plusPoint)) {
      final plusCode = OpenLocationCodeService.getShortPlusCode(plusPoint);
      final village = getNearestVillage(plusPoint);
      seen.add('plus:$plusCode');
      results.add(OsmPlace(
        title: 'Plus Code $plusCode',
        displayName: '$plusCode, $village, Kec. Pracimantoro, Kab. Wonogiri',
        location: plusPoint,
        distanceMeters: _distanceCalc.as(LengthUnit.Meter, center, plusPoint),
        category: 'Plus Code',
      ));
    }

    // 2. Database POI & 17 Desa/Kelurahan Kecamatan Pracimantoro
    final localMatches = PracimantoroPlacesDatabase.searchLocalPlaces(
      cleanQuery,
      userLocation: center,
    );
    for (final place in localMatches) {
      if (!isWithinPracimantoro(place.location)) continue;
      final key = place.title.toLowerCase().trim();
      if (seen.add(key)) {
        results.add(place);
      }
    }

    return results;
  }

  /// Algoritma Pencarian Lokasi Lengkap GAGE Pracimantoro:
  /// 1. Cache memori instan (0ms) + Tier 1 Database Lokal Pracimantoro & Plus Code.
  /// 2. Tier 2 Paralel (Nominatim bounded + Photon bounded) dengan timeout singkat & filter ketat Kec. Pracimantoro.
  static Future<List<OsmPlace>> searchPlaces(
    String query, {
    LatLng? proximityLocation,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];
    if (!_isAllowedAdministrativeArea(cleanQuery.toLowerCase())) return const [];

    final center = proximityLocation != null && isWithinPracimantoro(proximityLocation)
        ? proximityLocation
        : PracimantoroPlacesDatabase.centerPracimantoro;

    final cacheKey = cleanQuery.toLowerCase();
    final cached = _searchCache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.createdAt).inMinutes < 5) {
      return cached.results;
    }

    final List<OsmPlace> finalResults = searchLocalInstant(cleanQuery, proximityLocation: center);
    final Set<String> seenKeys = finalResults.map((p) => p.title.toLowerCase().trim()).toSet();

    try {
      final parallel = await Future.wait([
        _queryNominatimBounded(cleanQuery, center),
        _queryPhotonBounded(cleanQuery, center),
      ]);

      final List<OsmPlace> remoteResults = [
        ...parallel[0],
        ...parallel[1],
      ];

      remoteResults.sort((a, b) => (a.distanceMeters ?? 999999).compareTo(b.distanceMeters ?? 999999));

      for (final item in remoteResults) {
        final key = item.title.toLowerCase().trim();
        final nearExisting = finalResults.any(
          (existing) =>
              existing.title.toLowerCase().trim() == key ||
              (_distanceCalc.as(LengthUnit.Meter, existing.location, item.location) < 25 &&
                  existing.title.toLowerCase().contains(key)),
        );
        if (!nearExisting && seenKeys.add(key)) {
          finalResults.add(item);
        }
      }
    } catch (_) {}

    if (_searchCache.length >= 60) {
      _searchCache.remove(_searchCache.keys.first);
    }
    _searchCache[cacheKey] = _CachedSearchEntry(DateTime.now(), finalResults);
    return finalResults;
  }

  static Future<List<OsmPlace>> _queryNominatimBounded(String cleanQuery, LatLng center) async {
    try {
      final nominatimUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=jsonv2'
        '&q=${Uri.encodeComponent('$cleanQuery, Pracimantoro')}'
        '&viewbox=$minLon,$maxLat,$maxLon,$minLat'
        '&bounded=1'
        '&countrycodes=id'
        '&addressdetails=1'
        '&dedupe=1'
        '&limit=18'
        '&accept-language=id',
      );
      final res = await http.get(
        nominatimUrl,
        headers: {'User-Agent': 'GagePracimantoroApp/1.0'},
      ).timeout(const Duration(milliseconds: 1200));

      if (res.statusCode != 200) return const [];
      final List items = json.decode(res.body) as List? ?? const [];
      final out = <OsmPlace>[];
      for (final raw in items) {
        final item = raw as Map<String, dynamic>? ?? const {};
        final lat = double.tryParse(item['lat']?.toString() ?? '');
        final lon = double.tryParse(item['lon']?.toString() ?? '');
        if (lat == null || lon == null) continue;
        final point = LatLng(lat, lon);
        if (!isWithinPracimantoro(point)) continue;

        final displayName = (item['display_name'] as String? ?? '').trim();
        if (!_isAllowedAdministrativeArea(displayName.toLowerCase())) continue;

        final addr = item['address'] as Map<String, dynamic>? ?? const {};
        final name = (item['name'] as String? ?? '').trim();
        final road = (addr['road'] as String? ?? '').trim();
        final village = (addr['village'] as String? ?? addr['suburb'] as String? ?? addr['hamlet'] as String? ?? '').trim();
        final title = name.isNotEmpty ? name : (road.isNotEmpty ? road : (village.isNotEmpty ? village : cleanQuery));

        out.add(OsmPlace(
          title: title,
          displayName: displayName.isNotEmpty
              ? displayName
              : '$title, ${village.isNotEmpty ? '$village, ' : ''}Kec. Pracimantoro, Kab. Wonogiri',
          location: point,
          distanceMeters: _distanceCalc.as(LengthUnit.Meter, center, point),
          category: item['type'] as String?,
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static Future<List<OsmPlace>> _queryPhotonBounded(String cleanQuery, LatLng center) async {
    try {
      final urlStr = 'https://photon.komoot.io/api/?q=${Uri.encodeComponent(cleanQuery)}&limit=18'
          '&lat=${center.latitude}&lon=${center.longitude}'
          '&bbox=$minLon,$minLat,$maxLon,$maxLat';

      final res = await http.get(
        Uri.parse(urlStr),
        headers: {'User-Agent': 'GagePracimantoroApp/1.0'},
      ).timeout(const Duration(milliseconds: 1200));

      if (res.statusCode != 200) return const [];
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
        if (!isWithinPracimantoro(point)) continue;

        final country = (props['country'] as String? ?? '').toLowerCase();
        final countryCode = (props['countrycode'] as String? ?? '').toUpperCase();
        if (country.isNotEmpty && country != 'indonesia') continue;
        if (countryCode.isNotEmpty && countryCode != 'ID') continue;

        final name = props['name'] as String? ?? props['street'] as String? ?? cleanQuery;
        final street = props['street'] as String? ?? '';
        final district = props['district'] as String? ?? props['locality'] as String? ?? '';
        final city = props['city'] as String? ?? props['county'] as String? ?? props['state'] as String? ?? '';
        final adminText = '$district $city'.toLowerCase();
        if (adminText.trim().isNotEmpty && !_isAllowedAdministrativeArea(adminText)) continue;

        final parts = [name, street, district, city].where((s) => s.isNotEmpty).toSet().toList();
        final display = parts.join(', ');

        remoteResults.add(OsmPlace(
          title: name,
          displayName: display.isNotEmpty ? display : '$name, Kec. Pracimantoro, Wonogiri',
          location: point,
          distanceMeters: _distanceCalc.as(LengthUnit.Meter, center, point),
          category: props['osm_value'] as String?,
        ));
      }
      return remoteResults;
    } catch (_) {
      return const [];
    }
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
