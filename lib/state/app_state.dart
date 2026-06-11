import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../data/optimus_seed_data.dart';
import '../models/optimus_models.dart';
import '../services/cgm_sdk_service.dart';
import '../utils/glucose_utils.dart';
import '../utils/sensor_serial_parser.dart';

class AppState {
  const AppState({
    required this.isAuthenticated,
    required this.onboardingComplete,
    required this.currentUser,
    required this.activeRole,
    required this.activePatientId,
    required this.selectedPatientId,
    required this.patients,
    required this.sensors,
    required this.readings,
    required this.meals,
    required this.aiInterpretations,
    required this.orders,
    required this.syncLogs,
    required this.integrations,
    required this.consentPreferences,
    required this.alertSettings,
    required this.alerts,
    required this.reportExports,
    required this.chartDuration,
    required this.readingFilter,
    required this.themeMode,
    required this.cgmAuthorized,
    required this.cgmConnecting,
    required this.cgmConnected,
    required this.cgmConnectionStatus,
    required this.cgmSensorSn,
    required this.cgmLastError,
    required this.cgmSyncProgress,
    required this.cgmSdkLogs,
  });

  final bool isAuthenticated;
  final bool onboardingComplete;
  final OptimusUser? currentUser;
  final OptimusRole activeRole;
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
  final ConsentPreferences consentPreferences;
  final AlertSettings alertSettings;
  final List<GlucoseAlert> alerts;
  final List<ReportExport> reportExports;
  final ChartDuration chartDuration;
  final GlucoseStatus? readingFilter;
  final ThemeMode themeMode;
  final bool cgmAuthorized;
  final bool cgmConnecting;
  final bool cgmConnected;
  final String cgmConnectionStatus;
  final String? cgmSensorSn;
  final String? cgmLastError;
  final int cgmSyncProgress;
  final List<String> cgmSdkLogs;

  AppState copyWith({
    bool? isAuthenticated,
    bool? onboardingComplete,
    OptimusUser? currentUser,
    OptimusRole? activeRole,
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
    ConsentPreferences? consentPreferences,
    AlertSettings? alertSettings,
    List<GlucoseAlert>? alerts,
    List<ReportExport>? reportExports,
    ChartDuration? chartDuration,
    GlucoseStatus? readingFilter,
    ThemeMode? themeMode,
    bool? cgmAuthorized,
    bool? cgmConnecting,
    bool? cgmConnected,
    String? cgmConnectionStatus,
    String? cgmSensorSn,
    String? cgmLastError,
    int? cgmSyncProgress,
    List<String>? cgmSdkLogs,
    bool clearReadingFilter = false,
    bool clearCurrentUser = false,
    bool clearCgmLastError = false,
  }) {
    return AppState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      currentUser: clearCurrentUser ? null : currentUser ?? this.currentUser,
      activeRole: activeRole ?? this.activeRole,
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
      consentPreferences: consentPreferences ?? this.consentPreferences,
      alertSettings: alertSettings ?? this.alertSettings,
      alerts: alerts ?? this.alerts,
      reportExports: reportExports ?? this.reportExports,
      chartDuration: chartDuration ?? this.chartDuration,
      readingFilter: clearReadingFilter
          ? null
          : readingFilter ?? this.readingFilter,
      themeMode: themeMode ?? this.themeMode,
      cgmAuthorized: cgmAuthorized ?? this.cgmAuthorized,
      cgmConnecting: cgmConnecting ?? this.cgmConnecting,
      cgmConnected: cgmConnected ?? this.cgmConnected,
      cgmConnectionStatus: cgmConnectionStatus ?? this.cgmConnectionStatus,
      cgmSensorSn: cgmSensorSn ?? this.cgmSensorSn,
      cgmLastError: clearCgmLastError
          ? null
          : cgmLastError ?? this.cgmLastError,
      cgmSyncProgress: cgmSyncProgress ?? this.cgmSyncProgress,
      cgmSdkLogs: cgmSdkLogs ?? this.cgmSdkLogs,
    );
  }
}

