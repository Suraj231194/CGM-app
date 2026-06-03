import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../state/app_state.dart';
import '../../utils/glucose_utils.dart';
import '../../widgets/app_shell.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);

    return AppScreen(
      children: [
        const SectionHeader(
          eyebrow: 'Admin portal',
          title: 'Operations workspace',
          subtitle: 'Customers, clinicians, sensor sync, and support health.',
        ),
        ResponsiveGrid(
          minItemWidth: 165,
          children: [
            MetricTile(label: 'Customers', value: '${state.patients.length}'),
            MetricTile(
              label: 'Sensors',
              value: '${state.sensors.length}',
              color: AppColors.accentDeep,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Latest sync logs',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...state.syncLogs.map(
          (log) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: PremiumCard(
              elevated: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusPill(
                        label: log.status.toUpperCase(),
                        color: log.status == 'success'
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const Spacer(),
                      Text(
                        freshness(log.timestamp),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    log.event,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    log.details,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
