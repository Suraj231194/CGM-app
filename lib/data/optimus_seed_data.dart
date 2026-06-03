import 'dart:math' as math;

import '../app/theme.dart';
import '../models/optimus_models.dart';
import '../utils/glucose_utils.dart';

final _now = DateTime.now();

DateTime minutesAgo(int minutes) => _now.subtract(Duration(minutes: minutes));
DateTime minutesFromNow(int minutes) => _now.add(Duration(minutes: minutes));

TrendDirection trendFromDelta(int delta) {
  if (delta >= 10) return TrendDirection.risingFast;
  if (delta >= 4) return TrendDirection.rising;
  if (delta <= -10) return TrendDirection.fallingFast;
  if (delta <= -4) return TrendDirection.falling;
  return TrendDirection.steady;
}

const optimusUsers = <OptimusUser>[
  OptimusUser(
    id: 'user-customer-1',
    name: 'Aarav Mehta',
    role: OptimusRole.customer,
    email: 'customer@optimus.test',
    phone: '+91 98765 43210',
  ),
  OptimusUser(
    id: 'user-doctor-1',
    name: 'Dr. Meera Shah',
    role: OptimusRole.doctor,
    email: 'doctor@optimus.test',
    phone: '+91 99887 77665',
  ),
  OptimusUser(
    id: 'user-admin-1',
    name: 'Optimus Support Admin',
    role: OptimusRole.admin,
    email: 'admin@optimus.test',
    phone: '+91 90000 11122',
  ),
];

const optimusPatients = <Patient>[
  Patient(
    id: 'patient-1',
    name: 'Aarav Mehta',
    age: 42,
    gender: 'Male',
    doctorId: 'doctor-1',
    sensorId: 'sensor-1',
    riskLevel: 'stable',
  ),
  Patient(
    id: 'patient-2',
    name: 'Priya Nair',
    age: 36,
    gender: 'Female',
    doctorId: 'doctor-1',
    sensorId: 'sensor-2',
    riskLevel: 'watch',
  ),
  Patient(
    id: 'patient-3',
    name: 'Kabir Sethi',
    age: 51,
    gender: 'Male',
    doctorId: 'doctor-2',
    sensorId: 'sensor-3',
    riskLevel: 'urgent',
  ),
  Patient(
    id: 'patient-4',
    name: 'Nisha Rao',
    age: 29,
    gender: 'Female',
    doctorId: 'doctor-1',
    sensorId: 'sensor-4',
    riskLevel: 'stable',
  ),
];

final optimusSensors = <Sensor>[
  Sensor(
    id: 'sensor-1',
    serialNumber: 'OPT-CGM-14D-001',
    patientId: 'patient-1',
    status: SensorStatus.active,
    activationDate: minutesAgo(9 * 24 * 60),
    expiryDate: minutesFromNow(5 * 24 * 60),
    warmupStartTime: minutesAgo(9 * 24 * 60 + 60),
    warmupEndTime: minutesAgo(9 * 24 * 60),
    batteryStatus: 74,
    connectionStatus: ConnectionStatus.connected,
  ),
  Sensor(
    id: 'sensor-2',
    serialNumber: 'OPT-CGM-14D-002',
    patientId: 'patient-2',
    status: SensorStatus.active,
    activationDate: minutesAgo(12 * 24 * 60),
    expiryDate: minutesFromNow(2 * 24 * 60),
    batteryStatus: 38,
    connectionStatus: ConnectionStatus.weak,
  ),
  Sensor(
    id: 'sensor-3',
    serialNumber: 'OPT-CGM-14D-003',
    patientId: 'patient-3',
    status: SensorStatus.active,
    activationDate: minutesAgo(3 * 24 * 60),
    expiryDate: minutesFromNow(11 * 24 * 60),
    batteryStatus: 86,
    connectionStatus: ConnectionStatus.connected,
  ),
  Sensor(
    id: 'sensor-4',
    serialNumber: 'OPT-CGM-14D-004',
    patientId: 'patient-4',
    status: SensorStatus.warmingUp,
    warmupStartTime: minutesAgo(24),
    warmupEndTime: minutesFromNow(36),
    batteryStatus: 97,
    connectionStatus: ConnectionStatus.nearby,
  ),
];

