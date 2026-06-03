import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../widgets/app_shell.dart';

class SupportHubScreen extends StatefulWidget {
  const SupportHubScreen({super.key});

  @override
  State<SupportHubScreen> createState() => _SupportHubScreenState();
}

class _SupportHubScreenState extends State<SupportHubScreen> {
  var _selectedIndex = 0;
  final _nameController = TextEditingController(text: 'Aarav Mehta');
  final _contactController = TextEditingController(text: '+91 98765 43210');
  final _messageController = TextEditingController(
    text: 'Need help reviewing CGM sensor setup and care-team report sharing.',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _supportItems[_selectedIndex];

    return AppScreen(
      children: [
        const SectionHeader(
          eyebrow: 'Support',
          title: 'Support and information',
          subtitle: 'Contact, FAQs, company, legal, quote, and meeting flows.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final menu = _SupportMenu(
              selectedIndex: _selectedIndex,
              onSelect: (index) => setState(() => _selectedIndex = index),
            );
            final detail = _SupportDetail(
              item: selected,
              nameController: _nameController,
              contactController: _contactController,
              messageController: _messageController,
              onSubmit: () => _submitRequest(context, selected),
            );

            if (compact) {
              return Column(
                children: [
                  menu,
                  const SizedBox(height: AppSpacing.lg),
                  detail,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 360, child: menu),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: detail),
              ],
            );
          },
        ),
      ],
    );
  }

  void _submitRequest(BuildContext context, _SupportItem item) {
    final name = _nameController.text.trim();
    final contact = _contactController.text.trim();
    final message = _messageController.text.trim();

    if (name.isEmpty || contact.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all support fields.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.title} request prepared for $name.')),
    );
  }
}

class _SupportMenu extends StatelessWidget {
  const _SupportMenu({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < _supportItems.length; index += 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _SupportMenuTile(
              item: _supportItems[index],
              selected: index == selectedIndex,
              onTap: () => onSelect(index),
            ),
          ),
      ],
    );
  }
}

class _SupportMenuTile extends StatelessWidget {
  const _SupportMenuTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _SupportItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.wellness : AppColors.primary;

    return PremiumCard(
      elevated: selected,
      color: selected ? AppColors.wellnessSoft : null,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              SizedBox(width: 32, child: Icon(item.icon, color: color)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: selected ? AppColors.wellness : null,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: selected ? AppColors.wellness : AppColors.subtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportDetail extends StatelessWidget {
  const _SupportDetail({
    required this.item,
    required this.nameController,
    required this.contactController,
    required this.messageController,
    required this.onSubmit,
  });

  final _SupportItem item;
  final TextEditingController nameController;
  final TextEditingController contactController;
  final TextEditingController messageController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...item.sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _SupportSection(section: section),
            ),
          ),
          if (item.requestType != null) ...[
            const SizedBox(height: AppSpacing.md),
            _SupportRequestForm(
              item: item,
              nameController: nameController,
              contactController: contactController,
              messageController: messageController,
              onSubmit: onSubmit,
            ),
          ],
        ],
      ),
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection({required this.section});

  final _SupportSectionData section;

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) {
      return Text(
        section.body,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.muted, height: 1.45),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final row in section.items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.mint,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    row,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      height: 1.4,
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

class _SupportRequestForm extends StatelessWidget {
  const _SupportRequestForm({
    required this.item,
    required this.nameController,
    required this.contactController,
    required this.messageController,
    required this.onSubmit,
  });

  final _SupportItem item;
  final TextEditingController nameController;
  final TextEditingController contactController;
  final TextEditingController messageController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.requestType} request',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: contactController,
            decoration: const InputDecoration(
              labelText: 'Phone or email',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: messageController,
            minLines: 3,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Request details',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.check_rounded),
            label: Text('Prepare ${item.requestType}'),
          ),
        ],
      ),
    );
  }
}

class _SupportItem {
  const _SupportItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.sections,
    this.requestType,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_SupportSectionData> sections;
  final String? requestType;
}

class _SupportSectionData {
  const _SupportSectionData({
    required this.title,
    required this.body,
    this.items = const [],
  });

  final String title;
  final String body;
  final List<String> items;
}

