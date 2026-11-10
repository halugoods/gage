import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Gage3DFlipCardDialog
/// Dialog popup kartu 3D interaktif yang dapat dibalik (flip 180 derajat)
/// - Sisi Depan: Dynamic sesuai kartu terpilih (BCA, Mandiri, GoPay, BRI, dsb.)
///   dengan pilihan 10 tema warna gradient murni ala Nusa Kasir
/// - Sisi Belakang: Pita magnetik hitam, panel tanda tangan, kode CVV,
///   serta FITUR TERSEMBUNYI Hadiah Kejutan (Voucher & Poin acak yang dapat diklaim)
/// - Aksi: Salin nomor rekening, Edit Kartu & Kustomisasi Desain, serta Jadikan Rekening Utama
class Gage3DFlipCardDialog extends StatefulWidget {
  final Map<String, dynamic> cardData;
  final bool isPrimary;
  final VoidCallback? onSetAsPrimary;
  final void Function(Map<String, dynamic> updatedCard)? onCardUpdated;
  final void Function(int bonusPoints, String voucherCode)? onRewardClaimed;

  const Gage3DFlipCardDialog({
    super.key,
    required this.cardData,
    this.isPrimary = false,
    this.onSetAsPrimary,
    this.onCardUpdated,
    this.onRewardClaimed,
  });

  static const List<Map<String, dynamic>> colorSwatches = [
    {
      'name': 'Emerald Green',
      'colors': [Color(0xFF059669), Color(0xFF064E3B)],
      'primary': Color(0xFF059669),
    },
    {
      'name': 'Navy Blue',
      'colors': [Color(0xFF1E3A8A), Color(0xFF172554)],
      'primary': Color(0xFF1E3A8A),
    },
    {
      'name': 'Obsidian Slate',
      'colors': [Color(0xFF0F172A), Color(0xFF334155)],
      'primary': Color(0xFF0F172A),
    },
    {
      'name': 'Crimson Red',
      'colors': [Color(0xFFDC2626), Color(0xFF7F1D1D)],
      'primary': Color(0xFFDC2626),
    },
    {
      'name': 'Royal Amber',
      'colors': [Color(0xFFD97706), Color(0xFF78350F)],
      'primary': Color(0xFFD97706),
    },
    {
      'name': 'Deep Violet',
      'colors': [Color(0xFF7C3AED), Color(0xFF4C1D95)],
      'primary': Color(0xFF7C3AED),
    },
    {
      'name': 'Ocean Cyan',
      'colors': [Color(0xFF0284C7), Color(0xFF0E7490)],
      'primary': Color(0xFF0284C7),
    },
    {
      'name': 'Rose Quartz',
      'colors': [Color(0xFFBE185D), Color(0xFF831843)],
      'primary': Color(0xFFBE185D),
    },
    {
      'name': 'Sunset Copper',
      'colors': [Color(0xFFEA580C), Color(0xFF9A3412)],
      'primary': Color(0xFFEA580C),
    },
    {
      'name': 'Forest Pine',
      'colors': [Color(0xFF15803D), Color(0xFF14532D)],
      'primary': Color(0xFF15803D),
    },
  ];

