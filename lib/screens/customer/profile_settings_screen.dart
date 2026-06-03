import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/optimus_models.dart';
import '../../state/app_state.dart';
import '../../utils/glucose_utils.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_states.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.currentUser;
    final role = state.activeRole;
    final patient = ref.watch(selectedPatientProvider);
    final sensor = ref.watch(selectedSensorProvider);
    final summary = ref.watch(summaryProvider);
    final darkMode = state.themeMode == ThemeMode.dark;

    return AppScreen(
      children: [
        SectionHeader(
          showBack: true,
          eyebrow: 'Account',
          title: '${_roleTitle(role)} profile',
          subtitle: _roleSubtitle(role),
        ),
        PremiumCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: roleColor(role),
                child: Text(
                  (user?.name ?? 'O').substring(0, 1),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Optimus user',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      user?.email ?? '--',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: role.name.toUpperCase(),
                color: roleColor(role),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _RoleDetails(
          role: role,
          patient: patient,
          sensor: sensor,
          summary: summary,
          state: state,
        ),
        const SizedBox(height: AppSpacing.lg),
        _AppearanceCard(
          darkMode: darkMode,
          onDarkModeChanged: (value) {
            ref.read(appControllerProvider.notifier).toggleDarkMode(value);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._actionsForRole(role).map(
          (action) => _ActionTile(
            icon: action.icon,
            title: action.title,
            subtitle: action.subtitle,
            route: action.route,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await ConfirmDialog.show(
              context,
              title: 'Sign out',
              content: 'Are you sure you want to sign out of Optimus CGM?',
              confirmLabel: 'Sign out',
              isDestructive: true,
            );
            if (!confirmed || !context.mounted) return;
            ref.read(appControllerProvider.notifier).signOut();
            context.go('/login');
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
      ],
    );
  }

  String _roleTitle(OptimusRole role) {
    return switch (role) {
      OptimusRole.customer => 'Customer',
      OptimusRole.doctor => 'Doctor',
      OptimusRole.admin => 'Admin',
    };
  }

  String _roleSubtitle(OptimusRole role) {
    return switch (role) {
      OptimusRole.customer =>
        'Personal CGM, sensor, orders, and care-team details.',
      OptimusRole.doctor =>
        'Clinician profile, patient panel, and review shortcuts.',
      OptimusRole.admin =>
        'Operational identity, platform status, and support controls.',
    };
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Dark mode is available from Account. Toggle it here to change the app theme immediately.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              darkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppColors.wellness,
            ),
            title: Text(
              'Dark mode',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            subtitle: const Text(
              'Use the darker app theme for low-light review.',
            ),
            value: darkMode,
            onChanged: onDarkModeChanged,
          ),
        ],
      ),
    );
  }
}

class _RoleDetails extends StatelessWidget {
  const _RoleDetails({
    required this.role,
    required this.patient,
    required this.sensor,
    required this.summary,
    required this.state,
  });

  final OptimusRole role;
  final Patient? patient;
  final Sensor? sensor;
  final ({
    int average,
    int timeInRange,
    int timeAbove,
    int timeBelow,
    int min,
    int max,
  })
  summary;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return switch (role) {
      OptimusRole.customer => _CustomerDetails(
        patient: patient,
        sensor: sensor,
        summary: summary,
      ),
      OptimusRole.doctor => _DoctorDetails(state: state),
      OptimusRole.admin => _AdminDetails(state: state),
    };
  }
}

class _CustomerDetails extends StatelessWidget {
  const _CustomerDetails({
    required this.patient,
    required this.sensor,
    required this.summary,
  });

