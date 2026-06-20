import 'package:flutter/foundation.dart';

/// Debounce guard to prevent multiple simultaneous BLE connection attempts.
class BleConnectionGuard {
  BleConnectionGuard._();

  static bool _connecting = false;
  static DateTime? _lastAttempt;
  static const Duration _minInterval = Duration(seconds: 3);

  /// Whether a connection attempt is currently in progress.
  static bool get isConnecting => _connecting;

  /// Attempt to acquire the connection lock.
  /// Returns true if acquired, false if another connection is in progress
  /// or the minimum interval hasn't elapsed.
  static bool tryAcquire() {
    if (_connecting) {
      if (kDebugMode) {
        debugPrint('[BleConnectionGuard] Connection already in progress.');
      }
      return false;
    }

    final now = DateTime.now();
    if (_lastAttempt != null &&
        now.difference(_lastAttempt!) < _minInterval) {
      if (kDebugMode) {
        debugPrint('[BleConnectionGuard] Rate limited. Try again shortly.');
      }
      return false;
    }

    _connecting = true;
    _lastAttempt = now;
    return true;
  }

  /// Release the connection lock.
  static void release() {
    _connecting = false;
  }

  /// Force-release (e.g., on cancel or error).
  static void forceRelease() {
    _connecting = false;
  }
}

/// Tracks partial data sync progress to allow resuming after interruption.
class BleSyncCheckpoint {
  BleSyncCheckpoint._();

  static int _lastSyncedIndex = 0;
  static String? _sensorSn;

  /// The last successfully synced reading index.
  static int get lastSyncedIndex => _lastSyncedIndex;

  /// The sensor SN for the current sync session.
  static String? get sensorSn => _sensorSn;

  /// Update the checkpoint after successful data sync.
  static void update({
    required String sensorSn,
    required int lastIndex,
  }) {
    _sensorSn = sensorSn;
    _lastSyncedIndex = lastIndex;
    if (kDebugMode) {
      debugPrint(
        '[BleSyncCheckpoint] Updated: sn=$sensorSn, index=$lastIndex',
      );
    }
  }

  /// Get the resume index for a given sensor.
  /// Returns the last synced index + 1, or 1 if no checkpoint exists.
  static int resumeIndex(String sensorSn) {
    if (_sensorSn == sensorSn && _lastSyncedIndex > 0) {
      return _lastSyncedIndex + 1;
    }
    return 1;
  }

  /// Reset checkpoint (e.g., when sensor changes).
  static void reset() {
    _lastSyncedIndex = 0;
    _sensorSn = null;
  }

  /// Whether we have a valid checkpoint for resume.
  static bool hasCheckpoint(String sensorSn) {
    return _sensorSn == sensorSn && _lastSyncedIndex > 0;
  }
}
