// Localization configuration placeholder.
// To enable full l10n, add the following to pubspec.yaml under `flutter:`:
//
//   generate: true
//
// And create l10n.yaml:
//
//   arb-dir: lib/l10n
//   template-arb-file: app_en.arb
//   output-localization-file: app_localizations.dart
//
// Then create lib/l10n/app_en.arb with your strings.

/// Placeholder app strings for when full l10n is not yet configured.
/// Replace with generated AppLocalizations once arb files are set up.
class AppStrings {
  AppStrings._();

  // General
  static const appName = 'Optimus CGM';
  static const loading = 'Loading...';
  static const retry = 'Retry';
  static const cancel = 'Cancel';
  static const confirm = 'Confirm';
  static const save = 'Save';
  static const done = 'Done';
  static const error = 'Something went wrong.';

  // Auth
  static const signIn = 'Sign In';
  static const signOut = 'Sign Out';
  static const email = 'Email';
  static const password = 'Password';

  // CGM
  static const sensorNotConnected = 'Not connected';
  static const sensorConnecting = 'Connecting...';
  static const sensorConnected = 'Sensor connected';
  static const sensorExpired = 'Sensor expired';
  static const warmingUp = 'Warming up';

  // Glucose
  static const glucoseLow = 'Low';
  static const glucoseNormal = 'Normal';
  static const glucoseHigh = 'High';
  static const mgDl = 'mg/dL';

  // Alerts
  static const highGlucoseAlert = 'High glucose alert';
  static const lowGlucoseAlert = 'Low glucose alert';

  // Accessibility
  static const glucoseChartLabel = 'Glucose trend chart';
  static const currentGlucoseLabel = 'Current glucose reading';
  static const trendDirectionLabel = 'Trend direction';
}
