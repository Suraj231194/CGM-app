import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/optimus_models.dart';
import '../../state/app_state.dart';
import '../../widgets/app_shell.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(
      appControllerProvider.select((state) => state.consentPreferences),
    );
    final controller = ref.read(appControllerProvider.notifier);

    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Privacy',
          title: 'Consent and data controls',
          subtitle:
              'Review what Optimus can use for glucose insights, coaching, and reports.',
        ),
        _PrivacyHero(consent: consent),
        const SizedBox(height: AppSpacing.lg),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data permissions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              _ConsentRow(
                icon: Icons.monitor_heart_rounded,
                title: 'Health data',
                subtitle: 'Glucose, activity, sleep, and wellness context.',
                value: consent.healthData,
                onChanged: (value) => controller.updateConsent(
                  consent.copyWith(healthData: value),
                ),
              ),
              _ConsentRow(
                icon: Icons.sensors_rounded,
                title: 'Sensor data',
                subtitle: 'Readings, battery, warm-up, and sync logs.',
                value: consent.sensorData,
                onChanged: (value) => controller.updateConsent(
                  consent.copyWith(sensorData: value),
                ),
              ),
              _ConsentRow(
                icon: Icons.auto_awesome_rounded,
                title: 'Coaching insights',
                subtitle: 'Meal impact patterns and safe next-step prompts.',
                value: consent.aiCoaching,
                onChanged: (value) => controller.updateConsent(
                  consent.copyWith(aiCoaching: value),
                ),
              ),
              _ConsentRow(
                icon: Icons.ios_share_rounded,
                title: 'Report sharing',
                subtitle: 'Enable report exports for care-team review.',
                value: consent.reportSharing,
                onChanged: (value) => controller.updateConsent(
                  consent.copyWith(reportSharing: value),
                ),
              ),
              _ConsentRow(
                icon: Icons.verified_user_outlined,
                title: 'Safety terms',
                subtitle:
                    'Confirm insights are informational and not emergency guidance.',
                value: consent.termsAccepted,
                onChanged: (value) => controller.updateConsent(
                  consent.copyWith(termsAccepted: value),
                ),
              ),
            ],
          ),
        ),
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
                  'Use system privacy settings for HealthKit or Health Connect access. Disabling data here limits in-app insights but does not delete historical records.',
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

class _PrivacyHero extends StatelessWidget {
  const _PrivacyHero({required this.consent});

  final ConsentPreferences consent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.wellness,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          Icon(
            consent.readyForOnboarding
                ? Icons.verified_user_rounded
                : Icons.privacy_tip_outlined,
            color: AppColors.onDark,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consent.readyForOnboarding
                      ? 'Consent is ready'
                      : 'Consent needs review',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Your choices control health data, sensor data, coaching, and reports.',
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

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
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
