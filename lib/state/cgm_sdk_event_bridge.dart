import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cgm_sdk_service.dart';
import 'app_state.dart';

final cgmSdkEventBridgeProvider = Provider<void>((ref) {
  final supportedPlatform =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (kIsWeb || !supportedPlatform) {
    return;
  }

  final service = CgmSdkService.instance;
  final controller = ref.read(appControllerProvider.notifier);
  final subscription = service.events.listen(
    (event) => _handleSdkEvent(event, controller),
    onError: (Object error, StackTrace stackTrace) {
      controller.setCgmConnectionState(
        status: 'SDK event stream error',
        connected: false,
        connecting: false,
        error: error.toString(),
      );
    },
  );

  unawaited(
    service.checkAuthorized().then(
      (authorized) => controller.setCgmAuthState(authorized: authorized),
      onError: (_) {},
    ),
  );

  // Restore connection status on startup (#13)
  unawaited(
    service.isConnected().then((isConn) {
      if (isConn) {
        controller.setCgmConnectionState(
          status: 'Sensor connected',
          connected: true,
          connecting: false,
        );
      }
    }, onError: (_) {}),
  );

  ref.onDispose(subscription.cancel);
});

void _handleSdkEvent(CgmSdkEvent event, AppController controller) {
  switch (event.type) {
    case 'ready':
      controller.addCgmLog(
        _message(event, fallback: 'Native CGM bridge is ready.'),
      );
    case 'authSuccess':
      controller.setCgmAuthState(authorized: true);
    case 'authError':
      controller.setCgmAuthState(
        authorized: false,
        error: _message(event, fallback: 'SDK authorization failed.'),
      );
    case 'permissions':
      controller.addCgmLog(
        'Permissions: ${event.data['status'] ?? event.data['result'] ?? 'updated'}.',
      );
    case 'connection':
      final status = event.data['status']?.toString();
      final connected = _isConnectedEvent(event);
      final failed = _isFailedConnectionStatus(status);
      final message = _message(
        event,
        fallback: _connectionFallback(status, connected: connected),
      );
      controller.setCgmConnectionState(
        status: message,
        connected: connected,
        connecting: _isConnectingStatus(status),
        sensorSn: event.data['sn'] as String?,
        error: failed ? message : null,
      );
    case 'heartbeat':
      final status = event.data['status']?.toString().toLowerCase();
      final started = event.data['enabled'] == true || status == 'start';
      controller.addCgmLog('Heartbeat ${started ? 'started' : 'stopped'}.');
    case 'bindStep':
      controller.addCgmLog('Bind step: ${event.data['step'] ?? 'updated'}.');
    case 'syncProgress':
      final progress = event.data['progress'];
      if (progress is num) {
        controller.setCgmSyncProgress(progress.toInt());
      }
    case 'deviceInfo':
      controller.applyCgmDeviceInfo(event.data);
    case 'glucoseData':
      final rawReadings = event.data['readings'];
      if (rawReadings is List) {
        controller.applyCgmReadings(
          rawReadings
              .whereType<Map>()
              .map(CgmBloodSugarReading.fromMap)
              .toList(),
        );
      }
    case 'sdkError':
    case 'scanFailed':
      controller.setCgmConnectionState(
        status: _message(event, fallback: 'Sensor connection failed.'),
        connected: false,
        connecting: false,
        error: _message(event, fallback: 'Sensor connection failed.'),
      );
    case 'log':
      controller.addCgmLog(_message(event, fallback: 'SDK log received.'));
    default:
      controller.addCgmLog('SDK event: ${event.type}.');
  }
}

String _message(CgmSdkEvent event, {required String fallback}) {
  final mappedMessage =
      _sdkCodeMessage(event.data['code']) ??
      _sdkNameMessage(event.data['name']);
  final rawMessage = event.data['message'] ?? event.data['error'];

  if (rawMessage == null) return mappedMessage ?? fallback;

  final message = rawMessage.toString().trim();
  if (message.isEmpty) return mappedMessage ?? fallback;

  if (mappedMessage != null && _shouldReplaceSdkMessage(message)) {
    return mappedMessage;
  }

  return message;
}

