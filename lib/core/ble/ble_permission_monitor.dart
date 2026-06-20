import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/cgm_sdk_service.dart';
import '../lifecycle/app_lifecycle_observer.dart';
import 'ble_state_monitor.dart';

/// Detects BLE permission revocation by checking permissions on app resume.
class BlePermissionMonitor {
  BlePermissionMonitor._();

  static String? _lastKnownStatus;

  /// Check permissions and return whether they are still granted.
  /// Call this on app resume to detect revocation.
  static Future<BlePermissionCheckResult> checkPermissions() async {
    try {
      final status = await CgmSdkService.instance.requestBluetoothPermissions();
      final granted = status == 'granted' ||
          status == 'ios-managed' ||
          status == 'not-applicable';

      final wasGranted = _lastKnownStatus == 'granted' ||
          _lastKnownStatus == 'ios-managed' ||
          _lastKnownStatus == 'not-applicable';

      final revoked = _lastKnownStatus != null && wasGranted && !granted;
      _lastKnownStatus = status;

      return BlePermissionCheckResult(
        granted: granted,
        revoked: revoked,
        status: status,
      );
    } catch (e) {
      return const BlePermissionCheckResult(
        granted: false,
        revoked: false,
        status: 'error',
      );
    }
  }

  /// Update the last known status without triggering a permission request.
  static void updateStatus(String status) {
    _lastKnownStatus = status;
  }
}

class BlePermissionCheckResult {
  const BlePermissionCheckResult({
    required this.granted,
    required this.revoked,
    required this.status,
  });

  final bool granted;
  final bool revoked;
  final String status;
}

/// Provider that checks BLE permissions on app lifecycle resume.
final blePermissionWatcherProvider = Provider<void>((ref) {
  final supportedPlatform =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (kIsWeb || !supportedPlatform) return;

  ref.listen<AppLifecycleStatus>(appLifecycleProvider, (previous, next) {
    if (previous == AppLifecycleStatus.paused &&
        next == AppLifecycleStatus.active) {
      unawaited(_onResume(ref));
    }
  });
});

Future<void> _onResume(Ref ref) async {
  // Refresh BLE adapter state
  await ref.read(bleStateProvider.notifier).refresh();

  // Check if permissions were revoked while app was in background
  final result = await BlePermissionMonitor.checkPermissions();
  if (result.revoked) {
    if (kDebugMode) {
      debugPrint('[BlePermissionMonitor] Bluetooth permission was revoked');
    }
  }
}
