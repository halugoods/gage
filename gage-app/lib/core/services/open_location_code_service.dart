import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Implementasi murni Dart Google Open Location Code (Plus Code).
/// Menghasilkan Plus Code akurat (seperti `XR89+MHQ`) 100% offline tanpa dependensi eksternal.
class OpenLocationCodeService {
  static const String _alphabet = '23456789CFGHJMPQRVWX';
  static const int _encodingBase = 20;
  static const double _latitudeMax = 90.0;
  static const double _longitudeMax = 180.0;
  static const int _pairCodeLength = 10;
  static const int _gridRows = 5;
  static const int _gridColumns = 4;
  static const int _finalLatPrecision = 25000000;
  static const int _finalLngPrecision = 8192000;

  // Koordinat acuan pusat wilayah Kecamatan Pracimantoro (-8.05517, 110.80889)
  static const LatLng centerPracimantoro = LatLng(-8.05517, 110.80889);

  /// Encode (lat, lon) menjadi full Plus Code 11-karakter (misal `6P3GXR89+MHQ`)
  static String encode(double latitude, double longitude, {int codeLength = 11}) {
    double lat = math.min(_latitudeMax, math.max(-_latitudeMax, latitude));
    double lon = longitude;
    while (lon < -_longitudeMax) {
      lon += 360.0;
    }
    while (lon >= _longitudeMax) {
      lon -= 360.0;
    }
    if (lat == _latitudeMax) {
      lat -= 0.0000001;
    }

    int latVal = ((lat + _latitudeMax) * _finalLatPrecision).round();
    int lngVal = ((lon + _longitudeMax) * _finalLngPrecision).round();

    String code = '';

    // Bagian Grid (karakter ke-11 jika length > 10)
    if (codeLength > _pairCodeLength) {
      for (int i = 0; i < 5; i++) {
        final latDigit = latVal % _gridRows;
        final lngDigit = lngVal % _gridColumns;
        code = _alphabet[latDigit * _gridColumns + lngDigit] + code;
        latVal ~/= _gridRows;
        lngVal ~/= _gridColumns;
      }
    } else {
      latVal ~/= 3125;
      lngVal ~/= 1024;
    }

    // Bagian Pasangan (10 karakter awal)
    for (int i = 0; i < 5; i++) {
      code = _alphabet[lngVal % _encodingBase] + code;
      code = _alphabet[latVal % _encodingBase] + code;
      latVal ~/= _encodingBase;
      lngVal ~/= _encodingBase;
    }

    // Sisipkan tanda '+' pada posisi ke-8
    code = '${code.substring(0, 8)}+${code.substring(8)}';

    if (codeLength + 1 <= code.length) {
      return code.substring(0, codeLength + 1);
    }
    return code;
  }

  /// Memotong (shorten) Plus Code relatif terhadap wilayah Pracimantoro/Wonogiri.
  /// Contoh: `6P3GXR89+MHQ` dipendekkan menjadi `XR89+MHQ`.
  static String shorten(String fullCode, {LatLng? referencePoint}) {
    final ref = referencePoint ?? centerPracimantoro;
    final clean = fullCode.toUpperCase().trim();
    if (clean.length < 9 || !clean.contains('+')) return clean;

    // Untuk area Pracimantoro dan sekitarnya (prefix regional Jawa Tengah `6P3G` atau `6P5G`),
    // 4 karakter awal dapat dihilangkan jika dalam radius ~40 km.
    final refFull = encode(ref.latitude, ref.longitude, codeLength: 11);
    if (clean.length >= 11 && refFull.length >= 11) {
      if (clean.substring(0, 4) == refFull.substring(0, 4)) {
        return clean.substring(4);
      }
    }

    // Default fallback: jika 4 karakter awal mirip kode regional Jawa Tengah (6P..)
    if (clean.startsWith('6P') && clean.length >= 11) {
      return clean.substring(4);
    }

    return clean;
  }

  /// Menghasilkan Plus Code ringkas siap pakai untuk koordinat GPS
  static String getShortPlusCode(LatLng location, {LatLng? referencePoint}) {
    final full = encode(location.latitude, location.longitude, codeLength: 11);
    return shorten(full, referencePoint: referencePoint);
  }

  /// Mendekode full atau short Plus Code (misal `XR89+MHQ` atau `6P3GXR89+MHQ`) menjadi `LatLng`.
  /// Mengembalikan `null` jika string bukan Plus Code yang valid.
  static LatLng? tryDecode(String rawInput, {LatLng? referencePoint}) {
    final firstToken = rawInput.trim().split(RegExp(r'[\s,]+')).first.toUpperCase();
    if (!firstToken.contains('+')) return null;

    String normalized = firstToken;
    final plusIdx = normalized.indexOf('+');
    if (plusIdx == 4) {
      final ref = referencePoint ?? centerPracimantoro;
      final refFull = encode(ref.latitude, ref.longitude, codeLength: 11);
      normalized = '${refFull.substring(0, 4)}$normalized';
    } else if (plusIdx != 8) {
      return null;
    }

    final clean = normalized.replaceAll('+', '');
    if (clean.length < 10) return null;
    for (int i = 0; i < clean.length && i < 11; i++) {
      if (!_alphabet.contains(clean[i])) return null;
    }

    double lat = -_latitudeMax;
    double lon = -_longitudeMax;
    double res = 400.0;
    for (int i = 0; i < 5; i++) {
      res /= _encodingBase;
      lat += _alphabet.indexOf(clean[i * 2]) * res;
      lon += _alphabet.indexOf(clean[i * 2 + 1]) * res;
    }

    if (clean.length >= 11) {
      final gridIdx = _alphabet.indexOf(clean[10]);
      final latStep = res / _gridRows;
      final lonStep = res / _gridColumns;
      lat += (gridIdx ~/ _gridColumns + 0.5) * latStep;
      lon += (gridIdx % _gridColumns + 0.5) * lonStep;
    } else {
      lat += res / 2;
      lon += res / 2;
    }

    return LatLng(lat, lon);
  }
}