  static const List<Map<String, String>> flipInstitutions = [
    {'code': 'BCA', 'name': 'Bank Central Asia (BCA)', 'type': 'bank'},
    {'code': 'Mandiri', 'name': 'Bank Mandiri', 'type': 'bank'},
    {'code': 'BRI', 'name': 'Bank Rakyat Indonesia (BRI)', 'type': 'bank'},
    {'code': 'BNI', 'name': 'Bank Negara Indonesia (BNI)', 'type': 'bank'},
    {'code': 'BSI', 'name': 'Bank Syariah Indonesia (BSI)', 'type': 'bank'},
    {'code': 'CIMB Niaga', 'name': 'Bank CIMB Niaga', 'type': 'bank'},
    {'code': 'Permata', 'name': 'Bank Permata', 'type': 'bank'},
    {'code': 'Danamon', 'name': 'Bank Danamon', 'type': 'bank'},
    {'code': 'SeaBank', 'name': 'SeaBank Indonesia', 'type': 'bank'},
    {'code': 'Bank Jago', 'name': 'Bank Jago', 'type': 'bank'},
    {'code': 'Blu by BCA', 'name': 'Blu by BCA Digital', 'type': 'bank'},
    {'code': 'BTN', 'name': 'Bank Tabungan Negara (BTN)', 'type': 'bank'},
    {'code': 'Bank Mega', 'name': 'Bank Mega', 'type': 'bank'},
    {'code': 'Panin', 'name': 'Panin Bank', 'type': 'bank'},
    {'code': 'OCBC NISP', 'name': 'OCBC NISP', 'type': 'bank'},
    {'code': 'BNC', 'name': 'Bank Neo Commerce (BNC)', 'type': 'bank'},
    {'code': 'Muamalat', 'name': 'Bank Muamalat', 'type': 'bank'},
    {'code': 'Jenius', 'name': 'BTPN / Jenius', 'type': 'bank'},
    {'code': 'Sinarmas', 'name': 'Bank Sinarmas', 'type': 'bank'},
    {'code': 'GoPay', 'name': 'GoPay (Gojek)', 'type': 'ewallet'},
    {'code': 'OVO', 'name': 'OVO Cash', 'type': 'ewallet'},
    {'code': 'DANA', 'name': 'DANA Indonesia', 'type': 'ewallet'},
    {'code': 'ShopeePay', 'name': 'ShopeePay', 'type': 'ewallet'},
    {'code': 'LinkAja', 'name': 'LinkAja', 'type': 'ewallet'},
    {'code': 'AstraPay', 'name': 'AstraPay', 'type': 'ewallet'},
  ];

  static String? validateAccountNumber(String bank, String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+|-'), '');
    if (clean.isEmpty) return 'Nomor rekening / e-wallet wajib diisi';
    if (!RegExp(r'^\d+$').hasMatch(clean)) return 'Nomor harus berupa angka saja';

    if (['GoPay', 'OVO', 'DANA', 'ShopeePay', 'LinkAja', 'AstraPay'].contains(bank)) {
      if (!clean.startsWith('08') && !clean.startsWith('628')) {
        return 'Nomor e-wallet harus diawali 08 atau 628';
      }
      if (clean.length < 10 || clean.length > 13) {
        return 'Nomor e-wallet harus 10 - 13 digit (cth: 081234567890)';
      }
      return null;
    }

    switch (bank) {
      case 'BCA':
      case 'Blu by BCA':
        if (clean.length != 10) return 'Nomor rekening $bank harus tepat 10 digit';
        break;
      case 'Mandiri':
        if (clean.length != 13) return 'Nomor rekening Mandiri harus tepat 13 digit';
        break;
      case 'BRI':
        if (clean.length != 15) return 'Nomor rekening BRI harus tepat 15 digit';
        break;
      case 'BNI':
      case 'BSI':
      case 'Bank Mega':
      case 'Panin':
      case 'Muamalat':
      case 'Sinarmas':
        if (clean.length != 10) return 'Nomor rekening $bank harus tepat 10 digit';
        break;
      case 'Jenius':
        if (clean.length != 11) return 'Nomor rekening Jenius/BTPN harus tepat 11 digit';
        break;
      case 'CIMB Niaga':
        if (clean.length != 14) return 'Nomor rekening CIMB Niaga harus tepat 14 digit';
        break;
      case 'Permata':
        if (clean.length != 10 && clean.length != 16) {
          return 'Nomor rekening Permata harus 10 digit (atau 16 digit VA)';
        }
        break;
      case 'Danamon':
        if (clean.length != 10 && clean.length != 12) {
          return 'Nomor rekening Danamon harus 10 atau 12 digit';
        }
        break;
      case 'SeaBank':
      case 'Bank Jago':
      case 'OCBC NISP':
      case 'BNC':
        if (clean.length != 12) return 'Nomor rekening $bank harus tepat 12 digit';
        break;
      case 'BTN':
        if (clean.length != 16) return 'Nomor rekening BTN harus tepat 16 digit';
        break;
      default:
        if (clean.length < 8 || clean.length > 18) return 'Panjang nomor rekening tidak valid (8-18 digit)';
    }
    return null;
  }

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> cardData,
    bool isPrimary = false,
    VoidCallback? onSetAsPrimary,
    void Function(Map<String, dynamic> updatedCard)? onCardUpdated,
    void Function(int bonusPoints, String voucherCode)? onRewardClaimed,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Gage3DFlipCard',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Gage3DFlipCardDialog(
          cardData: cardData,
          isPrimary: isPrimary,
          onSetAsPrimary: onSetAsPrimary,
          onCardUpdated: onCardUpdated,
          onRewardClaimed: onRewardClaimed,
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  State<Gage3DFlipCardDialog> createState() => _Gage3DFlipCardDialogState();
}