class AppController extends Notifier<AppState> {
  @override
  AppState build() {
    return AppState(
      isAuthenticated: false,
      onboardingComplete: false,
      currentUser: null,
      activeRole: OptimusRole.customer,
      activePatientId: 'patient-1',
      selectedPatientId: 'patient-1',
      patients: optimusPatients,
      sensors: optimusSensors,
      readings: allOptimusReadings,
      meals: optimusMealLogs,
      aiInterpretations: optimusAIInterpretations,
      orders: optimusOrders,
      syncLogs: optimusSyncLogs,
      integrations: deviceIntegrations,
      consentPreferences: defaultConsentPreferences,
      alertSettings: defaultAlertSettings,
      alerts: optimusAlerts,
      reportExports: optimusReportExports,
      chartDuration: ChartDuration.day,
      readingFilter: null,
      themeMode: ThemeMode.light,
      cgmAuthorized: false,
      cgmConnecting: false,
      cgmConnected: false,
      cgmConnectionStatus: 'Not connected',
      cgmSensorSn: null,
      cgmLastError: null,
      cgmSyncProgress: 0,
      cgmSdkLogs: const [],
    );
  }

  void signIn(String email, {OptimusRole? role}) {
    final selectedRole = role ?? _inferRole(email);
    final user = _userForRole(selectedRole);
    final patient = _patientForRole(selectedRole);
    state = state.copyWith(
      isAuthenticated: true,
      currentUser: user,
      activeRole: selectedRole,
      activePatientId: patient.id,
      selectedPatientId: patient.id,
      onboardingComplete: selectedRole != OptimusRole.customer,
    );
  }

  void signOut() {
    state = state.copyWith(isAuthenticated: false, clearCurrentUser: true);
  }

  void switchRole(OptimusRole role) {
    final user = _userForRole(role);
    final patient = _patientForRole(role);
    state = state.copyWith(
      activeRole: role,
      currentUser: user,
      activePatientId: patient.id,
      selectedPatientId: patient.id,
      clearReadingFilter: true,
    );
  }

  void selectPatient(String patientId) {
    state = state.copyWith(selectedPatientId: patientId);
  }

  void setChartDuration(ChartDuration duration) {
    state = state.copyWith(chartDuration: duration);
  }

