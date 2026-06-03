import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/app_shell.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: AppScreen(
        maxWidth: 960,
        children: [
          SizedBox(height: AppSpacing.xl),
          _WelcomeHeader(),
          SizedBox(height: AppSpacing.xxl),
          _WorkspaceLabel(),
          SizedBox(height: AppSpacing.md),
          _RoleGrid(),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;

    return Column(
      children: [
        const Center(child: BrandLockup()),
        const SizedBox(height: AppSpacing.xl),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Welcome to Optimus CGM',
            textAlign: TextAlign.center,
            maxLines: 2,
            softWrap: true,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: compact ? 26 : null,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              height: compact ? 1.12 : 1.06,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Choose a workspace to review glucose, meals, care notes, and sensor tasks.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkspaceLabel extends StatelessWidget {
  const _WorkspaceLabel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Choose your role',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RoleGrid extends StatelessWidget {
  const _RoleGrid();

  @override
  Widget build(BuildContext context) {
    const cards = [
      _RoleLoginCard(
        title: 'Customer',
        subtitle: 'CGM trends, meal scores, logbook, coaching, and orders.',
        icon: Icons.monitor_heart_rounded,
        role: OptimusRole.customer,
        color: AppColors.wellness,
      ),
      _RoleLoginCard(
        title: 'Doctor',
        subtitle:
            'Patient panel, clinical risk review, readings, interpretation.',
        icon: Icons.medical_services_outlined,
        role: OptimusRole.doctor,
        color: AppColors.accentDeep,
      ),
      _RoleLoginCard(
        title: 'Admin',
        subtitle: 'Customers, clinicians, sync logs, and operations.',
        icon: Icons.admin_panel_settings_outlined,
        role: OptimusRole.admin,
        color: AppColors.admin,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                Expanded(child: cards[index]),
                if (index != cards.length - 1)
                  const SizedBox(width: AppSpacing.lg),
              ],
            ],
          );
        }

        return const Column(
          children: [
            _RoleLoginCard(
              title: 'Customer',
              subtitle:
                  'CGM trends, meal scores, logbook, coaching, and orders.',
              icon: Icons.monitor_heart_rounded,
              role: OptimusRole.customer,
              color: AppColors.wellness,
            ),
            SizedBox(height: AppSpacing.md),
            _RoleLoginCard(
              title: 'Doctor',
              subtitle:
                  'Patient panel, clinical risk review, readings, interpretation.',
              icon: Icons.medical_services_outlined,
              role: OptimusRole.doctor,
              color: AppColors.accentDeep,
            ),
            SizedBox(height: AppSpacing.md),
            _RoleLoginCard(
              title: 'Admin',
              subtitle: 'Customers, clinicians, sync logs, and operations.',
              icon: Icons.admin_panel_settings_outlined,
              role: OptimusRole.admin,
              color: AppColors.admin,
            ),
          ],
        );
      },
    );
  }
}

class _RoleLoginCard extends ConsumerWidget {
  const _RoleLoginCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.role,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final OptimusRole role;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compact = MediaQuery.sizeOf(context).width < 480;
    final iconSize = compact ? 42.0 : 46.0;

    return PremiumCard(
      padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: iconSize,
            width: iconSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: color),
              onPressed: () {
                ref.read(appControllerProvider.notifier).signIn('', role: role);
                context.go('/dashboard');
              },
              icon: const Icon(Icons.login_rounded),
              label: FittedBox(child: Text('Continue as $title')),
            ),
          ),
        ],
      ),
    );
  }
}
