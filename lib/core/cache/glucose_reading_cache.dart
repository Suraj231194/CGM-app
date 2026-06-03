import 'dart:collection';

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
