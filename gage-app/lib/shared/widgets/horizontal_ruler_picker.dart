import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// HorizontalRulerPicker
/// Mistar pengukur horizontal interaktif (Ruler Wheel Picker)
/// Menggunakan garis-garis skala vertikal (minor & major ticks) dengan jarum indikator tengah.
/// Dilengkapi feedback haptik taktil pada setiap kelipatan [step].
class HorizontalRulerPicker extends StatefulWidget {
  final int initialValue;
  final int minValue;
  final int maxValue;
  final int step; // Default kelipatan: Rp 5.000
  final ValueChanged<int> onChanged;
  final Color activeColor;

  const HorizontalRulerPicker({
    super.key,
    required this.initialValue,
    this.minValue = 5000,
    this.maxValue = 10000000, // Fleksibel hingga Rp 10.000.000+
    this.step = 5000,
    required this.onChanged,
    this.activeColor = const Color(0xFFE52320),
  });

  @override
  State<HorizontalRulerPicker> createState() => _HorizontalRulerPickerState();
}

class _HorizontalRulerPickerState extends State<HorizontalRulerPicker> {
  late ScrollController _scrollController;
  late int _currentValue;
  final double _tickSpacing = 14.0; // Jarak antar garis skala (px)
  bool _isUserScrolling = false;

  int get _totalSteps => ((widget.maxValue - widget.minValue) ~/ widget.step) + 1;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.clamp(widget.minValue, widget.maxValue);
    final initialIndex = (_currentValue - widget.minValue) ~/ widget.step;
    final initialOffset = initialIndex * _tickSpacing;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void didUpdateWidget(covariant HorizontalRulerPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isUserScrolling && widget.initialValue != _currentValue) {
      _currentValue = widget.initialValue.clamp(widget.minValue, widget.maxValue);
      final index = (_currentValue - widget.minValue) ~/ widget.step;
      final targetOffset = index * _tickSpacing;
      if (_scrollController.hasClients && (_scrollController.offset - targetOffset).abs() > 2) {
        _scrollController.jumpTo(targetOffset);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final index = (offset / _tickSpacing).round().clamp(0, _totalSteps - 1);
    final calculatedValue = widget.minValue + (index * widget.step);

    if (calculatedValue != _currentValue) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentValue = calculatedValue;
      });
      widget.onChanged(_currentValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rulerHeight = 64.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = constraints.maxWidth / 2;

        return SizedBox(
          height: rulerHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. List Garis Mistar yang Dapat Digulirkan
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification) {
                    _isUserScrolling = true;
                  } else if (notification is ScrollUpdateNotification) {
                    _onScroll();
                  } else if (notification is ScrollEndNotification) {
                    _isUserScrolling = false;
                    // Snap ke garis tick terdekat
                    final targetIndex = (_scrollController.offset / _tickSpacing).round().clamp(0, _totalSteps - 1);
                    final snapOffset = targetIndex * _tickSpacing;
                    _scrollController.animateTo(
                      snapOffset,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                    );
                  }
                  return true;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: halfWidth),
                  itemCount: _totalSteps,
                  itemBuilder: (context, index) {
                    final value = widget.minValue + (index * widget.step);
                    // Setiap kelipatan 50.000 adalah garis panjang (major tick)
                    final isMajor = (value % 50000) == 0;
                    // Setiap kelipatan 25.000 adalah garis sedang
                    final isMedium = (value % 25000) == 0;

                    final tickHeight = isMajor ? 32.0 : (isMedium ? 22.0 : 14.0);
                    final tickWidth = isMajor ? 2.0 : 1.2;
                    final tickColor = isMajor
                        ? (isDark ? Colors.white70 : const Color(0xFF334155))
                        : (isDark ? Colors.white24 : const Color(0xFFCBD5E1));

                    return SizedBox(
                      width: _tickSpacing,
                      child: Center(
                        child: Container(
                          width: tickWidth,
                          height: tickHeight,
                          decoration: BoxDecoration(
                            color: tickColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 2. Efek Fade di Ujung Kiri dan Kanan (Vignette Gradient)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 48,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                          (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 48,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.0),
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Jarum Penunjuk Indikator Tengah (Center Needle Indicator)
              Positioned(
                child: IgnorePointer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 2.8,
                        height: 38.0,
                        decoration: BoxDecoration(
                          color: widget.activeColor,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: widget.activeColor.withValues(alpha: 0.45),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
