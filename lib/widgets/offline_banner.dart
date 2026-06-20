import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/network/connectivity_monitor.dart';

/// A banner that appears at the top of the screen when offline.
/// Wrap your scaffold body or use as a persistent widget.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);

    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: AppColors.warningSoft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              'Offline. Showing saved data.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: 'Check connection',
            visualDensity: VisualDensity.compact,
            onPressed: () => ref.read(connectivityProvider.notifier).refresh(),
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
