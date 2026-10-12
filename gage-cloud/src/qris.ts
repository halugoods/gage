/**
 * GAGE QRIS Dynamic Generator Engine
 * Berdasarkan standar EMVCo QR Code Specification for Payment Systems (Tag 54 Injection)
 * $0 Fee Gateway - Teruji kompatibel dengan BCA, Mandiri, BRI, BNI, GoPay, OVO, DANA, ShopeePay
 */

// CRC16-CCITT (polynomial 0x1021) standar EMVCo QRIS
export function crc16CCITT(data: string): string {
  let crc = 0xFFFF;
  for (let i = 0; i < data.length; i++) {
    crc ^= data.charCodeAt(i) << 8;
    for (let j = 0; j < 8; j++) {
      if (crc & 0x8000) {
        crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
      } else {
        crc = (crc << 1) & 0xFFFF;
      }
    }
  }
  return crc.toString(16).toUpperCase().padStart(4, '0');
}

// Menghapus Tag 54 (amount) jika ada dari payload sebelumnya
export function removeTag54(qris: string): string {
  let i = 0;
  while (i + 4 <= qris.length) {
    const tag = qris.substring(i, i + 2);
    const len = parseInt(qris.substring(i + 2, i + 4), 10);
    const end = i + 4 + len;
    if (isNaN(len) || end > qris.length) break;
    if (tag === '54') {
      return qris.substring(0, i) + qris.substring(end);
    }
    i = end;
  }
  return qris;
}

/**
 * Mengubah QRIS Statis menjadi QRIS Dinamis dengan Tag 54 nominal spesifik.
 * @param staticQris String payload QRIS statis merchant (ShopeePay/BCA/dll)
 * @param amount Nominal tagihan dalam Rupiah (bilangan bulat)
 * @returns String QRIS dinamis siap dipindai
 */
export function generateDynamicQRIS(staticQris: string, amount: number): string {
  if (amount <= 0) {
    throw new Error('Nominal QRIS harus lebih besar dari 0');
  }

  let payload = staticQris.trim();

  // 1. Hapus CRC lama (Tag 63)
  const crcIdx = payload.lastIndexOf('6304');
  if (crcIdx !== -1) {
    payload = payload.substring(0, crcIdx);
  }

  // 2. Ubah Point of Initiation Method: 010211 (Statis) -> 010212 (Dinamis)
  payload = payload.replace('010211', '010212');

  // 3. Hapus Tag 54 lama jika ada
  payload = removeTag54(payload);

  // 4. Bangun Tag 54 baru (Nominal tanpa desimal)
  const amountStr = Math.round(amount).toString();
  const tag54Length = amountStr.length.toString().padStart(2, '0');
  const tag54 = `54${tag54Length}${amountStr}`;

  // 5. Sisipkan sebelum Tag 58 (Kode Negara "5802ID") atau di ujung sebelum CRC
  const idx58 = payload.indexOf('5802ID');
  if (idx58 !== -1) {
    payload = payload.substring(0, idx58) + tag54 + payload.substring(idx58);
  } else {
    payload += tag54;
  }

  // 6. Hitung dan tempelkan CRC16 baru
  const preCrc = payload + '6304';
  const newCrc = crc16CCITT(preCrc);

  return preCrc + newCrc;
}

// Utilitas untuk membaca komponen QRIS
export function parseEmvcoQR(qris: string): Record<string, string> {
  const result: Record<string, string> = {};
  let remaining = qris;
  while (remaining.length >= 4) {
    const id = remaining.substring(0, 2);
    const len = parseInt(remaining.substring(2, 4), 10);
    if (isNaN(len) || remaining.length < 4 + len) break;
    const val = remaining.substring(4, 4 + len);
    result[id] = val;
    remaining = remaining.substring(4 + len);
  }
  return result;
}
