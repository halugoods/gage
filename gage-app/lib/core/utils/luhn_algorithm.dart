/// Utilitas Algoritma Luhn (MOD 10 / ISO/IEC 7812)
/// Digunakan oleh lembaga keuangan, perbankan, dan e-wallet global
/// untuk menghasilkan dan memvalidasi nomor rekening / kartu secara instan
/// guna mencegah kesalahan salah ketik (typo) atau transposisi digit.
class LuhnAlgorithm {
  /// Menghitung check digit (1 digit terakhir) dari payload angka menggunakan Algoritma Luhn (Mod 10).
  /// [payload]: string yang hanya berisi digit angka (misal 11 digit).
  static int calculateCheckDigit(String payload) {
    if (payload.isEmpty) return 0;
    int sum = 0;
    bool alternate = true;

    // Iterasi dari kanan ke kiri
    for (int i = payload.length - 1; i >= 0; i--) {
      final codeUnit = payload.codeUnitAt(i);
      if (codeUnit < 48 || codeUnit > 57) continue; // Skip non-digit
      int digit = codeUnit - 48;

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      alternate = !alternate;
    }

    final mod = sum % 10;
    return mod == 0 ? 0 : 10 - mod;
  }

  /// Menghasilkan nomor rekening lengkap dengan check digit di akhir.
  /// Contoh: payload "89081234567" -> "89081234567X"
  static String generateWithCheckDigit(String payload) {
    final clean = payload.replaceAll(RegExp(r'\D'), '');
    final checkDigit = calculateCheckDigit(clean);
    return '$clean$checkDigit';
  }

  /// Memvalidasi nomor rekening lengkap (termasuk check digit) dengan Algoritma Luhn.
  /// Mengembalikan true jika nomor rekening valid menurut rumus Mod 10.
  static bool validate(String fullNumber) {
    final clean = fullNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 10) return false;

    int sum = 0;
    bool alternate = false;

    // Iterasi dari digit terakhir (check digit) ke kiri
    for (int i = clean.length - 1; i >= 0; i--) {
      int digit = clean.codeUnitAt(i) - 48;
      if (digit < 0 || digit > 9) return false;

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      alternate = !alternate;
    }

    return (sum % 10) == 0;
  }

  /// Format nomor rekening dengan spasi per 4 digit agar nyaman dibaca.
  /// Contoh: "890812345678" -> "8908 1234 5678"
  static String formatWithSpaces(String rawNumber) {
    final clean = rawNumber.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }
}
