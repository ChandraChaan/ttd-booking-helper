import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ttd_booking_helper/main.dart';
import 'package:ttd_booking_helper/src/model.dart';
import 'package:ttd_booking_helper/src/state.dart';

void main() {
  testWidgets('add a devotee, set release, see countdown; it is saved', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = AppState();
    await state.load();
    final now = DateTime(2026, 11, 24, 9, 0);
    await tester.pumpWidget(TtdApp(state: state, clock: () => now));
    await tester.pump();
    expect(find.text('Not set'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Name as on ID'),
      'LAKSHMI DEVI',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Age'), '54');
    await tester.tap(find.text('Female'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Aadhaar number'),
      '2345 6789 0123',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('LAKSHMI DEVI'), findsOneWidget);
    expect(find.text('54 · Female · Aadhaar •••• 0123'), findsOneWidget);

    state.setRelease(DateTime(2026, 11, 24, 10, 0));
    await tester.pump();
    expect(find.text('01:00:00'), findsOneWidget);
    expect(find.text('QUOTA OPENS 24 NOV, 10:00 AM'), findsOneWidget);

    final again = AppState();
    await again.load();
    expect(again.devotees.single.gender, Gender.female);
    expect(again.releaseAt, DateTime(2026, 11, 24, 10, 0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wrong Aadhaar number is refused with a reason', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(TtdApp(state: state));
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Name as on ID'),
      'RAVI',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Age'), '27');
    await tester.enterText(
      find.widgetWithText(TextField, 'Aadhaar number'),
      '1234',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Aadhaar has 12 digits.'), findsOneWidget);
    expect(state.devotees, isEmpty);
  });
}
