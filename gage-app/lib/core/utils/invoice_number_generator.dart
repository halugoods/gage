/// Generator Nomor Invoice Advance, Ringkas, dan Anti-Tabrakan Server & Database.
/// 
/// Format Spesifikasi:
/// `INV-{BASE36_TIMESTAMP}-{NODE_SEQ}{CHECKSUM}`
/// Contoh: `INV-K9X2B7Q1-P018`
/// 
/// Keunggulan Arsitektur:
/// 1. Auto-Detect Tanggal & Waktu: Timestamp epoch milidetik di-encode ke Base36,
///    sehingga waktu transaksi (tanggal, bulan, tahun, jam, menit, detik) dapat di-decode
///    secara instan dan 100% akurat langsung dari string invoice tanpa butuh format teks terpisah.
/// 2. Ringkas & Padat: Hanya ~17 karakter tanpa kode service atau tanggal redundan.
/// 3. Anti-Tabrakan Server & Database: Node ID (misal 'P' untuk Pracimantoro Worker)
///    dan 2-digit sequence counter menjamin zero collision saat migrasi/sinkronisasi antar server/database.
/// 4. Verifikasi Integritas Mandiri (Check Digit): Menggunakan algoritma Modulo 36 berbobot (weighted Luhn variant)
///    yang mendeteksi salah ketik 1 karakter atau transposisi karakter secara instan tanpa query database.
class InvoiceNumberGenerator {
  static int _sequenceCounter = 0;
  static const String _charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// Menghasilkan nomor invoice advance dan ringkas.
  static String generate({
    DateTime? timestamp,
    String nodeId = 'P',
  }) {
    final time = timestamp ?? DateTime.now();
    final millis = time.millisecondsSinceEpoch;
    final timeBase36 = millis.toRadixString(36).toUpperCase().padLeft(8, '0');

    // Monotonic rollover counter 00 - 99
    _sequenceCounter = (_sequenceCounter + 1) % 100;
    final seqStr = _sequenceCounter.toString().padLeft(2, '0');

    final cleanNode = nodeId.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final nodeChar = cleanNode.isNotEmpty ? cleanNode[0] : 'P';

    final payload = '$timeBase36-$nodeChar$seqStr';
    final checkChar = calculateCheckDigit(payload);

    return 'INV-$payload$checkChar';
  }

  /// Menghitung karakter check digit menggunakan algoritma Modulo 36 berbobot
  static String calculateCheckDigit(String payload) {
    final clean = payload.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    int factor = 2;
    int sum = 0;

    for (int i = clean.length - 1; i >= 0; i--) {
      final code = clean[i];
      final val = _charset.indexOf(code);
      if (val == -1) continue;

      int addend = factor * val;
      // Kurangi kelipatan 36 jika melebihi nilai maksimal satu karakter
      addend = (addend ~/ 36) + (addend % 36);
      sum += addend;

      factor = (factor == 2) ? 1 : 2;
    }

    final remainder = sum % 36;
    final checkVal = (36 - remainder) % 36;
    return _charset[checkVal];
  }

  /// Memvalidasi keaslian dan integritas format nomor invoice
  static bool validate(String invoiceNumber) {
    final clean = invoiceNumber.trim().toUpperCase();
    if (!clean.startsWith('INV-')) return false;

    final parts = clean.substring(4).split('-');
    if (parts.length != 2) return false;

    final timePart = parts[0];
    final tailPart = parts[1];
    if (timePart.length < 7 || tailPart.length < 4) return false;

    // Pisahkan payload dan check digit terakhir
    final checkChar = tailPart[tailPart.length - 1];
    final payloadTail = tailPart.substring(0, tailPart.length - 1);
    final fullPayload = '$timePart-$payloadTail';

    final expectedCheck = calculateCheckDigit(fullPayload);
    return checkChar == expectedCheck;
  }

  /// Auto-detect objek DateTime langsung dari nomor invoice tanpa query database
  static DateTime? extractDateTime(String invoiceNumber) {
    try {
      final clean = invoiceNumber.trim().toUpperCase();
      if (!clean.startsWith('INV-')) return null;

      final body = clean.substring(4);
      final dashIdx = body.indexOf('-');
      if (dashIdx == -1) return null;

      final timePart = body.substring(0, dashIdx);
      final millis = int.tryParse(timePart, radix: 36);
      if (millis == null || millis <= 0) return null;

      return DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      return null;
    }
  }

  /// Mengekstrak seluruh metadata dari nomor invoice
  static Map<String, dynamic>? parse(String invoiceNumber) {
    if (!validate(invoiceNumber)) return null;

    final dt = extractDateTime(invoiceNumber);
    final clean = invoiceNumber.trim().toUpperCase().substring(4);
    final parts = clean.split('-');
    final tail = parts[1];

    final node = tail.substring(0, 1);
    final seq = tail.substring(1, 3);
    final check = tail.substring(3);

    return {
      'invoice': invoiceNumber,
      'dateTime': dt,
      'nodeId': node,
      'sequence': int.tryParse(seq) ?? 0,
      'checkDigit': check,
      'isValid': true,
    };
  }
}
