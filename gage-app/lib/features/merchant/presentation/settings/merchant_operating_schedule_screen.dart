import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Full Screen Page: Pengaturan Jam Operasional Mingguan (Senin - Minggu)
class MerchantOperatingScheduleScreen extends StatefulWidget {
  final String merchantId;
  final MerchantOperatingSchedule? initialSchedule;

  const MerchantOperatingScheduleScreen({
    super.key,
    required this.merchantId,
    this.initialSchedule,
  });

  @override
  State<MerchantOperatingScheduleScreen> createState() => _MerchantOperatingScheduleScreenState();
}

class _MerchantOperatingScheduleScreenState extends State<MerchantOperatingScheduleScreen> {
  late bool _everydaySame;
  late String _everydayOpen;
  late String _everydayClose;
  late Map<int, DayOperatingHours> _days;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSchedule ?? MerchantOperatingSchedule.defaults();
    _everydaySame = initial.everydaySame;
    _everydayOpen = initial.everydayOpen;
    _everydayClose = initial.everydayClose;
    _days = Map<int, DayOperatingHours>.from(initial.days);
    if (widget.initialSchedule == null) {
      _loadPersistedSchedule();
    }
  }

  Future<void> _loadPersistedSchedule() async {
    final stored = await MerchantStorefrontService.loadStorefront(widget.merchantId);
    if (stored?.schedule != null && mounted) {
      final sched = stored!.schedule!;
      setState(() {
        _everydaySame = sched.everydaySame;
        _everydayOpen = sched.everydayOpen;
        _everydayClose = sched.everydayClose;
        _days = Map<int, DayOperatingHours>.from(sched.days);
      });
    }
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

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final result = _buildResult();
    final existing = await MerchantStorefrontService.loadStorefront(widget.merchantId);
    final updatedData = (existing ?? MerchantStorefrontData(merchantId: widget.merchantId)).copyWith(
      schedule: result,
    );
    await MerchantStorefrontService.saveStorefront(updatedData);

    if (!mounted) return;
    setState(() => _isSaving = false);
    GageToast.show(context, 'Jam operasional berhasil diperbarui!', type: GageToastType.success);
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Jam Operasional Toko',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Info Mode
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: GageTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.schedule_rounded, color: GageTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buka Setiap Hari (Senin - Minggu Sama)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _everydaySame
                              ? 'Seluruh hari memakai jam yang sama'
                              : 'Atur jadwal buka tutup secara terpisah per hari',
                          style: TextStyle(fontSize: 11.5, color: subColor),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _everydaySame,
                    activeTrackColor: GageTheme.primary.withValues(alpha: 0.45),
                    activeThumbColor: GageTheme.primary,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _everydaySame = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (_everydaySame) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jam Operasional Harian',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Perubahan jadwal langsung tersinkronisasi ke halaman info toko pelanggan.',
                      style: TextStyle(fontSize: 11.5, color: subColor),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ScheduleTimeCard(
                            label: 'Jam Buka',
                            value: '$_everydayOpen WIB',
                            inputBg: inputBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subColor: subColor,
                            onTap: () async {
                              final res = await _pickTime(_everydayOpen);
                              if (res != null) setState(() => _everydayOpen = res);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ScheduleTimeCard(
                            label: 'Jam Tutup',
                            value: '$_everydayClose WIB',
                            inputBg: inputBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subColor: subColor,
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
              ),
            ] else ...[
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: List.generate(MerchantOperatingSchedule.orderedWeekdays.length, (i) {
                    final weekday = MerchantOperatingSchedule.orderedWeekdays[i];
                    final dayName = MerchantOperatingSchedule.weekdayLabel(weekday);
                    final entry = _days[weekday] ?? DayOperatingHours(openTime: _everydayOpen, closeTime: _everydayClose);

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          dayName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: entry.isOpen
                                                ? GageTheme.accentGreen.withValues(alpha: 0.12)
                                                : GageTheme.primary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            entry.isOpen ? 'BUKA' : 'TUTUP',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: entry.isOpen ? GageTheme.accentGreen : GageTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: entry.isOpen,
                                    activeTrackColor: GageTheme.primary.withValues(alpha: 0.45),
                                    activeThumbColor: GageTheme.primary,
                                    onChanged: (v) {
                                      HapticFeedback.lightImpact();
                                      setState(() => _days[weekday] = entry.copyWith(isOpen: v));
                                    },
                                  ),
                                ],
                              ),
                              if (entry.isOpen) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ScheduleTimeCard(
                                        label: 'Buka',
                                        value: '${entry.openTime} WIB',
                                        inputBg: inputBg,
                                        borderColor: borderColor,
                                        textColor: textColor,
                                        subColor: subColor,
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
                                      child: _ScheduleTimeCard(
                                        label: 'Tutup',
                                        value: '${entry.closeTime} WIB',
                                        inputBg: inputBg,
                                        borderColor: borderColor,
                                        textColor: textColor,
                                        subColor: subColor,
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
                        ),
                        if (i < MerchantOperatingSchedule.orderedWeekdays.length - 1)
                          Divider(height: 1, indent: 16, endIndent: 16, color: borderColor),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? GageTheme.darkSurface : Colors.white,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSchedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Simpan Jadwal Operasional',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleTimeCard extends StatelessWidget {
  final String label;
  final String value;
  final Color inputBg;
  final Color borderColor;
  final Color textColor;
  final Color subColor;
  final VoidCallback onTap;

  const _ScheduleTimeCard({
    required this.label,
    required this.value,
    required this.inputBg,
    required this.borderColor,
    required this.textColor,
    required this.subColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 16, color: GageTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10.5, color: subColor)),
                  Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: subColor),
          ],
        ),
      ),
    );
  }
}
