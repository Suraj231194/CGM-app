import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/app_shell.dart';

class AIInterpretationScreen extends ConsumerWidget {
  const AIInterpretationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final patient = ref.watch(selectedPatientProvider);
    final summary = ref.watch(summaryProvider);
    final tone = state.activeRole == OptimusRole.doctor ? 'doctor' : 'patient';
    final interpretation = state.aiInterpretations
        .where((item) => item.patientId == patient?.id && item.tone == tone)
        .firstOrNull;
    final contentSummary =
        interpretation?.summary ??
        'Today averaged ${summary.average} mg/dL with ${summary.timeInRange}% time in range.';
    final patterns =
        interpretation?.patterns ??
        [
          '${summary.timeAbove}% readings are above range in this view.',
          '${summary.timeBelow}% readings are below range in this view.',
          'Observed range is ${summary.min}-${summary.max} mg/dL.',
        ];
    final recommendations =
        interpretation?.recommendations ??
        [
          'Review meal, medication, sleep, and activity timing with your care team.',
          'Use the full chart view to inspect exact data points before making decisions.',
        ];

    return AppScreen(
      children: [
        SectionHeader(
          showBack: true,
          eyebrow: 'Coaching',
          title: 'Insight report',
          subtitle: patient?.name ?? 'Selected patient',
        ),
        _InsightHero(summaryText: contentSummary, summary: summary),
        const SizedBox(height: AppSpacing.lg),
        _PatternGrid(items: patterns),
        const SizedBox(height: AppSpacing.lg),
        _RecommendationPanel(items: recommendations),
        const SizedBox(height: AppSpacing.lg),
        _ReportPreview(summary: summary),
        const SizedBox(height: AppSpacing.lg),
        PremiumCard(
          color: AppColors.warningSoft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.warning),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  interpretation?.disclaimer ??
                      'Informational only. This is not a diagnosis, emergency guidance, or a replacement for clinician advice.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightHero extends StatelessWidget {
  const _InsightHero({required this.summaryText, required this.summary});

  final String summaryText;
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.wellness,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.wellness.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Care coach',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Glucose, meal, and lifestyle review',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onDarkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusPill(
                label: 'READY',
                color: AppColors.mint,
                icon: Icons.verified_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.onDark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: AppColors.onDark.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              summaryText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.onDarkMuted,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _DarkMetric(
                  label: 'Average',
                  value: '${summary.average}',
                  unit: 'mg/dL',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DarkMetric(
                  label: 'Range',
                  value: '${summary.timeInRange}',
                  unit: '%',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DarkMetric(
                  label: 'Spread',
                  value: '${summary.min}-${summary.max}',
                  unit: '',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DarkMetric extends StatelessWidget {
  const _DarkMetric({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.onDark.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onDarkMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    unit,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onDarkMuted,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternGrid extends StatelessWidget {
  const _PatternGrid({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final data = items
        .take(3)
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => _PatternItem(
            icon: _patternIcon(entry.key),
            color: _patternColor(entry.key),
            title: _patternTitle(entry.key),
            text: entry.value,
          ),
        )
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact ? 1 : 3,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            mainAxisExtent: compact ? 132 : 172,
          ),
          itemBuilder: (context, index) => _PatternCard(item: data[index]),
        );
      },
    );
  }

  static IconData _patternIcon(int index) {
    return switch (index) {
      0 => Icons.restaurant_rounded,
      1 => Icons.nightlight_round,
      _ => Icons.directions_walk_rounded,
    };
  }

  static Color _patternColor(int index) {
    return switch (index) {
      0 => AppColors.honey,
      1 => AppColors.lilac,
      _ => AppColors.mint,
    };
  }

  static String _patternTitle(int index) {
    return switch (index) {
      0 => 'Meal response',
      1 => 'Overnight trend',
      _ => 'Recovery window',
    };
  }
}

class _PatternItem {
  const _PatternItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String text;
}

class _PatternCard extends StatelessWidget {
  const _PatternCard({required this.item});

  final _PatternItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Text(
              item.text,
              overflow: TextOverflow.fade,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationPanel extends StatelessWidget {
  const _RecommendationPanel({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.wellnessSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt_rounded, color: AppColors.wellness),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Coaching plan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.wellness,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in items.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 24,
                    width: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.wellness,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.onDark,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.wellness,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
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

class _ReportPreview extends StatelessWidget {
  const _ReportPreview({required this.summary});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly report preview',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.md),
          _ReportRow(
            icon: Icons.show_chart_rounded,
            label: 'Glucose stability',
            value: '${summary.timeInRange}% in target',
            color: AppColors.meadow,
          ),
          _ReportRow(
            icon: Icons.restaurant_menu_rounded,
            label: 'Meal timing',
            value: summary.timeAbove > 0 ? 'Review lunch rise' : 'On track',
            color: AppColors.honey,
          ),
          const _ReportRow(
            icon: Icons.directions_walk_rounded,
            label: 'Movement',
            value: 'Post-meal walk helps recovery',
            color: AppColors.primary,
            bottomPadding: 0,
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.bottomPadding = AppSpacing.md,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
