import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'internet_reachability_stub.dart'
    if (dart.library.io) 'internet_reachability_io.dart';

/// Connectivity status.
enum ConnectivityStatus { online, offline, unknown }

/// Monitors network connectivity using Riverpod Notifier.
class ConnectivityNotifier extends Notifier<ConnectivityStatus> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  ConnectivityStatus build() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) => unawaited(_applyConnectivity(results)),
      onError: (_) => state = ConnectivityStatus.unknown,
    );
    ref.onDispose(() => _subscription?.cancel());
    unawaited(refresh());
    return ConnectivityStatus.unknown;
  }

  /// Manually set connectivity (useful for testing or plugin integration).
  void setStatus(ConnectivityStatus status) {
    state = status;
  }

  Future<void> refresh() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _applyConnectivity(results);
    } catch (_) {
      state = ConnectivityStatus.unknown;
    }
  }

  Future<void> _applyConnectivity(List<ConnectivityResult> results) async {
    if (_isRadioOffline(results)) {
      state = ConnectivityStatus.offline;
      return;
    }

    state = await hasInternetAccess()
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;
  }

  bool _isRadioOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
  }
}

/// Provider for connectivity status throughout the app.
final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, ConnectivityStatus>(
      ConnectivityNotifier.new,
    );

/// Convenience provider: true when offline.
final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider) == ConnectivityStatus.offline;
});
