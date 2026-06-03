import 'package:flutter_test/flutter_test.dart';
import 'package:optimus_cgm_flutter/models/optimus_models.dart';
import 'package:optimus_cgm_flutter/utils/glucose_utils.dart';

void main() {
  group('statusFromValue', () {
    test('returns low for values below 70', () {
      expect(statusFromValue(69), GlucoseStatus.low);
      expect(statusFromValue(50), GlucoseStatus.low);
      expect(statusFromValue(0), GlucoseStatus.low);
    });

    test('returns normal for values 70-180', () {
      expect(statusFromValue(70), GlucoseStatus.normal);
      expect(statusFromValue(120), GlucoseStatus.normal);
      expect(statusFromValue(180), GlucoseStatus.normal);
    });

    test('returns high for values above 180', () {
      expect(statusFromValue(181), GlucoseStatus.high);
      expect(statusFromValue(250), GlucoseStatus.high);
    });
  });

  group('trendArrow', () {
    test('returns correct arrows', () {
      expect(trendArrow(TrendDirection.risingFast), '\u2191\u2191');
      expect(trendArrow(TrendDirection.rising), '\u2191');
      expect(trendArrow(TrendDirection.steady), '\u2192');
      expect(trendArrow(TrendDirection.falling), '\u2193');
      expect(trendArrow(TrendDirection.fallingFast), '\u2193\u2193');
    });
  });

  group('trendLabel', () {
    test('returns correct labels', () {
      expect(trendLabel(TrendDirection.risingFast), 'Rising fast');
      expect(trendLabel(TrendDirection.steady), 'Steady');
      expect(trendLabel(TrendDirection.fallingFast), 'Falling fast');
    });
  });

  group('glucoseStatusLabel', () {
    test('returns correct labels', () {
      expect(glucoseStatusLabel(GlucoseStatus.low), 'Low');
      expect(glucoseStatusLabel(GlucoseStatus.normal), 'Normal');
      expect(glucoseStatusLabel(GlucoseStatus.high), 'High');
    });
  });

  group('filterReadingsByDuration', () {
    final now = DateTime.now();
    final readings = List.generate(
      100,
      (i) => OptimusGlucoseReading(
        id: 'r-$i',
        sensorId: 's-1',
        patientId: 'p-1',
        timestamp: now.subtract(Duration(minutes: i * 5)),
        value: 100 + (i % 20),
        unit: 'mg/dL',
        trend: TrendDirection.steady,
        status: GlucoseStatus.normal,
      ),
    );

    test('filters to 1 hour correctly', () {
      final result = filterReadingsByDuration(readings, ChartDuration.oneHour);
      for (final r in result) {
        expect(now.difference(r.timestamp).inMinutes, lessThanOrEqualTo(60));
      }
    });

    test('filters to 3 hours correctly', () {
      final result = filterReadingsByDuration(
        readings,
        ChartDuration.threeHours,
      );
      for (final r in result) {
        expect(now.difference(r.timestamp).inMinutes, lessThanOrEqualTo(180));
      }
    });

    test('returns empty for no readings in range', () {
      final oldReadings = [
        OptimusGlucoseReading(
          id: 'old',
          sensorId: 's-1',
          patientId: 'p-1',
          timestamp: now.subtract(const Duration(days: 30)),
          value: 100,
          unit: 'mg/dL',
          trend: TrendDirection.steady,
          status: GlucoseStatus.normal,
        ),
      ];
      final result = filterReadingsByDuration(
        oldReadings,
        ChartDuration.oneHour,
      );
      expect(result, isEmpty);
    });
  });

  group('summarizeReadings', () {
    test('returns zeros for empty list', () {
      final result = summarizeReadings([]);
      expect(result.average, 0);
      expect(result.timeInRange, 0);
      expect(result.min, 0);
      expect(result.max, 0);
    });

    test('calculates correctly for all in-range', () {
      final readings = List.generate(
        10,
        (i) => OptimusGlucoseReading(
          id: 'r-$i',
          sensorId: 's-1',
          patientId: 'p-1',
          timestamp: DateTime.now(),
          value: 100,
          unit: 'mg/dL',
          trend: TrendDirection.steady,
          status: GlucoseStatus.normal,
        ),
      );
      final result = summarizeReadings(readings);
      expect(result.average, 100);
      expect(result.timeInRange, 100);
      expect(result.timeAbove, 0);
      expect(result.timeBelow, 0);
    });

    test('calculates min/max correctly', () {
      final readings = [
        OptimusGlucoseReading(
          id: 'r-1',
          sensorId: 's-1',
          patientId: 'p-1',
          timestamp: DateTime.now(),
          value: 60,
          unit: 'mg/dL',
          trend: TrendDirection.falling,
          status: GlucoseStatus.low,
        ),
        OptimusGlucoseReading(
          id: 'r-2',
          sensorId: 's-1',
          patientId: 'p-1',
          timestamp: DateTime.now(),
          value: 200,
          unit: 'mg/dL',
          trend: TrendDirection.rising,
          status: GlucoseStatus.high,
        ),
      ];
      final result = summarizeReadings(readings);
      expect(result.min, 60);
      expect(result.max, 200);
      expect(result.average, 130);
      expect(result.timeBelow, 50);
      expect(result.timeAbove, 50);
      expect(result.timeInRange, 0);
    });
  });

  group('mealScore', () {
    test('returns clamped 0-100', () {
      final high = mealScore(
        netCarbs: 0,
        protein: 100,
        fiber: 50,
        activityMinutes: 60,
      );
      expect(high, 100);

      final low = mealScore(
        netCarbs: 200,
        protein: 0,
        fiber: 0,
        activityMinutes: 0,
      );
      expect(low, 0);
    });

    test('balanced meal returns mid-range score', () {
      final score = mealScore(
        netCarbs: 40,
        protein: 25,
        fiber: 8,
        activityMinutes: 10,
      );
      expect(score, greaterThan(50));
      expect(score, lessThan(90));
    });
  });

  group('sensorDaysRemaining', () {
    test('returns 0 for null sensor', () {
      expect(sensorDaysRemaining(null), 0);
    });

    test('returns 0 for expired sensor', () {
      final sensor = Sensor(
        id: 's-1',
        serialNumber: 'SN-001',
        patientId: 'p-1',
        status: SensorStatus.expired,
        batteryStatus: 0,
        connectionStatus: ConnectionStatus.offline,
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(sensorDaysRemaining(sensor), 0);
    });

    test('returns correct days for active sensor', () {
      final sensor = Sensor(
        id: 's-1',
        serialNumber: 'SN-001',
        patientId: 'p-1',
        status: SensorStatus.active,
        batteryStatus: 80,
        connectionStatus: ConnectionStatus.connected,
        expiryDate: DateTime.now().add(const Duration(days: 5)),
      );
      expect(sensorDaysRemaining(sensor), 5);
    });
  });

  group('warmupMinutesRemaining', () {
    test('returns 0 for null sensor', () {
      expect(warmupMinutesRemaining(null), 0);
    });

    test('returns correct minutes', () {
      final sensor = Sensor(
        id: 's-1',
        serialNumber: 'SN-001',
        patientId: 'p-1',
        status: SensorStatus.warmingUp,
        batteryStatus: 90,
        connectionStatus: ConnectionStatus.nearby,
        warmupEndTime: DateTime.now().add(const Duration(minutes: 30)),
      );
      final result = warmupMinutesRemaining(sensor);
      expect(result, greaterThanOrEqualTo(29));
      expect(result, lessThanOrEqualTo(30));
    });
  });
}
