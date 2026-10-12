/// GAGE Dynamic QRIS Engine in Dart (Tag 54 Injection & CRC16)
class QrisEngine {
  static const String defaultStaticQris =
      '00020101021126510013ID.SHOPEE.WWW01189360091800216174620208151234565204549953033605802ID5914GAGE INDONESIA6007YOGYAKARTA61055512262070703A016304ED41';

  static String crc16(String data) {
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= data.codeUnitAt(i) << 8;
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  static String removeTag54(String qris) {
    int i = 0;
    while (i + 4 <= qris.length) {
      final tag = qris.substring(i, i + 2);
      final len = int.tryParse(qris.substring(i + 2, i + 4)) ?? -1;
      if (len == -1) break;
      final end = i + 4 + len;
      if (end > qris.length) break;
      if (tag == '54') {
        return qris.substring(0, i) + qris.substring(end);
      }
      i = end;
    }
    return qris;
  }

  static String generateDynamic({
    required int amount,
    String? staticQris,
  }) {
    String payload = (staticQris ?? defaultStaticQris).trim();

    // Hapus CRC lama
    final crcIdx = payload.lastIndexOf('6304');
    if (crcIdx != -1) {
      payload = payload.substring(0, crcIdx);
    }

    // Ubah POI Statis -> Dinamis
    payload = payload.replaceFirst('010211', '010212');

    // Hapus tag 54 lama
    payload = removeTag54(payload);

    // Bangun tag 54 baru
    final amountStr = amount.toString();
    final tag54 = '54${amountStr.length.toString().padLeft(2, '0')}$amountStr';

    final idx58 = payload.indexOf('5802ID');
    if (idx58 != -1) {
      payload = payload.substring(0, idx58) + tag54 + payload.substring(idx58);
    } else {
      payload += tag54;
    }

    final preCrc = '${payload}6304';
    final crc = crc16(preCrc);
    return preCrc + crc;
  }
}
