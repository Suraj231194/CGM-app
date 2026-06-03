import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../env/app_environment.dart';
import '../reporting/crash_reporter.dart';

/// Global error handler that catches unhandled Flutter and Dart errors.
/// In production, this could forward errors to Crashlytics or Sentry.
class AppErrorHandler {
  AppErrorHandler._();

  static void initialize() {
    FlutterError.onError = _handleFlutterError;
    PlatformDispatcher.instance.onError = _handlePlatformError;
  }

  static final _errorLog = <AppError>[];

  /// Recent errors captured (max 50).
  static List<AppError> get recentErrors =>
      List.unmodifiable(_errorLog.take(50));

  static void _handleFlutterError(FlutterErrorDetails details) {
    _record(
      AppError(
        message: details.exceptionAsString(),
        stackTrace: details.stack,
        source: 'FlutterError',
        timestamp: DateTime.now(),
      ),
    );
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  }

  static bool _handlePlatformError(Object error, StackTrace stackTrace) {
    _record(
      AppError(
        message: error.toString(),
        stackTrace: stackTrace,
        source: 'PlatformDispatcher',
        timestamp: DateTime.now(),
      ),
    );
    if (kDebugMode) {
      debugPrint('Unhandled error: $error\n$stackTrace');
    }
    return true; // Prevent the error from propagating to the zone.
  }

  /// Manually report an error (e.g., from a catch block).
  static void report(Object error, [StackTrace? stackTrace, String? context]) {
    _record(
      AppError(
        message: error.toString(),
        stackTrace: stackTrace,
        source: context ?? 'manual',
        timestamp: DateTime.now(),
      ),
    );
    if (EnvConfig.current.enableLogging && kDebugMode) {
      debugPrint('[AppError] $context: $error');
    }
  }

  static void _record(AppError error) {
    _errorLog.insert(0, error);
    if (_errorLog.length > 50) {
      _errorLog.removeRange(50, _errorLog.length);
    }
    CrashReporter.reportError(
      error.message,
      error.stackTrace,
      reason: error.source,
    );
  }
}

class AppError {
  const AppError({
    required this.message,
    required this.source,
    required this.timestamp,
    this.stackTrace,
  });

  final String message;
  final String source;
  final DateTime timestamp;
  final StackTrace? stackTrace;

  @override
  String toString() => '[$source @ $timestamp] $message';
}

/// Runs the app within an error zone that captures async errors.
Future<void> runAppGuarded(
  Widget app, {
  Future<void> Function()? beforeRun,
}) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      AppErrorHandler.initialize();
      await beforeRun?.call();
      runApp(app);
    },
    (error, stackTrace) {
      AppErrorHandler.report(error, stackTrace, 'runZonedGuarded');
    },
  );
}
