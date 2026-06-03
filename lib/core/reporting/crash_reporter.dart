import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../env/app_environment.dart';

/// Remote crash reporting adapter.
///
/// Uses Firebase Crashlytics for configured non-web builds. Local preview and
/// unconfigured Firebase environments fall back to debug logging.
class CrashReporter {
  CrashReporter._();

  static bool _firebaseReady = false;
  static bool _initialized = false;

  static Future<void> initialize() async {
    _firebaseReady = !kIsWeb && Firebase.apps.isNotEmpty;
    if (_firebaseReady) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        EnvConfig.current.isProduction,
      );
    }
    _initialized = true;
    _debug('initialize firebase_ready=$_firebaseReady');
  }

  static void reportError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
  }) {
    if (!_initialized) return;
    if (_firebaseReady) {
      unawaited(
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: reason ?? 'Non-fatal error',
        ),
      );
    }
    _debug('$reason: $error');
  }

  static void setUserId(String userId) {
    if (_firebaseReady) {
      unawaited(FirebaseCrashlytics.instance.setUserIdentifier(userId));
    }
    _debug('User set: $userId');
  }

  static void log(String message) {
    if (_firebaseReady) {
      unawaited(FirebaseCrashlytics.instance.log(message));
    }
    _debug(message);
  }

  static void setCustomKey(String key, Object value) {
    if (_firebaseReady) {
      unawaited(FirebaseCrashlytics.instance.setCustomKey(key, value));
    }
  }

  static void _debug(String message) {
    if (kDebugMode && EnvConfig.current.enableLogging) {
      debugPrint('[CrashReporter] $message');
    }
  }
}
