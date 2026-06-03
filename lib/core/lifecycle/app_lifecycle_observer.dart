import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLifecycleStatus { active, inactive, paused, hidden }

/// Riverpod Notifier that tracks app lifecycle state.
/// Watch this to pause BLE, hide sensitive data when backgrounded, etc.
class AppLifecycleNotifier extends Notifier<AppLifecycleStatus>
    with WidgetsBindingObserver {
  @override
  AppLifecycleStatus build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    return AppLifecycleStatus.active;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    this.state = switch (state) {
      AppLifecycleState.resumed => AppLifecycleStatus.active,
      AppLifecycleState.inactive => AppLifecycleStatus.inactive,
      AppLifecycleState.paused => AppLifecycleStatus.paused,
      AppLifecycleState.hidden => AppLifecycleStatus.hidden,
      AppLifecycleState.detached => AppLifecycleStatus.paused,
    };
  }

  bool get isActive => state == AppLifecycleStatus.active;
  bool get isBackground =>
      state == AppLifecycleStatus.paused || state == AppLifecycleStatus.hidden;
}

final appLifecycleProvider =
    NotifierProvider<AppLifecycleNotifier, AppLifecycleStatus>(
      AppLifecycleNotifier.new,
    );
