import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// Widget avatar aman lintas sumber (HTTP URL, Flutter asset, file lokal, atau fallback inisial).
class GageAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackName;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const GageAvatar({
    super.key,
    required this.imageUrl,
    required this.fallbackName,
    this.radius = 22,
    this.backgroundColor,
    this.foregroundColor,
  });

  String get _initial {
    final cleaned = fallbackName.trim();
    if (cleaned.isEmpty) return 'G';
    return cleaned.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? GageTheme.primary.withValues(alpha: 0.14);
    final fg = foregroundColor ?? GageTheme.primary;
    final src = imageUrl?.trim() ?? '';

    Widget fallbackWidget() => Center(
          child: Text(
            _initial,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: radius * 0.78,
            ),
          ),
        );

    Widget content;
    if (src.isEmpty) {
      content = fallbackWidget();
    } else if (src.startsWith('http://') || src.startsWith('https://')) {
      content = Image.network(
        src,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorBuilder: (_, __, ___) => fallbackWidget(),
      );
    } else if (src.startsWith('assets/')) {
      content = Image.asset(
        src,
        fit: BoxFit.cover,
        width: radius * 2,
        height: radius * 2,
        errorBuilder: (_, __, ___) => fallbackWidget(),
      );
    } else if (!kIsWeb) {
      final filePath = src.startsWith('file://') ? Uri.parse(src).toFilePath() : src;
      final file = File(filePath);
      if (file.existsSync()) {
        content = Image.file(
          file,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          errorBuilder: (_, __, ___) => fallbackWidget(),
        );
      } else {
        content = fallbackWidget();
      }
    } else {
      content = fallbackWidget();
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
