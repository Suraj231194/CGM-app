import 'package:flutter_test/flutter_test.dart';
import 'package:optimus_cgm_flutter/core/cache/glucose_reading_cache.dart';
import 'package:optimus_cgm_flutter/models/optimus_models.dart';

void main() {
  OptimusGlucoseReading makeReading(String id, int minutesAgo) {
    return OptimusGlucoseReading(
      id: id,
      sensorId: 's-1',
      patientId: 'p-1',
      timestamp: DateTime.now().subtract(Duration(minutes: minutesAgo)),
      value: 110,
      unit: 'mg/dL',
      trend: TrendDirection.steady,
      status: GlucoseStatus.normal,
    );
  }

  group('GlucoseReadingCache', () {
    test('addAll stores readings', () {
      final cache = GlucoseReadingCache(maxEntries: 100);
      cache.addAll([makeReading('r-1', 10), makeReading('r-2', 5)]);
      expect(cache.length, 2);
    });

    test('all returns sorted by timestamp', () {
      final cache = GlucoseReadingCache(maxEntries: 100);
      cache.addAll([makeReading('r-1', 10), makeReading('r-2', 5)]);
      final all = cache.all;
      expect(all.first.id, 'r-1'); // older first
      expect(all.last.id, 'r-2');
    });

    test('evicts oldest when over capacity', () {
      final cache = GlucoseReadingCache(maxEntries: 3);
      cache.addAll([
        makeReading('r-1', 30),
        makeReading('r-2', 20),
        makeReading('r-3', 10),
        makeReading('r-4', 5),
      ]);
      expect(cache.length, 3);
    });

    test('forPatient filters correctly', () {
      final cache = GlucoseReadingCache(maxEntries: 100);
      cache.add(
        OptimusGlucoseReading(
          id: 'r-a',
          sensorId: 's-1',
          patientId: 'p-1',
          timestamp: DateTime.now(),
          value: 100,
          unit: 'mg/dL',
          trend: TrendDirection.steady,
          status: GlucoseStatus.normal,
        ),
      );
      cache.add(
        OptimusGlucoseReading(
          id: 'r-b',
          sensorId: 's-2',
          patientId: 'p-2',
          timestamp: DateTime.now(),
          value: 150,
          unit: 'mg/dL',
          trend: TrendDirection.rising,
          status: GlucoseStatus.normal,
        ),
      );
      expect(cache.forPatient('p-1').length, 1);
      expect(cache.forPatient('p-2').length, 1);
      expect(cache.forPatient('p-3').length, 0);
    });

    test('clear removes all entries', () {
      final cache = GlucoseReadingCache(maxEntries: 100);
      cache.addAll([makeReading('r-1', 10), makeReading('r-2', 5)]);
      cache.clear();
      expect(cache.length, 0);
    });

    test('deduplicates by id', () {
      final cache = GlucoseReadingCache(maxEntries: 100);
      cache.add(makeReading('r-1', 10));
      cache.add(makeReading('r-1', 10));
      expect(cache.length, 1);
    });
  });
}