  final Patient? patient;
  final Sensor? sensor;
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
    return Column(
      children: [
        ResponsiveGrid(
          minItemWidth: 155,
          children: [
            MetricTile(
              label: 'Avg glucose',
              value: '${summary.average}',
              detail: 'mg/dL',
            ),
            MetricTile(
              label: 'Time in range',
              value: '${summary.timeInRange}%',
              color: AppColors.success,
            ),
            MetricTile(
              label: 'Sensor life',
              value: '${sensorDaysRemaining(sensor)}d',
              color: AppColors.wellness,
            ),
            MetricTile(
              label: 'Battery',
              value: '${sensor?.batteryStatus ?? 0}%',
              color: AppColors.accentDeep,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailRow(label: 'Patient', value: patient?.name ?? '--'),
              _DetailRow(
                label: 'Age / gender',
                value: patient == null
                    ? '--'
                    : '${patient!.age}, ${patient!.gender}',
              ),
              _DetailRow(
                label: 'Sensor SN',
                value: sensor?.serialNumber ?? '--',
              ),
              _DetailRow(
                label: 'Sensor status',
                value: sensor?.status.name ?? '--',
              ),
              _DetailRow(
                label: 'Connection',
                value: sensor?.connectionStatus.name ?? '--',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DoctorDetails extends StatelessWidget {
  const _DoctorDetails({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final patients = state.patients
        .where((patient) => patient.doctorId == 'doctor-1')
        .toList();
    final watch = patients
        .where((patient) => patient.riskLevel != 'stable')
        .length;

    return Column(
      children: [
        ResponsiveGrid(
          minItemWidth: 155,
          children: [
            MetricTile(label: 'Assigned', value: '${patients.length}'),
            MetricTile(
              label: 'Watch list',
              value: '$watch',
              color: AppColors.warning,
            ),
            MetricTile(
              label: 'Active sensors',
              value:
                  '${state.sensors.where((s) => s.status == SensorStatus.active).length}',
            ),
            MetricTile(
              label: 'Sync logs',
              value: '${state.syncLogs.length}',
              color: AppColors.accentDeep,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clinician details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              const _DetailRow(label: 'Specialization', value: 'Endocrinology'),
              const _DetailRow(
                label: 'Review mode',
                value: 'Patient trend and AI interpretation',
              ),
              _DetailRow(
                label: 'Patients',
                value: patients.map((p) => p.name).join(', '),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminDetails extends StatelessWidget {
  const _AdminDetails({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ResponsiveGrid(
          minItemWidth: 155,
          children: [
            MetricTile(label: 'Customers', value: '${state.patients.length}'),
            MetricTile(
              label: 'Sensors',
              value: '${state.sensors.length}',
              color: AppColors.accentDeep,
            ),
            MetricTile(label: 'Orders', value: '${state.orders.length}'),
            MetricTile(
              label: 'Warnings',
              value:
                  '${state.syncLogs.where((l) => l.status != 'success').length}',
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              const _DetailRow(
                label: 'Workspace',
                value: 'Operations and support',
              ),
              const _DetailRow(
                label: 'Access',
                value: 'Customers, clinicians, sensor logs',
              ),
              _DetailRow(
                label: 'Connected integrations',
                value:
                    '${state.integrations.where((i) => i.status == 'connected').length}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PremiumCard(
        elevated: false,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: ListTile(
            leading: Icon(icon, color: AppColors.primary),
            title: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(route),
          ),
        ),
      ),
    );
  }
}

class _ProfileAction {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}

List<_ProfileAction> _actionsForRole(OptimusRole role) {
  const common = [
    _ProfileAction(
      icon: Icons.support_agent_rounded,
      title: 'Support and company pages',
      subtitle: 'Contact, FAQ, legal, quote and meeting flows',
      route: '/support',
    ),
  ];

  return switch (role) {
    OptimusRole.customer => [
      const _ProfileAction(
        icon: Icons.sensors_rounded,
        title: 'Devices and integrations',
        subtitle: 'CGM, health, watch and bridge adapters',
        route: '/devices',
      ),
      const _ProfileAction(
        icon: Icons.privacy_tip_outlined,
        title: 'Privacy and consent',
        subtitle: 'Manage health data, coaching, and report sharing',
        route: '/privacy',
      ),
      const _ProfileAction(
        icon: Icons.notifications_active_outlined,
        title: 'Alerts and thresholds',
        subtitle: 'Configure low and high glucose alert logic',
        route: '/alerts',
      ),
      const _ProfileAction(
        icon: Icons.ios_share_rounded,
        title: 'Reports',
        subtitle: 'Generate care-team ready glucose summaries',
        route: '/reports',
      ),
      const _ProfileAction(
        icon: Icons.inventory_2_outlined,
        title: 'Reorder sensor',
        subtitle: 'Buy replacement 14-day sensor packs',
        route: '/reorder',
      ),
      const _ProfileAction(
        icon: Icons.receipt_long_rounded,
        title: 'Order history',
        subtitle: 'View sensor and product orders',
        route: '/orders',
      ),
      ...common,
    ],
    OptimusRole.doctor => [
      const _ProfileAction(
        icon: Icons.people_alt_outlined,
        title: 'Patient readings',
        subtitle: 'Review chart and reading history for selected patient',
        route: '/readings',
      ),
      const _ProfileAction(
        icon: Icons.auto_awesome_rounded,
        title: 'AI interpretation',
        subtitle: 'Clinical interpretation view',
        route: '/ai',
      ),
      ...common,
    ],
    OptimusRole.admin => [
      const _ProfileAction(
        icon: Icons.sync_alt_rounded,
        title: 'Sync logs',
        subtitle: 'Review operational sensor sync events',
        route: '/dashboard',
      ),
      const _ProfileAction(
        icon: Icons.hub_outlined,
        title: 'Integration status',
        subtitle: 'Review available and connected data sources',
        route: '/devices',
      ),
      ...common,
    ],
  };
}
