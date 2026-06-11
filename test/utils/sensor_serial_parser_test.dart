import 'package:flutter_test/flutter_test.dart';
import 'package:optimus_cgm_flutter/utils/sensor_serial_parser.dart';

void main() {
  group('parseSensorSerialFromQr', () {
    test('accepts a plain serial value', () {
      expect(parseSensorSerialFromQr(' abc12345 '), 'ABC12345');
    });

    test('extracts serial from URL query parameters', () {
      expect(
        parseSensorSerialFromQr(
          'https://device.optimus.test/activate?sensorSn=SN-9281',
        ),
        'SN-9281',
      );
    });

    test('extracts serial from labeled text', () {
      expect(parseSensorSerialFromQr('Device SN: cgm_445566'), 'CGM_445566');
    });

    test('extracts nested serial from JSON payload', () {
      expect(
        parseSensorSerialFromQr('{"device":{"serialNumber":"ab-9900"}}'),
        'AB-9900',
      );
    });

    test('extracts the printed SDK serial from parenthesized UDI data', () {
      expect(
        parseSensorSerialFromQr(
          '(01)06975022537510(11)260428(17)270428(21)66200387',
        ),
        'D115W66200387',
      );
    });

    test('extracts the printed SDK serial from compact GS1 data', () {
      expect(
        parseSensorSerialFromQr('010697502253751011260428172704282166200387'),
        'D115W66200387',
      );
    });

    test('extracts serial when SN label has only whitespace separator', () {
      expect(parseSensorSerialFromQr('SN D115W66200387'), 'D115W66200387');
    });

    test('uses the last serial-like URL path segment', () {
      expect(
        parseSensorSerialFromQr('https://example.test/sensor/CGM778899'),
        'CGM778899',
      );
    });

    test('rejects empty or generic QR payloads', () {
      expect(parseSensorSerialFromQr(''), isNull);
      expect(parseSensorSerialFromQr('sensor'), isNull);
    });
  });
}
