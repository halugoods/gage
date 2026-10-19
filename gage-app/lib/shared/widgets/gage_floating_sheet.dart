import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// Universal iOS-style Floating Bottom Sheet untuk GAGE Pracimantoro.
/// Menggunakan efek Frosted Glass Blur (BackdropFilter), mengambang dengan margin 16px,
/// sudut rounded 24px, dan Inset Grouped layout.
class GageFloatingSheet {
  /// Membuka sheet mengambang dengan latar belakang frosted glass blur
  static Future<T?> show<T>({
    required BuildContext context,
    Widget Function(BuildContext sheetContext)? builder,
    Widget? child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    EdgeInsets? padding,
    bool isScrollControlled = true,
    Color? backgroundColor,
  }) {
    assert(builder != null || child != null, 'Either builder or child must be provided');
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) {
        final content = builder != null ? builder(sheetContext) : child!;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  MediaQuery.of(sheetContext).padding.bottom > 0 ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor ?? (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    // iOS Grabber Pill
                    Container(
                      width: 38,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    if (title != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(sheetContext).pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 12),
                    ],
                    Flexible(
                      child: SingleChildScrollView(
                        padding: padding ?? const EdgeInsets.fromLTRB(20, 14, 20, 20),
                        child: content,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Interactive iOS Inset Grouped Sheet: Kirim Sebagai Hadiah
  static Future<Map<String, String>?> showGiftSheet({
    required BuildContext context,
    String initialName = '',
    String initialPhone = '',
    String initialMessage = '',
  }) {
    final nameCtrl = TextEditingController(text: initialName);
    final phoneCtrl = TextEditingController(text: initialPhone);
    final msgCtrl = TextEditingController(text: initialMessage);

    final presetChips = [
      {'label': '🎂 Ultah', 'text': 'Selamat ulang tahun! Makan enak ya hari ini~ 🎂🎉'},
      {'label': '☕ Semangat', 'text': 'Semangat kerjanya! Jangan lupa istirahat & makan ya ☕✨'},
      {'label': '🎉 Traktiran', 'text': 'Traktiran spesial buat kamu! Selamat menikmati~ 🎁'},
      {'label': '❤️ Makasih', 'text': 'Terima kasih banyak atas bantuannya selama ini! ❤️'},
    ];

    return show<Map<String, String>>(
      context: context,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: GageTheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.card_giftcard_rounded, color: GageTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kirim Sebagai Hadiah',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Kejutan spesial lengkap ucapan virtual',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.grey.shade400 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(sheetContext),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Inset Grouped Container
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Input 1: Nama Penerima
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 18, color: GageTheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: nameCtrl,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Nama Penerima (contoh: Bu Ani / Sahabat)',
                                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),

                      // Input 2: No WhatsApp
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.phone_android_rounded, size: 18, color: Color(0xFF16A34A)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'No. WhatsApp (contoh: 081234567890)',
                                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),

                      // Input 3: Kartu Ucapan
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.edit_note_rounded, size: 18, color: Colors.amber),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: msgCtrl,
                                maxLines: 2,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Pesan / Kartu Ucapan Virtual...',
                                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Preset Greeting Quick Chips
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: presetChips.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 6),
                    itemBuilder: (ctx, idx) {
                      final chip = presetChips[idx];
                      return ActionChip(
                        label: Text(chip['label']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300, width: 0.8),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          msgCtrl.text = chip['text']!;
                          setLocalState(() {});
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // Action Button (10px Rounded)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(sheetContext, {
                        'name': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'message': msgCtrl.text.trim(),
                      });
                    },
                    child: const Text('Simpan Detail Hadiah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Floating Input Sheet untuk Catatan (Patokan Alamat / Catatan Menu)
  static Future<String?> showNoteInput({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String initialValue,
    required String hintText,
    IconData icon = Icons.edit_note_rounded,
    Color iconColor = GageTheme.primary,
  }) {
    final textCtrl = TextEditingController(text: initialValue);

    return show<String>(
      context: context,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.grey.shade400 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(sheetContext),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: textCtrl,
                autofocus: true,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(sheetContext, textCtrl.text.trim());
                },
                child: const Text('Simpan Catatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Floating Confirmation Sheet (pengganti AlertDialog kaku)
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Konfirmasi',
    String cancelLabel = 'Batal',
    Color confirmColor = GageTheme.primary,
    IconData icon = Icons.info_outline_rounded,
  }) {
    return show<bool>(
      context: context,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: confirmColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: confirmColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.grey.shade300 : Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: Text(cancelLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(sheetContext, true);
                    },
                    child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
