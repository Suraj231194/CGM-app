import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/optimus_models.dart';
import '../../state/app_state.dart';
import '../../widgets/app_shell.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final consent = state.consentPreferences;
    final controller = ref.read(appControllerProvider.notifier);

    return Scaffold(
      body: AppScreen(
        maxWidth: 860,
        children: [
          const SectionHeader(
            eyebrow: 'Start',
            title: 'Set up your glucose workspace',
            subtitle:
                'Confirm privacy choices, learn the first sensor steps, and prepare your first meal log.',
          ),
          _ProgressHeader(consent: consent),
          const SizedBox(height: AppSpacing.lg),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Required privacy choices',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Optimus uses these choices to show glucose trends, meal context, and coaching summaries.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.md),
                _ConsentSwitch(
                  icon: Icons.monitor_heart_rounded,
                  title: 'Use health data',
                  subtitle: 'Glucose, activity, sleep, and wellness context.',
                  value: consent.healthData,
                  onChanged: (value) => controller.updateConsent(
                    consent.copyWith(healthData: value),
                  ),
                ),
                _ConsentSwitch(
                  icon: Icons.sensors_rounded,
                  title: 'Use sensor data',
                  subtitle:
                      'CGM readings, freshness, battery, and sync status.',
                  value: consent.sensorData,
                  onChanged: (value) => controller.updateConsent(
                    consent.copyWith(sensorData: value),
                  ),
                ),
                _ConsentSwitch(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Enable coaching insights',
                  subtitle: 'Food-glucose patterns and safe guidance prompts.',
                  value: consent.aiCoaching,
                  onChanged: (value) => controller.updateConsent(
                    consent.copyWith(aiCoaching: value),
                  ),
                ),
                _ConsentSwitch(
                  icon: Icons.verified_user_outlined,
                  title: 'Accept safety terms',
                  subtitle:
                      'Insights are informational and do not replace clinician advice.',
                  value: consent.termsAccepted,
                  onChanged: (value) => controller.updateConsent(
                    consent.copyWith(termsAccepted: value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const ResponsiveGrid(
            minItemWidth: 210,
            children: [
              _SetupTile(
                icon: Icons.clean_hands_outlined,
                title: 'Prep sensor site',
                subtitle: 'Clean, dry, attach, and keep phone nearby.',
                color: AppColors.meadow,
              ),
              _SetupTile(
                icon: Icons.restaurant_menu_rounded,
                title: 'Log first meal',
                subtitle: 'Capture carbs, protein, fiber, activity, and notes.',
                color: AppColors.honey,
              ),
              _SetupTile(
                icon: Icons.notifications_active_outlined,
                title: 'Set alerts',
                subtitle: 'Review low/high thresholds before live use.',
                color: AppColors.clay,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: consent.readyForOnboarding
                ? () {
                    controller.completeOnboarding();
                    context.go('/sensor');
                  }
                : null,
            icon: const Icon(Icons.sensors_rounded),
            label: const Text('Continue to sensor setup'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: consent.readyForOnboarding
                ? () {
                    controller.completeOnboarding();
                    context.go('/dashboard');
                  }
                : null,
            child: const Text('Finish setup later'),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.consent});

  final ConsentPreferences consent;

  @override
  Widget build(BuildContext context) {
    final complete = [
      consent.healthData,
      consent.sensorData,
      consent.aiCoaching,
      consent.termsAccepted,
    ].where((value) => value).length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.wellness,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(
            label: '$complete OF 4 COMPLETE',
            color: AppColors.mint,
            icon: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Privacy first, sensor second.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.onDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'High-quality glucose coaching starts with clear consent and a correctly connected sensor.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onDarkMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: complete / 4,
            minHeight: 8,
            color: AppColors.mint,
            backgroundColor: AppColors.onDark.withValues(alpha: 0.16),
          ),
        ],
      ),
    );
  }
}

class _ConsentSwitch extends StatelessWidget {
  const _ConsentSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: AppColors.wellness),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _SetupTile extends StatelessWidget {
  const _SetupTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
