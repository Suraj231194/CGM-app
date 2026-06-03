import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/optimus_models.dart';
import '../../state/app_state.dart';
import '../../utils/glucose_utils.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_states.dart';

class ReportExportScreen extends ConsumerWidget {
  const ReportExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(summaryProvider);
    final meals = ref.watch(selectedMealsProvider);
    final alerts = ref.watch(activeAlertsProvider);
    final exports = ref.watch(selectedReportExportsProvider);
    final consent = ref.watch(
      appControllerProvider.select((state) => state.consentPreferences),
    );
    final controller = ref.read(appControllerProvider.notifier);

    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Reports',
          title: 'Export and share',
          subtitle:
              'Prepare a clean glucose, meal, alert, and sensor summary for care-team review.',
        ),
        _ReportHero(
          timeInRange: summary.timeInRange,
          average: summary.average,
          meals: meals.length,
          alerts: alerts.length,
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report contents',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              _ReportContentRow(
                icon: Icons.show_chart_rounded,
                label: 'CGM summary',
                value:
                    '${summary.timeInRange}% time in range, ${summary.average} mg/dL average',
              ),
              _ReportContentRow(
                icon: Icons.restaurant_menu_rounded,
                label: 'Meal impact',
                value:
                    '${meals.length} logged meal${meals.length == 1 ? '' : 's'}',
              ),
              _ReportContentRow(
                icon: Icons.notifications_active_outlined,
                label: 'Alerts',
                value:
                    '${alerts.length} active alert${alerts.length == 1 ? '' : 's'}',
              ),
              _ReportContentRow(
                icon: Icons.privacy_tip_outlined,
                label: 'Sharing consent',
                value: consent.reportSharing ? 'Enabled' : 'Disabled',
                color: consent.reportSharing
                    ? AppColors.meadow
                    : AppColors.warning,
                bottomPadding: 0,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: consent.reportSharing
                    ? controller.generateReportExport
                    : null,
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Generate PDF report'),
              ),
              if (!consent.reportSharing) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Enable report sharing in Privacy before generating care-team exports.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Generated reports',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (exports.isEmpty)
          const AppEmptyState(
            icon: Icons.description_outlined,
            title: 'No reports generated',
            subtitle:
                'Care-team report exports will appear here after generation.',
          )
        else
          for (final report in exports)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _GeneratedReportCard(report: report),
            ),
      ],
    );
  }
}

class _GeneratedReportCard extends StatelessWidget {
  const _GeneratedReportCard({required this.report});

  final ReportExport report;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.description_outlined, color: AppColors.wellness),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${report.period} ${report.format} report',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${formatShortDate(report.generatedAt)} - ${report.summary}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.sm),
                StatusPill(
                  label: report.status.toUpperCase(),
                  color: AppColors.meadow,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportHero extends StatelessWidget {
  const _ReportHero({
    required this.timeInRange,
    required this.average,
    required this.meals,
    required this.alerts,
  });

  final int timeInRange;
  final int average;
  final int meals;
  final int alerts;

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
          const StatusPill(
            label: 'CARE TEAM READY',
            color: AppColors.mint,
            icon: Icons.ios_share_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Share the signal, not the clutter.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.onDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Reports combine CGM trends, food context, alerts, and sensor status into one review packet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onDarkMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _ReportMetric(label: 'Range', value: '$timeInRange%'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ReportMetric(label: 'Avg', value: '$average'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ReportMetric(label: 'Meals', value: '$meals'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ReportMetric(label: 'Alerts', value: '$alerts'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.onDark.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onDarkMuted,
              fontWeight: FontWeight.w900,
            ),
          ),
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

class _ReportContentRow extends StatelessWidget {
  const _ReportContentRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.wellness,
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
          Icon(icon, color: color),
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
