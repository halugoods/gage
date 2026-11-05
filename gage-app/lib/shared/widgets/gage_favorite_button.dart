import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Tombol Favorit Instan Reusable untuk Merchant Card & Slider Card
/// Menyimpan preferensi ke SharedPreferences ('fav_resto_$merchantId')
/// Memberikan haptic feedback dan GageToast instan tanpa harus membuka resto.
class GageFavoriteMerchantButton extends StatefulWidget {
  final String merchantId;
  final String merchantName;
  final bool? initialFavorite;
  final VoidCallback? onFavoriteChanged;
  final double size;
  final bool withBackground;

  const GageFavoriteMerchantButton({
    super.key,
    required this.merchantId,
    required this.merchantName,
    this.initialFavorite,
    this.onFavoriteChanged,
    this.size = 20,
    this.withBackground = false,
  });

  @override
  State<GageFavoriteMerchantButton> createState() => _GageFavoriteMerchantButtonState();
}

class _GageFavoriteMerchantButtonState extends State<GageFavoriteMerchantButton> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialFavorite ?? false;
    _loadStatus();
  }

  @override
  void didUpdateWidget(covariant GageFavoriteMerchantButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.merchantId != oldWidget.merchantId) {
      _loadStatus();
    } else if (widget.initialFavorite != null && widget.initialFavorite != _isFavorite) {
      setState(() => _isFavorite = widget.initialFavorite!);
    }
  }

  Future<void> _loadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool('fav_resto_${widget.merchantId}') ?? false;
      if (mounted) {
        setState(() => _isFavorite = val);
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.lightImpact();
    final newVal = !_isFavorite;
    setState(() => _isFavorite = newVal);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fav_resto_${widget.merchantId}', newVal);
    } catch (_) {}

    if (mounted) {
      GageToast.show(
        context,
        newVal
            ? '${widget.merchantName} ditambahkan ke Favorit ❤️'
            : '${widget.merchantName} dihapus dari Favorit',
        type: newVal ? GageToastType.success : GageToastType.info,
      );
    }

    widget.onFavoriteChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget iconWidget = Icon(
      _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      size: widget.size,
      color: _isFavorite
          ? const Color(0xFFEF4444)
          : (widget.withBackground
              ? Colors.white
              : (isDark ? Colors.white60 : Colors.black45)),
    );

    if (widget.withBackground) {
      return GestureDetector(
        onTap: _toggleFavorite,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 0.8),
          ),
          child: iconWidget,
        ),
      );
    }

    return InkWell(
      onTap: _toggleFavorite,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: iconWidget,
      ),
    );
  }
}
