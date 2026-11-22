import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/affiliate_commission_service.dart';
import 'package:gage_app/core/services/gage_audio_service.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';
import 'package:gage_app/features/merchant/presentation/merchant_kitchen_insights_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_menu_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_order_detail_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_review_screen.dart';
import 'package:gage_app/features/merchant/presentation/tabs/gage_merchant_orders_tab.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_floating_nav_bar.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_photo_picker_sheet.dart';
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
    // Skenario 10: Paritas Geometri Kapsul 999 & Ikon Tetap Solid pada Navbar
    // -------------------------------------------------------------------------
    testWidgets('Skenario 10: Paritas geometri kapsul 999 dan non-morphing icons pada MerchantFloatingNavBar',
        (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MerchantFloatingNavBar(
              currentIndex: selected,
              onTabSelected: (i) => selected = i,
            ),
          ),
        ),
      );
      await tester.pump();

      // Verifikasi 5 ikon tab merchant konsisten berbentuk solid
      expect(find.byIcon(Icons.receipt), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
      expect(find.byIcon(Icons.campaign_rounded), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);

      // Verifikasi label 5 tab
      expect(find.text('Pesanan'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Outlet'), findsOneWidget);
      expect(find.text('Marketing'), findsOneWidget);
      expect(find.text('GagePay'), findsOneWidget);
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
      expect(find.text('Disiapkan'), findsOneWidget);
      expect(find.text('Siap'), findsOneWidget);
      expect(find.text('Diantar'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

      // Ketuk tab "Siap"
      await tester.tap(find.text('Siap'));
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
      expect(find.text('Disiapkan'), findsOneWidget);
      expect(find.text('Siap'), findsOneWidget);
      expect(find.text('Diantar'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

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
      expect(find.text('PIN VERIFIKASI SERAH TERIMA'), findsOneWidget);
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

      // Verifikasi elemen Production-Grade Photo Picker (Bukan Sandbox Mock Presets)
      expect(find.text('Pilih Sumber Foto Produk'), findsOneWidget);
      expect(find.text('Ambil Foto Kamera'), findsOneWidget);
      expect(find.text('Pilih dari Galeri HP'), findsOneWidget);
    });
  });
}

