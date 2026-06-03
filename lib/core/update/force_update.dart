import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';

/// Minimum required app version. Update this when shipping critical patches.
/// In production, fetch this from your backend or Firebase Remote Config.
const String _minimumRequiredVersion = '1.0.0';
const String _storeUpdateUrl = 'https://optimus-cgm.example.com/download';

/// Checks if the current app version meets the minimum requirement.
/// Returns true if an update is required.
bool isUpdateRequired(String currentVersion) {
  final current = _parseVersion(currentVersion);
  final minimum = _parseVersion(_minimumRequiredVersion);

  if (current == null || minimum == null) return false;

  if (current.$1 < minimum.$1) return true;
  if (current.$1 == minimum.$1 && current.$2 < minimum.$2) return true;
  if (current.$1 == minimum.$1 &&
      current.$2 == minimum.$2 &&
      current.$3 < minimum.$3) {
    return true;
  }

  return false;
}

(int, int, int)? _parseVersion(String version) {
  final parts = version.split('+').first.split('.');
  if (parts.length < 3) return null;
  final major = int.tryParse(parts[0]);
  final minor = int.tryParse(parts[1]);
  final patch = int.tryParse(parts[2]);
  if (major == null || minor == null || patch == null) return null;
  return (major, minor, patch);
}

/// Provider that checks update requirement on app start.
/// In production, make this fetch from remote config.
final updateRequiredProvider = Provider<bool>((ref) {
  // Currently always returns false (no backend to check against).
  // When you have a backend, fetch minimum version and compare:
  // final remoteMin = await ref.read(remoteConfigProvider).getMinVersion();
  // return isUpdateRequired(currentAppVersion);
  return false;
});

/// Full-screen blocking dialog when update is required.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Update required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'A newer version of Optimus CGM is available with important safety updates. '
                'Please update to continue using the app.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(_storeUpdateUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Update now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
