import 'package:flutter/material.dart';

/// Callback signature invoked when an editable banner is tapped in Admin Live Preview.
typedef BannerEditHandler = Future<void> Function({
  required BuildContext context,
  required String screenTarget,
  String? bannerId,
  required String title,
  required String subtitle,
  required String badge,
  required String imageUrl,
  String actionUrl,
  double aspectRatio,
  VoidCallback? onSaved,
});

/// Scope marking whether the current widget tree runs inside Admin Live Preview edit mode.
class LiveAppEditScope extends InheritedWidget {
  final bool isEditMode;

  /// Global flag so live edit mode remains active across pushed routes.
  static bool globalEditMode = false;

  /// Runtime handler registered by Admin live preview to open the banner editor sheet.
  static BannerEditHandler? globalBannerEditor;

  const LiveAppEditScope({
    super.key,
    this.isEditMode = true,
    required super.child,
  });

  static LiveAppEditScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LiveAppEditScope>();
  }

  static bool isEditModeActive(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LiveAppEditScope>();
    return (scope != null && scope.isEditMode) || globalEditMode;
  }

  static Future<void> triggerEdit({
    required BuildContext context,
    required String screenTarget,
    String? bannerId,
    required String title,
    required String subtitle,
    required String badge,
    required String imageUrl,
    String actionUrl = '',
    double aspectRatio = 16 / 9,
    VoidCallback? onSaved,
  }) async {
    final handler = globalBannerEditor;
    if (handler != null) {
      await handler(
        context: context,
        screenTarget: screenTarget,
        bannerId: bannerId,
        title: title,
        subtitle: subtitle,
        badge: badge,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        aspectRatio: aspectRatio,
        onSaved: onSaved,
      );
    }
  }

  @override
  bool updateShouldNotify(LiveAppEditScope oldWidget) =>
      isEditMode != oldWidget.isEditMode;
}
