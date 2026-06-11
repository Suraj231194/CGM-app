import 'package:flutter/material.dart';
import 'package:clock/clock.dart';
import 'package:intl/intl.dart';

import '../app/theme.dart';
import '../models/optimus_models.dart';

String trendArrow(TrendDirection trend) {
  return switch (trend) {
    TrendDirection.risingFast => '\u2191\u2191',
    TrendDirection.rising => '\u2191',
    TrendDirection.steady => '\u2192',
    TrendDirection.falling => '\u2193',
    TrendDirection.fallingFast => '\u2193\u2193',
  };
}

String trendLabel(TrendDirection trend) {
  return switch (trend) {
    TrendDirection.risingFast => 'Rising fast',
    TrendDirection.rising => 'Rising',
    TrendDirection.steady => 'Steady',
    TrendDirection.falling => 'Falling',
    TrendDirection.fallingFast => 'Falling fast',
  };
}

Color glucoseStatusColor(GlucoseStatus status) {
  return switch (status) {
    GlucoseStatus.low => AppColors.danger,
    GlucoseStatus.normal => AppColors.success,
    GlucoseStatus.high => AppColors.warning,
  };
}

String glucoseStatusLabel(GlucoseStatus status) {
  return switch (status) {
    GlucoseStatus.low => 'Low',
    GlucoseStatus.normal => 'Normal',
    GlucoseStatus.high => 'High',
  };
}

String formatTime(DateTime value) => DateFormat('h:mm a').format(value);

String formatShortDate(DateTime value) => DateFormat('MMM d').format(value);

String freshness(DateTime value) {
  final minutes = clock.now().difference(value).inMinutes.clamp(0, 99999);
  if (minutes < 1) return 'Just now';
  if (minutes == 1) return '1 min ago';
  if (minutes < 60) return '$minutes min ago';
  return '${(minutes / 60).round()}h ago';
}

List<OptimusGlucoseReading> filterReadingsByDuration(
  List<OptimusGlucoseReading> readings,
  ChartDuration duration,
) {
  final minutes = switch (duration) {
    ChartDuration.oneHour => 60,
    ChartDuration.threeHours => 180,
    ChartDuration.sixHours => 360,
    ChartDuration.twelveHours => 720,
    ChartDuration.day => 1440,
    ChartDuration.week => 7 * 24 * 60,
    ChartDuration.twoWeeks => 14 * 24 * 60,
  };
  final cutoff = clock.now().subtract(Duration(minutes: minutes));
  return readings
      .where((reading) => reading.timestamp.isAfter(cutoff))
      .toList();
}

({int average, int timeInRange, int timeAbove, int timeBelow, int min, int max})
summarizeReadings(List<OptimusGlucoseReading> readings) {
  if (readings.isEmpty) {
    return (
      average: 0,
      timeInRange: 0,
      timeAbove: 0,
      timeBelow: 0,
      min: 0,
      max: 0,
    );
  }

  final values = readings.map((reading) => reading.value).toList();
  final average = values.reduce((a, b) => a + b) / values.length;
  final inRange = values.where((value) => value >= 70 && value <= 180).length;
  final above = values.where((value) => value > 180).length;
  final below = values.where((value) => value < 70).length;

  return (
    average: average.round(),
    timeInRange: ((inRange / values.length) * 100).round(),
    timeAbove: ((above / values.length) * 100).round(),
    timeBelow: ((below / values.length) * 100).round(),
    min: values.reduce((a, b) => a < b ? a : b),
    max: values.reduce((a, b) => a > b ? a : b),
  );
}

GlucoseStatus statusFromValue(int value) {
  if (value < 70) return GlucoseStatus.low;
  if (value > 180) return GlucoseStatus.high;
  return GlucoseStatus.normal;
}

int sensorDaysRemaining(Sensor? sensor) {
  final expiryDate = sensor?.expiryDate;
  if (expiryDate == null) return 0;
  return expiryDate.difference(clock.now()).inDays.clamp(0, 999);
}

int warmupMinutesRemaining(Sensor? sensor) {
  final warmupEndTime = sensor?.warmupEndTime;
  if (warmupEndTime == null) return 0;
  return warmupEndTime.difference(clock.now()).inMinutes.clamp(0, 999);
}

int mealScore({
  required int netCarbs,
  required int protein,
  required int fiber,
  required int activityMinutes,
}) {
  final carbPenalty = (netCarbs * 0.62).round();
  final proteinSupport = (protein * 0.32).round();
  final fiberSupport = (fiber * 1.8).round();
  final activitySupport = (activityMinutes * 0.7).round();
  return (82 - carbPenalty + proteinSupport + fiberSupport + activitySupport)
      .clamp(0, 100)
      .toInt();
}
