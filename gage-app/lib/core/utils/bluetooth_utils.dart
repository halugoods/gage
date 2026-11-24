import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utilitas Bluetooth Thermal Printer untuk GAGE Merchant Portal (Paritas 1:1 Nusa Kasir).
/// Menggunakan Native Android SPP (RFCOMM) via MethodChannel tanpa library pihak ketiga yang rentan bug.
class BluetoothUtils {
  static const _channel = MethodChannel('com.gage/bluetooth');

  /// Mengembalikan true jika Bluetooth pada HP sedang AKTIF / HIDUP secara fisik.
  static Future<bool> isBluetoothEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isBluetoothEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Meminta sistem Android memunculkan prompt "Aktifkan Bluetooth".
  static Future<bool> requestBluetoothEnable() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestBluetoothEnable');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Membuka layar Pengaturan Bluetooth sistem Android.
  static Future<bool> openBluetoothSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('openBluetoothSettings');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa izin Bluetooth runtime (BLUETOOTH_CONNECT & BLUETOOTH_SCAN pada Android 12+).
  static Future<bool> hasBluetoothPermissions() async {
    if (!Platform.isAndroid) return true;
    try {
      final scanStatus = await Permission.bluetoothScan.status;
      final connectStatus = await Permission.bluetoothConnect.status;
      return scanStatus.isGranted && connectStatus.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Meminta izin Bluetooth runtime kepada pengguna.
  static Future<bool> requestBluetoothPermissions() async {
    if (!Platform.isAndroid) return true;
    try {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      return (statuses[Permission.bluetoothScan]?.isGranted ?? false) &&
          (statuses[Permission.bluetoothConnect]?.isGranted ?? false);
    } catch (_) {
      return false;
    }
  }

  /// Memindai daftar printer yang sudah dipasangkan (bonded/paired).
  static Future<List<Map<String, String>>> scanDevices() async {
    if (!Platform.isAndroid) return [];
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('scanDevices');
      if (result == null) return [];
      return result.cast<Map<dynamic, dynamic>>().map((m) {
        return {
          'name': m['name']?.toString() ?? 'Printer Thermal',
          'address': m['address']?.toString() ?? '',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Menyambungkan soket RFCOMM SPP ke printer thermal berdasarkan alamat MAC.
  static Future<bool> connectDevice(String address) async {
    try {
      final result = await _channel.invokeMethod<bool>('connectDevice', {'address': address});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mengirimkan byte ESC/POS mentah ke printer yang sedang terhubung.
  static Future<bool> sendBytes(Uint8List bytes) async {
    try {
      final result = await _channel.invokeMethod<bool>('sendBytes', {'data': bytes});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Memutuskan sambungan dari printer.
  static Future<bool> disconnectDevice() async {
    try {
      final result = await _channel.invokeMethod<bool>('disconnectDevice');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mengecek apakah koneksi printer aktif saat ini.
  static Future<bool> isConnected() async {
    try {
      final result = await _channel.invokeMethod<bool>('isConnected');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
