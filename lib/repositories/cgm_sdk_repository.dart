import 'dart:async';

import 'package:flutter/services.dart';

import '../core/error/app_error_handler.dart';
import '../core/network/retry_policy.dart';
import '../services/cgm_sdk_service.dart';

/// A safe wrapper around [CgmSdkService] that catches [PlatformException]
/// and provides retry/timeout logic for BLE operations.
///
/// This does NOT replace the existing [CgmSdkService] but wraps it for
/// safer usage from the state layer.
class CgmSdkRepository {
  CgmSdkRepository({required CgmSdkServiceContract sdk})
    : _sdk = _validatedSdk(sdk);

  final CgmSdkServiceContract _sdk;

  final RetryPolicy _retryPolicy = RetryPolicy.defaultPolicy;

  static CgmSdkServiceContract _validatedSdk(CgmSdkServiceContract sdk) => sdk;

  /// Authorize the CGM SDK with retry and error handling.
  Future<({bool success, String? error})> authorize({
    required String appId,
    required String appSecret,
  }) async {
    try {
      final result = await _retryPolicy.execute(() async {
        final success = await withTimeout(
          () => _sdk.auth(appId: appId, appSecret: appSecret),
        );
        if (!success) {
          throw const CgmSdkOperationFailed('SDK authorization failed');
        }
        return success;
      }, shouldRetry: _isRetryableError);
      return (success: result, error: null);
    } on PlatformException catch (e) {
      AppErrorHandler.report(e, null, 'CgmSdkRepository.authorize');
      return (success: false, error: e.message ?? 'SDK authorization failed');
    } on TimeoutException catch (e) {
      AppErrorHandler.report(e, null, 'CgmSdkRepository.authorize');
      return (success: false, error: 'Authorization timed out');
    } catch (e) {
      AppErrorHandler.report(e, null, 'CgmSdkRepository.authorize');
      return (success: false, error: e.toString());
    }
  }

  /// Check if already authorized.
  Future<bool> checkAuthorized() async {
    try {
      return await withTimeout(_sdk.checkAuthorized);
    } on PlatformException catch (e) {
      AppErrorHandler.report(e, null, 'CgmSdkRepository.checkAuthorized');
      return false;
    } catch (e) {
      AppErrorHandler.report(e, null, 'CgmSdkRepository.checkAuthorized');
      return false;
    }
  }

  /// Connect to sensor with retry.
  Future<({bool success, String? error})> connect({
    required String sensorSn,
    bool autoConnect = false,
    int packageNum = 0,
  }) async {
    try {
      final result = await _retryPolicy.execute(() async {
        final success = await withTimeout(
          () => _sdk.connect(
            sensorSn: sensorSn,
            autoConnect: autoConnect,
            packageNum: packageNum,
          ),
          timeout: const Duration(seconds: 45),
        );
        if (!success) {
          throw const CgmSdkOperationFailed('Sensor connection failed');
        }
        return success;
      }, shouldRetry: _isRetryableError);
      return (success: result, error: null);
    } on PlatformException catch (e) {
      AppErrorHandler.report(e, null, 'CgmSdkRepository.connect');
      return (success: false, error: e.message ?? 'Connection failed');
    } on TimeoutException catch (e) {
      AppErrorHandler.report(e, null, 'CgmSdkRepository.connect');
      return (success: false, error: 'Connection timed out');
    } on CgmSdkOperationFailed catch (e) {
      AppErrorHandler.report(e, null, 'CgmSdkRepository.connect');
      return (success: false, error: e.message);
    } catch (e) {
      AppErrorHandler.report(e, null, 'CgmSdkRepository.connect');
      return (success: false, error: e.toString());
    }
  }

  /// Disconnect from sensor.
  Future<void> disconnect() async {
    try {
      await withTimeout(_sdk.disconnect);
    } on PlatformException catch (e) {
      AppErrorHandler.report(e, null, 'CgmSdkRepository.disconnect');
    } catch (e) {
      AppErrorHandler.report(e, null, 'CgmSdkRepository.disconnect');
    }
  }

  /// Request Bluetooth permissions.
  Future<String> requestBluetoothPermissions() async {
    try {
      return await _sdk.requestBluetoothPermissions();
    } on PlatformException catch (e) {
      AppErrorHandler.report(
        e,
        null,
        'CgmSdkRepository.requestBluetoothPermissions',
      );
      return 'error: ${e.message}';
    } catch (e) {
      AppErrorHandler.report(
        e,
        null,
        'CgmSdkRepository.requestBluetoothPermissions',
      );
      return 'error: $e';
    }
  }

