import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

/// Custom Digital Delivery Scheduling Sheet untuk GAGE SuperApp
/// Sesuai instruksi:
/// - Murni Tampilan Digital (Bukan Analog Clock Face, Tanpa Dialog Bawaan Android)
/// - Floating Sheet dengan Standarisasi GageFloatingSheet
/// - Pilihan Tanggal: Hari Ini / Besok
/// - Kontrol Jam & Menit Digital dengan Stepper Kapsul
/// - Tombol Preset Cepat (+30m, +1 Jam, +2 Jam, Makan Siang, Makan Malam)
class GageDigitalScheduleSheet extends StatefulWidget {
  final DateTime initialDateTime;

  const GageDigitalScheduleSheet({
    super.key,
    required this.initialDateTime,
  });

  /// Tampilkan Dialog Digital Time Picker di dalam GageFloatingSheet
  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialTime,
  }) async {
    HapticFeedback.lightImpact();
    final result = await GageFloatingSheet.show<DateTime>(
      context: context,
      isScrollControlled: true,
      child: GageDigitalScheduleSheet(
        initialDateTime: initialTime ?? DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    return result;
  }

  @override
  State<GageDigitalScheduleSheet> createState() => _GageDigitalScheduleSheetState();
}

class _GageDigitalScheduleSheetState extends State<GageDigitalScheduleSheet> {
  late int _selectedDayOffset; // 0 = Hari Ini, 1 = Besok
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final init = widget.initialDateTime;

    if (init.day != now.day) {
      _selectedDayOffset = 1;
    } else {
      _selectedDayOffset = 0;
    }

    _hour = init.hour;
    // Bulatkan menit ke kelipatan 5
    _minute = ((init.minute / 5).round() * 5) % 60;
  }

  DateTime get _computedDateTime {
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: _selectedDayOffset));
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      _hour,
      _minute,
    );
  }

  void _adjustHour(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _hour = (_hour + delta) % 24;
      if (_hour < 0) _hour += 24;
    });
  }

  void _adjustMinute(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _minute = (_minute + delta) % 60;
      if (_minute < 0) _minute += 60;
    });
  }

  void _applyPreset(int addMinutes) {
    HapticFeedback.lightImpact();
    final now = DateTime.now().add(Duration(minutes: addMinutes));
    setState(() {
      _selectedDayOffset = (now.day != DateTime.now().day) ? 1 : 0;
      _hour = now.hour;
      _minute = ((now.minute / 5).round() * 5) % 60;
    });
  }

  void _applyFixedTime(int targetHour, int targetMinute) {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    setState(() {
      if (now.hour > targetHour || (now.hour == targetHour && now.minute >= targetMinute)) {
        _selectedDayOffset = 1; // Jika jam sudah lewat hari ini, set ke besok
      } else {
        _selectedDayOffset = 0;
      }
      _hour = targetHour;
      _minute = targetMinute;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    final hourStr = _hour.toString().padLeft(2, '0');
    final minStr = _minute.toString().padLeft(2, '0');

    final computed = _computedDateTime;
    final formattedSummary = DateFormat('EEEE, d MMM yyyy • HH:mm', 'id_ID').format(computed);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Sheet
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.schedule_rounded, color: Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Atur Jadwal Pengantaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Pilih waktu digital yang paling pas untuk pesananmu',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),

        const SizedBox(height: 14),
        Divider(height: 1, color: borderColor),
        const SizedBox(height: 14),

        // 2. Pemilihan Tanggal (Hari Ini / Besok) - Kapsul Chips
        Text(
          'Pilih Hari',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDayOffset = 0);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedDayOffset == 0
                        ? GageTheme.primary
                        : cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedDayOffset == 0 ? GageTheme.primary : borderColor,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Hari Ini',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _selectedDayOffset == 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDayOffset = 1);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedDayOffset == 1
                        ? GageTheme.primary
                        : cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedDayOffset == 1 ? GageTheme.primary : borderColor,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Besok',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _selectedDayOffset == 1 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 3. Digital Clock Face Display dengan Steppers
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Kolom Jam (Hour)
                Column(
                  children: [
                    InkWell(
                      onTap: () => _adjustHour(1),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        child: const Icon(Icons.keyboard_arrow_up_rounded, size: 22, color: GageTheme.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 68,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: GageTheme.primary.withValues(alpha: 0.5), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: GageTheme.primary.withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          hourStr,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontFamily: 'monospace',
                            color: GageTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _adjustHour(-1),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        child: const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: GageTheme.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JAM',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.grey),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.0),
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: GageTheme.primary,
                    ),
                  ),
                ),

                // Kolom Menit (Minute)
                Column(
                  children: [
                    InkWell(
                      onTap: () => _adjustMinute(5),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        child: const Icon(Icons.keyboard_arrow_up_rounded, size: 22, color: GageTheme.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 68,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: GageTheme.primary.withValues(alpha: 0.5), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: GageTheme.primary.withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          minStr,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontFamily: 'monospace',
                            color: GageTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _adjustMinute(-5),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        child: const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: GageTheme.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MENIT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'WIB',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 4. Quick Preset Chips
        Text(
          'Pilihan Cepat',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: isDark ? Colors.white70 : Colors.black87),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPresetPill('+30 Menit', () => _applyPreset(30), cardBg, borderColor, isDark),
              const SizedBox(width: 6),
              _buildPresetPill('+1 Jam', () => _applyPreset(60), cardBg, borderColor, isDark),
              const SizedBox(width: 6),
              _buildPresetPill('+2 Jam', () => _applyPreset(120), cardBg, borderColor, isDark),
              const SizedBox(width: 6),
              _buildPresetPill('Makan Siang (12:00)', () => _applyFixedTime(12, 0), cardBg, borderColor, isDark),
              const SizedBox(width: 6),
              _buildPresetPill('Makan Malam (18:30)', () => _applyFixedTime(18, 30), cardBg, borderColor, isDark),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 5. Ringkasan & Konfirmasi Simpan (Stadium Button 28px)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF1E40AF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pesanan akan diantar pada:\n$formattedSummary WIB',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GageTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context, _computedDateTime);
            },
            child: const Text('Simpan Jadwal Pengantaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildPresetPill(String label, VoidCallback onTap, Color cardBg, Color borderColor, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }
}
