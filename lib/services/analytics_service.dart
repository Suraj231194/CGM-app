import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/env/app_environment.dart';

/// Analytics service for product and clinical workflow events.
///
/// Firebase Analytics is used when Firebase is configured. In browser preview
/// or local development without Firebase options, events are logged only in
/// debug mode so the app remains runnable.
class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  bool _firebaseReady = false;

  Future<void> initialize() async {
    _firebaseReady = Firebase.apps.isNotEmpty;
    if (_firebaseReady) {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
        !kDebugMode && EnvConfig.current.isProduction,
      );
    }
    _log('initialize', {'firebase_ready': _firebaseReady});
  }

  void setUser({required String userId, required String role}) {
    if (_firebaseReady) {
      unawaited(FirebaseAnalytics.instance.setUserId(id: userId));
      unawaited(
        FirebaseAnalytics.instance.setUserProperty(name: 'role', value: role),
      );
    }
    _log('set_user', {'user_id': userId, 'role': role});
  }

  void logScreenView(String screenName) {
    if (_firebaseReady) {
      unawaited(
        FirebaseAnalytics.instance.logScreenView(screenName: screenName),
      );
    }
    _log('screen_view', {'screen': screenName});
  }

  void logOnboardingComplete() {
    _logEvent('onboarding_complete');
  }

  void logMealLogged({required String mealType, required int score}) {
    _logEvent('meal_logged', {'meal_type': mealType, 'score': score});
  }

  void logSensorConnected({required String sensorSn, required bool success}) {
    _logEvent('sensor_connection', {'sensor_sn': sensorSn, 'success': success});
  }

  void logAlertAcknowledged({required String alertId}) {
    _logEvent('alert_acknowledged', {'alert_id': alertId});
  }

  void logReportGenerated({required String period, required String format}) {
    _logEvent('report_generated', {'period': period, 'format': format});
  }

  void logChartDurationChanged(String duration) {
    _logEvent('chart_duration_changed', {'duration': duration});
  }

  void logRoleSwitch(String role) {
    _logEvent('role_switch', {'role': role});
  }

  void _logEvent(String name, [Map<String, Object>? params]) {
    if (_firebaseReady) {
      unawaited(
        FirebaseAnalytics.instance.logEvent(name: name, parameters: params),
      );
    }
    _log(name, params);
  }

  void _log(String event, [Map<String, Object>? params]) {
    if (EnvConfig.current.enableLogging && kDebugMode) {
      debugPrint('[Analytics] $event ${params ?? ''}');
    }
  }
}