List<OptimusGlucoseReading> createOptimusReadings({
  String patientId = 'patient-1',
  String sensorId = 'sensor-1',
}) {
  final readings = <OptimusGlucoseReading>[];
  const total = 14 * 24 * 20;

  for (var index = total - 1; index >= 0; index -= 1) {
    final minutes = index * 3;
    final date = _now.subtract(Duration(minutes: minutes));
    final hour = date.hour + date.minute / 60;
    final breakfast = hour >= 7 && hour <= 9.5
        ? 24 * math.sin(((hour - 7) / 2.5) * math.pi)
        : 0.0;
    final lunch = hour >= 12.2 && hour <= 15
        ? 44 * math.sin(((hour - 12.2) / 2.8) * math.pi)
        : 0.0;
    final dinner = hour >= 19 && hour <= 22
        ? 36 * math.sin(((hour - 19) / 3) * math.pi)
        : 0.0;
    final overnight = hour >= 1 && hour <= 5 ? -8.0 : 0.0;
    final exercise = hour >= 17.2 && hour <= 18.2 ? -12.0 : 0.0;
    final weeklyRhythm = math.sin(index / 260) * 10;
    final signal = math.sin(index / 8) * 5 + math.cos(index / 17) * 4;
    final value =
        (106 +
                breakfast +
                lunch +
                dinner +
                overnight +
                exercise +
                weeklyRhythm +
                signal)
            .round()
            .clamp(54, 245);
    final previous = readings.isEmpty ? value : readings.last.value;

    readings.add(
      OptimusGlucoseReading(
        id: 'opt-reading-$patientId-$index',
        sensorId: sensorId,
        patientId: patientId,
        timestamp: date,
        value: value,
        unit: 'mg/dL',
        trend: trendFromDelta(value - previous),
        status: statusFromValue(value),
      ),
    );
  }

  return readings;
}

final allOptimusReadings = optimusPatients
    .expand(
      (patient) => createOptimusReadings(
        patientId: patient.id,
        sensorId: patient.sensorId,
      ),
    )
    .toList();

const defaultConsentPreferences = ConsentPreferences(
  healthData: false,
  sensorData: false,
  aiCoaching: false,
  reportSharing: false,
  termsAccepted: false,
);

const defaultAlertSettings = AlertSettings(
  notificationsEnabled: true,
  lowThreshold: 70,
  highThreshold: 180,
  quietHoursEnabled: false,
);

final optimusMealLogs = <MealLog>[
  MealLog(
    id: 'meal-1',
    patientId: 'patient-1',
    timestamp: minutesAgo(6 * 60),
    type: MealType.breakfast,
    title: 'Oats, eggs, and berries',
    netCarbs: 38,
    protein: 24,
    fiber: 9,
    activityMinutes: 12,
    score: 86,
    note: 'Stable response after a short walk.',
  ),
  MealLog(
    id: 'meal-2',
    patientId: 'patient-1',
    timestamp: minutesAgo(2 * 60),
    type: MealType.lunch,
    title: 'Rice bowl with paneer',
    netCarbs: 58,
    protein: 31,
    fiber: 7,
    activityMinutes: 8,
    score: 72,
    note: 'Higher carb load; pair with more fiber next time.',
  ),
];

final optimusAlerts = <GlucoseAlert>[
  GlucoseAlert(
    id: 'alert-lunch-rise',
    patientId: 'patient-1',
    timestamp: minutesAgo(96),
    title: 'Post-meal rise',
    message:
        'Glucose crossed the high threshold after lunch. Review meal timing with your care team.',
    value: 186,
    threshold: 180,
    severity: AlertSeverity.warning,
    acknowledged: false,
  ),
];

final optimusReportExports = <ReportExport>[
  ReportExport(
    id: 'report-7d-1',
    patientId: 'patient-1',
    period: '7 day',
    generatedAt: minutesAgo(18 * 60),
    format: 'PDF',
    status: 'ready',
    summary: 'Time in range, GMI, meal impact, alerts, and sensor summary.',
  ),
];

