import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_state.dart';
import 'domain_states.dart';

final authSliceProvider = Provider<AuthState>((ref) {
  final state = ref.watch(appControllerProvider);
  return AuthState(
    isAuthenticated: state.isAuthenticated,
    onboardingComplete: state.onboardingComplete,
    currentUser: state.currentUser,
    activeRole: state.activeRole,
  );
});

final cgmSliceProvider = Provider<CgmConnectionState>((ref) {
  final state = ref.watch(appControllerProvider);
  return CgmConnectionState(
    authorized: state.cgmAuthorized,
    connecting: state.cgmConnecting,
    connected: state.cgmConnected,
    connectionStatus: state.cgmConnectionStatus,
    sensorSn: state.cgmSensorSn,
    lastError: state.cgmLastError,
    syncProgress: state.cgmSyncProgress,
    sdkLogs: state.cgmSdkLogs,
  );
});

final patientDataSliceProvider = Provider<PatientDataState>((ref) {
  final state = ref.watch(appControllerProvider);
  return PatientDataState(
    activePatientId: state.activePatientId,
    selectedPatientId: state.selectedPatientId,
    patients: state.patients,
    sensors: state.sensors,
    readings: state.readings,
    meals: state.meals,
    aiInterpretations: state.aiInterpretations,
    orders: state.orders,
    syncLogs: state.syncLogs,
    integrations: state.integrations,
  );
});

final alertSliceProvider = Provider<AlertState>((ref) {
  final state = ref.watch(appControllerProvider);
  return AlertState(
    alertSettings: state.alertSettings,
    alerts: state.alerts,
    reportExports: state.reportExports,
    consentPreferences: state.consentPreferences,
  );
});

final chartPreferencesSliceProvider = Provider<ChartPreferencesState>((ref) {
  final state = ref.watch(appControllerProvider);
  return ChartPreferencesState(
    chartDuration: state.chartDuration,
    readingFilter: state.readingFilter,
  );
});
