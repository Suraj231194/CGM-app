import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/cgm_sdk_service.dart';

/// Bluetooth adapter state.
enum BleAdapterState { unknown, poweredOn, poweredOff, unauthorized, resetting }

/// Monitors Bluetooth adapter state changes in real-time via native events.
class BleStateNotifier extends Notifier<BleAdapterState> {
  static const _channel = EventChannel('optimus_cgm/ble_state');

  StreamSubscription<dynamic>? _subscription;
  int _consecutiveFailures = 0;

  /// Number of consecutive scan/connection failures for BLE stack health.
  int get consecutiveFailures => _consecutiveFailures;

  @override
  BleAdapterState build() {
    final supportedPlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (kIsWeb || !supportedPlatform) {
      return BleAdapterState.unknown;
    }

    _subscription = _channel.receiveBroadcastStream().listen(
      _handleStateEvent,
      onError: (_) => state = BleAdapterState.unknown,
    );

    ref.onDispose(() => _subscription?.cancel());

    // Initial check via method channel
    unawaited(_checkInitialState());

    return BleAdapterState.unknown;
  }

  void _handleStateEvent(dynamic event) {
    if (event is Map) {
      final stateValue = event['state']?.toString().toLowerCase();
      state = _mapState(stateValue);
    } else if (event is String) {
      state = _mapState(event.toLowerCase());
    }
  }

  BleAdapterState _mapState(String? value) {
    return switch (value) {
      'poweredon' || 'on' || 'powered_on' => BleAdapterState.poweredOn,
      'poweredoff' || 'off' || 'powered_off' => BleAdapterState.poweredOff,
      'unauthorized' || 'denied' => BleAdapterState.unauthorized,
      'resetting' => BleAdapterState.resetting,
      _ => BleAdapterState.unknown,
    };
  }

  Future<void> _checkInitialState() async {
    try {
      final enabled = await CgmSdkService.instance.isBluetoothEnabled();
      state = enabled ? BleAdapterState.poweredOn : BleAdapterState.poweredOff;
    } catch (_) {
      state = BleAdapterState.unknown;
    }
  }

  /// Refresh the Bluetooth adapter state.
  Future<void> refresh() async {
    await _checkInitialState();
  }

  /// Record a scan/connection failure for BLE stack health tracking.
  void recordFailure() {
    _consecutiveFailures++;
  }

  /// Reset the failure counter (call on successful operation).
  void resetFailures() {
    _consecutiveFailures = 0;
  }

  /// Whether the BLE stack appears unhealthy (many consecutive failures).
  bool get isStackUnhealthy => _consecutiveFailures >= 5;
}

/// Provider for BLE adapter state.
final bleStateProvider =
    NotifierProvider<BleStateNotifier, BleAdapterState>(BleStateNotifier.new);

/// Convenience: true when Bluetooth is off.
final isBluetoothOffProvider = Provider<bool>((ref) {
  return ref.watch(bleStateProvider) == BleAdapterState.poweredOff;
});

/// Convenience: true when Bluetooth is powered on and ready.
final isBluetoothReadyProvider = Provider<bool>((ref) {
  return ref.watch(bleStateProvider) == BleAdapterState.poweredOn;
});

/// Convenience: true when BLE stack appears unhealthy.
final isBleStackUnhealthyProvider = Provider<bool>((ref) {
  // Watch the provider to trigger rebuild when state changes
  ref.watch(bleStateProvider);
  return ref.read(bleStateProvider.notifier).isStackUnhealthy;
});
