import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/optimus_models.dart';
import '../app/theme.dart';

/// Focused state for authentication concerns only.
/// This is a domain-specific slice that can be watched independently
/// of the full AppState, reducing unnecessary rebuilds.
class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.onboardingComplete = false,
    this.currentUser,
    this.activeRole = OptimusRole.customer,
  });

  final bool isAuthenticated;
  final bool onboardingComplete;
  final OptimusUser? currentUser;
  final OptimusRole activeRole;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? onboardingComplete,
    OptimusUser? currentUser,
    OptimusRole? activeRole,
    bool clearCurrentUser = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      currentUser: clearCurrentUser ? null : currentUser ?? this.currentUser,
      activeRole: activeRole ?? this.activeRole,
    );
  }
}

/// Focused state for CGM/sensor connection concerns.
class CgmConnectionState {
  const CgmConnectionState({
    this.authorized = false,
    this.connecting = false,
    this.connected = false,
    this.connectionStatus = 'Not connected',
    this.sensorSn,
    this.lastError,
    this.syncProgress = 0,
    this.sdkLogs = const [],
  });

  final bool authorized;
  final bool connecting;
  final bool connected;
  final String connectionStatus;
  final String? sensorSn;
  final String? lastError;
  final int syncProgress;
  final List<String> sdkLogs;

  CgmConnectionState copyWith({
    bool? authorized,
    bool? connecting,
    bool? connected,
    String? connectionStatus,
    String? sensorSn,
    String? lastError,
    int? syncProgress,
    List<String>? sdkLogs,
    bool clearLastError = false,
  }) {
    return CgmConnectionState(
      authorized: authorized ?? this.authorized,
      connecting: connecting ?? this.connecting,
      connected: connected ?? this.connected,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      sensorSn: sensorSn ?? this.sensorSn,
      lastError: clearLastError ? null : lastError ?? this.lastError,
      syncProgress: syncProgress ?? this.syncProgress,
      sdkLogs: sdkLogs ?? this.sdkLogs,
    );
  }
}

/// Focused state for patient data and glucose readings.
class PatientDataState {
  const PatientDataState({
    this.activePatientId = 'patient-1',
    this.selectedPatientId = 'patient-1',
    this.patients = const [],
    this.sensors = const [],
    this.readings = const [],
    this.meals = const [],
    this.aiInterpretations = const [],
    this.orders = const [],
    this.syncLogs = const [],
    this.integrations = const [],
  });

  final String activePatientId;
  final String selectedPatientId;
  final List<Patient> patients;
  final List<Sensor> sensors;
  final List<OptimusGlucoseReading> readings;
  final List<MealLog> meals;
  final List<AIInterpretation> aiInterpretations;
  final List<Order> orders;
  final List<SensorSyncLog> syncLogs;
  final List<DeviceIntegration> integrations;

  PatientDataState copyWith({
    String? activePatientId,
    String? selectedPatientId,
    List<Patient>? patients,
    List<Sensor>? sensors,
    List<OptimusGlucoseReading>? readings,
    List<MealLog>? meals,
    List<AIInterpretation>? aiInterpretations,
    List<Order>? orders,
    List<SensorSyncLog>? syncLogs,
    List<DeviceIntegration>? integrations,
  }) {
    return PatientDataState(
      activePatientId: activePatientId ?? this.activePatientId,
      selectedPatientId: selectedPatientId ?? this.selectedPatientId,
      patients: patients ?? this.patients,
      sensors: sensors ?? this.sensors,
      readings: readings ?? this.readings,
      meals: meals ?? this.meals,
      aiInterpretations: aiInterpretations ?? this.aiInterpretations,
      orders: orders ?? this.orders,
      syncLogs: syncLogs ?? this.syncLogs,
      integrations: integrations ?? this.integrations,
    );
  }
}

/// Focused state for alerts and notification preferences.
class AlertState {
  const AlertState({
    this.alertSettings = const AlertSettings(
      notificationsEnabled: true,
      lowThreshold: 70,
      highThreshold: 180,
      quietHoursEnabled: false,
    ),
    this.alerts = const [],
    this.reportExports = const [],
    this.consentPreferences = const ConsentPreferences(
      healthData: false,
      sensorData: false,
      aiCoaching: false,
      reportSharing: false,
      termsAccepted: false,
    ),
  });

  final AlertSettings alertSettings;
  final List<GlucoseAlert> alerts;
  final List<ReportExport> reportExports;
  final ConsentPreferences consentPreferences;

  AlertState copyWith({
    AlertSettings? alertSettings,
    List<GlucoseAlert>? alerts,
    List<ReportExport>? reportExports,
    ConsentPreferences? consentPreferences,
  }) {
    return AlertState(
      alertSettings: alertSettings ?? this.alertSettings,
      alerts: alerts ?? this.alerts,
      reportExports: reportExports ?? this.reportExports,
      consentPreferences: consentPreferences ?? this.consentPreferences,
    );
  }
}

/// Focused state for UI/chart preferences.
class ChartPreferencesState {
  const ChartPreferencesState({
    this.chartDuration = ChartDuration.day,
    this.readingFilter,
  });

  final ChartDuration chartDuration;
  final GlucoseStatus? readingFilter;

  ChartPreferencesState copyWith({
    ChartDuration? chartDuration,
    GlucoseStatus? readingFilter,
    bool clearReadingFilter = false,
  }) {
    return ChartPreferencesState(
      chartDuration: chartDuration ?? this.chartDuration,
      readingFilter: clearReadingFilter
          ? null
          : readingFilter ?? this.readingFilter,
    );
  }
}

// ---------------------------------------------------------------------------
// Providers for domain-specific states (derived from the existing AppState).
// These allow widgets to watch only the slice they need, reducing rebuilds.
// The existing appControllerProvider remains the source of truth.
// ---------------------------------------------------------------------------

/// Provides only authentication-related state.
final authStateProvider = Provider<AuthState>((ref) {
  // Import deferred to avoid circular - this will be wired in app_state.dart
  throw UnimplementedError(
    'authStateProvider must be overridden in the ProviderScope or wired to appControllerProvider',
  );
});

/// Provides only CGM connection state.
final cgmConnectionStateProvider = Provider<CgmConnectionState>((ref) {
  throw UnimplementedError(
    'cgmConnectionStateProvider must be overridden in the ProviderScope or wired to appControllerProvider',
  );
});
