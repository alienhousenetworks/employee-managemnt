import 'package:flutter_test/flutter_test.dart';
import 'package:employee_hub_app/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Employee Hub shows the sign-in screen', (tester) async {
    await tester.pumpWidget(const EmployeeHubApp());
    expect(find.text('Your workday, in one place.'), findsOneWidget);
    expect(find.text('Sign in securely'), findsOneWidget);
  });
}
