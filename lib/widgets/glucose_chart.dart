import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/theme.dart';
import '../models/optimus_models.dart';

class GlucoseChart extends StatelessWidget {
  const GlucoseChart({super.key, required this.readings, this.height = 260});

  static const _minGlucose = 50.0;
  static const _maxGlucose = 250.0;
  static const _lowLimit = 70.0;
  static const _highLimit = 180.0;

  final List<OptimusGlucoseReading> readings;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Waiting for sensor data',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ),
      );
    }

    final compact = _compactReadings(readings);
    final latestIndex = compact.length - 1;
    final spots = compact.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();
    final bottomInterval = latestIndex <= 1 ? 1.0 : latestIndex / 2;
    final axisStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: AppColors.muted);
    final tooltipStyle = Theme.of(context).textTheme.labelMedium!.copyWith(
      color: AppColors.onDark,
      fontWeight: FontWeight.w800,
    );

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: latestIndex.toDouble(),
          minY: _minGlucose,
          maxY: _maxGlucose,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 50,
            getDrawingHorizontalLine: (value) => FlLine(
              color: value == _lowLimit || value == _highLimit
                  ? AppColors.border.withValues(alpha: 0)
                  : AppColors.border.withValues(alpha: 0.72),
              strokeWidth: 1,
            ),
          ),
          rangeAnnotations: RangeAnnotations(
            horizontalRangeAnnotations: [
              HorizontalRangeAnnotation(
                y1: _lowLimit,
                y2: _highLimit,
                color: AppColors.normalBand.withValues(alpha: 0.72),
              ),
            ],
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: 50,
                getTitlesWidget: (value, meta) {
                  if (value < _minGlucose || value > _maxGlucose) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(value.round().toString(), style: axisStyle),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: bottomInterval,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index > latestIndex) {
                    return const SizedBox.shrink();
                  }
                  final isEdge = index == 0 || index == latestIndex;
                  final isMiddle = (index - latestIndex / 2).abs() <= 1;
                  if (!isEdge && !isMiddle) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      DateFormat('h a').format(compact[index].timestamp),
                      style: axisStyle,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: _lowLimit,
                color: AppColors.danger.withValues(alpha: 0.45),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
              HorizontalLine(
                y: _highLimit,
                color: AppColors.warning.withValues(alpha: 0.45),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              barWidth: 2.8,
              color: AppColors.wellness,
              dotData: FlDotData(
                checkToShowDot: (spot, _) {
                  final index = spot.x.round();
                  return index == latestIndex ||
                      spot.y < _lowLimit ||
                      spot.y > _highLimit;
                },
                getDotPainter: (spot, percentage, bar, index) {
                  final isLatest = index == latestIndex;
                  return FlDotCirclePainter(
                    radius: isLatest ? 5.5 : 4,
                    color: _colorForValue(spot.y),
                    strokeColor: AppColors.surface,
                    strokeWidth: isLatest ? 2.5 : 2,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.mint.withValues(alpha: 0.08),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            getTouchedSpotIndicator: (barData, indicators) {
              return indicators.map((index) {
                final spot = barData.spots[index];
                return TouchedSpotIndicatorData(
                  FlLine(color: _colorForValue(spot.y).withValues(alpha: 0.75)),
                  FlDotData(
                    getDotPainter: (spot, percentage, bar, index) =>
                        FlDotCirclePainter(
                          radius: 5.5,
                          color: _colorForValue(spot.y),
                          strokeColor: AppColors.surface,
                          strokeWidth: 2.5,
                        ),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.primaryDeep,
              getTooltipItems: (items) => items.map((item) {
                final reading = compact[item.spotIndex];
                return LineTooltipItem(
                  '${item.y.round()} mg/dL',
                  tooltipStyle,
                  children: [
                    TextSpan(
                      text:
                          '\n${DateFormat('h:mm a').format(reading.timestamp)}',
                      style: tooltipStyle.copyWith(
                        color: AppColors.onDarkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        duration: AppMotion.slow,
        curve: AppMotion.emphasized,
      ),
    );
  }

  List<OptimusGlucoseReading> _compactReadings(
    List<OptimusGlucoseReading> values,
  ) {
    if (values.length <= 96) return values;

    final step = (values.length / 96).ceil();
    final compact = <OptimusGlucoseReading>[];
    for (var index = 0; index < values.length; index += step) {
      compact.add(values[index]);
    }
    if (compact.last != values.last) compact.add(values.last);
    return compact;
  }

  Color _colorForValue(double value) {
    if (value < _lowLimit) return AppColors.danger;
    if (value > _highLimit) return AppColors.warning;
    return AppColors.success;
  }
}
