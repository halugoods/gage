import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/routing/portal_routes.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/features/admin/presentation/admin_order_dispatch_screen.dart';
import 'package:gage_app/features/admin/presentation/admin_root_screen.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';
import 'package:gage_app/features/driver/presentation/driver_root_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_screen.dart';
import 'package:gage_app/features/driver/presentation/widgets/driver_bottom_nav_bar.dart';
import 'package:gage_app/features/home/presentation/promo_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_finance_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_root_screen.dart';
import 'package:gage_app/features/profile/presentation/widgets/gage_account_switcher_sheet.dart';
import 'package:gage_app/main.dart';
import 'package:gage_app/main_admin.dart';
import 'package:gage_app/main_driver.dart';
import 'package:gage_app/main_merchant.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/driver_order_provider.dart';
import 'package:gage_app/providers/driver_wallet_provider.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/live_app_edit_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LiveAppEditScope.globalEditMode = false;
    LiveAppEditScope.globalBannerEditor = null;
  });

  tearDown(() {
    LiveAppEditScope.globalEditMode = false;
    LiveAppEditScope.globalBannerEditor = null;
  });

  group('1. Portal Route Constants Contract', () {
    test('all Customer, Merchant, Driver, and Admin route constants match specification', () {
      expect(CustomerRoutes.root, equals('/'));
      expect(CustomerRoutes.home, equals('/home'));
      expect(CustomerRoutes.orders, equals('/orders'));
      expect(CustomerRoutes.promo, equals('/promo'));
      expect(CustomerRoutes.video, equals('/video'));
      expect(CustomerRoutes.profile, equals('/profile'));
      expect(CustomerRoutes.checkout, equals('/checkout'));

      expect(MerchantRoutes.root, equals('/merchant'));
      expect(MerchantRoutes.orders, equals('/merchant/orders'));
      expect(MerchantRoutes.menu, equals('/merchant/menu'));
      expect(MerchantRoutes.finance, equals('/merchant/finance'));
      expect(MerchantRoutes.chat, equals('/merchant/chat'));
      expect(MerchantRoutes.profile, equals('/merchant/profile'));

      expect(DriverRoutes.root, equals('/driver'));
      expect(DriverRoutes.radar, equals('/driver/radar'));
      expect(DriverRoutes.activity, equals('/driver/activity'));
      expect(DriverRoutes.earnings, equals('/driver/earnings'));
      expect(DriverRoutes.chat, equals('/driver/chat'));
      expect(DriverRoutes.account, equals('/driver/account'));

      expect(AdminRoutes.root, equals('/admin'));
      expect(AdminRoutes.dispatch, equals('/admin/dispatch'));
      expect(AdminRoutes.whatsapp, equals('/admin/whatsapp'));
      expect(AdminRoutes.curation, equals('/admin/curation'));
      expect(AdminRoutes.settings, equals('/admin/settings'));
      expect(AdminRoutes.preview, equals('/admin/preview'));
    });

    test('all named portal route strings are unique and well-formed', () {
      const allNamedRoutes = [
        CustomerRoutes.home,
        CustomerRoutes.orders,
        CustomerRoutes.promo,
        CustomerRoutes.video,
        CustomerRoutes.profile,
        CustomerRoutes.checkout,
        MerchantRoutes.root,
        MerchantRoutes.orders,
        MerchantRoutes.menu,
        MerchantRoutes.finance,
        MerchantRoutes.chat,
        MerchantRoutes.profile,
        DriverRoutes.root,
        DriverRoutes.radar,
        DriverRoutes.activity,
        DriverRoutes.earnings,
        DriverRoutes.chat,
        DriverRoutes.account,
        AdminRoutes.root,
        AdminRoutes.dispatch,
        AdminRoutes.whatsapp,
        AdminRoutes.curation,
        AdminRoutes.settings,
        AdminRoutes.preview,
      ];

      expect(allNamedRoutes.toSet().length, equals(allNamedRoutes.length));
      for (final route in allNamedRoutes) {
        expect(route.startsWith('/'), isTrue);
        expect(route, isNot(equals('/')));
      }
    });
  });

  group('2. GageApp Named Routes & Guarded Cross-Portal Navigation', () {
    testWidgets('GageApp registers customer and guarded portal routes without "/" conflict', (tester) async {
      await tester.pumpWidget(const GageApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.home, isA<AuthGate>());
      expect(materialApp.routes, isNotNull);

      final routes = materialApp.routes!;
      expect(routes.containsKey(CustomerRoutes.root), isFalse);
      expect(routes.containsKey(CustomerRoutes.home), isTrue);
      expect(routes.containsKey(CustomerRoutes.orders), isTrue);
      expect(routes.containsKey(CustomerRoutes.promo), isTrue);
      expect(routes.containsKey(CustomerRoutes.video), isTrue);
      expect(routes.containsKey(CustomerRoutes.profile), isTrue);
      expect(routes.containsKey(CustomerRoutes.checkout), isTrue);
      expect(routes.containsKey(MerchantRoutes.root), isTrue);
      expect(routes.containsKey(DriverRoutes.root), isTrue);
      expect(routes.containsKey(AdminRoutes.root), isTrue);
    });

    testWidgets('GageApp navigates cleanly to /promo, /merchant, /driver (guarded), and /admin', (tester) async {
      await tester.pumpWidget(const GageApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      NavigatorState navigator() => Navigator.of(tester.element(find.byType(AuthGate)));

      // Navigate to Customer Promo route
      navigator().pushNamed(CustomerRoutes.promo);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PromoScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      navigator().pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Navigate to Merchant Portal root route
      navigator().pushNamed(MerchantRoutes.root);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(MerchantRootScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      navigator().pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Navigate to Driver Portal root route (must have DriverOrderProvider & DriverWalletProvider via guard)
      navigator().pushNamed(DriverRoutes.root);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(DriverRootScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      navigator().pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Navigate to Admin Portal root route
      navigator().pushNamed(AdminRoutes.root);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AdminRootScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('3. Standalone Portal Entrypoint Route Registration', () {
    testWidgets('GageMerchantApp registers all MerchantRoutes and opens MerchantFinanceScreen', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MerchantOrderProvider()),
            ChangeNotifierProvider(create: (_) => InAppChatProvider()),
            ChangeNotifierProvider.value(value: BannerManagerService.instance),
          ],
          child: const GageMerchantApp(),
        ),
      );
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final routes = materialApp.routes!;
      expect(routes.containsKey('/'), isFalse);
      expect(routes.keys, containsAll([
        MerchantRoutes.root,
        MerchantRoutes.orders,
        MerchantRoutes.menu,
        MerchantRoutes.finance,
        MerchantRoutes.chat,
        MerchantRoutes.profile,
      ]));

      Navigator.of(tester.element(find.byType(MerchantRootScreen))).pushNamed(MerchantRoutes.finance);
      await tester.pumpAndSettle();
      expect(find.byType(MerchantFinanceScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GageDriverApp registers all DriverRoutes and renders DriverBottomNavBar on standalone /driver/radar', (tester) async {
      await tester.pumpWidget(const GageDriverApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final routes = materialApp.routes!;
      expect(routes.containsKey('/'), isFalse);
      expect(routes.keys, containsAll([
        DriverRoutes.root,
        DriverRoutes.radar,
        DriverRoutes.activity,
        DriverRoutes.earnings,
        DriverRoutes.chat,
        DriverRoutes.account,
      ]));

      Navigator.of(tester.element(find.byType(DriverRootScreen))).pushNamed(DriverRoutes.radar);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DriverScreen), findsWidgets);
      final standaloneDriver = tester.widgetList<DriverScreen>(find.byType(DriverScreen)).last;
      expect(standaloneDriver.showBottomNav, isTrue);
      expect(find.byType(DriverBottomNavBar), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('GageAdminApp registers all AdminRoutes and opens AdminOrderDispatchScreen', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => WalletProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(create: (_) => MultiMerchantCartService()),
            ChangeNotifierProvider(create: (_) => InAppChatProvider()),
            ChangeNotifierProvider(create: (_) => DriverOrderProvider()),
            ChangeNotifierProvider(create: (_) => DriverWalletProvider()),
            ChangeNotifierProvider.value(value: BannerManagerService.instance),
          ],
          child: const GageAdminApp(),
        ),
      );
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final routes = materialApp.routes!;
      expect(routes.containsKey('/'), isFalse);
      expect(routes.keys, containsAll([
        AdminRoutes.root,
        AdminRoutes.dispatch,
        AdminRoutes.whatsapp,
        AdminRoutes.curation,
        AdminRoutes.settings,
        AdminRoutes.preview,
      ]));

      Navigator.of(tester.element(find.byType(AdminRootScreen))).pushNamed(AdminRoutes.dispatch);
      await tester.pumpAndSettle();
      expect(find.byType(AdminOrderDispatchScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('4. Customer Flow Sanitization & Decoupled Live Edit Scope', () {
    testWidgets('GageAccountSwitcherSheet excludes merchant demo switcher leak', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const MaterialApp(
            home: Scaffold(
              body: GageAccountSwitcherSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mitra Merchant Dimsum Sewu'), findsNothing);
      expect(find.text('Akun Terdaftar Lainnya'), findsNothing);
      expect(find.textContaining('mitra.dimsum@gage.id'), findsNothing);
      expect(find.text('Tambah atau Masuk Akun Baru'), findsOneWidget);
    });

    testWidgets('LiveAppEditScope tracks inherited/global edit mode and delegates triggerEdit', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              capturedContext = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(LiveAppEditScope.isEditModeActive(capturedContext), isFalse);

      // Global mode activates edit detection
      LiveAppEditScope.globalEditMode = true;
      expect(LiveAppEditScope.isEditModeActive(capturedContext), isTrue);
      LiveAppEditScope.globalEditMode = false;

      // Inherited scope activates edit detection
      await tester.pumpWidget(
        MaterialApp(
          home: LiveAppEditScope(
            isEditMode: true,
            child: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(LiveAppEditScope.isEditModeActive(capturedContext), isTrue);

      // No-op when globalBannerEditor is null
      await LiveAppEditScope.triggerEdit(
        context: capturedContext,
        screenTarget: 'customer_home_hero',
        title: 'Hero',
        subtitle: 'Sub',
        badge: 'Promo',
        imageUrl: 'assets/images/banner_home.png',
      );

      String? receivedTarget;
      String? receivedTitle;
      LiveAppEditScope.globalBannerEditor = ({
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
        receivedTarget = screenTarget;
        receivedTitle = title;
      };

      await LiveAppEditScope.triggerEdit(
        context: capturedContext,
        screenTarget: 'customer_home_hero',
        title: 'Banner Updated',
        subtitle: 'Sub',
        badge: 'Promo',
        imageUrl: 'assets/images/banner_home.png',
      );

      expect(receivedTarget, equals('customer_home_hero'));
      expect(receivedTitle, equals('Banner Updated'));
    });
  });

  group('5. Static Architecture & Hygiene Invariants', () {
    Directory resolveAppDir() {
      if (Directory('lib').existsSync()) return Directory.current;
      final sub = Directory('gage-app');
      if (sub.existsSync() && Directory('${sub.path}/lib').existsSync()) return sub;
      throw StateError('Could not locate gage-app root from ${Directory.current.path}');
    }

    test('duplicate voucher card file is deleted and customer/shared contain no admin imports', () {
      final appDir = resolveAppDir();

      final duplicateCard = File('${appDir.path}/lib/features/voucher/presentation/widgets/gage_ticket_voucher_card.dart');
      expect(duplicateCard.existsSync(), isFalse);

      for (final folderName in ['lib/features/home', 'lib/shared']) {
        final dir = Directory('${appDir.path}/$folderName');
        expect(dir.existsSync(), isTrue);
        for (final entity in dir.listSync(recursive: true)) {
          if (entity is File && entity.path.endsWith('.dart')) {
            final content = entity.readAsStringSync();
            expect(
              content.contains('features/admin/'),
              isFalse,
              reason: '${entity.path} must not import features/admin/',
            );
          }
        }
      }
    });

    test('all R1-R4 modified and created files contain zero em dashes', () {
      final appDir = resolveAppDir();
      const targetFiles = [
        'lib/core/routing/portal_routes.dart',
        'lib/shared/widgets/live_app_edit_scope.dart',
        'lib/shared/widgets/gage_service_header.dart',
        'lib/shared/widgets/gage_standalone_banner.dart',
        'lib/shared/widgets/gage_bottom_nav_bar.dart',
        'lib/features/home/presentation/promo_screen.dart',
        'lib/features/home/presentation/widgets/gage_home_header.dart',
        'lib/features/home/presentation/widgets/promo_carousel.dart',
        'lib/features/home/presentation/widgets/gage_ticket_voucher_card.dart',
        'lib/features/checkout/presentation/checkout_screen.dart',
        'lib/features/voucher/presentation/voucher_selection_screen.dart',
        'lib/features/profile/presentation/widgets/gage_account_switcher_sheet.dart',
        'lib/features/admin/presentation/portal_interactive_preview_screen.dart',
        'lib/features/admin/presentation/widgets/in_place_banner_editor_sheet.dart',
        'lib/main.dart',
        'lib/main_merchant.dart',
        'lib/main_driver.dart',
        'lib/main_admin.dart',
        'test/promo_screen_accordion_test.dart',
        'test/portal_routes_test.dart',
      ];

      for (final rel in targetFiles) {
        final file = File('${appDir.path}/$rel');
        expect(file.existsSync(), isTrue, reason: 'Missing file: $rel');
        final content = file.readAsStringSync();
        expect(content.contains('\u2014'), isFalse, reason: 'Em dash found in $rel');
      }
    });
  });
}
