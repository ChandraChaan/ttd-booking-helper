import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ttd_booking_helper/src/model.dart';
import 'package:ttd_booking_helper/src/state.dart';

Devotee d({String idType = 'Aadhaar', String idNumber = '2345 6789 0123'}) =>
    Devotee(
      id: '1',
      name: 'VENKATA REDDY',
      age: 58,
      gender: Gender.male,
      idType: idType,
      idNumber: idNumber,
    );

void main() {
  test('ID is masked to the last four', () {
    expect(d().maskedId, '•••• 0123');
    expect(d(idType: 'Passport', idNumber: 'K1234567').maskedId, '•••• 4567');
  });

  test('Aadhaar must be 12 digits not starting with 0 or 1', () {
    expect(d().idProblem, isNull);
    expect(d(idNumber: '1234 5678 9012').idProblem, isNotNull);
    expect(d(idNumber: '2345 6789').idProblem, isNotNull);
    expect(d(idType: 'Passport', idNumber: 'K1234567').idProblem, isNull);
    expect(d(idType: 'Passport', idNumber: '').idProblem, 'ID number missing');
  });

  test('values are typed without spaces in the ID', () {
    expect(d().valueOf(DevoteeField.idNumber), '234567890123');
    expect(d().valueOf(DevoteeField.age), '58');
    expect(d().valueOf(DevoteeField.gender), 'Male');
  });

  test('countdown', () {
    final now = DateTime(2026, 11, 24, 9, 55, 0);
    expect(countdown(now, DateTime(2026, 11, 24, 10)), '00:05:00');
    expect(countdown(now, DateTime(2026, 11, 26, 10, 0, 9)), '2 d 00:05:09');
    expect(countdown(now, DateTime(2026, 11, 24, 9, 0)), 'Open now');
  });

  test('payment intent links become links the UPI app can open', () {
    expect(
      intentToUri(
        'intent://pay?pa=ttd@sbi&pn=TTD&am=600.00&cu=INR#Intent;scheme=upi;package=com.phonepe.app;end',
      ).toString(),
      'upi://pay?pa=ttd@sbi&pn=TTD&am=600.00&cu=INR',
    );
    expect(intentToUri('https://example.com'), isNull);
    expect(intentToUri('intent://x#Intent;package=a;end'), isNull);
  });

  test('which links leave the in-app browser', () {
    expect(opensOutside(Uri.parse('upi://pay?pa=a@b')), isTrue);
    expect(opensOutside(Uri.parse('tel:155257')), isTrue);
    expect(
      opensOutside(Uri.parse('https://ttdevasthanams.ap.gov.in/')),
      isFalse,
    );
    expect(opensOutside(Uri.parse('about:blank')), isFalse);
  });

  test('devotee survives JSON', () {
    final back = Devotee.fromJson(
      jsonDecode(jsonEncode(d().toJson())) as Map<String, dynamic>,
    );
    expect(
      (back.name, back.age, back.gender, back.idNumber),
      ('VENKATA REDDY', 58, Gender.male, '2345 6789 0123'),
    );
  });

  test('reorder moves a devotee to the slot the list reports', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    for (final n in ['A', 'B', 'C']) {
      s.upsert(
        Devotee(
          id: n,
          name: n,
          age: 30,
          gender: Gender.male,
          idType: 'Passport',
          idNumber: 'X1',
        ),
      );
    }
    s.reorder(0, 2); // A dragged below C: after removal the new index is 2
    expect(s.devotees.map((d) => d.name), ['B', 'C', 'A']);
    s.reorder(2, 0);
    expect(s.devotees.map((d) => d.name), ['A', 'B', 'C']);
  });
}