String? _sdkCodeMessage(Object? code) {
  final value = code is num
      ? code.toInt()
      : int.tryParse(code?.toString() ?? '');
  return switch (value) {
    400001 => 'Network error while contacting the CGM service.',
    400002 => 'The CGM service response could not be parsed.',
    400003 => 'The CGM service returned invalid data.',
    400004 => 'A required CGM SDK parameter is missing.',
    400005 => 'CGM SDK signature verification failed.',
    400006 => 'The requested CGM record was not found.',
    400007 => 'CGM SDK token was not found.',
    400008 => 'CGM SDK token expired. Please authorize again.',
    500001 => 'Sensor serial number is missing.',
    500002 =>
      'Sensor not found. Keep the phone close to the sensor and try again.',
    500003 => 'Sensor has expired.',
    500004 => 'Bluetooth connection failed.',
    500005 => 'Bluetooth service discovery failed.',
    500006 => 'Bluetooth characteristic discovery failed.',
    500007 => 'Bluetooth communication failed.',
    _ => null,
  };
}

String? _sdkNameMessage(Object? name) {
  final value = name?.toString().toLowerCase();
  if (value == null || value.isEmpty) return null;

  if (value.contains('nodevice')) {
    return 'Sensor not found. Keep the phone close to the sensor and try again.';
  }
  if (value.contains('expired')) return 'Sensor has expired.';
  if (value.contains('sn')) return 'Sensor serial number is missing.';
  if (value.contains('discoverservices')) {
    return 'Bluetooth service discovery failed.';
  }
  if (value.contains('discovercharacteristics')) {
    return 'Bluetooth characteristic discovery failed.';
  }
  if (value.contains('ble') || value.contains('connect')) {
    return 'Bluetooth connection failed.';
  }
  if (value.contains('token')) {
    return 'CGM SDK token error. Please authorize again.';
  }
  if (value.contains('sign')) {
    return 'CGM SDK signature verification failed.';
  }
  if (value.contains('network') || value.contains('api')) {
    return 'Network error while contacting the CGM service.';
  }
  if (value.contains('param')) {
    return 'A required CGM SDK parameter is missing.';
  }
  return null;
}

bool _shouldReplaceSdkMessage(String message) {
  final lower = message.toLowerCase();
  return _containsCjk(message) ||
      _looksMojibake(message) ||
      lower.contains('operation couldn') ||
      lower.contains('operation could not') ||
      lower.contains('localized description');
}

bool _containsCjk(String value) {
  return value.runes.any((codePoint) {
    return (codePoint >= 0x3400 && codePoint <= 0x4DBF) ||
        (codePoint >= 0x4E00 && codePoint <= 0x9FFF) ||
        (codePoint >= 0xF900 && codePoint <= 0xFAFF);
  });
}

bool _looksMojibake(String value) {
  const markerCodePoints = {
    0x00C2, // Latin capital A with circumflex.
    0x00C3, // Latin capital A with tilde.
    0x00E5, // Latin small a with ring above.
    0x00E6, // Latin small ae.
    0x00E7, // Latin small c with cedilla.
    0x00E8, // Latin small e with grave.
    0x00EF, // Latin small i with diaeresis.
    0x0153, // Latin small oe.
    0x20AC, // Euro sign, common in mojibake fragments.
    0xFFFD, // Replacement character.
  };
  return value.runes.any(markerCodePoints.contains);
}

bool _isConnectedEvent(CgmSdkEvent event) {
  final connected = event.data['connected'];
  if (connected is bool) {
    return connected;
  }

  final status = event.data['status']?.toString().toLowerCase();
  return status == 'connected' || status == 'reconnected';
}

bool _isConnectingStatus(String? status) {
  final normalized = status?.toLowerCase();
  return normalized == 'scanning' || normalized == 'connecting';
}

bool _isFailedConnectionStatus(String? status) {
  final normalized = status?.toLowerCase();
  return normalized == 'failed' ||
      normalized == 'timeout' ||
      normalized == 'reconnectfailed';
}

String _connectionFallback(String? status, {required bool connected}) {
  switch (status?.toLowerCase()) {
    case 'scanning':
      return 'Scanning for sensor.';
    case 'connected':
      return 'Sensor connected.';
    case 'reconnected':
      return 'Sensor reconnected.';
    case 'disconnected':
      return 'Sensor disconnected.';
    case 'timeout':
      return 'Sensor connection timed out.';
    case 'failed':
    case 'reconnectfailed':
      return 'Sensor connection failed.';
    default:
      return connected ? 'Sensor connected.' : 'Sensor disconnected.';
  }
}
