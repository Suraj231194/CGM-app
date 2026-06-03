import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/env/app_environment.dart';

/// Push notification adapter for glucose alerts, reports, and sensor events.
///
/// Firebase Messaging is used when Firebase is configured on native builds.
/// Browser preview remains safe and simply reports notifications as disabled.
class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();

  String? _fcmToken;
  bool _firebaseReady = false;
  final _subscriptions = <StreamSubscription<dynamic>>[];

  String? get fcmToken => _fcmToken;
  bool get isReady => _firebaseReady && _fcmToken != null;

  final _onNotificationTap = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotificationTap =>
      _onNotificationTap.stream;

  Future<void> initialize() async {
    _firebaseReady = !kIsWeb && Firebase.apps.isNotEmpty;
    if (!_firebaseReady) {
      _debug('disabled: Firebase Messaging not configured for this runtime');
      return;
    }

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(criticalAlert: true);

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _debug('permission denied');
      return;
    }

    _fcmToken = await messaging.getToken();
    _subscriptions
      ..add(
        messaging.onTokenRefresh.listen((token) {
          _fcmToken = token;
          _debug('token refreshed');
        }),
      )
      ..add(FirebaseMessaging.onMessage.listen(_handleForegroundMessage))
      ..add(
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap),
      );

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
    _debug('ready token=${_fcmToken == null ? 'none' : 'available'}');
  }

  Future<void> registerToken(String userId) async {
    if (_fcmToken == null) return;
    // Backend registration endpoint is expected to persist this token.
    _debug('token ready for backend registration user=$userId');
  }

  Future<void> subscribeToPatient(String patientId) async {
    if (!_firebaseReady) return;
    await FirebaseMessaging.instance.subscribeToTopic('patient-$patientId');
  }

  Future<void> unsubscribeFromPatient(String patientId) async {
    if (!_firebaseReady) return;
    await FirebaseMessaging.instance.unsubscribeFromTopic('patient-$patientId');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _debug('foreground ${message.data}');
  }

  void _handleNotificationTap(RemoteMessage message) {
    _onNotificationTap.add(message.data);
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    _onNotificationTap.close();
  }

  void _debug(String message) {
    if (EnvConfig.current.enableLogging && kDebugMode) {
      debugPrint('[Push] $message');
    }
  }
}

class PushNotificationPayload {
  const PushNotificationPayload({
    required this.type,
    this.patientId,
    this.alertId,
    this.route,
  });

  final String type;
  final String? patientId;
  final String? alertId;
  final String? route;

  factory PushNotificationPayload.fromData(Map<String, dynamic> data) {
    return PushNotificationPayload(
      type: data['type'] as String? ?? 'unknown',
      patientId: data['patientId'] as String?,
      alertId: data['alertId'] as String?,
      route: data['route'] as String?,
    );
  }

  String get deepLinkRoute {
    return route ??
        switch (type) {
          'glucose_alert' => '/alerts',
          'report_ready' => '/reports',
          'sensor_expiry' => '/sensor',
          _ => '/dashboard',
        };
  }
}
