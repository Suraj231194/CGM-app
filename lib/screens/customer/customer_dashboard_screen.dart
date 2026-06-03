import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/optimus_models.dart';
import '../../state/app_state.dart';
import '../../utils/glucose_utils.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/glucose_chart.dart';

class CustomerDashboardScreen extends ConsumerWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ref.watch(selectedPatientProvider);
    final sensor = ref.watch(selectedSensorProvider);
    final readings = ref.watch(selectedReadingsProvider);
    final latest = ref.watch(latestReadingProvider);
    final summary = ref.watch(summaryProvider);
    final appState = ref.watch(appControllerProvider);
    final activeAlerts = ref.watch(activeAlertsProvider);
    final interpretation = appState.aiInterpretations
        .where(
          (item) => item.patientId == patient?.id && item.tone == 'patient',
        )
        .firstOrNull;

    return AppScreen(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        _HomeHero(
          patient: patient,
          latest: latest,
          summary: summary,
          connected: appState.cgmConnected,
          onChart: () => context.go('/chart'),
          onDevices: () => context.push('/devices'),
        ),
        if (activeAlerts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _AlertBanner(
            alert: activeAlerts.first,
            onOpen: () => context.push('/alerts'),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _GlucoseStoryCard(
          readings: readings,
          latest: latest,
          summary: summary,
          onChart: () => context.go('/chart'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _QuickActionDeck(
          onMeal: () => context.push('/meal'),
          onAI: () => context.push('/ai'),
          onReport: () => context.push('/reports'),
          onDevices: () => context.push('/devices'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _NutritionFocusCard(summary: summary),
        const SizedBox(height: AppSpacing.lg),
        _LogbookPreview(
          readings: readings.reversed.take(5).toList(),
          onOpen: () => context.go('/readings'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _GuidanceCard(
          summaryText:
              interpretation?.summary ??
              'Your glucose pattern is mostly steady today. Lunch timing is the main opportunity to review.',
          recommendations:
              interpretation?.recommendations ??
              const [
                'Pair lunch carbohydrates with protein and fiber.',
                'Add a short walk after your largest meal.',
              ],
          onOpenAI: () => context.push('/ai'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SensorStatusCard(
          sensor: sensor,
          appState: appState,
          onManage: () => context.push('/sensor'),
          onReorder: () => context.push('/reorder'),
        ),
      ],
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.patient,
    required this.latest,
    required this.summary,
    required this.connected,
    required this.onChart,
    required this.onDevices,
  });

  final Patient? patient;
  final OptimusGlucoseReading? latest;
  final ({
    int average,
    int timeInRange,
    int timeAbove,
    int timeBelow,
    int min,
    int max,
  })
  summary;
  final bool connected;
  final VoidCallback onChart;
  final VoidCallback onDevices;

  @override
  Widget build(BuildContext context) {
    final firstName = patient?.name.split(' ').first ?? 'there';
    final statusColor = latest == null
        ? AppColors.muted
        : glucoseStatusColor(latest!.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.wellness,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.wellness.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final readingPanel = _HeroReadingPanel(
            latest: latest,
            statusColor: statusColor,
            onChart: onChart,
          );
          final copyPanel = _HeroCopyPanel(
            firstName: firstName,
            connected: connected,
            summary: summary,
            onDevices: onDevices,
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copyPanel,
                const SizedBox(height: AppSpacing.lg),
                readingPanel,
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 5, child: copyPanel),
              const SizedBox(width: AppSpacing.xl),
              Expanded(flex: 4, child: readingPanel),
            ],
          );
        },
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.alert, required this.onOpen});

  final GlucoseAlert alert;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.severity) {
      AlertSeverity.info => AppColors.primary,
      AlertSeverity.warning => AppColors.honey,
      AlertSeverity.urgent => AppColors.danger,
    };

    return Material(
      color: color.withValues(alpha: 0.11),
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.notifications_active_rounded, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${alert.value} mg/dL - ${alert.message}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCopyPanel extends StatelessWidget {
  const _HeroCopyPanel({
    required this.firstName,
    required this.connected,
    required this.summary,
    required this.onDevices,
  });

  final String firstName;
  final bool connected;
  final ({
    int average,
    int timeInRange,
    int timeAbove,
    int timeBelow,
    int min,
    int max,
  })
  summary;
  final VoidCallback onDevices;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.onDark.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: const Icon(
                Icons.monitor_heart_rounded,
                color: AppColors.onDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatusPill(
                label: connected ? 'LIVE SENSOR' : 'SAMPLE DATA',
                color: AppColors.mint,
                icon: connected
                    ? Icons.sensors_rounded
                    : Icons.visibility_outlined,
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Manage devices',
              onPressed: onDevices,
              icon: const Icon(Icons.hub_outlined),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Good afternoon, $firstName',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.onDark,
            fontWeight: FontWeight.w900,
            height: 1.03,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your CGM, meals, and coaching notes are ready for a quick review.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.onDarkMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: _HeroMetric(
                label: 'Time in range',
                value: '${summary.timeInRange}%',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _HeroMetric(label: 'Avg', value: '${summary.average}'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _HeroMetric(
                label: 'GMI',
                value: _estimatedGmi(summary.average),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _estimatedGmi(int average) {
    if (average <= 0) return '--';
    return (3.31 + (0.02392 * average)).toStringAsFixed(1);
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.onDark.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.onDark.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onDarkMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.onDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroReadingPanel extends StatelessWidget {
  const _HeroReadingPanel({
    required this.latest,
    required this.statusColor,
    required this.onChart,
  });

  final OptimusGlucoseReading? latest;
  final Color statusColor;
  final VoidCallback onChart;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Current glucose',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: onChart, child: const Text('Chart')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 140,
            width: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GlucoseGaugePainter(
                      value: latest?.value.toDouble(),
                      color: statusColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          latest?.value.toString() ?? '--',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: AppColors.text,
                                fontWeight: FontWeight.w900,
                                height: 0.95,
                              ),
                        ),
                      ),
                      Text(
                        latest?.unit ?? 'mg/dL',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatusPill(
                label: latest == null
                    ? 'Waiting'
                    : glucoseStatusLabel(latest!.status),
                color: statusColor,
                icon: Icons.bolt_rounded,
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusPill(
                label: latest == null ? 'No trend' : trendLabel(latest!.trend),
                color: AppColors.primary,
                icon: Icons.trending_up_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlucoseGaugePainter extends CustomPainter {
  const _GlucoseGaugePainter({required this.value, required this.color});

  final double? value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final rect = Rect.fromLTWH(
      strokeWidth,
      strokeWidth,
      size.width - strokeWidth * 2,
      size.height * 1.42,
    );
    const start = math.pi * 0.82;
    const sweep = math.pi * 1.36;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = AppColors.border;
    canvas.drawArc(rect, start, sweep, false, paint);

    paint.color = AppColors.danger;
    canvas.drawArc(rect, start, sweep * 0.2, false, paint);
    paint.color = AppColors.mint;
    canvas.drawArc(rect, start + sweep * 0.23, sweep * 0.54, false, paint);
    paint.color = AppColors.honey;
    canvas.drawArc(rect, start + sweep * 0.8, sweep * 0.2, false, paint);

    final current = value;
    if (current == null) return;

    final progress = ((current - 50) / 200).clamp(0.0, 1.0);
    final angle = start + sweep * progress;
    final center = rect.center;
    final radius = rect.width / 2;
    final marker = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    canvas.drawCircle(marker, 10, Paint()..color = AppColors.surface);
    canvas.drawCircle(marker, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _GlucoseGaugePainter oldDelegate) {
    return value != oldDelegate.value || color != oldDelegate.color;
  }
}

class _GlucoseStoryCard extends StatelessWidget {
  const _GlucoseStoryCard({
    required this.readings,
    required this.latest,
    required this.summary,
    required this.onChart,
  });

  final List<OptimusGlucoseReading> readings;
  final OptimusGlucoseReading? latest;
  final ({
    int average,
    int timeInRange,
    int timeAbove,
    int timeBelow,
    int min,
    int max,
  })
  summary;
  final VoidCallback onChart;

  @override
  Widget build(BuildContext context) {
    final rangeCopy = summary.timeInRange >= 85
        ? 'Smooth day'
        : summary.timeAbove > summary.timeBelow
        ? 'Lunch rise'
        : 'Low watch';

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Glucose curve',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Target range 70-180 mg/dL',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: rangeCopy,
                color: summary.timeInRange >= 85
                    ? AppColors.meadow
                    : AppColors.honey,
                icon: Icons.insights_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GlucoseChart(readings: readings, height: 236),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _InlineStat(
                  label: 'Low',
                  value: '${summary.timeBelow}%',
                  color: AppColors.danger,
                ),
              ),
              Expanded(
                child: _InlineStat(
                  label: 'In range',
                  value: '${summary.timeInRange}%',
                  color: AppColors.mint,
                ),
              ),
              Expanded(
                child: _InlineStat(
                  label: 'High',
                  value: '${summary.timeAbove}%',
                  color: AppColors.honey,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onChart,
            icon: const Icon(Icons.tune_rounded),
            label: Text(
              latest == null
                  ? 'Explore trends'
                  : 'Explore trends - ${freshness(latest!.timestamp)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            '$label $value',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionDeck extends StatelessWidget {
  const _QuickActionDeck({
    required this.onMeal,
    required this.onAI,
    required this.onReport,
    required this.onDevices,
  });

  final VoidCallback onMeal;
  final VoidCallback onAI;
  final VoidCallback onReport;
  final VoidCallback onDevices;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final actions = [
          _ActionTileData(
            icon: Icons.restaurant_menu_rounded,
            label: 'Meal',
            tone: AppColors.meadow,
            onTap: onMeal,
          ),
          _ActionTileData(
            icon: Icons.auto_awesome_rounded,
            label: 'Coach',
            tone: AppColors.lilac,
            onTap: onAI,
          ),
          _ActionTileData(
            icon: Icons.description_outlined,
            label: 'Report',
            tone: AppColors.primary,
            onTap: onReport,
          ),
          _ActionTileData(
            icon: Icons.hub_outlined,
            label: 'Devices',
            tone: AppColors.accentDeep,
            onTap: onDevices,
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact ? 2 : 4,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            mainAxisExtent: 86,
          ),
          itemBuilder: (context, index) => _ActionTile(data: actions[index]),
        );
      },
    );
  }
}

class _ActionTileData {
  const _ActionTileData({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tone;
  final VoidCallback onTap;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.data});

  final _ActionTileData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: data.tone.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: data.tone,
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: Icon(data.icon, color: AppColors.onDark, size: 21),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionFocusCard extends StatelessWidget {
  const _NutritionFocusCard({required this.summary});

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
    final mealScore = (summary.timeInRange - summary.timeAbove * 0.35).round();

    return PremiumCard(
      color: AppColors.wellnessSoft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final score = _MealScore(score: mealScore.clamp(0, 100));
          const macros = _MacroStack(
            rows: [
              _MacroRow('Net carbs', '116g', 0.68, AppColors.honey),
              _MacroRow('Protein', '82g', 0.82, AppColors.mint),
              _MacroRow('Fiber', '24g', 0.72, AppColors.meadow),
              _MacroRow('Activity', '38m', 0.76, AppColors.primary),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.eco_outlined, color: AppColors.wellness),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      "Today's Focus",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.wellness,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const StatusPill(
                    label: 'MEAL IMPACT',
                    color: AppColors.meadow,
                    icon: Icons.restaurant_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Keep lunch balanced and add a 10 minute walk after dinner.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.wellness,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (wide)
                Row(
                  children: [
                    SizedBox(width: 158, child: score),
                    const SizedBox(width: AppSpacing.xl),
                    const Expanded(child: macros),
                  ],
                )
              else ...[
                score,
                const SizedBox(height: AppSpacing.lg),
                macros,
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MealScore extends StatelessWidget {
  const _MealScore({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 120,
              width: 120,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                color: AppColors.meadow,
                backgroundColor: AppColors.surface.withValues(alpha: 0.72),
              ),
            ),
            Column(
              children: [
                Text(
                  '$score',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.wellness,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'score',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.wellness,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _MacroRow {
  const _MacroRow(this.label, this.value, this.progress, this.color);

  final String label;
  final String value;
  final double progress;
  final Color color;
}

class _MacroStack extends StatelessWidget {
  const _MacroStack({required this.rows});

  final List<_MacroRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _MacroProgress(row: row),
            ),
          )
          .toList(),
    );
  }
}

class _MacroProgress extends StatelessWidget {
  const _MacroProgress({required this.row});

  final _MacroRow row;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              row.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.wellness,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              row.value,
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
            value: row.progress,
            minHeight: 9,
            color: row.color,
            backgroundColor: AppColors.surface.withValues(alpha: 0.82),
          ),
        ),
      ],
    );
  }
}

class _LogbookPreview extends StatelessWidget {
  const _LogbookPreview({required this.readings, required this.onOpen});

  final List<OptimusGlucoseReading> readings;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Logbook',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(onPressed: onOpen, child: const Text('Open')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in readings.take(4))
            _LogbookRow(
              reading: entry,
              mealLabel: _mealLabelFor(entry.timestamp.hour),
              activityLabel: _activityLabelFor(entry.timestamp.hour),
            ),
        ],
      ),
    );
  }

  String _mealLabelFor(int hour) {
    if (hour >= 6 && hour < 11) return 'Breakfast';
    if (hour >= 11 && hour < 16) return 'Lunch';
    if (hour >= 18 && hour < 23) return 'Dinner';
    return 'Fasting';
  }

  String _activityLabelFor(int hour) {
    if (hour >= 16 && hour <= 20) return 'Walk';
    if (hour >= 6 && hour <= 9) return 'Hydrate';
    return 'Note';
  }
}

class _LogbookRow extends StatelessWidget {
  const _LogbookRow({
    required this.reading,
    required this.mealLabel,
    required this.activityLabel,
  });

  final OptimusGlucoseReading reading;
  final String mealLabel;
  final String activityLabel;

  @override
  Widget build(BuildContext context) {
    final color = glucoseStatusColor(reading.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              formatTime(reading.timestamp),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Center(
              child: Text(
                '${reading.value}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _EventChip(
                  icon: Icons.restaurant_rounded,
                  label: mealLabel,
                  color: AppColors.honey,
                ),
                _EventChip(
                  icon: Icons.directions_walk_rounded,
                  label: activityLabel,
                  color: AppColors.primary,
                ),
                const _EventChip(
                  icon: Icons.water_drop_outlined,
                  label: 'Water',
                  color: AppColors.accentDeep,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  const _EventChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({
    required this.summaryText,
    required this.recommendations,
    required this.onOpenAI,
  });

  final String summaryText;
  final List<String> recommendations;
  final VoidCallback onOpenAI;

  @override
  Widget build(BuildContext context) {
    final topItems = recommendations.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.aiAccent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.aiAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Coach review',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.aiAccent,
                ),
                onPressed: onOpenAI,
                child: const Text('Review'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            summaryText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onDarkMuted,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in topItems)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.mint,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onDarkMuted,
                        height: 1.4,
                      ),
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

class _SensorStatusCard extends StatelessWidget {
  const _SensorStatusCard({
    required this.sensor,
    required this.appState,
    required this.onManage,
    required this.onReorder,
  });

  final Sensor? sensor;
  final AppState appState;
  final VoidCallback onManage;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final daysLeft = sensorDaysRemaining(sensor);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors_rounded, color: AppColors.wellness),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensor?.serialNumber ?? 'No sensor connected',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      sensor == null
                          ? 'Start activation to connect a sensor.'
                          : '$daysLeft days left - ${appState.cgmConnectionStatus}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: sensor?.status.name.toUpperCase() ?? 'OFFLINE',
                color: sensor?.status == SensorStatus.active
                    ? AppColors.mint
                    : AppColors.honey,
                icon: Icons.bluetooth_connected_rounded,
              ),
            ],
          ),
          if (appState.cgmSyncProgress > 0 && appState.cgmSyncProgress < 100)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: LinearProgressIndicator(
                value: appState.cgmSyncProgress / 100,
                minHeight: 5,
              ),
            ),
          if (appState.cgmLastError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                appState.cgmLastError!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.settings_bluetooth_rounded),
                  label: const Text('Manage'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReorder,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Reorder'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