const optimusAIInterpretations = <AIInterpretation>[
  AIInterpretation(
    id: 'ai-patient-1-day',
    patientId: 'patient-1',
    period: 'Today',
    tone: 'patient',
    summary:
        'Your glucose was mostly within range today, with a short rise after lunch and stable overnight values.',
    patterns: [
      'Post-lunch glucose rose above your usual daily pattern.',
      'Evening recovery improved after activity was logged.',
      'No sustained low glucose period was detected in the current view.',
    ],
    recommendations: [
      'Review lunch timing, portion size, and carbohydrate pairing with your clinician.',
      'Repeat the post-meal walk habit for the next three lunches.',
      'Keep the phone close to the sensor for continuous 3-minute updates.',
    ],
    disclaimer:
        'Informational only. This is not a diagnosis, emergency guidance, or a replacement for clinician advice.',
  ),
];

final optimusSyncLogs = <SensorSyncLog>[
  SensorSyncLog(
    id: 'sync-1',
    sensorId: 'sensor-1',
    patientId: 'patient-1',
    event: 'Reading sync',
    status: 'success',
    timestamp: minutesAgo(3),
    details: 'Latest 3-minute reading received from connected phone.',
  ),
  SensorSyncLog(
    id: 'sync-2',
    sensorId: 'sensor-2',
    patientId: 'patient-2',
    event: 'Connection quality',
    status: 'warning',
    timestamp: minutesAgo(18),
    details:
        'Weak phone proximity detected. Ask customer to keep phone close to sensor.',
  ),
  SensorSyncLog(
    id: 'sync-3',
    sensorId: 'sensor-3',
    patientId: 'patient-3',
    event: 'High alert delivery',
    status: 'success',
    timestamp: minutesAgo(41),
    details: 'High alert acknowledged in app notification center.',
  ),
];

final optimusOrders = <Order>[
  Order(
    id: 'order-1001',
    patientId: 'patient-1',
    productName: 'Optimus CGM 14-day sensor',
    quantity: 2,
    status: 'delivered',
    shippingAddress: '221 Health Park, Mumbai, Maharashtra 400001',
    createdAt: minutesAgo(21 * 24 * 60),
  ),
  Order(
    id: 'order-1002',
    patientId: 'patient-1',
    productName: 'Optimus CGM 14-day sensor',
    quantity: 1,
    status: 'shipped',
    shippingAddress: '221 Health Park, Mumbai, Maharashtra 400001',
    createdAt: minutesAgo(2 * 24 * 60),
  ),
];

const deviceIntegrations = <DeviceIntegration>[
  DeviceIntegration(
    id: 'optimus-native',
    name: 'Optimus CGM SDK',
    provider: 'Native bridge',
    category: 'cgm',
    status: 'available',
    summary:
        'Android .aar and iOS .xcframework integration path for direct sensor connectivity.',
  ),
  DeviceIntegration(
    id: 'dexcom',
    name: 'Dexcom',
    provider: 'OAuth API',
    category: 'cgm',
    status: 'available',
    summary: 'Cloud glucose import for supported Dexcom accounts.',
  ),
  DeviceIntegration(
    id: 'nightscout',
    name: 'Nightscout',
    provider: 'REST adapter',
    category: 'cgm',
    status: 'available',
    summary: 'Import readings from a Nightscout endpoint for continuity.',
  ),
  DeviceIntegration(
    id: 'apple-health',
    name: 'Apple Health',
    provider: 'HealthKit',
    category: 'health',
    status: 'comingSoon',
    summary: 'iOS lifestyle context for activity, sleep, and vitals.',
  ),
  DeviceIntegration(
    id: 'health-connect',
    name: 'Health Connect',
    provider: 'Android',
    category: 'health',
    status: 'comingSoon',
    summary: 'Android health context once native plugin permissions are added.',
  ),
  DeviceIntegration(
    id: 'watch-widget',
    name: 'Smartwatch widget',
    provider: 'Companion surfaces',
    category: 'watch',
    status: 'available',
    summary: 'Glanceable glucose, freshness, trend arrow, and alert state.',
  ),
];
