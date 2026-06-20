import 'dart:convert';
import 'dart:collection';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/optimus_models.dart';

/// In-memory cache for glucose readings with LRU eviction.
/// Provides offline-first access to recently loaded readings.
class GlucoseReadingCache {
  GlucoseReadingCache({this.maxEntries = 5000});

  final int maxEntries;
  final LinkedHashMap<String, OptimusGlucoseReading> _cache =
      LinkedHashMap<String, OptimusGlucoseReading>();

  /// All cached readings sorted by timestamp.
  List<OptimusGlucoseReading> get all {
    final readings = _cache.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return readings;
  }

  /// Readings for a specific patient.
  List<OptimusGlucoseReading> forPatient(String patientId) {
    return all.where((r) => r.patientId == patientId).toList();
  }

  /// Add or update readings in the cache.
  void addAll(Iterable<OptimusGlucoseReading> readings) {
    for (final reading in readings) {
      _cache[reading.id] = reading;
    }
    _evict();
  }

  /// Add a single reading.
  void add(OptimusGlucoseReading reading) {
    _cache[reading.id] = reading;
    _evict();
  }

  /// Number of cached entries.
  int get length => _cache.length;

  /// Clear all cached readings.
  void clear() => _cache.clear();

  void _evict() {
    while (_cache.length > maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }
}

class PersistentGlucoseReadingCache {
  const PersistentGlucoseReadingCache._();

  static const _storageKey = 'optimus_live_glucose_readings_v1';

  static Future<List<OptimusGlucoseReading>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => glucoseReadingFromJson(Map<String, dynamic>.from(item)),
          )
          .whereType<OptimusGlucoseReading>()
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(
    Iterable<OptimusGlucoseReading> readings, {
    int maxEntries = 5000,
  }) async {
    final sorted = readings.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final trimmed = sorted.length > maxEntries
        ? sorted.sublist(sorted.length - maxEntries)
        : sorted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(trimmed.map(glucoseReadingToJson).toList()),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

Map<String, Object?> glucoseReadingToJson(OptimusGlucoseReading reading) {
  return {
    'id': reading.id,
    'sensorId': reading.sensorId,
    'patientId': reading.patientId,
    'timestamp': reading.timestamp.toIso8601String(),
    'value': reading.value,
    'unit': reading.unit,
    'trend': reading.trend.name,
    'status': reading.status.name,
  };
}

OptimusGlucoseReading? glucoseReadingFromJson(Map<String, dynamic> json) {
  final id = json['id'] as String?;
  final sensorId = json['sensorId'] as String?;
  final patientId = json['patientId'] as String?;
  final timestamp = DateTime.tryParse(json['timestamp']?.toString() ?? '');
  final value = json['value'];
  final unit = json['unit'] as String?;
  final trend = _enumByName(TrendDirection.values, json['trend']);
  final status = _enumByName(GlucoseStatus.values, json['status']);

  if (id == null ||
      sensorId == null ||
      patientId == null ||
      timestamp == null ||
      value is! num ||
      unit == null ||
      trend == null ||
      status == null) {
    return null;
  }

  return OptimusGlucoseReading(
    id: id,
    sensorId: sensorId,
    patientId: patientId,
    timestamp: timestamp,
    value: value.toInt(),
    unit: unit,
    trend: trend,
    status: status,
  );
}

T? _enumByName<T extends Enum>(Iterable<T> values, Object? name) {
  final target = name?.toString();
  if (target == null) return null;
  for (final value in values) {
    if (value.name == target) return value;
  }
  return null;
}
