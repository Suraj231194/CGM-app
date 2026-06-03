import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/optimus_models.dart';
import '../../state/app_state.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/glucose_chart.dart';

class FullScreenChartScreen extends ConsumerWidget {
  const FullScreenChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readings = ref.watch(selectedReadingsProvider);
    final duration = ref.watch(
      appControllerProvider.select((state) => state.chartDuration),
    );
    final summary = ref.watch(summaryProvider);

    return AppScreen(
      children: [
        const SectionHeader(
          eyebrow: 'Trends',
          title: 'Glucose trends',
          subtitle: 'Averages, target range, and meal response patterns.',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<ChartDuration>(
            segments: const [
              ButtonSegment(value: ChartDuration.oneHour, label: Text('1H')),
              ButtonSegment(value: ChartDuration.threeHours, label: Text('3H')),
              ButtonSegment(value: ChartDuration.sixHours, label: Text('6H')),
              ButtonSegment(
                value: ChartDuration.twelveHours,
                label: Text('12H'),
              ),
              ButtonSegment(value: ChartDuration.day, label: Text('24H')),
              ButtonSegment(value: ChartDuration.week, label: Text('7D')),
              ButtonSegment(value: ChartDuration.twoWeeks, label: Text('14D')),
            ],
            selected: {duration},
            onSelectionChanged: (value) {
              ref
                  .read(appControllerProvider.notifier)
                  .setChartDuration(value.first);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _TrendHero(summary: summary, duration: duration),
        const SizedBox(height: AppSpacing.lg),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _durationTitle(duration),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const StatusPill(
                    label: '70-180',
                    color: AppColors.meadow,
                    icon: Icons.flag_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              GlucoseChart(readings: readings, height: 340),
              const SizedBox(height: AppSpacing.lg),
              const _GlucoseLegend(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _MealImpactPanel(summary: summary),
      ],
    );
  }

  String _durationTitle(ChartDuration duration) {
    return switch (duration) {
      ChartDuration.oneHour => 'Last hour',
      ChartDuration.threeHours => 'Last 3 hours',
      ChartDuration.sixHours => 'Last 6 hours',
      ChartDuration.twelveHours => 'Last 12 hours',
      ChartDuration.day => 'Today',
      ChartDuration.week => '7 day trend',
      ChartDuration.twoWeeks => '14 day trend',
    };
  }
}

class _TrendHero extends StatelessWidget {
  const _TrendHero({required this.summary, required this.duration});

  final ({
    int average,
    int timeInRange,
    int timeAbove,
    int timeBelow,
    int min,
    int max,
  })
  summary;
  final ChartDuration duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.wellness,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pattern report',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusPill(
                label: _durationLabel(duration),
                color: AppColors.mint,
                icon: Icons.calendar_today_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            summary.timeInRange >= 85
                ? 'Your curve is staying smooth with strong time in range.'
                : 'The main opportunity is reducing sharper meal-linked rises.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onDarkMuted,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final cards = [
                _TrendMetricData(
                  'Average',
                  '${summary.average}',
                  'mg/dL',
                  AppColors.onDark,
                ),
                _TrendMetricData(
                  'In range',
                  '${summary.timeInRange}',
                  '%',
                  AppColors.mint,
                ),
                _TrendMetricData(
                  'GMI',
                  _estimatedGmi(summary.average),
                  '%',
                  AppColors.aiAccent,
                ),
                _TrendMetricData(
                  'Peak',
                  '${summary.max}',
                  'mg/dL',
                  AppColors.honey,
                ),
              ];

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: compact ? 2 : 4,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  mainAxisExtent: 86,
                ),
                itemBuilder: (context, index) =>
                    _TrendMetricCard(data: cards[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  String _durationLabel(ChartDuration duration) {
    return switch (duration) {
      ChartDuration.oneHour => '1 HOUR',
      ChartDuration.threeHours => '3 HOURS',
      ChartDuration.sixHours => '6 HOURS',
      ChartDuration.twelveHours => '12 HOURS',
      ChartDuration.day => '24 HOURS',
      ChartDuration.week => '7 DAYS',
      ChartDuration.twoWeeks => '14 DAYS',
    };
  }

  String _estimatedGmi(int average) {
    if (average <= 0) return '--';
    return (3.31 + (0.02392 * average)).toStringAsFixed(1);
  }
}

class _TrendMetricData {
  const _TrendMetricData(this.label, this.value, this.unit, this.color);

  final String label;
  final String value;
  final String unit;
  final Color color;
}

class _TrendMetricCard extends StatelessWidget {
  const _TrendMetricCard({required this.data});

  final _TrendMetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.onDark.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.onDark.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onDarkMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                Text(
                  data.value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: data.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  data.unit,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onDarkMuted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlucoseLegend extends StatelessWidget {
  const _GlucoseLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        _LegendItem(color: AppColors.mint, label: 'Range', range: '70-180'),
        _LegendItem(color: AppColors.honey, label: 'High', range: '> 180'),
        _LegendItem(color: AppColors.danger, label: 'Low', range: '< 70'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.range,
  });

  final Color color;
  final String label;
  final String range;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 18,
            width: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            range,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealImpactPanel extends StatelessWidget {
  const _MealImpactPanel({required this.summary});

  final ({
    int average,
    int timeInRange,
    int timeAbove,
    int timeBelow,
    int min,
    int max,
  })
  summary;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.wellnessSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.restaurant_menu_rounded,
                color: AppColors.wellness,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Meal impact',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.wellness,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _ImpactRow(
            label: 'Breakfast',
            value: 'Smooth rise',
            progress: 0.32,
            color: AppColors.meadow,
          ),
          _ImpactRow(
            label: 'Lunch',
            value: summary.timeAbove > 0 ? 'Highest response' : 'On target',
            progress: summary.timeAbove > 0 ? 0.78 : 0.42,
            color: AppColors.honey,
          ),
          const _ImpactRow(
            label: 'Dinner',
            value: 'Recovered quickly',
            progress: 0.48,
            color: AppColors.primary,
            bottomPadding: 0,
          ),
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    this.bottomPadding = AppSpacing.md,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.wellness,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.wellness,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              color: color,
              backgroundColor: AppColors.surface.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}
