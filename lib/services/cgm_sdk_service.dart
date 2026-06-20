import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CgmSdkService {
  CgmSdkService._();

  static final CgmSdkService instance = CgmSdkService._();

  static const _methodChannel = MethodChannel('optimus_cgm/sdk');
  static const _eventChannel = EventChannel('optimus_cgm/sdk_events');

  Stream<CgmSdkEvent>? _events;

  Stream<CgmSdkEvent> get events {
    return _events ??= _eventChannel.receiveBroadcastStream().map((event) {
      final payload = Map<String, dynamic>.from(event as Map);
      return CgmSdkEvent(
        type: payload['type'] as String? ?? 'unknown',
        data: Map<String, dynamic>.from(payload['data'] as Map? ?? {}),
      );
    });
  }

  Future<bool> auth({required String appId, required String appSecret}) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('auth', {
        'appId': appId,
        'appSecret': appSecret,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[CgmSdk] auth PlatformException: ${e.message}');
      return false;
    }
  }

  Future<bool> checkAuthorized() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('checkAuthorized');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[CgmSdk] checkAuthorized PlatformException: ${e.message}');
      return false;
    }
  }

  Future<String> requestBluetoothPermissions() async {
    try {
      final result = await _methodChannel.invokeMethod<String>(
        'requestBluetoothPermissions',
      );
      return result ?? 'unknown';
    } on PlatformException catch (e) {
      debugPrint(
        '[CgmSdk] requestBluetoothPermissions PlatformException: ${e.message}',
      );
      return 'error';
    }
  }

  Future<String> requestCameraPermission() async {
    try {
      final result = await _methodChannel.invokeMethod<String>(
        'requestCameraPermission',
      );
      return result ?? 'unknown';
    } on PlatformException catch (e) {
      debugPrint(
        '[CgmSdk] requestCameraPermission PlatformException: ${e.message}',
      );
      return 'error';
    }
  }

  Future<void> openAppPermissionSettings() async {
    try {
      await _methodChannel.invokeMethod<void>('openAppPermissionSettings');
    } on PlatformException catch (e) {
      debugPrint(
        '[CgmSdk] openAppPermissionSettings PlatformException: ${e.message}',
      );
    }
  }

  Future<void> openBluetoothSettings() async {
    try {
      await _methodChannel.invokeMethod<void>('openBluetoothSettings');
    } on PlatformException catch (e) {
      debugPrint(
        '[CgmSdk] openBluetoothSettings PlatformException: ${e.message}',
      );
      await openAppPermissionSettings();
    }
  }

  Future<String> requestBleAndBackgroundPermissions() async {
    try {
      final result = await _methodChannel.invokeMethod<String>(
        'requestBleAndBackgroundPermissions',
      );
      return result ?? 'unknown';
    } on PlatformException catch (e) {
      debugPrint(
        '[CgmSdk] requestBleAndBackgroundPermissions PlatformException: ${e.message}',
      );
      return 'error';
    }
  }

  Future<String> requestIgnoreBatteryOptimization() async {
    try {
      final result = await _methodChannel.invokeMethod<String>(
        'requestIgnoreBatteryOptimization',
      );
      return result ?? 'unknown';
    } on PlatformException catch (e) {
      debugPrint(
        '[CgmSdk] requestIgnoreBatteryOptimization PlatformException: ${e.message}',
      );
      return 'error';
    }
  }

  Future<bool> connect({
    required String sensorSn,
    bool autoConnect = false,
    int packageNum = 0,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('connect', {
        'sn': sensorSn,
        'autoConnect': autoConnect,
        'packageNum': packageNum,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[CgmSdk] connect PlatformException: ${e.message}');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod<void>('disconnect');
    } on PlatformException catch (e) {
      debugPrint('[CgmSdk] disconnect PlatformException: ${e.message}');
    }
  }

  Future<bool> isConnected() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isConnected');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[CgmSdk] isConnected PlatformException: ${e.message}');
      return false;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'isBluetoothEnabled',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[CgmSdk] isBluetoothEnabled PlatformException: ${e.message}');
      // If method not implemented, assume BT is on (let the SDK handle it)
      return true;
    }
  }

  Future<List<CgmBloodSugarReading>> getHistoryFromIndexStart({
    required String sensorSn,
    int indexStart = 1,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<List<dynamic>>(
        'getHistoryFromIndexStart',
        {'sn': sensorSn, 'indexStart': indexStart},
      );
      return _readingsFromResult(result);
    } on PlatformException catch (e) {
      debugPrint(
        '[CgmSdk] getHistoryFromIndexStart PlatformException: ${e.message}',
      );
      return const [];
    }
  }

  Future<List<CgmBloodSugarReading>> getHistoryFromTimeRange({
    required String sensorSn,
    required int startTimeSeconds,
    required int endTimeSeconds,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<List<dynamic>>(
        'getHistoryFromTimeRange',
        {
          'sn': sensorSn,
          'startTime': startTimeSeconds,
          'endTime': endTimeSeconds,
        },
      );
      return _readingsFromResult(result);
    } on PlatformException catch (e) {
      debugPrint(
        '[CgmSdk] getHistoryFromTimeRange PlatformException: ${e.message}',
      );
      return const [];
    }
  }

  Future<void> startHeartbeat() async {
    try {
      await _methodChannel.invokeMethod<void>('startHeartbeat');
    } on PlatformException catch (e) {
      debugPrint('[CgmSdk] startHeartbeat PlatformException: ${e.message}');
    }
  }

  Future<void> stopHeartbeat() async {
    try {
      await _methodChannel.invokeMethod<void>('stopHeartbeat');
    } on PlatformException catch (e) {
      debugPrint('[CgmSdk] stopHeartbeat PlatformException: ${e.message}');
    }
  }

  /// Check if Bluetooth permissions are currently granted without prompting.
  Future<String> checkBluetoothPermissions() async {
    try {
      final result = await _methodChannel.invokeMethod<String>(
        'checkBluetoothPermissions',
      );
      return result ?? 'unknown';
    } on PlatformException catch (e) {
      debugPrint(
        '[CgmSdk] checkBluetoothPermissions PlatformException: ${e.message}',
      );
      return 'error';
    }
  }

  List<CgmBloodSugarReading> _readingsFromResult(List<dynamic>? result) {
    return result
            ?.map((item) => CgmBloodSugarReading.fromMap(Map.from(item as Map)))
            .toList() ??
        const [];
  }
}

