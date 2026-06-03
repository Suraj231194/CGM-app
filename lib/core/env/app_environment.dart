/// Environment configuration for the application.
///
/// Use flavors or compile-time constants to switch between environments.
enum AppEnvironment { development, staging, production }

class EnvConfig {
  const EnvConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.cgmSdkAppId,
    required this.cgmSdkAppSecret,
    required this.enableLogging,
    required this.connectionTimeoutSeconds,
    required this.maxRetryAttempts,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String cgmSdkAppId;
  final String cgmSdkAppSecret;
  final bool enableLogging;
  final int connectionTimeoutSeconds;
  final int maxRetryAttempts;

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
