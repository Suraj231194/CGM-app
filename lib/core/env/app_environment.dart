import 'package:flutter/foundation.dart';

/// Environment configuration for the application.
///
/// Use flavors or compile-time constants to switch between environments.
enum AppEnvironment { development, staging, production }

class EnvConfig {
  const EnvConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this._cgmSdkAppId,
    required this._cgmSdkAppSecret,
    required this.enableLogging,
    required this.connectionTimeoutSeconds,
    required this.maxRetryAttempts,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String _cgmSdkAppId;
  final String _cgmSdkAppSecret;
  final bool enableLogging;
  final int connectionTimeoutSeconds;
  final int maxRetryAttempts;

  String get cgmSdkAppId {
    if (_cgmSdkAppId.isNotEmpty) return _cgmSdkAppId;
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return '505285';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return '642434';
    }
    return '';
  }

  String get cgmSdkAppSecret {
    if (_cgmSdkAppSecret.isNotEmpty) return _cgmSdkAppSecret;
    if (kIsWeb) return '';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'a6BgbGLjiseZndCgzq6SdLQlbnJx0UCb';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'wtrWYS8bnRTxssyNwbbwsyNYccpYlkP8';
    }
    return '';
  }

  static const development = EnvConfig._(
    environment: AppEnvironment.development,
    apiBaseUrl: 'https://dev-api.optimus-cgm.com',
    cgmSdkAppId: String.fromEnvironment('CGM_APP_ID'),
    cgmSdkAppSecret: String.fromEnvironment('CGM_APP_SECRET'),
    enableLogging: true,
    connectionTimeoutSeconds: 30,
    maxRetryAttempts: 3,
  );

  static const staging = EnvConfig._(
    environment: AppEnvironment.staging,
    apiBaseUrl: 'https://staging-api.optimus-cgm.com',
    cgmSdkAppId: String.fromEnvironment('CGM_APP_ID'),
    cgmSdkAppSecret: String.fromEnvironment('CGM_APP_SECRET'),
    enableLogging: true,
    connectionTimeoutSeconds: 20,
    maxRetryAttempts: 3,
  );

  static const production = EnvConfig._(
    environment: AppEnvironment.production,
    apiBaseUrl: 'https://api.optimus-cgm.com',
    cgmSdkAppId: String.fromEnvironment('CGM_APP_ID'),
    cgmSdkAppSecret: String.fromEnvironment('CGM_APP_SECRET'),
    enableLogging: false,
    connectionTimeoutSeconds: 15,
    maxRetryAttempts: 5,
  );

  static EnvConfig get current {
    const env = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    return switch (env) {
      'production' => production,
      'staging' => staging,
      _ => development,
    };
  }

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isProduction => environment == AppEnvironment.production;
}
