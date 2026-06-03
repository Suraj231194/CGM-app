import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/optimus_models.dart';
import '../../state/app_state.dart';
import '../../utils/glucose_utils.dart';
import '../../widgets/app_shell.dart';

class DevicesIntegrationsScreen extends ConsumerWidget {
  const DevicesIntegrationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final integrations = ref.watch(
      appControllerProvider.select((state) => state.integrations),
    );

    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Integrations',
          title: 'Devices and integrations',
          subtitle: 'Manage connected devices and health data sources.',
        ),
        ...['cgm', 'health', 'watch'].map(
          (category) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...integrations
                    .where((item) => item.category == category)
                    .map(
                      (integration) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _IntegrationCard(
                          integration: integration,
                          icon: _iconFor(category),
                          onAction:
                              integration.status == 'comingSoon' ||
                                  integration.status == 'connected'
                              ? null
                              : () {
                                  if (integration.id == 'optimus-native') {
                                    context.push('/sensor');
                                    return;
                                  }
                                  ref
                                      .read(appControllerProvider.notifier)
                                      .connectIntegration(integration.id);
                                },
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(String category) {
    return switch (category) {
      'cgm' => Icons.sensors_rounded,
      'health' => Icons.favorite_border_rounded,
      _ => Icons.watch_rounded,
    };
  }
}

class _IntegrationCard extends StatelessWidget {
  const _IntegrationCard({
    required this.integration,
    required this.icon,
    required this.onAction,
  });

  final DeviceIntegration integration;
  final IconData icon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (integration.status) {
      'connected' => AppColors.success,
      'comingSoon' => AppColors.warning,
      _ => AppColors.primary,
    };
    final statusLabel = switch (integration.status) {
      'connected' => 'CONNECTED',
      'comingSoon' => 'SOON',
      _ => 'AVAILABLE',
    };
    final actionLabel = integration.id == 'optimus-native'
        ? 'Manage'
        : integration.status == 'connected'
        ? 'Connected'
        : integration.status == 'comingSoon'
        ? 'Soon'
        : 'Enable';

    return PremiumCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, color: statusColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      integration.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      integration.summary,
                      maxLines: compact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                    if (integration.lastSync != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Synced ${freshness(integration.lastSync!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
          final controls = Row(
            mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
            children: [
              StatusPill(label: statusLabel, color: statusColor),
              const SizedBox(width: AppSpacing.sm),
              if (compact) const Spacer(),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: AppSpacing.md),
                controls,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: AppSpacing.md),
              controls,
            ],
          );
        },
      ),
    );
  }
}
