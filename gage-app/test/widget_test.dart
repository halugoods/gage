import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/main.dart';

void main() {
  testWidgets('Gage App Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const GageApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('GAGE'), findsWidgets);
  });
}
