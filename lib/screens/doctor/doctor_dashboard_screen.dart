import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/app_shell.dart';

class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final patients = state.patients
        .where((patient) => patient.doctorId == 'doctor-1')
        .toList();

    return AppScreen(
      children: [
        const SectionHeader(
          eyebrow: 'Doctor portal',
          title: 'Clinical workspace',
          subtitle: 'Assigned patients, risk status, and care review.',
        ),
        ResponsiveGrid(
          minItemWidth: 165,
          children: [
            MetricTile(label: 'Patients', value: '${patients.length}'),
            MetricTile(
              label: 'Watch list',
              value: '${patients.where((p) => p.riskLevel != 'stable').length}',
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ...patients.map(
          (patient) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: PremiumCard(
              elevated: false,
              padding: EdgeInsets.zero,
              child: ListTile(
                onTap: () {
                  ref
                      .read(appControllerProvider.notifier)
                      .selectPatient(patient.id);
                  context.go('/readings');
                },
                leading: Semantics(
                  label: patient.name,
                  child: CircleAvatar(
                    backgroundColor: roleColor(
                      OptimusRole.doctor,
                    ).withValues(alpha: 0.12),
                    foregroundColor: roleColor(OptimusRole.doctor),
                    child: Text(patient.name.substring(0, 1)),
                  ),
                ),
                title: Text(
                  patient.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${patient.age}, ${patient.gender} - ${patient.riskLevel}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusPill(
                      label: patient.riskLevel.toUpperCase(),
                      color: patient.riskLevel == 'stable'
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