  /// Request BLE and background permissions.
  Future<String> requestBleAndBackgroundPermissions() async {
    try {
      return await _sdk.requestBleAndBackgroundPermissions();
    } on PlatformException catch (e) {
      AppErrorHandler.report(
        e,
        null,
        'CgmSdkRepository.requestBleAndBackgroundPermissions',
      );
      return 'error: ${e.message}';
    } catch (e) {
      AppErrorHandler.report(
        e,
        null,
        'CgmSdkRepository.requestBleAndBackgroundPermissions',
      );
      return 'error: $e';
    }
  }

  /// Request ignore battery optimization.
  Future<String> requestIgnoreBatteryOptimization() async {
    try {
      return await _sdk.requestIgnoreBatteryOptimization();
    } on PlatformException catch (e) {
      AppErrorHandler.report(
        e,
        null,
        'CgmSdkRepository.requestIgnoreBatteryOptimization',
      );
      return 'error: ${e.message}';
    } catch (e) {
      AppErrorHandler.report(
        e,
        null,
        'CgmSdkRepository.requestIgnoreBatteryOptimization',
      );
      return 'error: $e';
    }
  }

  /// Check connection status.
  Future<bool> isConnected() async {
    try {
      return await withTimeout(_sdk.isConnected);
    } on PlatformException catch (e) {
      AppErrorHandler.report(e, null, 'CgmSdkRepository.isConnected');
      return false;
    } catch (e) {
      AppErrorHandler.report(e, null, 'CgmSdkRepository.isConnected');
      return false;
    }
  }

  /// Get event stream safely.
  Stream<CgmSdkEventData> get events => _sdk.eventStream;

  bool _isRetryableError(Object error) {
    if (error is PlatformException) {
      // Don't retry auth errors, invalid arguments, or concurrent connect guard.
      return error.code != 'INVALID_ARGUMENT' &&
          error.code != 'AUTH_FAILED' &&
          error.code != 'connect_in_progress' &&
          error.code != 'bluetooth_permission_required' &&
          error.code != 'bluetooth_disabled';
    }
    if (error is TimeoutException) return true;
    if (error is CgmSdkOperationFailed) return true;
    return false;
  }
}

class CgmSdkOperationFailed implements Exception {
  const CgmSdkOperationFailed(this.message);

  final String message;

  @override
  String toString() => message;
}

class CgmSdkServiceAdapter implements CgmSdkServiceContract {
  CgmSdkServiceAdapter(this._service);

  final CgmSdkService _service;

  @override
  Future<bool> auth({required String appId, required String appSecret}) {
    return _service.auth(appId: appId, appSecret: appSecret);
  }

  @override
  Future<bool> checkAuthorized() => _service.checkAuthorized();

  @override
  Future<bool> connect({
    required String sensorSn,
    bool autoConnect = false,
    int packageNum = 0,
  }) {
    return _service.connect(
      sensorSn: sensorSn,
      autoConnect: autoConnect,
      packageNum: packageNum,
    );
  }

  @override
  Future<void> disconnect() => _service.disconnect();

  @override
  Stream<CgmSdkEventData> get eventStream {
    return _service.events.map(
      (event) => CgmSdkEventData(type: event.type, data: event.data),
    );
  }

  @override
  Future<bool> isConnected() => _service.isConnected();

  @override
  Future<String> requestBleAndBackgroundPermissions() {
    return _service.requestBleAndBackgroundPermissions();
  }

  @override
  Future<String> requestBluetoothPermissions() {
    return _service.requestBluetoothPermissions();
  }

  @override
  Future<String> requestIgnoreBatteryOptimization() {
    return _service.requestIgnoreBatteryOptimization();
  }
}

/// Abstract contract for CgmSdkService to allow mocking in tests.
abstract class CgmSdkServiceContract {
  Future<bool> auth({required String appId, required String appSecret});
  Future<bool> checkAuthorized();
  Future<String> requestBluetoothPermissions();
  Future<String> requestBleAndBackgroundPermissions();
  Future<String> requestIgnoreBatteryOptimization();
  Future<bool> connect({
    required String sensorSn,
    bool autoConnect = false,
    int packageNum = 0,
  });
  Future<void> disconnect();
  Future<bool> isConnected();
  Stream<CgmSdkEventData> get eventStream;
}

/// Minimal event data structure for the repository layer.
class CgmSdkEventData {
  const CgmSdkEventData({required this.type, required this.data});

  final String type;
  final Map<String, dynamic> data;
}