  void setReadingFilter(GlucoseStatus? status) {
    state = state.copyWith(
      readingFilter: status,
      clearReadingFilter: status == null,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void toggleDarkMode(bool enabled) {
    setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  void completeOnboarding() {
    state = state.copyWith(onboardingComplete: true);
  }

  void updateConsent(ConsentPreferences preferences) {
    state = state.copyWith(consentPreferences: preferences);
  }

  void addMealLog({
    required MealType type,
    required String title,
    required int netCarbs,
    required int protein,
    required int fiber,
    required int activityMinutes,
    required String note,
  }) {
    final now = DateTime.now();
    final score = mealScore(
      netCarbs: netCarbs,
      protein: protein,
      fiber: fiber,
      activityMinutes: activityMinutes,
    );
    final label = title.trim().isEmpty ? _mealTypeLabel(type) : title.trim();
    state = state.copyWith(
      meals: [
        MealLog(
          id: 'meal-${now.millisecondsSinceEpoch}',
          patientId: state.selectedPatientId,
          timestamp: now,
          type: type,
          title: label,
          netCarbs: netCarbs,
          protein: protein,
          fiber: fiber,
          activityMinutes: activityMinutes,
          score: score,
          note: note.trim(),
        ),
        ...state.meals,
      ],
    );
  }

  void updateAlertSettings(AlertSettings settings) {
    final latestAlerts = _alertsForReadings(
      selectedReadings.takeLast(40),
      settings,
    );
    final merged = <String, GlucoseAlert>{
      for (final alert in state.alerts) alert.id: alert,
      for (final alert in latestAlerts) alert.id: alert,
    };
    state = state.copyWith(
      alertSettings: settings,
      alerts: merged.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
    );
  }

  void acknowledgeAlert(String alertId) {
    state = state.copyWith(
      alerts: state.alerts
          .map(
            (alert) => alert.id == alertId
                ? alert.copyWith(acknowledged: true)
                : alert,
          )
          .toList(),
    );
  }

  void generateReportExport({String period = '14 day', String format = 'PDF'}) {
    final now = DateTime.now();
    final summary = summarizeReadings(selectedReadings);
    state = state.copyWith(
      reportExports: [
        ReportExport(
          id: 'report-${now.millisecondsSinceEpoch}',
          patientId: state.selectedPatientId,
          period: period,
          generatedAt: now,
          format: format,
          status: 'ready',
          summary:
              '${summary.timeInRange}% time in range, ${summary.average} mg/dL average, ${state.meals.where((meal) => meal.patientId == state.selectedPatientId).length} meal log(s), and ${state.alerts.where((alert) => alert.patientId == state.selectedPatientId).length} alert(s).',
        ),
        ...state.reportExports,
      ],
    );
  }

  void startSensorActivation() {
    state = state.copyWith(
      sensors: _updateActiveSensor(
        (sensor) => sensor.copyWith(
          status: SensorStatus.inactive,
          batteryStatus: 100,
          connectionStatus: ConnectionStatus.offline,
        ),
      ),
    );
  }

  void attachSensor() {
    state = state.copyWith(
      sensors: _updateActiveSensor(
        (sensor) => sensor.copyWith(
          status: SensorStatus.attached,
          connectionStatus: ConnectionStatus.nearby,
        ),
      ),
    );
  }

  void scanAndConnectSensor({String? serialNumber, bool previewOnly = false}) {
    final now = DateTime.now();
    final cleanSerial = _cleanSerial(serialNumber);
    final patient = selectedPatient;

    if (!previewOnly) {
      state = state.copyWith(
        cgmSensorSn: cleanSerial,
        cgmConnecting: true,
        cgmConnected: false,
        cgmConnectionStatus: 'Scanning for sensor',
        clearCgmLastError: true,
        sensors: _updateActiveSensor(
          (sensor) => sensor.copyWith(
            serialNumber: cleanSerial ?? sensor.serialNumber,
            status: sensor.status == SensorStatus.inactive
                ? SensorStatus.attached
                : sensor.status,
            connectionStatus: ConnectionStatus.nearby,
          ),
        ),
        syncLogs: [
          SensorSyncLog(
            id: 'sync-${now.millisecondsSinceEpoch}',
            sensorId: patient?.sensorId ?? 'sensor-1',
            patientId: state.selectedPatientId,
            event: 'Sensor scan',
            status: 'pending',
            timestamp: now,
            details: 'Scanning for the sensor via the native CGM SDK.',
          ),
          ...state.syncLogs,
        ],
      );
      return;
    }

    final warmupEnd = now.add(const Duration(hours: 1));
    state = state.copyWith(
      cgmSensorSn: cleanSerial,
      cgmConnecting: false,
      cgmConnected: false,
      cgmConnectionStatus: 'Browser preview only',
      clearCgmLastError: true,
      sensors: _updateActiveSensor(
        (sensor) => sensor.copyWith(
          serialNumber: cleanSerial ?? sensor.serialNumber,
          status: SensorStatus.warmingUp,
          warmupStartTime: now,
          warmupEndTime: warmupEnd,
          connectionStatus: ConnectionStatus.nearby,
        ),
      ),
      syncLogs: [
        SensorSyncLog(
          id: 'sync-${now.millisecondsSinceEpoch}',
          sensorId: patient?.sensorId ?? 'sensor-1',
          patientId: state.selectedPatientId,
          event: 'Sensor scan',
          status: 'success',
          timestamp: now,
          details:
              'Browser preview started the activation flow without native sensor connection.',
        ),
        ...state.syncLogs,
      ],
    );
  }

  void setCgmAuthState({required bool authorized, String? error}) {
    state = state.copyWith(
      cgmAuthorized: authorized,
      cgmLastError: error,
      clearCgmLastError: error == null,
      cgmSdkLogs: _prependLog(
        authorized
            ? 'SDK authorization completed.'
            : 'SDK authorization failed.',
      ),
    );
  }

  void setCgmConnectionState({
    required String status,
    bool? connected,
    bool? connecting,
    String? sensorSn,
    String? error,
  }) {
    final isConnected = connected ?? state.cgmConnected;
    final now = DateTime.now();
    final cleanSerial = _cleanSerial(sensorSn);
    state = state.copyWith(
      cgmConnected: isConnected,
      cgmConnecting: connecting ?? false,
      cgmConnectionStatus: status,
      cgmSensorSn: cleanSerial ?? state.cgmSensorSn,
      cgmLastError: error,
      clearCgmLastError: error == null,
      cgmSdkLogs: _prependLog(status),
      sensors: _updateActiveSensor(
        (sensor) => sensor.copyWith(
          serialNumber: cleanSerial ?? sensor.serialNumber,
          status: isConnected
              ? sensor.status == SensorStatus.active
                    ? SensorStatus.active
                    : SensorStatus.warmingUp
              : sensor.status,
          warmupStartTime: isConnected
              ? sensor.warmupStartTime ?? now
              : sensor.warmupStartTime,
          warmupEndTime: isConnected
              ? sensor.warmupEndTime ?? now.add(const Duration(hours: 1))
              : sensor.warmupEndTime,
          connectionStatus: isConnected
              ? ConnectionStatus.connected
              : sensor.connectionStatus,
        ),
      ),
    );
  }

  void setCgmSyncProgress(int progress) {
    state = state.copyWith(cgmSyncProgress: progress.clamp(0, 100));
  }

  void addCgmLog(String message) {
    state = state.copyWith(cgmSdkLogs: _prependLog(message));
  }

  void applyCgmDeviceInfo(Map<String, dynamic> info) {
    final now = DateTime.now();
    final sdkSensorState = info['sensorState'] is num
        ? (info['sensorState'] as num).toInt()
        : null;
    final isExpired =
        info['isExpired'] == true ||
        sdkSensorState == 3 ||
        sdkSensorState == 4 ||
        sdkSensorState == 5;
    final isPreheating = info['isPreheating'] == true || sdkSensorState == 1;
    final isInUse = info['isInUse'] == true || sdkSensorState == 2;
    final battery = info['battery'] is num
        ? (info['battery'] as num).toInt().clamp(0, 100)
        : null;
    final activationTimestamp = _firstIntValue([
      info['deviceActivateTimestamp'],
      info['sensorStartTime'],
    ]);
    final activationDate =
        activationTimestamp == null || activationTimestamp <= 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(activationTimestamp * 1000);

    state = state.copyWith(
      cgmConnected: isInUse || state.cgmConnected,
      cgmConnecting: false,
      cgmConnectionStatus: isExpired
          ? 'Sensor expired'
          : isPreheating
          ? 'Sensor warming up'
          : isInUse
          ? 'Sensor active'
          : state.cgmConnectionStatus,
      sensors: _updateActiveSensor(
        (sensor) => sensor.copyWith(
          status: isExpired
              ? SensorStatus.expired
              : isPreheating
              ? SensorStatus.warmingUp
              : isInUse
              ? SensorStatus.active
              : sensor.status,
          batteryStatus: battery ?? sensor.batteryStatus,
          activationDate: activationDate ?? sensor.activationDate,
          expiryDate:
              activationDate?.add(const Duration(days: 14)) ??
              sensor.expiryDate,
          warmupStartTime: isPreheating
              ? sensor.warmupStartTime ?? now
              : sensor.warmupStartTime,
          warmupEndTime: isPreheating
              ? sensor.warmupEndTime ?? now.add(const Duration(hours: 1))
              : sensor.warmupEndTime,
          connectionStatus: isInUse || state.cgmConnected
              ? ConnectionStatus.connected
              : sensor.connectionStatus,
        ),
      ),
    );
  }

  void applyCgmReadings(List<CgmBloodSugarReading> sdkReadings) {
    if (sdkReadings.isEmpty) return;

    final patient = selectedPatient ?? state.patients.first;
    final sensor = state.sensors.firstWhere(
      (item) => item.id == patient.sensorId,
      orElse: () => state.sensors.first,
    );
    final converted = sdkReadings.map((reading) {
      final value = _sdkGlucoseToMgDl(reading.processedBloodSugar);
      return OptimusGlucoseReading(
        id: 'sdk-${sensor.id}-${reading.createTime}-${reading.timeOffset}-${reading.trend}',
        sensorId: sensor.id,
        patientId: patient.id,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          reading.createTime * 1000,
        ),
        value: value,
        unit: 'mg/dL',
        trend: _sdkTrend(reading.trend),
        status: statusFromValue(value),
      );
    });

    final byId = <String, OptimusGlucoseReading>{
      for (final reading in state.readings) reading.id: reading,
      for (final reading in converted) reading.id: reading,
    };
    final merged = byId.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    state = state.copyWith(
      readings: merged,
      alerts: _mergeAlerts(
        state.alerts,
        _alertsForReadings(converted, state.alertSettings),
      ),
      cgmConnected: true,
      cgmConnecting: false,
      cgmConnectionStatus: 'Live glucose data received',
      sensors: _updateActiveSensor(
        (item) => item.copyWith(
          status: SensorStatus.active,
          connectionStatus: ConnectionStatus.connected,
        ),
      ),
      syncLogs: [
        SensorSyncLog(
          id: 'sync-sdk-${DateTime.now().millisecondsSinceEpoch}',
          sensorId: sensor.id,
          patientId: patient.id,
          event: 'SDK reading sync',
          status: 'success',
          timestamp: DateTime.now(),
          details: '${sdkReadings.length} live SDK reading(s) received.',
        ),
        ...state.syncLogs,
      ],
    );
  }

  void finishWarmupNow() {
    final now = DateTime.now();
    state = state.copyWith(
      sensors: _updateActiveSensor(
        (sensor) => sensor.copyWith(
          status: SensorStatus.active,
          activationDate: now,
          expiryDate: now.add(const Duration(days: 14)),
          warmupEndTime: now,
          connectionStatus: ConnectionStatus.connected,
        ),
      ),
    );
  }

  void placeReorder(int quantity, String shippingAddress) {
    final now = DateTime.now();
    state = state.copyWith(
      orders: [
        Order(
          id: 'order-${now.millisecondsSinceEpoch}',
          patientId: state.activePatientId,
          productName: 'Optimus CGM 14-day sensor',
          quantity: quantity,
          status: 'placed',
          shippingAddress: shippingAddress,
          createdAt: now,
        ),
        ...state.orders,
      ],
    );
  }

  void connectIntegration(String integrationId) {
    state = state.copyWith(
      integrations: state.integrations
          .map(
            (integration) => integration.id == integrationId
                ? integration.copyWith(
                    status: 'connected',
                    lastSync: DateTime.now(),
                  )
                : integration,
          )
          .toList(),
    );
  }

  List<Sensor> _updateActiveSensor(Sensor Function(Sensor sensor) updater) {
    final patient = selectedPatient ?? state.patients.first;
    return state.sensors
        .map(
          (sensor) => sensor.id == patient.sensorId ? updater(sensor) : sensor,
        )
        .toList();
  }

  List<String> _prependLog(String message) {
    final time = DateTime.now();
    final stamp =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return ['$stamp  $message', ...state.cgmSdkLogs].take(20).toList();
  }

  String? _cleanSerial(String? value) {
    return normalizeSensorSerial(value);
  }

  int _sdkGlucoseToMgDl(double value) {
    final mgDl = value > 25 ? value : value * 18.0182;
    return mgDl.round().clamp(0, 500);
  }

  int? _firstIntValue(List<Object?> values) {
    for (final value in values) {
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  TrendDirection _sdkTrend(int trend) {
    return switch (trend) {
      15 => TrendDirection.risingFast,
      5 => TrendDirection.rising,
      20 => TrendDirection.fallingFast,
      10 => TrendDirection.falling,
      _ => TrendDirection.steady,
    };
  }

  OptimusRole _inferRole(String email) {
    return optimusUsers
        .firstWhere(
          (user) => user.email.toLowerCase() == email.trim().toLowerCase(),
          orElse: () => optimusUsers.first,
        )
        .role;
  }

  OptimusUser _userForRole(OptimusRole role) {
    return optimusUsers.firstWhere((user) => user.role == role);
  }

  Patient _patientForRole(OptimusRole role) {
    if (role == OptimusRole.doctor) {
      return state.patients.firstWhere(
        (patient) => patient.doctorId == 'doctor-1',
      );
    }
    return state.patients.first;
  }

  Patient? get selectedPatient => state.patients
      .where((patient) => patient.id == state.selectedPatientId)
      .firstOrNull;

  List<OptimusGlucoseReading> get selectedReadings {
    return state.readings
        .where((reading) => reading.patientId == state.selectedPatientId)
        .toList();
  }

  String _mealTypeLabel(MealType type) {
    return switch (type) {
      MealType.breakfast => 'Breakfast',
      MealType.lunch => 'Lunch',
      MealType.dinner => 'Dinner',
      MealType.snack => 'Snack',
    };
  }

  List<GlucoseAlert> _mergeAlerts(
    List<GlucoseAlert> existing,
    List<GlucoseAlert> incoming,
  ) {
    final byId = <String, GlucoseAlert>{
      for (final alert in existing) alert.id: alert,
      for (final alert in incoming) alert.id: alert,
    };
    return byId.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<GlucoseAlert> _alertsForReadings(
    Iterable<OptimusGlucoseReading> readings,
    AlertSettings settings,
  ) {
    if (!settings.notificationsEnabled) return const [];

    return readings
        .where((reading) {
          return reading.value <= settings.lowThreshold ||
              reading.value >= settings.highThreshold;
        })
        .map((reading) {
          final high = reading.value >= settings.highThreshold;
          return GlucoseAlert(
            id: 'alert-${reading.id}',
            patientId: reading.patientId,
            timestamp: reading.timestamp,
            title: high ? 'High glucose alert' : 'Low glucose alert',
            message: high
                ? 'Glucose crossed ${settings.highThreshold} mg/dL. Review food, activity, and care-team guidance.'
                : 'Glucose dropped below ${settings.lowThreshold} mg/dL. Follow your clinician-approved safety plan.',
            value: reading.value,
            threshold: high ? settings.highThreshold : settings.lowThreshold,
            severity: high ? AlertSeverity.warning : AlertSeverity.urgent,
            acknowledged: false,
          );
        })
        .toList();
  }
}

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

final selectedPatientProvider = Provider<Patient?>((ref) {
  final state = ref.watch(appControllerProvider);
  return state.patients
      .where((patient) => patient.id == state.selectedPatientId)
      .firstOrNull;
});

final selectedSensorProvider = Provider<Sensor?>((ref) {
  final state = ref.watch(appControllerProvider);
  final patient = ref.watch(selectedPatientProvider);
  return state.sensors
      .where((sensor) => sensor.id == patient?.sensorId)
      .firstOrNull;
});

final selectedReadingsProvider = Provider<List<OptimusGlucoseReading>>((ref) {
  final state = ref.watch(appControllerProvider);
  final patientId = state.selectedPatientId;
  final patientReadings = state.readings
      .where((reading) => reading.patientId == patientId)
      .toList();
  final liveSdkSession =
      state.cgmSensorSn != null || state.cgmConnecting || state.cgmConnected;
  final readings = liveSdkSession
      ? patientReadings
            .where((reading) => reading.id.startsWith('sdk-'))
            .toList()
      : patientReadings;
  final filtered = filterReadingsByDuration(readings, state.chartDuration);
  final status = state.readingFilter;
  if (status == null) return filtered;
  return filtered.where((reading) => reading.status == status).toList();
});

final latestReadingProvider = Provider<OptimusGlucoseReading?>((ref) {
  final readings = ref.watch(selectedReadingsProvider);
  return readings.isEmpty ? null : readings.last;
});

final summaryProvider = Provider((ref) {
  final readings = ref.watch(selectedReadingsProvider);
  return summarizeReadings(readings);
});

final selectedMealsProvider = Provider<List<MealLog>>((ref) {
  final state = ref.watch(appControllerProvider);
  return state.meals
      .where((meal) => meal.patientId == state.selectedPatientId)
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

final activeAlertsProvider = Provider<List<GlucoseAlert>>((ref) {
  final state = ref.watch(appControllerProvider);
  return state.alerts
      .where(
        (alert) =>
            alert.patientId == state.selectedPatientId && !alert.acknowledged,
      )
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});

final selectedReportExportsProvider = Provider<List<ReportExport>>((ref) {
  final state = ref.watch(appControllerProvider);
  return state.reportExports
      .where((report) => report.patientId == state.selectedPatientId)
      .toList()
    ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
});

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

extension TakeLast<T> on List<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return skip(length - count);
  }
}
