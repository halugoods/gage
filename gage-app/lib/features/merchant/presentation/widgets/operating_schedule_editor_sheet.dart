import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// Shows an interactive modal sheet for merchants to configure dynamic Mon-Sun operating hours
/// or check "Buka setiap hari".
Future<MerchantOperatingSchedule?> showOperatingScheduleEditorSheet({
  required BuildContext context,
  required MerchantOperatingSchedule initialSchedule,
}) {
  return showModalBottomSheet<MerchantOperatingSchedule>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _OperatingScheduleEditorSheet(initialSchedule: initialSchedule),
  );
}

class _OperatingScheduleEditorSheet extends StatefulWidget {
  final MerchantOperatingSchedule initialSchedule;

  const _OperatingScheduleEditorSheet({required this.initialSchedule});

  @override
  State<_OperatingScheduleEditorSheet> createState() => _OperatingScheduleEditorSheetState();
}

class _OperatingScheduleEditorSheetState extends State<_OperatingScheduleEditorSheet> {
  late bool _everydaySame;
  late String _everydayOpen;
  late String _everydayClose;
  late Map<int, DayOperatingHours> _days;

  @override
  void initState() {
    super.initState();
    _everydaySame = widget.initialSchedule.everydaySame;
    _everydayOpen = widget.initialSchedule.everydayOpen;
    _everydayClose = widget.initialSchedule.everydayClose;
    _days = Map<int, DayOperatingHours>.from(widget.initialSchedule.days);
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    final h = (parts.isNotEmpty ? int.tryParse(parts[0]) : null) ?? 9;
    final m = (parts.length > 1 ? int.tryParse(parts[1]) : null) ?? 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  String _formatTime(TimeOfDay tod) {
    final hh = tod.hour.toString().padLeft(2, '0');
    final mm = tod.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<String?> _pickTime(String current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(current),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return null;
    return _formatTime(picked);
  }

  MerchantOperatingSchedule _buildResult() {
    return MerchantOperatingSchedule(
      everydaySame: _everydaySame,
      everydayOpen: _everydayOpen,
      everydayClose: _everydayClose,
      days: _days,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Atur Jam Operasional Toko',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Atur jam buka Senin - Minggu secara fleksibel. Perubahan langsung tampil di info toko pelanggan.',
            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : GageTheme.textSecondary),
          ),
          const SizedBox(height: 12),

          // Checkbox Buka Setiap Hari
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _everydaySame
                    ? GageTheme.primary.withValues(alpha: 0.45)
                    : (isDark ? Colors.white12 : Colors.grey.shade200),
              ),
            ),
            child: CheckboxListTile(
              value: _everydaySame,
              activeColor: GageTheme.primary,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Buka setiap hari (Senin - Minggu sama)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                _everydaySame
                    ? 'Centang aktif: seluruh hari memakai jam yang sama'
                    : 'Nonaktif: atur jam buka tutup per hari secara terpisah',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : GageTheme.textSecondary),
              ),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _everydaySame = val ?? true);
              },
            ),
          ),
          const SizedBox(height: 12),

          if (_everydaySame)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jam Operasional Setiap Hari',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeChipButton(
                          label: 'Jam Buka',
                          value: '$_everydayOpen WIB',
                          onTap: () async {
                            final res = await _pickTime(_everydayOpen);
                            if (res != null) setState(() => _everydayOpen = res);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TimeChipButton(
                          label: 'Jam Tutup',
                          value: '$_everydayClose WIB',
                          onTap: () async {
                            final res = await _pickTime(_everydayClose);
                            if (res != null) setState(() => _everydayClose = res);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: MerchantOperatingSchedule.orderedWeekdays.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final weekday = MerchantOperatingSchedule.orderedWeekdays[idx];
                  final dayName = MerchantOperatingSchedule.weekdayLabel(weekday);
                  final entry = _days[weekday] ?? DayOperatingHours(openTime: _everydayOpen, closeTime: _everydayClose);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: entry.isOpen
                            ? (isDark ? Colors.white12 : Colors.grey.shade200)
                            : Colors.red.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    dayName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: entry.isOpen
                                          ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                                          : Colors.red.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      entry.isOpen ? 'Buka' : 'Tutup',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: entry.isOpen ? const Color(0xFF16A34A) : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: entry.isOpen,
                              activeTrackColor: GageTheme.accentGreen,
                              onChanged: (v) {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _days[weekday] = entry.copyWith(isOpen: v);
                                });
                              },
                            ),
                          ],
                        ),
                        if (entry.isOpen) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _TimeChipButton(
                                  label: 'Buka',
                                  value: '${entry.openTime} WIB',
                                  onTap: () async {
                                    final res = await _pickTime(entry.openTime);
                                    if (res != null) {
                                      setState(() => _days[weekday] = entry.copyWith(openTime: res));
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _TimeChipButton(
                                  label: 'Tutup',
                                  value: '${entry.closeTime} WIB',
                                  onTap: () async {
                                    final res = await _pickTime(entry.closeTime);
                                    if (res != null) {
                                      setState(() => _days[weekday] = entry.copyWith(closeTime: res));
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, _buildResult());
              },
              child: const Text(
                'Simpan Jadwal Operasional',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeChipButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeChipButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 15, color: GageTheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10, color: GageTheme.textSecondary)),
                  Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
