import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/features/profile/presentation/edit_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('EditProfileScreen renders form fields and avatar', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'gage_primary_address': 'Dusun Tubokarto RT 02/RW 01, Tubokarto, Pracimantoro',
    });

    final authProvider = AuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: const MaterialApp(
          home: EditProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar Title
    expect(find.text('Ubah Profil'), findsOneWidget);

    // Verify Form Labels
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Nomor WhatsApp'), findsOneWidget);
    expect(find.text('Alamat Email'), findsOneWidget);
    expect(find.text('Alamat Pengantaran Utama'), findsOneWidget);

    // Verify Save Button
    expect(find.text('Simpan Perubahan'), findsOneWidget);

    // Verify Avatar button
    expect(find.text('Ganti Foto Profil'), findsOneWidget);
  });
}
