import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// Delivery & driver tracking progress bar styled after Shopee Partner / ShopeeFood:
/// - 1-stage mode (when orderStatus == null): compact track for outer order card.
/// - 5-stage mode (when orderStatus != null): symmetrical 5-node merchant flow
///   (Masuk -> Disiapkan -> Siap -> Diantar -> Selesai) with per-segment motor movement.
/// - Magnifying glass animation when searching for a driver.
class GageDeliveryTrackProgress extends StatefulWidget {
  final bool isSearchingDriver;
  final bool isDriverArrived;
  final String domain; // 'food' | 'shop' | 'farm'
  final String? orderStatus; // 'NEW' | 'COOKING' | 'READY_FOR_PICKUP' | 'ON_DELIVERY' | 'COMPLETED'
  final String? labelPrefix;
  final String? labelHighlight;

  const GageDeliveryTrackProgress({
    super.key,
    required this.isSearchingDriver,
    this.isDriverArrived = false,
    this.domain = 'food',
    this.orderStatus,
    this.labelPrefix,
    this.labelHighlight,
  });

  @override
  State<GageDeliveryTrackProgress> createState() => _GageDeliveryTrackProgressState();
}

class _GageDeliveryTrackProgressState extends State<GageDeliveryTrackProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.isSearchingDriver ? 1600 : 2400),
    );
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(covariant GageDeliveryTrackProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSearchingDriver != widget.isSearchingDriver) {
      _ctrl.duration = Duration(milliseconds: widget.isSearchingDriver ? 1600 : 2400);
      if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
        _ctrl.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  IconData get _outletIcon {
    switch (widget.domain.toLowerCase()) {
      case 'shop':
        return Icons.shopping_bag_rounded;
      case 'farm':
        return Icons.eco_rounded;
      case 'food':
      default:
        return Icons.restaurant_rounded;
    }
  }

  int _resolveActiveStageIndex() {
    final s = (widget.orderStatus ?? '').toUpperCase();
    if (s == 'COMPLETED') return 4;
    if (s == 'PICKED_UP' || s == 'ON_DELIVERY') return 3;
    if (s == 'READY_FOR_PICKUP' || s == 'DRIVER_ASSIGNED' || s == 'AT_MERCHANT') return 2;
    if (s == 'COOKING' || s == 'SEARCHING_DRIVER') return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackBg = isDark ? Colors.white12 : const Color(0xFFFEE2E2);
    final trackFill = widget.isDriverArrived ? const Color(0xFF10B981) : GageTheme.primary;

    final prefixText = widget.labelPrefix ??
        (widget.isSearchingDriver
            ? 'Sedang mencari kurir terdekat'
            : (widget.isDriverArrived ? 'Pengemudi telah tiba di toko' : 'Driver menuju toko'));
    final highlightText = widget.labelHighlight ??
        (widget.isSearchingDriver ? '...' : (widget.isDriverArrived ? '' : ' • Est. 5 mnt'));

    final isFiveStage = widget.orderStatus != null;
    final activeIdx = isFiveStage ? _resolveActiveStageIndex() : 1;

    final Widget labelWidget;
    if (widget.isDriverArrived) {
      labelWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 9,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              prefixText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ],
      );
    } else {
      labelWidget = RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(fontSize: 12.5, height: 1.3),
          children: [
            TextSpan(
              text: prefixText,
              style: const TextStyle(
                color: GageTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (highlightText.isNotEmpty)
              TextSpan(
                text: highlightText,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      );
    }

    final trackWidget = LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const riderWidth = 34.0;
        const riderHeight = 22.0;

        final trackStart = isFiveStage ? 22.0 : 4.0;
        final trackEnd = isFiveStage
            ? (totalWidth - 22.0).clamp(60.0, totalWidth)
            : (totalWidth - 24.0).clamp(40.0, totalWidth);

        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final double t = Curves.easeInOut.transform(_ctrl.value);
            double minRatio;
            double maxRatio;

            if (widget.isSearchingDriver) {
              minRatio = 0.08;
              maxRatio = isFiveStage ? 0.35 : 0.38;
            } else if (isFiveStage) {
              if (activeIdx >= 4) {
                minRatio = 1.0;
                maxRatio = 1.0;
              } else if (activeIdx == 2 && widget.isDriverArrived) {
                minRatio = 0.50;
                maxRatio = 0.50;
              } else {
                minRatio = activeIdx / 4.0;
                maxRatio = ((activeIdx + 1).clamp(0, 4)) / 4.0;
              }
            } else {
              if (widget.isDriverArrived) {
                // Rider has arrived at destination store: stationed right at outlet node with soft idle vibration
                minRatio = 0.94;
                maxRatio = 0.96;
              } else {
                minRatio = 0.35;
                maxRatio = 0.85;
              }
            }

            final double riderRatio = minRatio + (maxRatio - minRatio) * t;
            final double riderCenterX =
                (trackStart + (trackEnd - trackStart) * riderRatio)
                    .clamp(riderWidth / 2, totalWidth - riderWidth / 2);
            final double fillWidth = widget.isDriverArrived
                ? (trackEnd - trackStart)
                : (riderCenterX - trackStart).clamp(0.0, trackEnd - trackStart);

            const stages = ['Masuk', 'Disiapkan', 'Siap', 'Diantar', 'Selesai'];
            final nodeIcons = [
              Icons.receipt_long_rounded,
              _outletIcon,
              Icons.inventory_2_rounded,
              Icons.two_wheeler_rounded,
              Icons.location_on_rounded,
            ];

            return Stack(
              alignment: Alignment.topLeft,
              clipBehavior: Clip.none,
              children: [
                // Track background
                Positioned(
                  top: 11,
                  left: trackStart,
                  width: (trackEnd - trackStart).clamp(0.0, totalWidth),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: trackBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                // Filled progress line
                Positioned(
                  top: 11,
                  left: trackStart,
                  width: fillWidth,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: trackFill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                if (isFiveStage) ...[
                  // 5-Stage Icons & Symmetrical Labels (No circular container)
                  ...List.generate(5, (idx) {
                    final isDoneOrActive = idx <= activeIdx;
                    final isCurrent = idx == activeIdx;
                    final isArrivedNode = widget.isDriverArrived && idx == 2;
                    final nodeX = trackStart + (trackEnd - trackStart) * (idx / 4.0);

                    return Positioned(
                      top: 1,
                      left: (nodeX - 24).clamp(0.0, totalWidth - 48),
                      width: 48,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isArrivedNode
                                  ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                                  : (isDoneOrActive
                                      ? (isDark ? const Color(0xFF2B1214) : const Color(0xFFFFF1F2))
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isArrivedNode
                                    ? const Color(0xFF10B981)
                                    : (isDoneOrActive
                                        ? GageTheme.primary.withValues(alpha: 0.35)
                                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                                width: isArrivedNode ? 1.5 : 1,
                              ),
                            ),
                            child: Icon(
                              nodeIcons[idx],
                              size: 14,
                              color: isArrivedNode
                                  ? const Color(0xFF059669)
                                  : (isDoneOrActive
                                      ? GageTheme.primary
                                      : (isDark ? Colors.white30 : Colors.grey.shade400)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stages[idx],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : (isDoneOrActive ? FontWeight.w600 : FontWeight.w400),
                              color: isArrivedNode
                                  ? const Color(0xFF059669)
                                  : (isCurrent
                                      ? GageTheme.primary
                                      : (isDoneOrActive
                                          ? (isDark ? Colors.white70 : const Color(0xFF334155))
                                          : (isDark ? Colors.white30 : Colors.grey.shade400))),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  // 1-Stage Compact Mode (Outer Order Card)
                  if (widget.isDriverArrived) ...[
                    Positioned(
                      top: 1,
                      right: 0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft pulsing beacon ring
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF10B981).withValues(alpha: 0.15 + (1 - t) * 0.35),
                            ),
                          ),
                          // Arrived outlet icon container
                          Container(
                            width: 19,
                            height: 19,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              _outletIcon,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                          // Mini arrived check dot badge
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 7,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Positioned(
                      top: 2,
                      right: 0,
                      child: Icon(
                        widget.isSearchingDriver
                            ? Icons.search_rounded
                            : Icons.location_on_rounded,
                        size: 20,
                        color: GageTheme.primary,
                      ),
                    ),
                  ],
                ],
                // Moving Icon: Red G-Rider
                Positioned(
                  top: 2,
                  left: riderCenterX - (riderWidth / 2),
                  child: CustomPaint(
                    size: const Size(riderWidth, riderHeight),
                    painter: _TopDownCourierRiderPainter(
                      accentColor: GageTheme.primary,
                      isSearching: false,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (!isFiveStage) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: labelWidget),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            height: 26,
            child: trackWidget,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        labelWidget,
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: trackWidget,
        ),
      ],
    );
  }
}

/// CustomPainter drawing a top-down isometric motorbike courier with delivery box,
/// matching the ShopeeFood / Shopee Partner live delivery track aesthetic.
class _TopDownCourierRiderPainter extends CustomPainter {
  final Color accentColor;
  final bool isSearching;

  _TopDownCourierRiderPainter({
    required this.accentColor,
    required this.isSearching,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cy = h / 2;

    // Subtle shadow under scooter
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, cy + 2), width: w * 0.85, height: h * 0.55),
      shadowPaint,
    );

    // Front wheel
    final wheelPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.84, cy), width: 7, height: 4),
        const Radius.circular(2),
      ),
      wheelPaint,
    );

    // Scooter chassis / fairing (GAGE Red)
    final bodyPaint = Paint()..color = accentColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.58, cy), width: 17, height: 10),
        const Radius.circular(5),
      ),
      bodyPaint,
    );

    // Handlebars
    final barPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.72, cy - 8), Offset(w * 0.72, cy + 8), barPaint);

    // Rider arms (jacket white/light)
    final armPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.50, cy - 6), Offset(w * 0.70, cy - 6.5), armPaint);
    canvas.drawLine(Offset(w * 0.50, cy + 6), Offset(w * 0.70, cy + 6.5), armPaint);

    // Rear delivery box (GAGE primary red)
    final boxRect = Rect.fromCenter(center: Offset(w * 0.24, cy), width: 11, height: 12);
    final boxPaint = Paint()..color = accentColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(2.5)),
      boxPaint,
    );

    // Crisp white letter 'G' inside delivery box
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        boxRect.center.dx - (textPainter.width / 2),
        boxRect.center.dy - (textPainter.height / 2),
      ),
    );

    // Rider helmet (dark red accent)
    final helmetPaint = Paint()..color = const Color(0xFFB91C1C);
    canvas.drawCircle(Offset(w * 0.50, cy), 5.2, helmetPaint);
    // Helmet visor
    final visorPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.51, cy), radius: 4.2),
      -0.8,
      1.6,
      false,
      visorPaint..style = PaintingStyle.stroke..strokeWidth = 1.8,
    );
  }

  @override
  bool shouldRepaint(covariant _TopDownCourierRiderPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor || oldDelegate.isSearching != isSearching;
  }
}