class _Gage3DFlipCardDialogState extends State<Gage3DFlipCardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isFront = true;

  late Map<String, dynamic> _card;
  bool _isRewardClaimed = false;
  final String _rewardTitle = 'Voucher Diskon 50% + 50 Poin';

  @override
  void initState() {
    super.initState();
    _card = Map<String, dynamic>.from(widget.cardData);
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    HapticFeedback.mediumImpact();
    if (_isFront) {
      _flipCtrl.forward();
    } else {
      _flipCtrl.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  void _claimSecretReward() {
    if (_isRewardClaimed) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _isRewardClaimed = true;
    });
    if (widget.onRewardClaimed != null) {
      widget.onRewardClaimed!(50, 'DISKON50');
    }
    GageToast.show(
      context,
      '🎁 Hore! Kamu membuka Hadiah Kejutan GAGE: $_rewardTitle!',
      type: GageToastType.success,
    );
  }

  void _openThemeAndEditSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final holderCtrl = TextEditingController(text: _card['holder'] as String? ?? 'PENGGUNA GAGE');
    final rawNumber = (_card['fullNumber'] ?? _card['accountNumber'] ?? '552499104242').toString().replaceAll(' ', '');
    final numberCtrl = TextEditingController(text: rawNumber);
    String selectedBank = _card['bank'] as String? ?? 'BCA';
    List<Color> currentGradient = (_card['gradient'] as List?)?.cast<Color>() ??
        const [Color(0xFF1E3A8A), Color(0xFF172554)];
    String? validationError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: GageTheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.edit_note_rounded, color: GageTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Edit Rekening & Desain Kartu',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black54),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // 1. Pilihan Desain Kartu (Lingkaran Warna ala Nusa Kasir)
                    Text(
                      'Pilihan Desain Kartu:',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 58,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: Gage3DFlipCardDialog.colorSwatches.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (ctx, idx) {
                          final swatch = Gage3DFlipCardDialog.colorSwatches[idx];
                          final colors = swatch['colors'] as List<Color>;
                          final name = swatch['name'] as String;
                          final isSelected = currentGradient.first == colors.first && currentGradient.last == colors.last;

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setSheetState(() => currentGradient = colors);
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: colors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? (isDark ? Colors.white : GageTheme.primary) : Colors.black12,
                                      width: isSelected ? 2.5 : 1.0,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: colors.first.withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(Icons.check_rounded, color: Colors.white, size: 18),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  name.split(' ').first,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? (isDark ? Colors.white : GageTheme.primary)
                                        : (isDark ? Colors.white60 : Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Dropdown Bank Mitra Flip
                    Text(
                      'Pilih Bank / E-Wallet (Mitra Flip):',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: Gage3DFlipCardDialog.flipInstitutions.any((i) => i['code'] == selectedBank)
                          ? selectedBank
                          : 'BCA',
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      items: Gage3DFlipCardDialog.flipInstitutions.map((inst) {
                        final code = inst['code']!;
                        final name = inst['name']!;
                        final isEwallet = inst['type'] == 'ewallet';
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Row(
                            children: [
                              Icon(
                                isEwallet ? Icons.account_balance_wallet_rounded : Icons.account_balance_rounded,
                                size: 18,
                                color: isEwallet ? const Color(0xFF0D9488) : const Color(0xFF1E3A8A),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() {
                            selectedBank = val;
                            validationError = Gage3DFlipCardDialog.validateAccountNumber(selectedBank, numberCtrl.text);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 3. Nomor Rekening & Validasi Spesifik Bank
                    Text(
                      'Nomor Rekening / E-Wallet:',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: numberCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      decoration: InputDecoration(
                        hintText: selectedBank == 'BRI'
                            ? '15 digit angka (cth: 001201000123500)'
                            : selectedBank == 'Mandiri'
                                ? '13 digit angka (cth: 1370012345678)'
                                : selectedBank == 'BCA'
                                    ? '10 digit angka (cth: 8210394812)'
                                    : 'Nomor HP e-wallet (cth: 081234567890)',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white30 : Colors.black38,
                          letterSpacing: 0,
                        ),
                        errorText: validationError,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                      ),
                      onChanged: (val) {
                        setSheetState(() {
                          validationError = Gage3DFlipCardDialog.validateAccountNumber(selectedBank, val);
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // 4. Nama Pemilik Rekening
                    Text(
                      'Nama Pemilik Akun:',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: holderCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nama sesuai buku tabungan / e-wallet',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white30 : Colors.black38,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tombol Simpan Perubahan
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final err = Gage3DFlipCardDialog.validateAccountNumber(selectedBank, numberCtrl.text);
                          if (err != null) {
                            setSheetState(() => validationError = err);
                            GageToast.show(context, err, type: GageToastType.warning);
                            return;
                          }
                          if (holderCtrl.text.trim().isEmpty) {
                            GageToast.show(context, 'Nama pemilik akun tidak boleh kosong', type: GageToastType.warning);
                            return;
                          }

                          Navigator.pop(sheetCtx);
                          final cleanNum = numberCtrl.text.replaceAll(' ', '');
                          final masked = cleanNum.length >= 4
                              ? '•••• ${cleanNum.substring(cleanNum.length - 4)}'
                              : cleanNum;

                          setState(() {
                            _card['bank'] = selectedBank;
                            _card['holder'] = holderCtrl.text.toUpperCase();
                            _card['fullNumber'] = cleanNum;
                            _card['accountNumber'] = cleanNum;
                            _card['maskedNumber'] = masked;
                            _card['gradient'] = currentGradient;
                          });

                          if (widget.onCardUpdated != null) {
                            widget.onCardUpdated!(_card);
                          }
                          GageToast.show(context, 'Detail rekening dan desain berhasil disimpan!', type: GageToastType.success);
                        },
                        child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bankName = _card['bank'] as String? ?? 'GAGE PAY';
    final fullNumber = _card['fullNumber'] as String? ?? _card['accountNumber'] as String? ?? '5524 9910 4242';
    final holder = _card['holder'] as String? ?? 'PENGGUNA GAGE';
    final validThru = _card['validThru'] as String? ?? '12 / 28';
    final gradientColors = (_card['gradient'] as List?)?.cast<Color>() ??
        const [Color(0xFF1E3A8A), Color(0xFF172554)];
    final icon = _card['icon'] as IconData? ?? Icons.account_balance_rounded;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Petunjuk & Tombol Tutup
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _isFront ? 'Ketuk kartu untuk balik sisi & klaim hadiah' : 'Ketuk kartu untuk kembali ke sisi depan',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Interactive 3D Flip Card Container
              GestureDetector(
                onTap: _toggleFlip,
                child: AnimatedBuilder(
                  animation: _flipAnim,
                  builder: (context, _) {
                    final angle = _flipAnim.value * math.pi;
                    final isUnder = (angle > math.pi / 2);

                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015) // Efek perspektif 3D
                        ..rotateY(angle),
                      child: isUnder
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: _buildBackCard(fullNumber, gradientColors),
                            )
                          : _buildFrontCard(bankName, fullNumber, holder, validThru, gradientColors, icon),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // Baris Aksi Utama: Salin Nomor & Tombol EDIT KARTU yang Menonjol
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: fullNumber.replaceAll(' ', '')));
                        HapticFeedback.lightImpact();
                        GageToast.show(
                          context,
                          'Nomor rekening berhasil disalin: $fullNumber',
                          type: GageToastType.success,
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Salin Nomor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _openThemeAndEditSheet,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit Kartu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Baris Tambahan: Jadikan Rekening Utama
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isPrimary ? const Color(0xFF16A34A) : Colors.white12,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: widget.isPrimary
                      ? null
                      : () {
                          if (widget.onSetAsPrimary != null) {
                            widget.onSetAsPrimary!();
                          }
                          Navigator.pop(context);
                          GageToast.show(
                            context,
                            '$bankName dijadikan sebagai Rekening Utama!',
                            type: GageToastType.success,
                          );
                        },
                  icon: Icon(
                    widget.isPrimary ? Icons.check_circle_rounded : Icons.star_rounded,
                    size: 16,
                    color: widget.isPrimary ? Colors.white : const Color(0xFFF59E0B),
                  ),
                  label: Text(
                    widget.isPrimary ? 'Rekening Utama Aktif' : 'Jadikan Rekening Utama Penarikan',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard(
    String bank,
    String number,
    String holder,
    String date,
    List<Color> gradientColors,
    IconData icon,
  ) {
    return Container(
      width: 320,
      height: 195,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Background Specular Shimmer
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Header: Brand & Contactless Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    bank.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.contactless_rounded,
                color: Colors.white70,
                size: 24,
              ),
            ],
          ),

          // EMV Chip Emas
          Positioned(
            left: 0,
            top: 48,
            child: Container(
              width: 38,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black26, width: 0.8),
              ),
              child: CustomPaint(painter: _ChipPatternPainter()),
            ),
          ),

          // Nomor Rekening Embossed
          Positioned(
            left: 0,
            bottom: 34,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.2,
                fontFamily: 'monospace',
                shadows: [
                  Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 1)),
                ],
              ),
            ),
          ),

          // Footer: Cardholder & Expiry
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CARDHOLDER',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      holder,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'VALID THRU',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(String number, List<Color> gradientColors) {
    return Container(
      width: 320,
      height: 195,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientColors.last, const Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Pita Magnetik Hitam Tekstur
          Container(
            width: double.infinity,
            height: 34,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Color(0xFF262626), Colors.black],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Panel Signature Strip & CVV Code
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEDED),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    child: Container(height: 1, color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '829',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Hadiah Kejutan Tersembunyi (Hadiah Loyalitas GAGE)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _claimSecretReward,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _isRewardClaimed
                      ? const Color(0xFF16A34A).withValues(alpha: 0.25)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isRewardClaimed ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isRewardClaimed ? Icons.check_circle_rounded : Icons.card_giftcard_rounded,
                      color: _isRewardClaimed ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRewardClaimed ? 'Hadiah Terklaim!' : 'Hadiah Kejutan Belakang Kartu',
                            style: TextStyle(
                              color: _isRewardClaimed ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _isRewardClaimed ? '$_rewardTitle telah masuk ke akunmu' : 'Ketuk untuk klaim bonus voucher & poin',
                            style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // 4. Logo GAGE Secure di Pojok Kanan Bawah
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'GAGE SECURE WALLET',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'ID: GG-${number.replaceAll(' ', '').length >= 4 ? number.replaceAll(' ', '').substring(number.replaceAll(' ', '').length - 4) : '0000'}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 8,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(4)),
      paint,
    );
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.35, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.65, 0), Offset(size.width * 0.65, size.height), paint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