class CgmSdkEvent {
  const CgmSdkEvent({required this.type, required this.data});

  final String type;
  final Map<String, dynamic> data;
}

class CgmBloodSugarReading {
  const CgmBloodSugarReading({
    required this.originalBloodSugar,
    required this.processedBloodSugar,
    required this.createTime,
    required this.timeOffset,
    required this.trend,
    this.connectCode,
    this.measurementStatus,
    this.current,
    this.temperature,
    this.batteryVoltage,
  });

  final double originalBloodSugar;
  final double processedBloodSugar;
  final int createTime;
  final int timeOffset;
  final int trend;
  final String? connectCode;
  final int? measurementStatus;
  final double? current;
  final double? temperature;
  final double? batteryVoltage;

  factory CgmBloodSugarReading.fromMap(Map<dynamic, dynamic> map) {
    return CgmBloodSugarReading(
      originalBloodSugar: _doubleValue(map['originalBloodSugar']),
      processedBloodSugar: _doubleValue(map['processedBloodSugar']),
      createTime: _intValue(map['createTime']),
      timeOffset: _intValue(map['timeOffset']),
      trend: _intValue(map['trend']),
      connectCode: map['connectCode'] as String?,
      measurementStatus: map['measurementStatus'] as int?,
      current: _nullableDoubleValue(map['current']),
      temperature: _nullableDoubleValue(map['temperature']),
      batteryVoltage: _nullableDoubleValue(map['batteryVoltage']),
    );
  }

  static double _doubleValue(Object? value) {
    return value is num ? value.toDouble() : 0;
  }

  static double? _nullableDoubleValue(Object? value) {
    return value is num ? value.toDouble() : null;
  }

  static int _intValue(Object? value) {
    return value is num ? value.toInt() : 0;
  }
}
