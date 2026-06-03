import 'package:flutter_test/flutter_test.dart';
import 'package:optimus_cgm_flutter/core/pagination/readings_paginator.dart';
import 'package:optimus_cgm_flutter/models/optimus_models.dart';

void main() {
  List<OptimusGlucoseReading> createReadings(int count) {
    return List.generate(
      count,
      (i) => OptimusGlucoseReading(
        id: 'r-$i',
        sensorId: 's-1',
        patientId: 'p-1',
        timestamp: DateTime.now().subtract(Duration(minutes: i * 3)),
        value: 100 + (i % 30),
        unit: 'mg/dL',
        trend: TrendDirection.steady,
        status: GlucoseStatus.normal,
      ),
    );
  }

  group('ReadingsPaginator', () {
    test('reports correct total count and pages', () {
      final paginator = ReadingsPaginator(allReadings: createReadings(250));
      expect(paginator.totalCount, 250);
      expect(paginator.totalPages, 3);
      expect(paginator.currentPage, 0);
      expect(paginator.hasMore, isTrue);
    });

    test('currentPageReadings returns correct slice', () {
      final paginator = ReadingsPaginator(allReadings: createReadings(250));
      expect(paginator.currentPageReadings.length, 100);
    });

    test('loadNext advances page', () {
      final paginator = ReadingsPaginator(allReadings: createReadings(250));
      final next = paginator.loadNext();
      expect(next.length, 100);
      expect(paginator.currentPage, 1);
    });

    test('hasMore returns false on last page', () {
      final paginator = ReadingsPaginator(allReadings: createReadings(150));
      paginator.loadNext(); // page 1 (last)
      expect(paginator.hasMore, isFalse);
    });

    test('loadNext returns empty when no more pages', () {
      final paginator = ReadingsPaginator(allReadings: createReadings(50));
      expect(paginator.hasMore, isFalse);
      final result = paginator.loadNext();
      expect(result, isEmpty);
    });

    test('reset goes back to page 0', () {
      final paginator = ReadingsPaginator(allReadings: createReadings(250));
      paginator.loadNext();
      paginator.loadNext();
      expect(paginator.currentPage, 2);
      paginator.reset();
      expect(paginator.currentPage, 0);
    });

    test('loadedReadings grows with pages', () {
      final paginator = ReadingsPaginator(allReadings: createReadings(250));
      expect(paginator.loadedReadings.length, 100);
      paginator.loadNext();
      expect(paginator.loadedReadings.length, 200);
      paginator.loadNext();
      expect(paginator.loadedReadings.length, 250);
    });
  });
}
