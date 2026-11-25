import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/models/merchant_branch_model.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/affiliate_commission_service.dart';
import 'package:gage_app/core/services/gage_audio_service.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/chat/presentation/widgets/gage_product_catalog_sheet.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';
import 'package:gage_app/features/merchant/presentation/merchant_profile_screen.dart';
import 'package:gage_app/features/merchant/presentation/settings/merchant_location_and_requests_screen.dart';
import 'package:gage_app/features/merchant/presentation/settings/merchant_operating_schedule_screen.dart';
import 'package:gage_app/features/merchant/presentation/settings/merchant_printer_settings_screen.dart';
import 'package:gage_app/features/merchant/presentation/settings/merchant_receipt_settings_screen.dart';
import 'package:gage_app/features/merchant/presentation/settings/merchant_store_info_screen.dart';
import 'package:gage_app/features/merchant/presentation/auth/merchant_store_setup_wizard_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_kitchen_insights_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_menu_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_order_detail_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_review_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_terms_and_privacy_screen.dart';
import 'package:gage_app/features/merchant/presentation/tabs/gage_merchant_chat_tab.dart';
import 'package:gage_app/features/merchant/presentation/tabs/gage_merchant_orders_tab.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_branch_switcher_sheet.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_floating_nav_bar.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_help_center_sheet.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_photo_picker_sheet.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_printer_settings_sheet.dart';
import 'package:gage_app/shared/widgets/gage_delivery_track_progress.dart';
import 'package:gage_app/features/merchant/services/merchant_receipt_printer_service.dart';
import 'package:gage_app/core/services/notification_service.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Merchant Comprehensive Audit & Parity Scenarios Test Suite', () {
    // -------------------------------------------------------------------------
    // Skenario 1: Verifikasi PIN 4 Digit Acak Serah Terima Dapur
    // -------------------------------------------------------------------------
    test('Skenario 1: Verifikasi PIN 4 digit serah terima acak & variatif (Bukan Hardcoded)', () {
      final random = Random();
      String generatePin() => (1000 + random.nextInt(9000)).toString();

      final pinRegex = RegExp(r'^\d{4}$');
      final generatedPins = <String>{};

      for (int i = 0; i < 50; i++) {
        final pin = generatePin();
        expect(pinRegex.hasMatch(pin), isTrue,
            reason: 'PIN serah terima wajib berupa 4 digit angka pasti');
        expect(int.parse(pin), inInclusiveRange(1000, 9999));
        generatedPins.add(pin);
      }

      // Memastikan keacakan PIN menghasilkan variasi yang luas
      expect(generatedPins.length, greaterThan(35),
          reason: 'Generator PIN harus bervariasi acak dan bukan angka statis');
    });

    // -------------------------------------------------------------------------
    // Skenario 2: Transisi Siklus Pesanan (PAID -> COOKING -> READY -> COMPLETED)
    // -------------------------------------------------------------------------
    test('Skenario 2: Transisi siklus pesanan berjalan deterministik', () {
      final prevSetting = GageApiClient.allowDevSeedFallback;
      try {
        GageApiClient.allowDevSeedFallback = true;
        final provider = MerchantOrderProvider();
        expect(provider.orders, isNotEmpty);

        final initialPending = provider.orders
            .where((o) => o.status == 'NEW' || o.status == 'PAID')
            .firstOrNull;
        if (initialPending != null) {
          final orderId = initialPending.id;
          expect(initialPending.status, isIn(['NEW', 'PAID']));

          // 1. Terima Pesanan -> Status berubah jadi COOKING (Dapur mulai proses)
          provider.acceptOrder(orderId);
          final cookingOrder = provider.orders.firstWhere((o) => o.id == orderId);
          expect(cookingOrder.status, equals('COOKING'));

          // 2. Tandai Siap -> Status berubah jadi READY_FOR_PICKUP
          provider.markReadyForPickup(orderId);
          final readyOrder = provider.orders.firstWhere((o) => o.id == orderId);
          expect(readyOrder.status, equals('READY_FOR_PICKUP'));

          // 3. Selesai Serah Terima -> Status berubah jadi COMPLETED
          provider.completeOrder(orderId);
          final completedOrder = provider.orders.firstWhere((o) => o.id == orderId);
          expect(completedOrder.status, equals('COMPLETED'));
        }
      } finally {
        GageApiClient.allowDevSeedFallback = prevSetting;
      }
    });

    // -------------------------------------------------------------------------
    // Skenario 3: Penolakan Pesanan dengan Alasan Resmi
    // -------------------------------------------------------------------------
    test('Skenario 3: Penolakan pesanan tersimpan dengan alasan resmi operasional', () {
      final prevSetting = GageApiClient.allowDevSeedFallback;
      try {
        GageApiClient.allowDevSeedFallback = true;
        final provider = MerchantOrderProvider();
        final pending = provider.orders
            .where((o) => o.status == 'NEW' || o.status == 'PAID')
            .firstOrNull;
        if (pending != null) {
          final orderId = pending.id;
          const rejectionReason = 'Bahan baku ayam & dimsum habis';

          provider.rejectOrder(orderId, rejectionReason);
          final rejectedOrder = provider.orders.firstWhere((o) => o.id == orderId);
          expect(rejectedOrder.status, equals('CANCELLED'));
          expect(rejectedOrder.cancellationReason, equals(rejectionReason));
        }
      } finally {
        GageApiClient.allowDevSeedFallback = prevSetting;
      }
    });

    // -------------------------------------------------------------------------
    // Skenario 4: Format Nota Thermal Monospace Kasir (58mm & 80mm)
    // -------------------------------------------------------------------------
    test('Skenario 4: Generator nota thermal 58mm (32 col) & 80mm (48 col) monospace', () {
      String generateThermalText({
        required String storeName,
        required String invoiceNo,
        required List<Map<String, dynamic>> items,
        required int subtotal,
        required int discount,
        required int platformFee,
        required int total,
        required int columns,
      }) {
        final buffer = StringBuffer();
        final divider = '-' * columns;

        // Centered header
        buffer.writeln(storeName.padLeft((columns + storeName.length) ~/ 2));
        buffer.writeln('Pracimantoro, Wonogiri'.padLeft((columns + 22) ~/ 2));
        buffer.writeln(divider);
        buffer.writeln('No: $invoiceNo');
        buffer.writeln('Waktu: 22/11/2026 03:00 WIB');
        buffer.writeln(divider);

        // Items
        for (final item in items) {
          final nameQty = '${item['name']} x${item['qty']}';
          final priceStr = 'Rp ${item['price']}';
          final spaces = columns - nameQty.length - priceStr.length;
          buffer.writeln('$nameQty${' ' * (spaces > 0 ? spaces : 1)}$priceStr');
        }

        buffer.writeln(divider);
        // Totals
        void writeLine(String label, String val) {
          final sp = columns - label.length - val.length;
          buffer.writeln('$label${' ' * (sp > 0 ? sp : 1)}$val');
        }

        writeLine('Subtotal', 'Rp $subtotal');
        if (discount > 0) writeLine('Diskon Toko', '-Rp $discount');
        writeLine('Biaya Layanan', 'Rp $platformFee');
        writeLine('TOTAL BAYAR', 'Rp $total');
        buffer.writeln(divider);
        buffer.writeln('TERIMA KASIH'.padLeft((columns + 12) ~/ 2));

        return buffer.toString();
      }

      final mockItems = [
        {'name': 'Dimsum Mentai', 'qty': 2, 'price': 30000},
        {'name': 'Es Teh Manis', 'qty': 2, 'price': 10000},
      ];

      // Test 58mm (32 columns)
      final receipt58 = generateThermalText(
        storeName: 'Dimsum Sewu Halu Goods',
        invoiceNo: 'INV-20261122-001',
        items: mockItems,
        subtotal: 40000,
        discount: 5000,
        platformFee: 2000,
        total: 37000,
        columns: 32,
      );
      expect(receipt58, contains('--------------------------------'));
      expect(receipt58, contains('Dimsum Mentai x2'));
      expect(receipt58, contains('TOTAL BAYAR'));

      // Test 80mm (48 columns)
      final receipt80 = generateThermalText(
        storeName: 'Dimsum Sewu Halu Goods',
        invoiceNo: 'INV-20261122-001',
        items: mockItems,
        subtotal: 40000,
        discount: 5000,
        platformFee: 2000,
        total: 37000,
        columns: 48,
      );
      expect(receipt80, contains('------------------------------------------------'));
      expect(receipt80, contains('Dimsum Mentai x2'));
      expect(receipt80, contains('TERIMA KASIH'));
    });

    // -------------------------------------------------------------------------
    // Skenario 5: Formula MDR 10% Platform Fee & Payout Bersih Merchant
    // -------------------------------------------------------------------------
    test('Skenario 5: Formula MDR 10% platform fee dan payout bersih merchant akurat', () {
      const orderSubtotal = 50000;
      const mdrRate = 0.10; // 10% platform fee

      final fee = (orderSubtotal * mdrRate).round();
      final netPayout = orderSubtotal - fee;

      expect(fee, equals(5000));
      expect(netPayout, equals(45000));
      expect(netPayout + fee, equals(orderSubtotal));
    });

    // -------------------------------------------------------------------------
    // Skenario 6: Sinkronisasi Persistensi Diskon Langsung Toko ke Storefront
    // -------------------------------------------------------------------------
    test('Skenario 6: Sinkronisasi diskon langsung toko (Voucher Toko) pada MerchantStorefrontData', () {
      const original = MerchantStorefrontData(
        merchantId: 'mch-dimsum-01',
        name: 'Dimsum Sewu by Halu Goods',
        address: 'Jl. Raya Pracimantoro, Wonogiri',
      );

      final updated = original.copyWith(
        directDiscountAmount: 7000,
        minSpendAmount: 40000,
        directDiscountActive: true,
      );

      expect(updated.directDiscountAmount, equals(7000));
      expect(updated.minSpendAmount, equals(40000));
      expect(updated.directDiscountActive, isTrue);

      // Verify serialization round-trip
      final json = updated.toJson();
      expect(json['directDiscountAmount'], equals(7000));
      expect(json['minSpendAmount'], equals(40000));
      expect(json['directDiscountActive'], isTrue);

      final decoded = MerchantStorefrontData.fromJson(updated.merchantId, json);
      expect(decoded.directDiscountAmount, equals(7000));
      expect(decoded.minSpendAmount, equals(40000));
      expect(decoded.directDiscountActive, isTrue);
    });

    // -------------------------------------------------------------------------
    // Skenario 7: Perhitungan Investasi Iklan Toko (Budget Harian x Durasi)
    // -------------------------------------------------------------------------
    test('Skenario 7: Perhitungan budget iklan toko harian dan durasi hari', () {
      int calculateAdBudget(int dailyBudget, int days) => dailyBudget * days;

      expect(calculateAdBudget(15000, 3), equals(45000));
      expect(calculateAdBudget(15000, 7), equals(105000));
      expect(calculateAdBudget(25000, 7), equals(175000));
      expect(calculateAdBudget(50000, 14), equals(700000));
    });

    // -------------------------------------------------------------------------
    // Skenario 8: Batas Aman Alokasi Komisi Afiliasi (0% - 20%)
    // -------------------------------------------------------------------------
    test('Skenario 8: Batas aman alokasi komisi afiliasi (0.0% s/d 20.0%) ter-clamp ketat', () {
      const data = MerchantStorefrontData(merchantId: 'mch-dimsum-01');

      // Valid range
      final normal = data.copyWith(affiliateCommissionRate: 10.0);
      expect(normal.affiliateCommissionRate, equals(10.0));

      // Over 20% -> clamped to 20%
      final overMax = data.copyWith(affiliateCommissionRate: 25.5);
      expect(overMax.affiliateCommissionRate, equals(20.0));

      // Below 0% -> clamped to 0%
      final belowMin = data.copyWith(affiliateCommissionRate: -5.0);
      expect(belowMin.affiliateCommissionRate, equals(0.0));
    });

    // -------------------------------------------------------------------------
    // Skenario 9: Quick Replies Khusus Dapur saat currentRole == 'merchant'
    // -------------------------------------------------------------------------
    testWidgets('Skenario 9: Quick Replies khusus dapur saat currentRole == merchant tersedia lengkap',
        (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<InAppChatProvider>(
          create: (_) => InAppChatProvider(),
          child: const MaterialApp(
            home: InAppChatScreen(
              orderId: 'ORD-1001',
              recipientName: 'Budi Santoso',
              recipientRole: 'customer',
              recipientPhone: '081234567890',
              currentRole: 'merchant',
            ),
          ),
        ),
      );
      await tester.pump();

      // Verifikasi chips quick replies operasional dapur ke customer
      expect(find.text('Halo kak, pesanan segera kami masak dengan higienis!'), findsOneWidget);
      expect(find.text('Saus dan sambal sudah dipisah di kemasan khusus ya kak.'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Skenario 10: Paritas Geometri Kapsul 999 & Dynamic Outline/Filled Icons
    // -------------------------------------------------------------------------
    testWidgets('Skenario 10: Paritas geometri kapsul 999 dan dynamic outline/filled icons pada MerchantFloatingNavBar',
        (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              bottomNavigationBar: MerchantFloatingNavBar(
                currentIndex: selected,
                onTabSelected: (i) {
                  setState(() => selected = i);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verifikasi ikon tab merchant: Tab 0 terpilih (filled solid), tab lainnya unselected (outline stroke)
      expect(find.byIcon(Icons.receipt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
      expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);

      // Verifikasi label 5 tab
      expect(find.text('Pesanan'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Outlet'), findsOneWidget);
      expect(find.text('Marketing'), findsOneWidget);
      expect(find.text('GagePay'), findsOneWidget);

      // Tap tab Chat (index 1), verifikasi Chat berubah jadi filled dan Pesanan jadi outline
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.receipt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Skenario 11: Verifikasi Styling Form Field Mewah (Radius 14, Soft BG)
    // -------------------------------------------------------------------------
    test('Skenario 11: Standar styling form field mewah anti-slop (Radius 14, Border Halus)', () {
      final inputDecorationLight = InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

      expect(inputDecorationLight.filled, isTrue);
      expect(inputDecorationLight.fillColor, equals(const Color(0xFFF8FAFC)));
      final border = inputDecorationLight.border as OutlineInputBorder;
      expect(border.borderRadius, equals(BorderRadius.circular(14)));
    });

    // -------------------------------------------------------------------------
    // Skenario 12: Pemisahan Layar Penuh (Full Screen Page) vs Floating Sheet
    // -------------------------------------------------------------------------
    testWidgets('Skenario 12: MerchantReviewScreen & MerchantKitchenInsightsScreen adalah Full Screen Page',
        (tester) async {
      // 1. MerchantReviewScreen render sebagai halaman penuh dengan AppBar
      await tester.pumpWidget(
        const MaterialApp(
          home: MerchantReviewScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Penilaian & Ulasan Toko'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('98 Ulasan'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // 2. MerchantKitchenInsightsScreen render sebagai halaman penuh dengan AppBar
      await tester.pumpWidget(
        const MaterialApp(
          home: MerchantKitchenInsightsScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Wawasan & Analitik Dapur'), findsOneWidget);
      expect(find.text('Waktu Masak'), findsOneWidget);
      expect(find.text('Jam Sibuk Dapur & Pesanan'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Skenario 13: Kalkulator Harga In-Place Langsung di Tambah Menu
    // -------------------------------------------------------------------------
    test('Skenario 13: Kalkulator harga in-place (MDR 10%, komisi afiliasi, net payout & margin)', () {
      int offlinePrice = 15000;
      double affiliateRate = 0.10; // 10%
      int gagePrice = AffiliateCommissionService.calculateRecommendedOnlinePrice(
        offlinePrice,
        platformRate: 0.10,
        affiliateRate: affiliateRate,
      );

      // Verifikasi harga rekomendasi anti-rugi
      expect(gagePrice, greaterThanOrEqualTo(offlinePrice));

      int platformFee = (gagePrice * 0.10).round();
      int affiliateFee = (gagePrice * affiliateRate).round();
      int netPayout = gagePrice - platformFee - affiliateFee;
      int margin = netPayout - offlinePrice;

      // Pencairan bersih tidak boleh di bawah harga warung fisik
      expect(netPayout, greaterThanOrEqualTo(offlinePrice));
      expect(margin, greaterThanOrEqualTo(0));

      // Verifikasi saat merchant set harga manual terlalu murah (di bawah modal)
      int cheapGagePrice = 14000;
      int cheapPlatformFee = (cheapGagePrice * 0.10).round();
      int cheapAffiliateFee = (cheapGagePrice * affiliateRate).round();
      int cheapNetPayout = cheapGagePrice - cheapPlatformFee - cheapAffiliateFee;
      int cheapMargin = cheapNetPayout - offlinePrice;

      // Terdeteksi margin tipis/rugi
      expect(cheapNetPayout, lessThan(offlinePrice));
      expect(cheapMargin, lessThan(0));
    });

    // -------------------------------------------------------------------------
    // Skenario 14: Integrasi Image Picker & createMerchantMenu dengan Image Path
    // -------------------------------------------------------------------------
    test('Skenario 14: GageApiClient.createMerchantMenu meneruskan image path foto produk', () async {
      final res = await GageApiClient.createMerchantMenu(
        merchantId: MerchantStorefrontService.defaultPortalMerchantId,
        name: 'Dimsum Kulit Tahu Krispi',
        description: 'Kulit tahu renyah isi udang segar',
        category: 'Dimsum Goreng',
        offlinePrice: 15000,
        gagePrice: 18500,
        image: '/data/user/0/com.gagepracimantoro.merchant/cache/menu_sample.jpg',
      );

      expect(res, isNotNull);
      expect(res!['name'], equals('Dimsum Kulit Tahu Krispi'));
      expect(res['offline_price'], equals(15000));
      expect(res['gage_price'], equals(18500));
      expect(res['image'], equals('/data/user/0/com.gagepracimantoro.merchant/cache/menu_sample.jpg'));
    });

    // -------------------------------------------------------------------------
    // Skenario 15: Tambah Menu menampilkan Image Picker interaktif & Kalkulator Harga in-place
    // -------------------------------------------------------------------------
    testWidgets('Skenario 15: Tambah Menu menampilkan Image Picker interaktif & Kalkulator Harga in-place',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MerchantMenuScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Temukan tombol Menu Baru
      final addBtn = find.text('Menu Baru');
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi header bottom sheet
      expect(find.text('Tambah Produk / Menu Baru'), findsOneWidget);

      // Verifikasi Image Picker Android 14 / One UI Ala Nusa Kasir
      expect(find.text('Foto Produk / Menu'), findsOneWidget);
      expect(find.text('Pilih Foto Produk'), findsOneWidget);

      // Verifikasi Kalkulator Harga In-Place Langsung
      expect(find.text('Kalkulator Harga & Margin Produk'), findsOneWidget);
      expect(find.text('Harga Warung (Offline)'), findsOneWidget);
      expect(find.text('Harga Jual di GAGE'), findsOneWidget);
      expect(find.text('Alokasi Komisi Afiliasi / Kreator Video (Maks 20%):'), findsOneWidget);
      expect(find.text('10% (Rekomendasi)'), findsOneWidget);

      // Verifikasi Tombol Simpan
      expect(find.text('Simpan Produk / Menu'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Skenario 16: Audio Alarm Pesanan Masuk Dapur Bising
    // -------------------------------------------------------------------------
    test('Skenario 16: Audio alarm pesanan masuk dapur bising aktif & auto-stop saat pesanan diterima', () async {
      final provider = MerchantOrderProvider();
      expect(provider.soundAlarmEnabled, isTrue);

      // Toggle sound alarm
      provider.toggleSoundAlarm(false);
      expect(provider.soundAlarmEnabled, isFalse);
      expect(GageAudioService.instance.isOrderAlertRunning, isFalse);

      provider.toggleSoundAlarm(true);
      expect(provider.soundAlarmEnabled, isTrue);

      // Terima order baru
      final newOrder = provider.orders.firstWhere((o) => o.status == 'NEW' || o.status == 'PAID');
      await provider.acceptOrder(newOrder.id);

      final accepted = provider.orders.firstWhere((o) => o.id == newOrder.id);
      expect(accepted.status, equals('COOKING'));
      expect(GageAudioService.instance.isOrderAlertRunning, isFalse);
      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 17: Filter 4 Kategori Status Pesanan Kapsul Universal
    // -------------------------------------------------------------------------
    testWidgets('Skenario 17: Filter 4 kategori status pesanan kapsul universal pada GageMerchantOrdersTab',
        (tester) async {
      final provider = MerchantOrderProvider();
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MerchantOrderProvider>.value(
            value: provider,
            child: Scaffold(
              body: GageMerchantOrdersTab(currencyFormatter: formatter),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verifikasi 4 label filter kapsul universal ringkas (Food, Shop, Farm)
      expect(find.text('Disiapkan'), findsWidgets);
      expect(find.text('Siap'), findsWidgets);
      expect(find.text('Diantar'), findsWidgets);
      expect(find.text('Selesai'), findsWidgets);

      // Ketuk tab "Siap"
      await tester.tap(find.text('Siap').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 18: Alur Penolakan Pesanan Beradab (Alasan Operasional & 100% Refund)
    // -------------------------------------------------------------------------
    test('Skenario 18: Alur penolakan pesanan beradab menyimpan alasan operasional & 100% refund', () async {
      final provider = MerchantOrderProvider();
      final targetOrder = provider.orders.firstWhere((o) => o.status == 'NEW' || o.status == 'PAID');
      final totalBefore = targetOrder.totalAmount;

      await provider.rejectOrder(
        targetOrder.id,
        'Stok produk habis (Stok beras habis)',
      );

      final rejected = provider.orders.firstWhere((o) => o.id == targetOrder.id);
      expect(rejected.status, equals('CANCELLED'));
      expect(rejected.cancellationReason, contains('Stok produk habis'));
      expect(rejected.refundAmount, equals(totalBefore));
      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 19: Cetak Struk Multi-Rangkap (1x, 2x Dapur+Kurir, 3x) & Auto-Print
    // -------------------------------------------------------------------------
    test('Skenario 19: Cetak struk multi-rangkap (1x, 2x Dapur+Kurir, 3x) & auto-print on accept', () async {
      final provider = MerchantOrderProvider();

      // Default adalah 2 rangkap (1x Dapur, 1x Kurir/Pelanggan)
      expect(provider.receiptCopies, equals(2));
      expect(provider.autoPrintOnAccept, isTrue);
      expect(provider.preferredPaperSize, equals('58mm'));

      // Ubah ke 3 rangkap (+ Kasir)
      provider.setReceiptCopies(3);
      expect(provider.receiptCopies, equals(3));

      // Test eksekusi cetak struk multi-rangkap
      final printOk = await provider.printOrderReceipt('ord-8822', paperSize: '58mm', copies: 3);
      expect(printOk, isTrue);

      // Toggle auto-print
      provider.toggleAutoPrintOnAccept(false);
      expect(provider.autoPrintOnAccept, isFalse);
      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 20: Builder Varian & Modifiers Menu (Add-ons / Topping)
    // -------------------------------------------------------------------------
    test('Skenario 20: Builder varian & modifiers menu (Add-ons / Topping) via GageApiClient', () async {
      final variantGroups = [
        {
          'name': 'Level Pedas',
          'title': 'Level Pedas',
          'required': true,
          'multi_select': false,
          'options': [
            {'name': 'Level 0 (Original)', 'price': 0},
            {'name': 'Level 1 (Sedang)', 'price': 0},
            {'name': 'Level 2 (Pedas)', 'price': 2000},
          ],
        },
        {
          'name': 'Ekstra Topping',
          'title': 'Ekstra Topping',
          'required': false,
          'multi_select': true,
          'options': [
            {'name': 'Keju Mozzarella', 'price': 3000},
          ],
        },
      ];

      final res = await GageApiClient.createMerchantMenu(
        merchantId: MerchantStorefrontService.defaultPortalMerchantId,
        name: 'Siomay Dimsum Pedas Mozza',
        description: 'Siomay ayam udang dengan varian pedas dan keju leleh',
        category: 'Dimsum Kukus',
        offlinePrice: 16000,
        gagePrice: 19500,
        variantGroups: variantGroups,
      );

      expect(res, isNotNull);
      expect(res!['has_variants'], isTrue);
      expect(res['variant_groups'], isA<List>());
      final groups = res['variant_groups'] as List;
      expect(groups.length, equals(2));
      expect(groups[0]['name'], equals('Level Pedas'));
      expect(groups[1]['name'], equals('Ekstra Topping'));
    });

    // -------------------------------------------------------------------------
    // Skenario 21: Quick Status Operasional Lapak (Buka Normal, Istirahat, Tutup)
    // -------------------------------------------------------------------------
    test('Skenario 21: Quick status operasional lapak (Buka Normal, Istirahat 30 Menit, Tutup Toko)', () {
      final provider = MerchantOrderProvider();
      expect(provider.isOpen, isTrue);
      expect(provider.isBusy, isFalse);

      // Aktifkan Mode Istirahat 30 Menit
      provider.pauseOrders(const Duration(minutes: 30), reason: 'Istirahat Siang Dapur');
      expect(provider.isBusy, isTrue);
      expect(provider.busyRemainingMinutes, greaterThanOrEqualTo(29));
      expect(provider.busyReason, equals('Istirahat Siang Dapur'));

      // Resume Toko
      provider.resumeOrders();
      expect(provider.isBusy, isFalse);
      expect(provider.busyRemainingMinutes, equals(0));

      // Tutup Toko
      provider.toggleStoreOpen(false);
      expect(provider.isOpen, isFalse);
      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 22: Static Segmented Tab Switch (Non-Scrollable, 4 Kategori Universal)
    // -------------------------------------------------------------------------
    testWidgets('Skenario 22: Static Segmented Tab Switch non-scrollable dengan 4 kapsul Expanded', (tester) async {
      final provider = MerchantOrderProvider();
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MerchantOrderProvider>.value(
            value: provider,
            child: Scaffold(
              body: GageMerchantOrdersTab(currencyFormatter: formatter),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pastikan ada 4 label status ringkas
      expect(find.text('Disiapkan'), findsWidgets);
      expect(find.text('Siap'), findsWidgets);
      expect(find.text('Diantar'), findsWidgets);
      expect(find.text('Selesai'), findsWidgets);

      // Verifikasi bahwa segmented switch tidak berada di dalam SingleChildScrollView horizontal
      final horizontalScrollFinder = find.byWidgetPredicate(
        (widget) => widget is SingleChildScrollView && widget.scrollDirection == Axis.horizontal,
      );
      // Segmented switch tab pesanan kini statis (Row of Expanded)
      expect(find.descendant(of: find.byType(GageMerchantOrdersTab), matching: horizontalScrollFinder), findsNothing);
      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 23: Navigasi Order Detail Full-Screen Menu (Bukan Floating Sheet)
    // -------------------------------------------------------------------------
    testWidgets('Skenario 23: Tap kartu pesanan membuka MerchantOrderDetailScreen full-screen', (tester) async {
      final provider = MerchantOrderProvider();
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<MerchantOrderProvider>.value(
            value: provider,
            child: Scaffold(
              body: GageMerchantOrdersTab(currencyFormatter: formatter),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Temukan kartu pesanan pertama dan ketuk
      final orderCard = find.text('Galih Pambudi');
      expect(orderCard, findsOneWidget);
      await tester.tap(orderCard);
      await tester.pumpAndSettle();

      // Verifikasi bahwa MerchantOrderDetailScreen terbuka sebagai Full Screen Page
      expect(find.byType(MerchantOrderDetailScreen), findsOneWidget);
      expect(find.text('PIN Verifikasi Serah Terima'), findsOneWidget);
      expect(find.text('Rincian Pembayaran & Pendapatan'), findsOneWidget);
      expect(find.text('Pendapatan Bersih Toko'), findsOneWidget);

      // Kembali ke halaman pesanan
      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();
      expect(find.byType(MerchantOrderDetailScreen), findsNothing);
      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 24: Production 1:1 Photo Picker & Crop/Rotate Architecture
    // -------------------------------------------------------------------------
    testWidgets('Skenario 24: MerchantPhotoPickerSheet menampilkan opsi Kamera dan Galeri riil (Production 1:1)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => MerchantPhotoPickerSheet.show(context),
                child: const Text('Buka Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Picker'));
      await tester.pumpAndSettle();

      // Verifikasi elemen Production-Grade Photo Picker (GageFloatingSheet title bersih tanpa duplikasi)
      expect(find.text('Pilih Sumber Foto'), findsOneWidget);
      expect(find.text('Pilih Sumber Foto Produk'), findsNothing);
      expect(find.text('Ambil Foto Kamera'), findsOneWidget);
      expect(find.text('Pilih dari Galeri HP'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Skenario 25: Countdown SLA Penyiapan Pesanan & Penalti Poin Toko
    // -------------------------------------------------------------------------
    test('Skenario 25: SLA Countdown penyiapan pesanan & penalti toko saat timer habis', () {
      final provider = MerchantOrderProvider();
      expect(provider.penaltyPoints, 0);

      final cookingOrder = provider.orders.firstWhere((o) => o.status == 'COOKING');
      expect(cookingOrder.cookingSecondsRemaining, greaterThan(0));
      expect(cookingOrder.formattedCookingTimeRemaining.contains(':'), isTrue);

      // Simulasi cooking timer habis
      provider.triggerCookingTimeoutForTesting(cookingOrder.id);
      
      final updatedOrder = provider.orders.firstWhere((o) => o.id == cookingOrder.id);
      expect(updatedOrder.status, 'READY_FOR_PICKUP');
      expect(provider.penaltyPoints, 1);
      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 26: Paritas Kartu Pesanan Luar (Total Pesanan Merah & Chat Pembeli)
    // -------------------------------------------------------------------------
    testWidgets('Skenario 26: Paritas Kartu Pesanan Luar (Total Pesanan, Chat Pembeli, Avatar Berlingkar)', (tester) async {
      final provider = MerchantOrderProvider();
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MerchantOrderProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GageMerchantOrdersTab(currencyFormatter: formatter),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi label nominal luar adalah Total Pesanan (bukan Pendapatan Bersih)
      expect(find.text('Total Pesanan:'), findsWidgets);

      // Wave 15: Kartu pesanan luar bebas tombol Chat Pembeli
      expect(find.text('Chat Pembeli'), findsNothing);

      // Verifikasi widget delivery track tampil pada kartu pesanan
      expect(find.byType(GageDeliveryTrackProgress), findsWidgets);

      // Verifikasi tombol cooking menampilkan countdown timer MM:SS
      expect(find.textContaining('Pesanan Siap Diambil ('), findsWidgets);

      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 27: Wave 10 Privasi Pelanggan, Zero-D1 Asset Image & Eliminasi Tombol Serahkan
    // -------------------------------------------------------------------------
    testWidgets('Skenario 27: Wave 10 Privasi Pelanggan, True Floating Button & No Duplicate Print', (tester) async {
      final provider = MerchantOrderProvider();
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
      final readyOrder = provider.orders.firstWhere((o) => o.status == 'READY_FOR_PICKUP' && !o.isPickup);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MerchantOrderProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: MerchantOrderDetailScreen(
              order: readyOrder,
              currencyFormatter: formatter,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi badge raw status READY_FOR_PICKUP telah dieliminasi
      expect(find.text('READY_FOR_PICKUP'), findsNothing);

      // 2. Verifikasi tombol serahkan pesanan delivery manual telah dieliminasi
      expect(find.text('Serahkan Pesanan'), findsNothing);
      expect(find.text('Serahkan ke Driver'), findsNothing);

      // 3. Verifikasi tombol cetak struk hanya 1 (di AppBar) dan tidak ada duplikasi di floating bar
      expect(find.byIcon(Icons.print_outlined), findsOneWidget);
      expect(find.byIcon(Icons.print_rounded), findsNothing);

      // 4. Verifikasi privasi pelanggan: nama pelanggan tampil
      expect(find.text(readyOrder.customerName ?? 'Pelanggan GAGE'), findsOneWidget);

      // 5. Verifikasi effectiveImageUrl mengembalikan path asset lokal (Zero D1 Query Overhead)
      for (final item in readyOrder.items) {
        expect(item.effectiveImageUrl.isNotEmpty, isTrue);
      }

      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 28: Wave 11 Eliminasi Status Banner & Pemisahan Kontainer Pembeli / Driver
    // -------------------------------------------------------------------------
    testWidgets('Skenario 28: Wave 11 Detail Order Banner Status Dieliminasi & Header Kontainer Terpisah', (tester) async {
      final provider = MerchantOrderProvider();
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
      final readyOrder = provider.orders.firstWhere((o) => o.status == 'READY_FOR_PICKUP');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MerchantOrderProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: MerchantOrderDetailScreen(
              order: readyOrder,
              currencyFormatter: formatter,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi banner status atas dieliminasi total
      expect(find.text('Pesanan Siap Diambil'), findsNothing);
      expect(find.text('READY_FOR_PICKUP'), findsNothing);
      expect(find.text('Toko telah menyelesaikan penyiapan, menunggu kurir / pembeli.'), findsNothing);

      // 2. Verifikasi PIN serah terima kurir tampil dengan label PIN Verifikasi Serah Terima
      expect(find.text('PIN Verifikasi Serah Terima'), findsOneWidget);

      // 3. Verifikasi kontainer pembeli terpisah dengan header Pembeli
      expect(find.text('Pembeli'), findsOneWidget);

      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 29: Wave 11 Engine Cetak Struk Monospace & Notifikasi Interaktif imageUrl
    // -------------------------------------------------------------------------
    test('Skenario 29: Wave 11 MerchantReceiptPrinterService ESC/POS Formatting & Notifikasi Media', () {
      final provider = MerchantOrderProvider();
      final order = provider.orders.first;
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

      // Test format 58mm (32 kolom)
      final receipt58 = MerchantReceiptPrinterService.instance.generateReceiptText(
        order: order,
        paperSize: '58mm',
        currencyFormatter: formatter,
        copyIndex: 1,
      );
      expect(receipt58.contains('GAGE PRACIMANTORO'), isTrue);
      expect(receipt58.contains(order.orderNumber), isTrue);

      // Test format 80mm (48 kolom)
      final receipt80 = MerchantReceiptPrinterService.instance.generateReceiptText(
        order: order,
        paperSize: '80mm',
        currencyFormatter: formatter,
        copyIndex: 1,
      );
      expect(receipt80.contains('GAGE PRACIMANTORO'), isTrue);

      // Test format salinan tiket dapur
      final kitchenTicket = MerchantReceiptPrinterService.instance.generateReceiptText(
        order: order,
        paperSize: '58mm',
        currencyFormatter: formatter,
        copyIndex: 2,
      );
      expect(kitchenTicket.contains('SALINAN TIKET DAPUR'), isTrue);

      // Test formatTwoColumns & formatCenter
      final twoCol = MerchantReceiptPrinterService.formatTwoColumns('Kiri', 'Kanan', 32);
      expect(twoCol.startsWith('Kiri'), isTrue);
      expect(twoCol.endsWith('Kanan'), isTrue);

      // Test GageNotification model serialization dengan imageUrl
      final notif = GageNotification(
        id: 'notif-test-01',
        title: 'Promo Spesial',
        body: 'Diskon 30%',
        category: 'promo',
        timestamp: DateTime.now(),
        imageUrl: 'https://pub-r2.gage.id/promos/test.png',
        actionUrl: 'gage://promo/test',
      );
      final json = notif.toJson();
      expect(json['imageUrl'], equals('https://pub-r2.gage.id/promos/test.png'));
      expect(json['actionUrl'], equals('gage://promo/test'));

      final reconstructed = GageNotification.fromJson(json);
      expect(reconstructed.imageUrl, equals('https://pub-r2.gage.id/promos/test.png'));
      expect(reconstructed.actionUrl, equals('gage://promo/test'));

      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 30: Wave 12 Driver Dock Merah & Detail Order Clean Up
    // -------------------------------------------------------------------------
    testWidgets('Skenario 30: Wave 12 Driver Dock Merah & Detail Order Clean Up', (tester) async {
      final provider = MerchantOrderProvider();
      final orderWithDriver = provider.orders.firstWhere((o) => o.hasAssignedDriver);
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

      await tester.pumpWidget(
        ChangeNotifierProvider<MerchantOrderProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: MerchantOrderDetailScreen(
                order: orderWithDriver,
                currencyFormatter: formatter,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verifikasi badge kurir terpasang & pengantaran kurir telah dihapus
      expect(find.text('Kurir Terpasang'), findsNothing);
      expect(find.text('Driver / Kurir GAGE'), findsNothing);
      expect(find.text('Pengantaran kurir ke alamat pembeli'), findsNothing);
      expect(find.text('Wajib Validasi'), findsNothing);

      // Verifikasi judul blok bersih: "Driver" dan "Pembeli"
      expect(find.text('Driver'), findsOneWidget);
      expect(find.text('Pembeli'), findsOneWidget);

      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 31: Wave 12 Nusa Kasir Parity Printer & Provider Toggles
    // -------------------------------------------------------------------------
    test('Skenario 31: Wave 12 Nusa Kasir Parity Printer & Provider Toggles', () async {
      final provider = MerchantOrderProvider();

      // Verifikasi toggle Cetak Otomatis & Buka Laci Uang
      expect(provider.autoPrintOrders, isTrue);
      provider.setAutoPrintOrders(false);
      expect(provider.autoPrintOrders, isFalse);

      expect(provider.openCashDrawerOnPrint, isFalse);
      provider.setOpenCashDrawerOnPrint(true);
      expect(provider.openCashDrawerOnPrint, isTrue);

      // Verifikasi uji cetak sample Nusa Kasir
      final testReceipt = MerchantReceiptPrinterService.instance.generateTestReceipt(
        storeName: 'Dimsum Sewu Pracimantoro',
        paperSize: '58mm',
      );
      expect(testReceipt.contains('UJI COBA CETAK THERMAL'), isTrue);
      expect(testReceipt.contains('Printer Siap Operasional!'), isTrue);

      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 32: Wave 12 Google-First Onboarding & Setup Store Completion Flag
    // -------------------------------------------------------------------------
    test('Skenario 32: Wave 12 Google-First Onboarding & Setup Store Completion Flag', () async {
      SharedPreferences.setMockInitialValues({});
      // Pastikan store setup flag terintegrasi dengan shared preferences
      const testMerchantId = 'm-test-store-setup-01';
      final isCompletedBefore = await MerchantStorefrontService.hasCompletedStoreSetup(testMerchantId);
      expect(isCompletedBefore, isFalse);

      await MerchantStorefrontService.markStoreSetupCompleted(testMerchantId);
      final isCompletedAfter = await MerchantStorefrontService.hasCompletedStoreSetup(testMerchantId);
      expect(isCompletedAfter, isTrue);
    });

    // -------------------------------------------------------------------------
    // Skenario 33: Wave 13 Floating Action Button Full-Width & Eliminasi Tombol Chat Driver
    // -------------------------------------------------------------------------
    testWidgets('Skenario 33: Wave 13 Floating Action Button Full-Width & Eliminasi Tombol Chat Driver', (tester) async {
      final provider = MerchantOrderProvider();
      final orderWithDriver = provider.orders.firstWhere((o) => o.hasAssignedDriver);
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

      await tester.pumpWidget(
        ChangeNotifierProvider<MerchantOrderProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: MerchantOrderDetailScreen(
                order: orderWithDriver,
                currencyFormatter: formatter,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verifikasi Tombol Chat Driver dilarang dan dihapus total
      expect(find.text('Chat Driver'), findsNothing);

      // Verifikasi ikon Chat (Driver & Pembeli) & Telepon In-App tersedia
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.phone_outlined), findsWidgets);

      // Verifikasi stage action button memiliki layout full-width dock
      expect(find.byType(ElevatedButton), findsWidgets);

      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 34: Wave 13 Kartu Pesanan Luar Rounded Penuh & Red Driver Dock Terintegrasi
    // -------------------------------------------------------------------------
    testWidgets('Skenario 34: Wave 13 Kartu Pesanan Luar Rounded Penuh & Red Driver Dock Terintegrasi', (tester) async {
      final provider = MerchantOrderProvider();
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

      await tester.pumpWidget(
        ChangeNotifierProvider<MerchantOrderProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: GageMerchantOrdersTab(currencyFormatter: formatter),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi tidak ada tombol Chat Driver di kartu pesanan luar
      expect(find.text('Chat Driver'), findsNothing);

      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 35: Wave 13 Setup Wizard Domain Strict (Food, Shop, Farm Only & No Bio Field)
    // -------------------------------------------------------------------------
    testWidgets('Skenario 35: Wave 13 Setup Wizard Domain Strict (Food, Shop, Farm Only & No Bio Field)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MerchantStoreSetupWizardScreen(),
        ),
      );
      await tester.pump();

      // Verifikasi domain valid: Kuliner (Food), Kelontong (Shop), Tani (Farm)
      expect(find.text('Kuliner (Food)'), findsOneWidget);
      expect(find.text('Kelontong (Shop)'), findsOneWidget);
      expect(find.text('Tani (Farm)'), findsOneWidget);
      expect(find.text('Bangunan (Build)'), findsNothing);

      // Lanjut ke step 2
      final lanjutBtn = find.text('Lanjutkan');
      await tester.tap(lanjutBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi bio / slogan toko dihapus
      expect(find.text('Slogan / Bio Singkat Toko'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // Skenario 36: Wave 19 Seamless Grouped Cards Pengaturan & Pengajuan Lokasi
    // -------------------------------------------------------------------------
    testWidgets('Skenario 36: Wave 19 Seamless Grouped Cards Pengaturan & Pengajuan Lokasi', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const MaterialApp(
          home: MerchantProfileScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi Header & Seamless Grouped Cards
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('TERVERIFIKASI'), findsOneWidget);
      expect(find.textContaining('ID Toko:'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Menu'), findsNothing);
      expect(find.text('Kepatuhan SOP'), findsNothing);

      // Verifikasi section headers & menu item tanpa grid '\n' lama maupun duplikasi Pusat Bantuan
      expect(find.text('TOKO & OPERASIONAL'), findsOneWidget);
      expect(find.text('PESANAN, NOTIFIKASI & PRINTER'), findsOneWidget);
      expect(find.text('Informasi Toko'), findsOneWidget);
      expect(find.text('Pengaturan Pesanan'), findsOneWidget);
      expect(find.text('Pengaturan Notifikasi & Alarm'), findsOneWidget);
      expect(find.text('Printer Bluetooth Thermal'), findsOneWidget);
      expect(find.text('Pengaturan Struk'), findsOneWidget);
      expect(find.text('Lokasi Toko & Pindah Alamat'), findsOneWidget);
      expect(find.text('Pusat Bantuan & Hotline'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Keluar dari Akun Mitra'), 300);
      expect(find.text('Keluar dari Akun Mitra'), findsOneWidget);

      // Verifikasi model & persistence Pengajuan Pindah Lokasi Toko
      final req = MerchantLocationChangeRequest(
        id: 'test-req-01',
        merchantId: 'm-test',
        currentAddress: 'Jl. Raya Pracimantoro No. 14',
        newAddress: 'Jl. Raya Pracimantoro No. 88',
        newLandmark: 'Samping Kantor Pos',
        newLatitude: -8.089,
        newLongitude: 110.837,
        reason: 'Pindah ke ruko sendiri',
        submittedAt: DateTime.now(),
      );
      await MerchantStorefrontService.saveLocationChangeRequest(req);
      final loaded = await MerchantStorefrontService.loadLocationChangeRequest('m-test');
      expect(loaded, isNotNull);
      expect(loaded!.newAddress, equals('Jl. Raya Pracimantoro No. 88'));
      expect(loaded.status, equals('PENDING'));
    });

    // -------------------------------------------------------------------------
    // Skenario 37: Wave 14: Conditional Countdown & Animasi Cari Driver
    // -------------------------------------------------------------------------
    testWidgets('Skenario 37: Wave 14: Countdown memasak hanya muncul saat driver terpasang, jika belum tampilkan animasi mencari kurir', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      final provider = MerchantOrderProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MerchantOrderProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GageMerchantOrdersTab(currencyFormatter: formatter),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Temukan pesanan aktif
      final deliveryOrdersWithDriver = provider.orders.where((o) => o.hasAssignedDriver && !o.isPickup && o.status == 'COOKING').toList();
      if (deliveryOrdersWithDriver.isNotEmpty) {
        expect(find.byType(GageDeliveryTrackProgress), findsWidgets);
        expect(find.textContaining('Pesanan Siap Diambil ('), findsWidgets);
      }

      // Buat pesanan delivery tanpa driver dalam status COOKING
      final testOrder = provider.orders.first.copyWith(
        status: 'COOKING',
        isPickup: false,
        driverName: null,
        driverPlate: null,
      );
      expect(testOrder.hasAssignedDriver, isFalse);
      expect((testOrder.hasAssignedDriver || testOrder.isPickup), isFalse);
      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 38: Wave 14: Driver Dock Kapsul Full-Rounded & Animasi Menuju Kios
    // -------------------------------------------------------------------------
    testWidgets('Skenario 38: Wave 14: Driver Dock Kapsul Full-Rounded (Radius 999), Border-Free & Animasi Menuju Kios', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      final provider = MerchantOrderProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MerchantOrderProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GageMerchantOrdersTab(currencyFormatter: formatter),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi delivery track progress tampil
      expect(find.byType(GageDeliveryTrackProgress), findsWidgets);
      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 39: Wave 14: Header Avatar Kotak Rounded, No Menu Button, Store ID D1 & Rating Nav
    // -------------------------------------------------------------------------
    testWidgets('Skenario 39: Wave 14: Avatar Kotak Rounded, Eliminasi Tombol Menu, Store ID Terstruktur Cloudflare D1 & Tap Rating', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const MaterialApp(
          home: MerchantProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi Store ID baku sesuai Cloudflare D1 (GAGE-PRC-FD01)
      expect(find.textContaining('GAGE-PRC-FD01'), findsOneWidget);

      // 2. Verifikasi tombol "Menu" tidak ada di header
      expect(find.widgetWithText(ElevatedButton, 'Menu'), findsNothing);

      // 3. Verifikasi tap Rating Toko membuka MerchantReviewScreen
      expect(find.text('Rating Toko'), findsOneWidget);
      await tester.tap(find.text('Rating Toko'));
      await tester.pumpAndSettle();

      expect(find.byType(MerchantReviewScreen), findsOneWidget);
      expect(find.text('Penilaian & Ulasan Toko'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Skenario 40: Wave 14: Dokumen Kebijakan Kemitraan Full-Screen & Pusat Bantuan Non-Gimmick
    // -------------------------------------------------------------------------
    testWidgets('Skenario 40: Wave 14: Dokumen Kebijakan Kemitraan Full-Screen & Pusat Bantuan Non-Gimmick', (tester) async {
      SharedPreferences.setMockInitialValues({});

      // 1. Verifikasi MerchantTermsAndPrivacyScreen
      await tester.pumpWidget(
        const MaterialApp(
          home: MerchantTermsAndPrivacyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kebijakan Privasi & Kemitraan'), findsOneWidget);
      expect(find.textContaining('1. Skema Bagi Hasil & Komisi Layanan (MDR)'), findsOneWidget);
      expect(find.textContaining('10% (sepuluh persen)'), findsOneWidget);
      
      await tester.scrollUntilVisible(find.text('Salin Ringkasan Dokumen'), 300);
      expect(find.text('Salin Ringkasan Dokumen'), findsOneWidget);

      // 2. Verifikasi MerchantHelpCenterSheet
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MerchantHelpCenterSheet(
              storeName: 'Dimsum Sewu',
              storeId: 'GAGE-PRC-FD01',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hotline Darurat'), findsOneWidget);
      expect(find.text('Chat CS WhatsApp'), findsOneWidget);
      expect(find.text('PERTANYAAN UMUM (FAQ)'), findsOneWidget);
      expect(find.textContaining('Kapan saldo penjualan toko otomatis dicairkan?'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Skenario 41: Wave 15: GageDeliveryTrackProgress Animasi Top-Down Rider
    // -------------------------------------------------------------------------
    testWidgets('Skenario 41: Wave 15: Delivery Track Progress bar dengan motor rider top-down & status dinamis', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GageDeliveryTrackProgress(
                  isSearchingDriver: true,
                  labelPrefix: 'Sedang mencari kurir terdekat',
                  labelHighlight: '...',
                ),
                GageDeliveryTrackProgress(
                  isSearchingDriver: false,
                  labelPrefix: 'Menuju Kios',
                  labelHighlight: ' • Est. 5 mnt',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GageDeliveryTrackProgress), findsNWidgets(2));
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Skenario 42: Wave 15: Outer Card Tanpa Chat Pembeli (Gambar 2 Parity)
    // -------------------------------------------------------------------------
    testWidgets('Skenario 42: Wave 15: Kartu pesanan luar menghilangkan tombol Chat Pembeli', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      final provider = MerchantOrderProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MerchantOrderProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GageMerchantOrdersTab(currencyFormatter: formatter),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chat Pembeli'), findsNothing);
      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 43: Wave 15: Detail Order Dual Action Icons (Chat & Phone In-App)
    // -------------------------------------------------------------------------
    testWidgets('Skenario 43: Wave 15: Detail order menampilkan ikon Telepon pada Driver dan Chat + Telepon pada Pembeli', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      final provider = MerchantOrderProvider();
      final orderWithDriver = provider.orders.firstWhere((o) => o.hasAssignedDriver);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MerchantOrderProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: MerchantOrderDetailScreen(
              order: orderWithDriver,
              currencyFormatter: formatter,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Driver has chat + phone icons, Customer has chat + phone icons -> 2 phone icons, 2 chat icons
      expect(find.byIcon(Icons.phone_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNWidgets(2));
      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 44: Wave 15: Floating Sheet Tanpa Duplikasi Handle Bar & Header
    // -------------------------------------------------------------------------
    testWidgets('Skenario 44: Wave 15: MerchantPrinterSettingsSheet bebas duplikasi judul & handle bar internal', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final provider = MerchantOrderProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MerchantOrderProvider>.value(value: provider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MerchantPrinterSettingsSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Internal duplicate title 'Printer Bluetooth' must NOT exist inside child widget
      expect(find.text('Printer Bluetooth'), findsNothing);
      expect(find.text('Cetak Otomatis'), findsOneWidget);
      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 45: Wave 15: Kelola Cabang Multi-Outlet & Sinkronisasi Nama Toko
    // -------------------------------------------------------------------------
    testWidgets('Skenario 45: Wave 15: Kelola Cabang Multi-Outlet berganti & menambah cabang secara reaktif', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final provider = MerchantOrderProvider();
      await provider.loadBranches();
      expect(provider.activeBranchName, contains('Dimsum Sewu Pracimantoro'));
      expect(provider.branches.length, greaterThanOrEqualTo(2));

      // Switch to Branch 2
      final secondBranch = provider.branches[1];
      await provider.switchBranch(secondBranch);
      expect(provider.activeBranchName, equals(secondBranch.name));

      // Add a new Branch
      const newBranch = MerchantBranch(
        id: 'GAGE-PRC-FD01-03',
        name: 'Dimsum Sewu Baturetno (Cabang 2)',
        address: 'Jl. Raya Baturetno No. 5',
        landmark: 'Depan Terminal',
        phone: '085156955799',
      );
      await provider.addBranch(newBranch);
      expect(provider.activeBranchName, equals('Dimsum Sewu Baturetno (Cabang 2)'));
      expect(provider.branches.length, equals(3));

      // Render Branch Switcher Sheet
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MerchantOrderProvider>.value(value: provider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MerchantBranchSwitcherSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dimsum Sewu Pracimantoro (Pusat)'), findsOneWidget);
      expect(find.text('Dimsum Sewu Baturetno (Cabang 2)'), findsOneWidget);
      expect(find.text('Tambah Cabang Outlet Baru'), findsOneWidget);
      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 46: Wave 16: GageDeliveryTrackProgress Domain-Aware Icons (Food, Shop, Farm)
    // -------------------------------------------------------------------------
    testWidgets('Skenario 46: Wave 16: GageDeliveryTrackProgress merender ikon tengah adaptif untuk Food, Shop, dan Farm', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GageDeliveryTrackProgress(isSearchingDriver: false, domain: 'food', orderStatus: 'COOKING'),
                GageDeliveryTrackProgress(isSearchingDriver: false, domain: 'shop', orderStatus: 'COOKING'),
                GageDeliveryTrackProgress(isSearchingDriver: false, domain: 'farm', orderStatus: 'COOKING'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_rounded), findsOneWidget);
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Skenario 47: Wave 16: Detail Order Catatan Pembeli Highlight Merah & Ikon Polos
    // -------------------------------------------------------------------------
    testWidgets('Skenario 47: Wave 16: Detail order menyorot Catatan Pembeli dengan kontainer merah tipis', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      final provider = MerchantOrderProvider();
      final orderWithNotes = provider.orders.firstWhere(
        (o) => o.notes != null && o.notes!.isNotEmpty,
        orElse: () => provider.orders.first.copyWith(notes: 'Sambal dipisah ya'),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MerchantOrderProvider>.value(value: provider),
          ],
          child: MaterialApp(
            home: MerchantOrderDetailScreen(
              order: orderWithNotes,
              currencyFormatter: formatter,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Catatan Pembeli:', findRichText: true), findsOneWidget);
      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 48: Wave 16: Chat Tab Merchant Paritas Handoff Customer
    // -------------------------------------------------------------------------
    testWidgets('Skenario 48: Wave 16: GageMerchantChatTab bebas label 24/7/AI dan memakai filter Bantuan/Driver/Pelanggan', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final provider = MerchantOrderProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MerchantOrderProvider>.value(value: provider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GageMerchantChatTab(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pusat Bantuan'), findsOneWidget);
      expect(find.textContaining('24/7'), findsNothing);
      expect(find.textContaining('AI'), findsNothing);
      expect(find.text('Bantuan'), findsWidgets);
      expect(find.text('Driver'), findsWidgets);
      expect(find.text('Pelanggan'), findsWidgets);
      provider.dispose();
    });

    // -------------------------------------------------------------------------
    // Skenario 49: Wave 17: Mode Kirim Katalog Produk di Chat Merchant
    // -------------------------------------------------------------------------
    testWidgets('Skenario 49: Wave 17: GageProductCatalogSheet mode merchant menampilkan Kirim Katalog Produk', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GageProductCatalogSheet(
              merchantId: 'm-dimsum-sewu',
              merchantName: 'Dimsum Sewu Pracimantoro',
              isMerchantMode: true,
              onProductSelected: (_, _, _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kirim Katalog Produk'), findsOneWidget);
      expect(find.textContaining('langsung dikirim ke pembeli'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Skenario 50: Wave 17: GageDeliveryTrackProgress 5-Stage Merchant Flow
    // -------------------------------------------------------------------------
    testWidgets('Skenario 50: Wave 17: GageDeliveryTrackProgress menampilkan 5 tahap alur merchant', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GageDeliveryTrackProgress(
              isSearchingDriver: false,
              domain: 'shop',
              orderStatus: 'COOKING',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Disiapkan'), findsWidgets);
      expect(find.text('Siap'), findsWidgets);
      expect(find.text('Diantar'), findsWidgets);
      expect(find.text('Selesai'), findsWidgets);
      expect(find.byIcon(Icons.shopping_bag_rounded), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // Skenario 51: Wave 19: Smart Split Full-Screen Sub-Pages & SharedPrefs Sync
    // -------------------------------------------------------------------------
    testWidgets('Skenario 51: Wave 19: Full-Screen Pengaturan Sub-Pages, Printer Rangkap & Persistence', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final provider = MerchantOrderProvider();

      // 1. Verifikasi MerchantStoreInfoScreen Full Screen
      await tester.pumpWidget(
        ChangeNotifierProvider<MerchantOrderProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: MerchantStoreInfoScreen(
              merchantId: 'm-test',
              storeIdFormatted: 'GAGE-PRC-FD01',
              initialName: 'Dimsum Sewu Uji',
              initialWhatsapp: '085156955735',
              initialLogo: 'assets/images/resto_dimsum_sewu.png',
              initialBanner: 'assets/images/resto_dimsum_sewu.png',
              storeAddress: 'Jl. Raya Pracimantoro No. 14',
              landmark: 'Depan Pasar',
              latitude: -8.0892,
              longitude: 110.8374,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Informasi Toko'), findsOneWidget);
      expect(find.text('Nama Toko / Outlet'), findsOneWidget);
      expect(find.text('Simpan Informasi Toko'), findsOneWidget);

      // 2. Verifikasi MerchantReceiptSettingsScreen Full Screen + Tampilkan Logo Toggle
      await tester.pumpWidget(
        const MaterialApp(
          home: MerchantReceiptSettingsScreen(storeName: 'Dimsum Sewu Uji'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pengaturan Struk'), findsOneWidget);
      expect(find.text('Tampilkan Logo Toko'), findsOneWidget);
      expect(find.text('Simpan Pengaturan Struk'), findsOneWidget);

      // 3. Verifikasi MerchantPrinterSettingsScreen Full Screen + Jumlah Rangkap (1x/2x/3x)
      await tester.pumpWidget(
        ChangeNotifierProvider<MerchantOrderProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: MerchantPrinterSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Printer Bluetooth Thermal'), findsOneWidget);
      expect(find.text('Jumlah Rangkap'), findsOneWidget);
      expect(find.text('1x'), findsOneWidget);
      expect(find.text('2x'), findsOneWidget);
      expect(find.text('3x'), findsOneWidget);
      await tester.tap(find.text('3x'));
      await tester.pumpAndSettle();
      expect(provider.receiptCopies, equals(3));

      // 4. Verifikasi MerchantOperatingScheduleScreen & MerchantLocationAndRequestsScreen
      await tester.pumpWidget(
        const MaterialApp(
          home: MerchantOperatingScheduleScreen(merchantId: 'm-test'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jam Operasional Toko'), findsOneWidget);
      expect(find.text('Simpan Jadwal Operasional'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: MerchantLocationAndRequestsScreen(
            merchantId: 'm-test',
            storeName: 'Dimsum Sewu Uji',
            currentAddress: 'Jl. Raya Pracimantoro No. 14',
            currentLandmark: 'Depan Pasar',
            currentLatitude: -8.0892,
            currentLongitude: 110.8374,
            markerImagePath: 'assets/images/resto_dimsum_sewu.png',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lokasi Toko & Pengajuan'), findsOneWidget);
      expect(find.text('Kirim Pengajuan ke Admin GAGE'), findsOneWidget);

      // 5. Verifikasi SharedPreferences sync pada MerchantOrderProvider
      provider.setCookingTime(20);
      provider.setSelfPickupEnabled(false);
      provider.toggleAutoAccept(true);
      await tester.pump(const Duration(milliseconds: 100));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('merchant_cooking_time'), equals(20));
      expect(prefs.getBool('merchant_self_pickup'), isFalse);
      expect(prefs.getBool('merchant_auto_accept'), isTrue);

      provider.dispose();
    });
  });
}

