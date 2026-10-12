import 'package:flutter/material.dart';
import 'package:gage_app/features/order/presentation/order_tracking_screen.dart';

/// Legacy Wrapper: Meneruskan secara seamless ke OrderTrackingScreen
/// Mengikuti Clean-Room Flutter code & $0 Infra GAGE Pracimantoro.
class ActiveOrderTrackerScreen extends StatelessWidget {
  final String orderId;

  const ActiveOrderTrackerScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return OrderTrackingScreen(orderId: orderId);
  }
}
