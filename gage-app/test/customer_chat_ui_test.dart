import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/presentation/chat_hub_screen.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/chat/presentation/widgets/gage_chat_input_bar.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/shared/widgets/gage_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Customer Chat UI & Badge Tests', () {
    testWidgets('ChatHubScreen renders Bantuan tab, Pusat Bantuan, clean driver name, keeps Driver/Toko chips, and excludes transport orders from Toko', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => InAppChatProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
          ],
          child: const MaterialApp(
            home: ChatHubScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifikasi Judul
      expect(find.text('Pesan & Bantuan'), findsOneWidget);

      // Verifikasi TabBar Capsule
      expect(find.text('Semua'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Bantuan'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Driver'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Toko'), findsOneWidget);

      // Verifikasi tidak ada label AI atau 24/7 dan order G-Ride tidak masuk sebagai Toko
      expect(find.text('Bantuan AI'), findsNothing);
      expect(find.text('AI 24/7'), findsNothing);
      expect(find.textContaining('(Driver GAGE)'), findsNothing);
      expect(find.text('GAGE Ride Pracimantoro'), findsNothing);

      // Verifikasi entri Pusat Bantuan & Driver bersih + chip Driver & Toko tetap ada
      expect(find.text('Pusat Bantuan'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Driver'), findsWidgets);
      expect(find.text('Toko'), findsWidgets);
    });

    testWidgets('InAppChatScreen strips (Driver GAGE), shows clean bubbles, order context pill, and capsule quick replies', (tester) async {
      final chatProv = InAppChatProvider();
      chatProv.sendMessage(
        orderId: '8821',
        senderId: 'driver-01',
        senderRole: 'driver',
        senderName: 'Budi Santoso (Driver GAGE)',
        text: 'Halo kak, pesanan sudah saya ambil dari resto ya.',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider.value(value: chatProv),
          ],
          child: const MaterialApp(
            home: InAppChatScreen(
              orderId: '8821',
              recipientName: 'Budi Santoso (Driver GAGE)',
              recipientRole: 'driver',
              recipientPhone: '081234567890',
              currentRole: 'customer',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifikasi AppBar menampilkan nama driver bersih tanpa (Driver GAGE)
      expect(find.text('Budi Santoso (Driver GAGE)'), findsNothing);
      expect(find.text('Budi Santoso'), findsWidgets);
      expect(find.textContaining('Mitra Driver GAGE'), findsOneWidget);

      // Verifikasi Sticky Context Banner
      expect(find.text('Pesanan #8821'), findsOneWidget);
      expect(find.text('Pengantaran Aktif'), findsOneWidget);

      // Verifikasi Date Separator
      expect(find.text('Hari Ini'), findsOneWidget);

      // Verifikasi Bubble Pesan
      expect(find.text('Halo kak, pesanan sudah saya ambil dari resto ya.'), findsOneWidget);

      // Verifikasi Quick Reply Pills
      expect(find.text('Saya sudah di titik jemput'), findsOneWidget);
      expect(find.text('Sesuai titik ya mas'), findsOneWidget);

      // Verifikasi Input Bar
      expect(find.byType(GageChatInputBar), findsOneWidget);
      expect(find.text('Ketik pesan disini...'), findsOneWidget);
    });

    testWidgets('GageChatInputBar displays GageTheme.primary send button when text is entered', (tester) async {
      final ctrl = TextEditingController();
      String sentText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GageChatInputBar(
              controller: ctrl,
              onSend: (txt) => sentText = txt,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ketik pesan
      await tester.enterText(find.byType(TextField), 'Halo driver');
      await tester.pumpAndSettle();

      // Verifikasi tombol submit muncul
      final submitFinder = find.byKey(const ValueKey('btn_submit'));
      expect(submitFinder, findsOneWidget);

      // Verifikasi dekorasi tombol submit menggunakan GageTheme.primary
      final container = tester.widget<Container>(
        find.descendant(of: submitFinder, matching: find.byType(Container)),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, GageTheme.primary);

      // Tap kirim
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(sentText, 'Halo driver');
    });

    test('GageAvatar.resolveSourceUrl normalizes Cloudflare relative media paths', () {
      expect(
        GageAvatar.resolveSourceUrl('/api/chat/media/driver-avatar.jpg'),
        '${GageApiClient.baseUrl}/api/chat/media/driver-avatar.jpg',
      );
      expect(
        GageAvatar.resolveSourceUrl('https://cdn.example.com/p.jpg'),
        'https://cdn.example.com/p.jpg',
      );
      expect(
        GageAvatar.resolveSourceUrl('assets/images/gage_icon.png'),
        'assets/images/gage_icon.png',
      );
    });
  });
}
