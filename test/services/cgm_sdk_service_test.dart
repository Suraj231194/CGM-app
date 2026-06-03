import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:optimus_cgm_flutter/services/cgm_sdk_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('optimus_cgm/sdk');
  late List<MethodCall> log;

  setUp(() {
    log = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          switch (call.method) {
            case 'connect':
              final sn = call.arguments['sn'] as String?;
              if (sn == 'VALID_SN') return true;
              if (sn == 'TIMEOUT_SN') return false;
              throw PlatformException(
                code: 'connect_failed',
                message: 'Sensor not found',
              );
            case 'isBluetoothEnabled':
              return true;
            case 'isConnected':
              return false;
            case 'requestBleAndBackgroundPermissions':
              return 'granted';
            case 'startHeartbeat':
              return null;
            case 'disconnect':
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('CgmSdkService.connect', () {
    test('returns true on successful connection', () async {
      final result = await CgmSdkService.instance.connect(sensorSn: 'VALID_SN');
      expect(result, isTrue);
      expect(log.last.method, 'connect');
      expect(log.last.arguments['sn'], 'VALID_SN');
    });

    test('returns false on timeout', () async {
      final result = await CgmSdkService.instance.connect(
        sensorSn: 'TIMEOUT_SN',
      );
      expect(result, isFalse);
    });

    test('returns false on PlatformException (connect_failed)', () async {
      final result = await CgmSdkService.instance.connect(sensorSn: 'UNKNOWN');
      expect(result, isFalse);
    });

    test('passes autoConnect and packageNum arguments', () async {
      await CgmSdkService.instance.connect(
        sensorSn: 'VALID_SN',
        autoConnect: true,
        packageNum: 5,
      );
      final call = log.last;
      expect(call.arguments['autoConnect'], isTrue);
      expect(call.arguments['packageNum'], 5);
    });
  });

  group('CgmSdkService.isBluetoothEnabled', () {
    test('returns true when bluetooth is on', () async {
      final result = await CgmSdkService.instance.isBluetoothEnabled();
      expect(result, isTrue);
    });

    test('returns true on PlatformException (graceful fallback)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'isBluetoothEnabled') {
              throw PlatformException(code: 'unavailable');
            }
            return null;
          });
      final result = await CgmSdkService.instance.isBluetoothEnabled();
      expect(result, isTrue);
    });
  });

  group('CgmSdkService.disconnect', () {
    test('calls disconnect method', () async {
      await CgmSdkService.instance.disconnect();
      expect(log.any((c) => c.method == 'disconnect'), isTrue);
    });
  });
}
