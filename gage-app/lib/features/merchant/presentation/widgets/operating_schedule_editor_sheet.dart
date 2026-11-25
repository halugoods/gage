import 'package:flutter/material.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/features/merchant/presentation/settings/merchant_operating_schedule_screen.dart';

/// Opens the Full Screen operating schedule editor for merchants to configure
/// dynamic Mon-Sun hours or unified daily operating hours.
Future<MerchantOperatingSchedule?> showOperatingScheduleEditorSheet({
  required BuildContext context,
  required MerchantOperatingSchedule initialSchedule,
  String? merchantId,
}) {
  return Navigator.of(context).push<MerchantOperatingSchedule>(
    MaterialPageRoute(
      builder: (_) => MerchantOperatingScheduleScreen(
        merchantId: merchantId ?? MerchantStorefrontService.defaultPortalMerchantId,
        initialSchedule: initialSchedule,
      ),
    ),
  );
}
