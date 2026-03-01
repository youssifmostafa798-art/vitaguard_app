import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitaguard_app/onbording/ui/onbording_screen/onboarding_screen.dart';

import 'package:vitaguard_app/main.dart';

void main() {
  testWidgets('App boots to onboarding screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
