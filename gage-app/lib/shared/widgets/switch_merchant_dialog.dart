import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

/// Floating Bottom Sheet konfirmasi pergantian toko/merchant saat menambahkan item dari toko berbeda
/// Mendukung aturan transaksi GAGE Pracimantoro: 1 Pesanan = 1 Toko (Single-Merchant Locking)
/// Menggunakan standar GageFloatingSheet (iOS frosted blur, 28px radius, capsule buttons)
class SwitchMerchantDialog extends StatelessWidget {
  final String currentMerchantName;
  final String newMerchantName;

  const SwitchMerchantDialog({
    super.key,
    required this.currentMerchantName,
    required this.newMerchantName,
  });

  /// Menampilkan sheet konfirmasi pergantian toko.
  /// Mengembalikan true jika pengguna memilih untuk mengosongkan keranjang dan berganti ke toko baru.
  static Future<bool?> show(
    BuildContext context, {
    required String currentMerchantName,
    required String newMerchantName,
  }) {
    HapticFeedback.lightImpact();
    return GageFloatingSheet.showConfirm(
      context: context,
      title: 'Ganti Toko?',
      message: 'Keranjang Anda saat ini berisi menu dari "$currentMerchantName". 1 pesanan hanya untuk 1 toko/resto.\n\nKosongkan keranjang untuk beralih ke "$newMerchantName"?',
      confirmLabel: 'Ganti & Tambah',
      cancelLabel: 'Batal',
      confirmColor: GageTheme.primary,
      icon: Icons.swap_horiz_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
