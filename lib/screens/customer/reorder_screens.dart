import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../state/app_state.dart';
import '../../utils/glucose_utils.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_states.dart';

class ReorderSensorScreen extends ConsumerStatefulWidget {
  const ReorderSensorScreen({super.key});

  @override
  ConsumerState<ReorderSensorScreen> createState() =>
      _ReorderSensorScreenState();
}

class _ReorderSensorScreenState extends ConsumerState<ReorderSensorScreen> {
  static const _maxQuantity = 5;
  int quantity = 1;
  final addressController = TextEditingController(
    text: '221 Health Park, Mumbai, Maharashtra 400001',
  );
  String? confirmation;

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Orders',
          title: 'Reorder sensor',
          subtitle:
              'Order replacement sensor packs for uninterrupted monitoring.',
        ),
        PremiumCard(
          child: Row(
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '14-day sensor pack',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Reorder before expiry to avoid data gaps.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quantity',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => setState(
                      () => quantity = (quantity - 1).clamp(1, _maxQuantity),
                    ),
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Text(
                      '$quantity',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: quantity >= _maxQuantity
                        ? null
                        : () => setState(() => quantity += 1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Maximum $_maxQuantity packs per reorder.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: addressController,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Shipping address',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: () async {
            if (addressController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a shipping address.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            final confirmed = await ConfirmDialog.show(
              context,
              title: 'Confirm order',
              content:
                  'Place order for $quantity sensor pack${quantity == 1 ? '' : 's'} to the address provided?',
              confirmLabel: 'Place order',
            );
            if (!confirmed || !context.mounted) return;
            ref
                .read(appControllerProvider.notifier)
                .placeReorder(quantity, addressController.text);
            setState(
              () => confirmation =
                  'Order placed for $quantity sensor pack${quantity == 1 ? '' : 's'}',
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order placed successfully!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Confirm reorder'),
        ),
        if (confirmation != null) ...[
          const SizedBox(height: AppSpacing.md),
          PremiumCard(
            color: AppColors.successSoft,
            child: Text(
              confirmation!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final orders = state.orders
        .where((order) => order.patientId == state.activePatientId)
        .toList();

    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Orders',
          title: 'Order history',
          subtitle: 'Track your sensor pack orders.',
        ),
        if (orders.isEmpty)
          const AppEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No orders yet',
            subtitle: 'Your sensor pack orders will appear here once placed.',
          )
        else
          ...orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: PremiumCard(
                elevated: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.productName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        StatusPill(
                          label: order.status.toUpperCase(),
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${formatShortDate(order.createdAt)} - Qty ${order.quantity}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      order.shippingAddress,
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
