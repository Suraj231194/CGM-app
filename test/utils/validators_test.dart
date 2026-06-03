import 'package:flutter_test/flutter_test.dart';
import 'package:optimus_cgm_flutter/utils/validators.dart';

void main() {
  group('Validators', () {
    group('required', () {
      test('returns error for null', () {
        expect(Validators.required(null), isNotNull);
      });

      test('returns error for empty string', () {
        expect(Validators.required(''), isNotNull);
      });

      test('returns error for whitespace only', () {
        expect(Validators.required('   '), isNotNull);
      });

      test('returns null for valid input', () {
        expect(Validators.required('hello'), isNull);
      });
    });

    group('email', () {
      test('returns error for null', () {
        expect(Validators.email(null), isNotNull);
      });

      test('returns error for empty', () {
        expect(Validators.email(''), isNotNull);
      });

      test('returns error for invalid format', () {
        expect(Validators.email('notanemail'), isNotNull);
        expect(Validators.email('missing@domain'), isNotNull);
      });

      test('returns null for valid email', () {
        expect(Validators.email('user@example.com'), isNull);
        expect(Validators.email('test+tag@domain.co.in'), isNull);
      });
    });

    group('password', () {
      test('returns error for null', () {
        expect(Validators.password(null), isNotNull);
      });

      test('returns error for too short', () {
        expect(Validators.password('abc'), isNotNull);
        expect(Validators.password('1234567'), isNotNull);
      });

      test('returns null for 8+ characters', () {
        expect(Validators.password('12345678'), isNull);
        expect(Validators.password('strongpass'), isNull);
      });
    });

    group('glucoseValue', () {
      test('returns error for null/empty', () {
        expect(Validators.glucoseValue(null), isNotNull);
        expect(Validators.glucoseValue(''), isNotNull);
      });

      test('returns error for non-numeric', () {
        expect(Validators.glucoseValue('abc'), isNotNull);
      });

      test('returns error for out of range', () {
        expect(Validators.glucoseValue('10'), isNotNull);
        expect(Validators.glucoseValue('600'), isNotNull);
      });

      test('returns null for valid range', () {
        expect(Validators.glucoseValue('70'), isNull);
        expect(Validators.glucoseValue('180'), isNull);
        expect(Validators.glucoseValue('500'), isNull);
      });
    });

    group('sensorSerialNumber', () {
      test('returns error for null/empty', () {
        expect(Validators.sensorSerialNumber(null), isNotNull);
        expect(Validators.sensorSerialNumber(''), isNotNull);
      });

      test('returns error for too short', () {
        expect(Validators.sensorSerialNumber('AB'), isNotNull);
      });

      test('returns null for valid serial', () {
        expect(Validators.sensorSerialNumber('OPT-CGM-001'), isNull);
      });
    });

    group('quantity', () {
      test('returns error for invalid', () {
        expect(Validators.quantity(null), isNotNull);
        expect(Validators.quantity('0'), isNotNull);
        expect(Validators.quantity('11'), isNotNull);
        expect(Validators.quantity('abc'), isNotNull);
      });

      test('returns null for valid', () {
        expect(Validators.quantity('1'), isNull);
        expect(Validators.quantity('5'), isNull);
        expect(Validators.quantity('10'), isNull);
      });
    });

    group('shippingAddress', () {
      test('returns error for too short', () {
        expect(Validators.shippingAddress('short'), isNotNull);
      });

      test('returns null for valid address', () {
        expect(
          Validators.shippingAddress('221 Health Park, Mumbai 400001'),
          isNull,
        );
      });
    });

    group('threshold', () {
      test('returns error for out of range', () {
        expect(Validators.threshold('30', min: 40, max: 100), isNotNull);
        expect(Validators.threshold('110', min: 40, max: 100), isNotNull);
      });

      test('returns null for valid', () {
        expect(Validators.threshold('70', min: 40, max: 100), isNull);
      });
    });
  });
}
