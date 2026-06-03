import '../../app/theme.dart';
import '../../models/optimus_models.dart';

String _string(Map<String, dynamic> json, String key, [String fallback = '']) {
  return json[key]?.toString() ?? fallback;
}

int _int(Map<String, dynamic> json, String key, [int fallback = 0]) {
  final value = json[key];
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _bool(Map<String, dynamic> json, String key, [bool fallback = false]) {
  final value = json[key];
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true' ? true : fallback;
}

DateTime _date(Map<String, dynamic> json, String key) {
  return DateTime.tryParse(json[key]?.toString() ?? '') ?? DateTime.now();
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  final text = raw?.toString();
  return values.firstWhere(
    (value) => value.name == text,
    orElse: () => fallback,
  );
}

List<Map<String, dynamic>> recordsFrom(Object? data, String key) {
  final payload = data is Map<String, dynamic>
      ? data[key] ?? data['data']
      : data;
  if (payload is List) {
    return payload.whereType<Map>().map((item) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }).toList();
  }
  return const [];
}

OptimusUser userFromJson(Map<String, dynamic> json) {
  return OptimusUser(
    id: _string(json, 'id'),
    name: _string(json, 'name'),
    role: _enumByName(OptimusRole.values, json['role'], OptimusRole.customer),
    email: _string(json, 'email'),
    phone: _string(json, 'phone'),
  );
}

Patient patientFromJson(Map<String, dynamic> json) {
  return Patient(
    id: _string(json, 'id'),
    name: _string(json, 'name'),
    age: _int(json, 'age'),
    gender: _string(json, 'gender'),
    doctorId: _string(json, 'doctorId', _string(json, 'doctor_id')),
    sensorId: _string(json, 'sensorId', _string(json, 'sensor_id')),
    riskLevel: _string(
      json,
      'riskLevel',
      _string(json, 'risk_level', 'stable'),
    ),
  );
}

Sensor sensorFromJson(Map<String, dynamic> json) {
  return Sensor(
    id: _string(json, 'id'),
    serialNumber: _string(json, 'serialNumber', _string(json, 'serial_number')),
    patientId: _string(json, 'patientId', _string(json, 'patient_id')),
    status: _enumByName(
      SensorStatus.values,
      json['status'],
      SensorStatus.inactive,
    ),
    batteryStatus: _int(json, 'batteryStatus', _int(json, 'battery_status')),
    connectionStatus: _enumByName(
      ConnectionStatus.values,
      json['connectionStatus'] ?? json['connection_status'],
      ConnectionStatus.offline,
    ),
    activationDate:
        _optionalDate(json, 'activationDate') ??
        _optionalDate(json, 'activation_date'),
    expiryDate:
        _optionalDate(json, 'expiryDate') ?? _optionalDate(json, 'expiry_date'),
    warmupStartTime:
        _optionalDate(json, 'warmupStartTime') ??
        _optionalDate(json, 'warmup_start_time'),
    warmupEndTime:
        _optionalDate(json, 'warmupEndTime') ??
        _optionalDate(json, 'warmup_end_time'),
  );
}

OptimusGlucoseReading readingFromJson(Map<String, dynamic> json) {
  final value = _int(json, 'value');
  return OptimusGlucoseReading(
    id: _string(json, 'id'),
    sensorId: _string(json, 'sensorId', _string(json, 'sensor_id')),
    patientId: _string(json, 'patientId', _string(json, 'patient_id')),
    timestamp: _date(json, 'timestamp'),
    value: value,
    unit: _string(json, 'unit', 'mg/dL'),
    trend: _enumByName(
      TrendDirection.values,
      json['trend'],
      TrendDirection.steady,
    ),
    status: _enumByName(
      GlucoseStatus.values,
      json['status'],
      value < 70
          ? GlucoseStatus.low
          : value > 180
          ? GlucoseStatus.high
          : GlucoseStatus.normal,
    ),
  );
}

MealLog mealFromJson(Map<String, dynamic> json) {
  return MealLog(
    id: _string(json, 'id'),
    patientId: _string(json, 'patientId', _string(json, 'patient_id')),
    timestamp: _date(json, 'timestamp'),
    type: _enumByName(MealType.values, json['type'], MealType.lunch),
    title: _string(json, 'title'),
    netCarbs: _int(json, 'netCarbs', _int(json, 'net_carbs')),
    protein: _int(json, 'protein'),
    fiber: _int(json, 'fiber'),
    activityMinutes: _int(
      json,
      'activityMinutes',
      _int(json, 'activity_minutes'),
    ),
    score: _int(json, 'score'),
    note: _string(json, 'note'),
  );
}

AIInterpretation interpretationFromJson(Map<String, dynamic> json) {
  return AIInterpretation(
    id: _string(json, 'id'),
    patientId: _string(json, 'patientId', _string(json, 'patient_id')),
    period: _string(json, 'period'),
    summary: _string(json, 'summary'),
    patterns:
        (json['patterns'] as List?)?.map((item) => item.toString()).toList() ??
        const [],
    recommendations:
        (json['recommendations'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const [],
    disclaimer: _string(json, 'disclaimer'),
    tone: _string(json, 'tone', 'patient'),
  );
}

Order orderFromJson(Map<String, dynamic> json) {
  return Order(
    id: _string(json, 'id'),
    patientId: _string(json, 'patientId', _string(json, 'patient_id')),
    productName: _string(json, 'productName', _string(json, 'product_name')),
    quantity: _int(json, 'quantity', 1),
    status: _string(json, 'status', 'placed'),
    shippingAddress: _string(
      json,
      'shippingAddress',
      _string(json, 'shipping_address'),
    ),
    createdAt: _date(json, 'createdAt'),
  );
}

GlucoseAlert alertFromJson(Map<String, dynamic> json) {
  return GlucoseAlert(
    id: _string(json, 'id'),
    patientId: _string(json, 'patientId', _string(json, 'patient_id')),
    timestamp: _date(json, 'timestamp'),
    title: _string(json, 'title'),
    message: _string(json, 'message'),
    value: _int(json, 'value'),
    threshold: _int(json, 'threshold'),
    severity: _enumByName(
      AlertSeverity.values,
      json['severity'],
      AlertSeverity.info,
    ),
    acknowledged: _bool(json, 'acknowledged'),
  );
}

AlertSettings alertSettingsFromJson(Map<String, dynamic> json) {
  return AlertSettings(
    notificationsEnabled: _bool(
      json,
      'notificationsEnabled',
      _bool(json, 'notifications_enabled', true),
    ),
    lowThreshold: _int(json, 'lowThreshold', _int(json, 'low_threshold', 70)),
    highThreshold: _int(
      json,
      'highThreshold',
      _int(json, 'high_threshold', 180),
    ),
    quietHoursEnabled: _bool(
      json,
      'quietHoursEnabled',
      _bool(json, 'quiet_hours_enabled'),
    ),
  );
}

ReportExport reportFromJson(Map<String, dynamic> json) {
  return ReportExport(
    id: _string(json, 'id'),
    patientId: _string(json, 'patientId', _string(json, 'patient_id')),
    period: _string(json, 'period'),
    generatedAt: _date(json, 'generatedAt'),
    format: _string(json, 'format', 'PDF'),
    status: _string(json, 'status', 'ready'),
    summary: _string(json, 'summary'),
  );
}
