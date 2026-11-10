import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

/// GageSecurityService
/// Layanan terpadu keamanan otentikasi biometrik (sidik jari) & PIN 6 Digit
/// Khusus diverifikasi saat transaksi pembayaran dan top up GAGEPay.
class GageSecurityService {
  static final GageSecurityService instance = GageSecurityService._();
  GageSecurityService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _prefBiometricKey = 'pref_biometric_enabled';
  static const String _prefPinKey = 'pref_transaction_pin';
  static const String defaultPin = '123456';

  /// Cek apakah perangkat keras mendukung biometrik
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported || canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Cek apakah sidik jari sudah terdaftar di sistem OS
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final available = await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Cek status aktif biometrik di preferensi pengguna
  Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefBiometricKey) ?? false;
  }

  /// Simpan preferensi biometrik
  Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefBiometricKey, enabled);
  }

  /// Ambil PIN transaksi tersimpan
  Future<String> getTransactionPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefPinKey) ?? defaultPin;
  }

  /// Simpan PIN transaksi baru
  Future<void> setTransactionPin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPinKey, newPin);
  }

  /// Eksekusi pemindaian biometrik autentik via LocalAuthentication
  Future<bool> authenticateWithBiometrics({required String localizedReason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: ${e.message}');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Verifikasi otorisasi transaksi finansial (GAGEPay Checkout / Topup)
  /// - Jika biometrik aktif: Pindai sidik jari terlebih dahulu.
  /// - Jika biometrik nonaktif atau gagal: Buka modal input PIN 6 Digit.
  Future<bool> verifyAuthorization(
    BuildContext context, {
    required String title,
    required int amount,
  }) async {
    final isBioOn = await isBiometricsEnabled();
    final isSupported = await isDeviceSupported();

    if (isBioOn && isSupported) {
      final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      final success = await authenticateWithBiometrics(
        localizedReason: 'Konfirmasi otorisasi $title senilai ${currency.format(amount)}',
      );
      if (success) {
        HapticFeedback.mediumImpact();
        return true;
      }
    }

    // Fallback: Verifikasi PIN 6 Digit
    if (!context.mounted) return false;
    return await promptPinVerificationSheet(context, title: title, amount: amount);
  }

  /// Dialog BottomSheet Interaktif untuk Memasukkan PIN 6 Digit
  Future<bool> promptPinVerificationSheet(
    BuildContext context, {
    required String title,
    required int amount,
  }) async {
    HapticFeedback.lightImpact();
    final savedPin = await getTransactionPin();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await GageFloatingSheet.show<bool>(
      context: context,
      title: 'Verifikasi Keamanan',
      builder: (sheetCtx) {
        String enteredPin = '';
        String? errorMessage;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void onKeyPress(String val) {
              if (enteredPin.length >= 6) return;
              HapticFeedback.selectionClick();
              setSheetState(() {
                enteredPin += val;
                errorMessage = null;
              });

              if (enteredPin.length == 6) {
                if (enteredPin == savedPin) {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(sheetCtx, true);
                } else {
                  HapticFeedback.heavyImpact();
                  setSheetState(() {
                    errorMessage = 'PIN transaksi salah. Silakan coba lagi.';
                    enteredPin = '';
                  });
                }
              }
            }

            void onDelete() {
              if (enteredPin.isEmpty) return;
              HapticFeedback.selectionClick();
              setSheetState(() {
                enteredPin = enteredPin.substring(0, enteredPin.length - 1);
                errorMessage = null;
              });
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: GageTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_rounded, color: GageTheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '$title: ${currency.format(amount)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: GageTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Masukkan 6 digit PIN GAGEPay Anda',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 16),

                // PIN Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final isFilled = index < enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? GageTheme.primary
                            : (isDark ? Colors.white24 : Colors.grey.shade300),
                        border: Border.all(
                          color: isFilled ? GageTheme.primary : (isDark ? Colors.white38 : Colors.grey.shade400),
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                ),

                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ],

                const SizedBox(height: 24),

                // Tactile Number Pad
                for (var row = 0; row < 3; row++) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var col = 1; col <= 3; col++) ...[
                        _buildPadButton('${row * 3 + col}', onKeyPress, isDark),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 64, height: 50),
                    _buildPadButton('0', onKeyPress, isDark),
                    SizedBox(
                      width: 64,
                      height: 50,
                      child: InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Icon(
                            Icons.backspace_outlined,
                            size: 20,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  static Widget _buildPadButton(String text, Function(String) onTap, bool isDark) {
    return SizedBox(
      width: 64,
      height: 50,
      child: InkWell(
        onTap: () => onTap(text),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
