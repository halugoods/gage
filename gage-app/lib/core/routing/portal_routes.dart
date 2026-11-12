/// Centralized typed route constants for every portal in the GAGE ecosystem.
abstract final class CustomerRoutes {
  static const String root = '/';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String promo = '/promo';
  static const String video = '/video';
  static const String profile = '/profile';
  static const String checkout = '/checkout';
}

abstract final class MerchantRoutes {
  static const String root = '/merchant';
  static const String orders = '/merchant/orders';
  static const String menu = '/merchant/menu';
  static const String finance = '/merchant/finance';
  static const String chat = '/merchant/chat';
  static const String profile = '/merchant/profile';
}

abstract final class DriverRoutes {
  static const String root = '/driver';
  static const String radar = '/driver/radar';
  static const String activity = '/driver/activity';
  static const String earnings = '/driver/earnings';
  static const String chat = '/driver/chat';
  static const String account = '/driver/account';
}

abstract final class AdminRoutes {
  static const String root = '/admin';
  static const String dispatch = '/admin/dispatch';
  static const String whatsapp = '/admin/whatsapp';
  static const String curation = '/admin/curation';
  static const String settings = '/admin/settings';
  static const String preview = '/admin/preview';
}
