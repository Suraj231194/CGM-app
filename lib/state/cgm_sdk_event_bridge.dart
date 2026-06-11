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
  return (event.data['message'] ?? event.data['error'] ?? fallback).toString();
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
