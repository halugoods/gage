import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/core/constants/qris_engine.dart';

void main() {
  group('QrisEngine Tests', () {
    test('Calculates CRC16 checksum accurately', () {
      // Standard CCITT 0xFFFF init with polynomial 0x1021
      final crc = QrisEngine.crc16('123456789');
      expect(crc.length, 4);
      expect(crc, '29B1');
    });

    test('Injects Tag 54 amount and changes Point of Initiation to 12 (Dynamic)', () {
      final dynamicQris = QrisEngine.generateDynamic(amount: 25000);

      // Verify Point of Initiation is dynamic (12)
      expect(dynamicQris.contains('010212'), isTrue);

      // Verify Tag 54 with amount 25000 (length 05)
      expect(dynamicQris.contains('540525000'), isTrue);

      // Verify ends with 6304 + 4 hex chars CRC
      expect(dynamicQris.contains('6304'), isTrue);
      final lastCrc = dynamicQris.substring(dynamicQris.length - 4);
      expect(lastCrc.length, 4);

      // Verify recalculated CRC matches
      final preCrc = dynamicQris.substring(0, dynamicQris.length - 4);
      expect(QrisEngine.crc16(preCrc), lastCrc);
    });

    test('Replaces existing Tag 54 when regenerated with new amount', () {
      final first = QrisEngine.generateDynamic(amount: 10000);
      final second = QrisEngine.generateDynamic(amount: 75000, staticQris: first);

      expect(second.contains('540575000'), isTrue);
      expect(second.contains('540510000'), isFalse);
    });
  });
}
