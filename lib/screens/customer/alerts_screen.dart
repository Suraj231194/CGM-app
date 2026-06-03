import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/optimus_models.dart';
import '../../state/app_state.dart';
import '../../utils/glucose_utils.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_states.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final activeAlerts = ref.watch(activeAlertsProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final settings = state.alertSettings;

    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Alerts',
          title: 'Glucose alert center',
          subtitle:
              'Configure low/high thresholds and review important glucose events.',
        ),
        _AlertSummary(activeCount: activeAlerts.length),
        const SizedBox(height: AppSpacing.lg),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notification rules',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.wellness,
                  ),
                  title: const Text('Enable glucose alerts'),
                  subtitle: const Text(
                    'Show in-app alerts for low/high readings.',
                  ),
                  value: settings.notificationsEnabled,
                  onChanged: (value) => controller.updateAlertSettings(
                    settings.copyWith(notificationsEnabled: value),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.bedtime_outlined,
                    color: AppColors.wellness,
                  ),
                  title: const Text('Quiet hours'),
                  subtitle: const Text(
                    'Keep non-urgent coaching quiet overnight.',
                  ),
                  value: settings.quietHoursEnabled,
                  onChanged: (value) => controller.updateAlertSettings(
                    settings.copyWith(quietHoursEnabled: value),
                  ),
                ),
              ),
              _ThresholdSlider(
                label: 'Low threshold',
                value: settings.lowThreshold,
                min: 55,
                max: 90,
                color: AppColors.danger,
                onChanged: (value) => controller.updateAlertSettings(
                  settings.copyWith(lowThreshold: value.round()),
                ),
              ),
              _ThresholdSlider(
                label: 'High threshold',
                value: settings.highThreshold,
                min: 140,
                max: 240,
                color: AppColors.honey,
                onChanged: (value) => controller.updateAlertSettings(
                  settings.copyWith(highThreshold: value.round()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Active alerts',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (activeAlerts.isEmpty)
          const AppEmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'No active alerts',
            subtitle: 'Low and high glucose events will appear here.',
          )
        else
          for (final alert in activeAlerts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _AlertCard(
                alert: alert,
                onAcknowledge: () => controller.acknowledgeAlert(alert.id),
              ),
            ),
      ],
    );
  }
}

class _AlertSummary extends StatelessWidget {
  const _AlertSummary({required this.activeCount});

  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: activeCount == 0 ? AppColors.wellness : AppColors.clay,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            color: AppColors.onDark,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeCount == 0
                      ? 'All clear'
                      : '$activeCount alert${activeCount == 1 ? '' : 's'} need review',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Use these alerts as a review prompt, not emergency or treatment guidance.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onDarkMuted,
                    height: 1.45,
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

class _ThresholdSlider extends StatelessWidget {
  const _ThresholdSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final int value;
  final double min;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '$value mg/dL',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Slider(
            min: min,
            max: max,
            divisions: (max - min).round(),
            value: value.toDouble().clamp(min, max),
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onAcknowledge});

  final GlucoseAlert alert;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.severity) {
      AlertSeverity.info => AppColors.primary,
      AlertSeverity.warning => AppColors.honey,
      AlertSeverity.urgent => AppColors.danger,
    };

    return PremiumCard(
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                label: '${alert.value} mg/dL',
                color: color,
                icon: Icons.monitor_heart_rounded,
              ),
              const Spacer(),
              Text(
                formatTime(alert.timestamp),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            alert.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            alert.message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onAcknowledge,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }
}
