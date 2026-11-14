import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/utils/luhn_algorithm.dart';
import 'package:gage_app/providers/wallet_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Wave 3 UX & Banking-Grade Luhn Tests', () {
    test('LuhnAlgorithm generates and validates ISO/IEC 7812 check digits', () {
      // Test vektor Luhn terkenal: 7992739871 (payload 10 digit) -> check digit 3
      final check = LuhnAlgorithm.calculateCheckDigit('7992739871');
      expect(check, equals(3));
      expect(LuhnAlgorithm.validate('79927398713'), isTrue);

      // Transposisi / salah ketik 1 digit harus ditolak
      expect(LuhnAlgorithm.validate('79927398714'), isFalse);
      expect(LuhnAlgorithm.validate('79927398723'), isFalse);

      // Format dengan spasi
      final spaced = LuhnAlgorithm.formatWithSpaces('890812345678');
      expect(spaced, equals('8908 1234 5678'));
    });

    test('WalletProvider produces valid 12-digit Luhn account number', () {
      final wallet = WalletProvider();
      expect(wallet.accountNumber.length, equals(12));
      expect(wallet.accountNumber.startsWith('8908'), isTrue);
      expect(LuhnAlgorithm.validate(wallet.accountNumber), isTrue);

      // Formatted account number harus memiliki 2 spasi
      expect(wallet.formattedAccountNumber.split(' ').length, equals(3));
    });
  });
}
