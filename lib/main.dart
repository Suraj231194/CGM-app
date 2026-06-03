import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/error/app_error_handler.dart';
import 'core/lifecycle/app_lifecycle_observer.dart';
import 'core/observers/app_provider_observer.dart';
import 'core/reporting/crash_reporter.dart';
import 'core/security/inactivity_detector.dart';
import 'services/analytics_service.dart';
import 'services/push_notification_service.dart';
import 'state/app_state.dart';
import 'state/cgm_sdk_event_bridge.dart';

void main() {
  runAppGuarded(
    ProviderScope(
      observers: [AppProviderObserver()],
      child: const OptimusCgmApp(),
    ),
    beforeRun: initializeRuntimeServices,
  );
}

Future<void> initializeRuntimeServices() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (error, stackTrace) {
    AppErrorHandler.report(error, stackTrace, 'Firebase.initializeApp');
  }

  await CrashReporter.initialize();
  await AnalyticsService.instance.initialize();
  await PushNotificationService.instance.initialize();
}

class OptimusCgmApp extends ConsumerWidget {
  const OptimusCgmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(cgmSdkEventBridgeProvider);
    ref.watch(appLifecycleProvider);
    final router = ref.watch(appRouterProvider);
    final isAuthenticated = ref.watch(
      appControllerProvider.select((s) => s.isAuthenticated),
    );
    final themeMode = ref.watch(
      appControllerProvider.select((s) => s.themeMode),
    );

    return InactivityDetector(
      enabled: isAuthenticated,
      onTimeout: () {
        ref.read(appControllerProvider.notifier).signOut();
      },
      child: MaterialApp.router(
        title: 'Optimus CGM',
        debugShowCheckedModeBanner: false,
        theme: buildOptimusTheme(),
        darkTheme: buildOptimusDarkTheme(),
        themeMode: themeMode,
        routerConfig: router,
      ),
    );
  }
}
