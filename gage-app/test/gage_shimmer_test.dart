import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

void main() {
  testWidgets('GageShimmer and Skeleton components render properly without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              GageSkeletonBox(width: 100, height: 20),
              GageSkeletonStatBox(),
              GageSkeletonRestoCard(),
              GageSkeletonProductCard(),
            ],
          ),
        ),
      ),
    );

    // Initial pump
    expect(find.byType(GageSkeletonBox), findsWidgets);
    expect(find.byType(GageSkeletonStatBox), findsOneWidget);
    expect(find.byType(GageSkeletonRestoCard), findsOneWidget);
    expect(find.byType(GageSkeletonProductCard), findsOneWidget);

    // Advance shimmer animation frame
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(GageShimmer), findsWidgets);
  });
}
