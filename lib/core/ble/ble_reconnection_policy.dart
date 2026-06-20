import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/cgm_sdk_service.dart';
import '../env/app_environment.dart';
import '../error/app_error_handler.dart';
import 'ble_state_monitor.dart';

/// Configurable BLE reconnection policy with exponential backoff.
class BleReconnectionPolicy {
  BleReconnectionPolicy({
    this.maxAttempts = 10,
    this.initialDelay = const Duration(seconds: 5),
    this.maxDelay = const Duration(minutes: 2),
    this.backoffMultiplier = 1.5,
  });

  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;

  int _currentAttempt = 0;
  Duration _currentDelay = Duration.zero;
  Timer? _reconnectTimer;
  bool _active = false;

  /// Whether a reconnection cycle is currently active.
  bool get isActive => _active;

  /// Current attempt number (1-based).
  int get currentAttempt => _currentAttempt;

  /// Start the reconnection cycle.
  void start({
    required Future<bool> Function() reconnectAction,
    VoidCallback? onAttempt,
    VoidCallback? onSuccess,
    void Function(int attempt, int maxAttempts)? onFailure,
    VoidCallback? onExhausted,
  }) {
    if (_active) return;
    _active = true;
    _currentAttempt = 0;
    _currentDelay = initialDelay;
    _scheduleNext(
      reconnectAction: reconnectAction,
      onAttempt: onAttempt,
      onSuccess: onSuccess,
      onFailure: onFailure,
      onExhausted: onExhausted,
    );
  }

  /// Cancel any pending reconnection attempt.
  void cancel() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _active = false;
    _currentAttempt = 0;
    _currentDelay = initialDelay;
  }

  void _scheduleNext({
    required Future<bool> Function() reconnectAction,
    VoidCallback? onAttempt,
    VoidCallback? onSuccess,
    void Function(int attempt, int maxAttempts)? onFailure,
    VoidCallback? onExhausted,
  }) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_currentDelay, () async {
      _currentAttempt++;
      onAttempt?.call();

      if (kDebugMode) {
        debugPrint(
          '[BleReconnect] Attempt $_currentAttempt/$maxAttempts '
          '(delay: ${_currentDelay.inSeconds}s)',
        );
      }

      try {
        final success = await reconnectAction();
        if (success) {
          _active = false;
          _currentAttempt = 0;
          _currentDelay = initialDelay;
          onSuccess?.call();
          return;
        }
      } catch (e) {
        AppErrorHandler.report(e, null, 'BleReconnectionPolicy');
      }

      onFailure?.call(_currentAttempt, maxAttempts);

      if (_currentAttempt >= maxAttempts) {
        _active = false;
        onExhausted?.call();
        return;
      }

      // Exponential backoff
      _currentDelay = Duration(
        milliseconds: (_currentDelay.inMilliseconds * backoffMultiplier)
            .round()
            .clamp(0, maxDelay.inMilliseconds),
      );
      _scheduleNext(
        reconnectAction: reconnectAction,
        onAttempt: onAttempt,
        onSuccess: onSuccess,
        onFailure: onFailure,
        onExhausted: onExhausted,
      );
    });
  }
}

/// Manages BLE reconnection state and policy via Riverpod.
class BleReconnectionNotifier extends Notifier<BleReconnectionState> {
  late final BleReconnectionPolicy _policy;

  @override
  BleReconnectionState build() {
    _policy = BleReconnectionPolicy(
      maxAttempts: EnvConfig.current.maxRetryAttempts * 3,
    );
    ref.onDispose(() => _policy.cancel());
    return const BleReconnectionState();
  }

  /// Start reconnection for a given sensor.
  void startReconnection(String sensorSn) {
    if (_policy.isActive) return;

    final bleState = ref.read(bleStateProvider);
    if (bleState != BleAdapterState.poweredOn) {
      state = state.copyWith(
        status: BleReconnectStatus.waitingForBluetooth,
        sensorSn: sensorSn,
      );
      return;
    }

    state = state.copyWith(
      status: BleReconnectStatus.reconnecting,
      sensorSn: sensorSn,
      attempt: 0,
    );

    _policy.start(
      reconnectAction: () async {
        return CgmSdkService.instance.connect(
          sensorSn: sensorSn,
          autoConnect: true,
        );
      },
      onAttempt: () {
        state = state.copyWith(
          attempt: _policy.currentAttempt,
          status: BleReconnectStatus.reconnecting,
        );
      },
      onSuccess: () {
        ref.read(bleStateProvider.notifier).resetFailures();
        state = state.copyWith(status: BleReconnectStatus.connected);
      },
      onFailure: (attempt, max) {
        ref.read(bleStateProvider.notifier).recordFailure();
        state = state.copyWith(
          attempt: attempt,
          status: BleReconnectStatus.reconnecting,
        );
      },
      onExhausted: () {
        state = state.copyWith(status: BleReconnectStatus.exhausted);
      },
    );
  }

  /// Cancel active reconnection.
  void cancel() {
    _policy.cancel();
    state = state.copyWith(status: BleReconnectStatus.idle);
  }

  /// Reset state after successful manual connection.
  void markConnected() {
    _policy.cancel();
    ref.read(bleStateProvider.notifier).resetFailures();
    state = state.copyWith(status: BleReconnectStatus.connected);
  }
}

enum BleReconnectStatus {
  idle,
  reconnecting,
  waitingForBluetooth,
  connected,
  exhausted,
}

class BleReconnectionState {
  const BleReconnectionState({
    this.status = BleReconnectStatus.idle,
    this.sensorSn,
    this.attempt = 0,
  });

  final BleReconnectStatus status;
  final String? sensorSn;
  final int attempt;

  BleReconnectionState copyWith({
    BleReconnectStatus? status,
    String? sensorSn,
    int? attempt,
  }) {
    return BleReconnectionState(
      status: status ?? this.status,
      sensorSn: sensorSn ?? this.sensorSn,
      attempt: attempt ?? this.attempt,
    );
  }
}

/// Provider for BLE reconnection management.
final bleReconnectionProvider =
    NotifierProvider<BleReconnectionNotifier, BleReconnectionState>(
      BleReconnectionNotifier.new,
    );