const _supportItems = [
  _SupportItem(
    title: 'Contact Us',
    subtitle: 'Reach care, sales, or technical support.',
    icon: Icons.call_outlined,
    color: AppColors.primary,
    requestType: 'Support',
    sections: [
      _SupportSectionData(
        title: 'Response channels',
        body: '',
        items: [
          'Care support: sensor setup, alerts, meal logs, and reports.',
          'Technical support: app access, integrations, and data sync.',
          'Commercial support: quotes, PI requests, and institutional orders.',
        ],
      ),
    ],
  ),
  _SupportItem(
    title: 'Frequently Asked Questions',
    subtitle: 'Payments, refunds, shipping, and service guidance.',
    icon: Icons.quiz_outlined,
    color: AppColors.lilac,
    sections: [
      _SupportSectionData(
        title: 'Common answers',
        body: '',
        items: [
          'CGM sensor records are reviewed in Dashboard, Chart, and Readings.',
          'Reports require sharing consent from Privacy before export.',
          'Sensor reorder and order history are available from Account.',
          'Alerts are informational review prompts, not emergency guidance.',
        ],
      ),
    ],
  ),
  _SupportItem(
    title: 'About Biogenix',
    subtitle: 'Vision, quality posture, and operating model.',
    icon: Icons.business_outlined,
    color: AppColors.wellness,
    sections: [
      _SupportSectionData(
        title: 'Company profile',
        body:
            'Biogenix supports connected health workflows across monitoring, reporting, and clinical review. Optimus CGM focuses on practical glucose intelligence for customers and care teams.',
      ),
      _SupportSectionData(
        title: 'Quality posture',
        body: '',
        items: [
          'Privacy-first consent and report-sharing controls.',
          'Clear separation between coaching insights and clinical advice.',
          'Operational screens for support, sync review, and orders.',
        ],
      ),
    ],
  ),
  _SupportItem(
    title: 'Meet the Team',
    subtitle: 'Leadership and operational stakeholders.',
    icon: Icons.groups_outlined,
    color: AppColors.accentDeep,
    sections: [
      _SupportSectionData(
        title: 'Team coverage',
        body: '',
        items: [
          'Care operations: onboarding, report readiness, and customer support.',
          'Clinical review: patient trend interpretation and risk review.',
          'Platform operations: integrations, sensor logs, and reliability.',
        ],
      ),
    ],
  ),
  _SupportItem(
    title: 'Generate Quote',
    subtitle: 'Quotation request for sensors and institutional plans.',
    icon: Icons.request_quote_outlined,
    color: AppColors.honey,
    requestType: 'Quote',
    sections: [
      _SupportSectionData(
        title: 'Quote details',
        body: '',
        items: [
          'Include required sensor quantity, delivery city, and billing entity.',
          'For care-team deployments, add patient count and onboarding needs.',
        ],
      ),
    ],
  ),
  _SupportItem(
    title: 'Request PI',
    subtitle: 'Prepare a proforma invoice request.',
    icon: Icons.description_outlined,
    color: AppColors.primary,
    requestType: 'PI',
    sections: [
      _SupportSectionData(
        title: 'PI preparation',
        body: '',
        items: [
          'Provide billing name, GST/tax details if applicable, and quantity.',
          'Add shipment address and expected dispatch timeline.',
        ],
      ),
    ],
  ),
  _SupportItem(
    title: 'Book a Meeting',
    subtitle: 'Schedule sales or technical consultation.',
    icon: Icons.event_available_outlined,
    color: AppColors.meadow,
    requestType: 'Meeting',
    sections: [
      _SupportSectionData(
        title: 'Meeting agenda',
        body: '',
        items: [
          'Choose implementation, sensor setup, care-team reporting, or pricing.',
          'Add preferred date, time, and attendee count in request details.',
        ],
      ),
    ],
  ),
  _SupportItem(
    title: 'Diagnostic Quiz',
    subtitle: 'Capture requirements and lead qualification.',
    icon: Icons.fact_check_outlined,
    color: AppColors.clay,
    requestType: 'Diagnostic',
    sections: [
      _SupportSectionData(
        title: 'Requirement capture',
        body: '',
        items: [
          'Current monitoring method and target patient population.',
          'Need for reports, alerts, integrations, or clinical dashboards.',
        ],
      ),
    ],
  ),
  _SupportItem(
    title: 'Portfolio',
    subtitle: 'Institutional reach and customer footprint.',
    icon: Icons.account_balance_outlined,
    color: AppColors.admin,
    sections: [
      _SupportSectionData(
        title: 'Portfolio view',
        body: '',
        items: [
          'Customer CGM workspace with dashboard, readings, and reports.',
          'Doctor workspace for assigned-patient risk review.',
          'Admin workspace for operations, support, and sync visibility.',
        ],
      ),
    ],
  ),
  _SupportItem(
    title: 'Privacy Policy',
    subtitle: 'Privacy and data-handling commitments.',
    icon: Icons.privacy_tip_outlined,
    color: AppColors.wellness,
    sections: [
      _SupportSectionData(
        title: 'Policy summary',
        body: '',
        items: [
          'Health and sensor data are controlled by explicit consent choices.',
          'Report sharing is disabled unless enabled in Privacy settings.',
          'Coaching insights are informational and not emergency guidance.',
        ],
      ),
    ],
  ),
  _SupportItem(
    title: 'Terms & Conditions',
    subtitle: 'Commercial terms and usage boundaries.',
    icon: Icons.rule_folder_outlined,
    color: AppColors.primaryDeep,
    sections: [
      _SupportSectionData(
        title: 'Terms summary',
        body: '',
        items: [
          'Use the app as a review and logging tool with clinician oversight.',
          'Sensor availability and orders are subject to fulfillment checks.',
          'Clinical treatment decisions must follow care-team guidance.',
        ],
      ),
    ],
  ),
  _SupportItem(
    title: 'Refund Policy',
    subtitle: 'Refund and cancellation guidance.',
    icon: Icons.assignment_return_outlined,
    color: AppColors.warning,
    sections: [
      _SupportSectionData(
        title: 'Refund guidance',
        body: '',
        items: [
          'Order issues should include order ID, quantity, and delivery status.',
          'Sensor replacement review may require serial number and sync logs.',
          'Commercial refunds follow the invoice and fulfillment terms.',
        ],
      ),
    ],
  ),
];
