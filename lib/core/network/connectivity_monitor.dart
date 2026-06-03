import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity status.
enum ConnectivityStatus { online, offline, unknown }

/// Monitors network connectivity using Riverpod Notifier.
/// Currently assumes online (no backend). When you add `connectivity_plus`,
/// wire real stream here.
class ConnectivityNotifier extends Notifier<ConnectivityStatus> {
  @override
  ConnectivityStatus build() {
    // In local/seed mode, always online.
    return ConnectivityStatus.online;
  }

  /// Manually set connectivity (useful for testing or plugin integration).
  void setStatus(ConnectivityStatus status) {
    state = status;
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
