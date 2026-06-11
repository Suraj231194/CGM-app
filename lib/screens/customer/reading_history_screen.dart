import 'package:flutter/material.dart';
import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../models/optimus_models.dart';
import '../../state/app_state.dart';
import '../../utils/glucose_utils.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_states.dart';
import '../../widgets/glucose_chart.dart';

class ReadingHistoryScreen extends ConsumerStatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  ConsumerState<ReadingHistoryScreen> createState() =>
      _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends ConsumerState<ReadingHistoryScreen> {
  DateTime _selectedDate = clock.now();

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final patientReadings =
        appState.readings
            .where((reading) => reading.patientId == appState.selectedPatientId)
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final minDate = patientReadings.isEmpty
        ? _dateOnly(clock.now())
        : _dateOnly(patientReadings.first.timestamp);
    final maxDate = patientReadings.isEmpty
        ? _dateOnly(clock.now())
        : _dateOnly(patientReadings.last.timestamp);
    final selectedDate = _clampedDate(_selectedDate, minDate, maxDate);
    final readingsForDate = patientReadings
        .where((reading) => _isSameDay(reading.timestamp, selectedDate))
        .toList();
    final filter = ref.watch(
      appControllerProvider.select((state) => state.readingFilter),
    );
    final filteredRows =
        (filter == null
                ? readingsForDate
                : readingsForDate
                      .where((reading) => reading.status == filter)
                      .toList())
            .reversed
            .toList();
    final summary = summarizeReadings(readingsForDate);

    return AppScreen(
      children: [
        const SectionHeader(
          eyebrow: 'Logbook',
          title: 'Daily glucose log',
          subtitle: 'Glucose values, meals, activity, and notes in one view.',
        ),
        _LogbookHero(
          readings: readingsForDate,
          summary: summary,
          selectedDate: selectedDate,
        ),
        const SizedBox(height: AppSpacing.lg),
        _DateSelectorCard(
          selectedDate: selectedDate,
          minDate: minDate,
          maxDate: maxDate,
          onPrevious: _canGoPrevious(selectedDate, minDate)
              ? () => setState(() {
                  _selectedDate = selectedDate.subtract(
                    const Duration(days: 1),
                  );
                })
              : null,
          onNext: _canGoNext(selectedDate, maxDate)
              ? () => setState(() {
                  _selectedDate = selectedDate.add(const Duration(days: 1));
                })
              : null,
          onToday: _canJumpToday(selectedDate, minDate, maxDate)
              ? () => setState(() {
                  _selectedDate = _dateOnly(clock.now());
                })
              : null,
          onPick: () => _pickDate(context, minDate, maxDate, selectedDate),
        ),
        const SizedBox(height: AppSpacing.lg),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<GlucoseStatus?>(
            segments: const [
              ButtonSegment(
                value: null,
                icon: Icon(Icons.all_inclusive_rounded),
                label: Text('All'),
              ),
              ButtonSegment(
                value: GlucoseStatus.low,
                icon: Icon(Icons.arrow_downward_rounded),
                label: Text('Low'),
              ),
              ButtonSegment(
                value: GlucoseStatus.normal,
                icon: Icon(Icons.check_rounded),
                label: Text('Range'),
              ),
              ButtonSegment(
                value: GlucoseStatus.high,
                icon: Icon(Icons.arrow_upward_rounded),
                label: Text('High'),
              ),
            ],
            selected: {filter},
            onSelectionChanged: (value) {
              ref
                  .read(appControllerProvider.notifier)
                  .setReadingFilter(value.first);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _QuickLogPanel(onMeal: () => context.push('/meal')),
        const SizedBox(height: AppSpacing.lg),
        if (filteredRows.isEmpty)
          AppEmptyState(
            icon: Icons.show_chart_rounded,
            title: 'No readings found',
            subtitle:
                'No ${filter == null ? '' : '${glucoseStatusLabel(filter).toLowerCase()} '}readings were found for ${_dateTitle(selectedDate)}.',
          )
        else
          _LogbookList(readings: filteredRows),
      ],
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    DateTime minDate,
    DateTime maxDate,
    DateTime selectedDate,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: minDate,
      lastDate: maxDate,
      helpText: 'Select reading date',
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = _dateOnly(picked));
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _clampedDate(DateTime value, DateTime minDate, DateTime maxDate) {
    final date = _dateOnly(value);
    if (date.isBefore(minDate)) return minDate;
    if (date.isAfter(maxDate)) return maxDate;
    return date;
  }

  bool _isSameDay(DateTime value, DateTime date) {
    return value.year == date.year &&
        value.month == date.month &&
        value.day == date.day;
  }

  bool _canGoPrevious(DateTime selectedDate, DateTime minDate) {
    return selectedDate.isAfter(minDate);
  }

  bool _canGoNext(DateTime selectedDate, DateTime maxDate) {
    return selectedDate.isBefore(maxDate);
  }

  bool _canJumpToday(
    DateTime selectedDate,
    DateTime minDate,
    DateTime maxDate,
  ) {
    final today = _dateOnly(clock.now());
    return selectedDate != today &&
        !today.isBefore(minDate) &&
        !today.isAfter(maxDate);
  }
}

String _dateTitle(DateTime date) {
  final today = clock.now();
  if (date.year == today.year &&
      date.month == today.month &&
      date.day == today.day) {
    return 'Today';
  }
  return DateFormat('MMM d').format(date);
}

class _LogbookHero extends StatelessWidget {
  const _LogbookHero({
    required this.readings,
    required this.summary,
    required this.selectedDate,
  });

  final List<OptimusGlucoseReading> readings;
  final ({
    int average,
    int timeInRange,
    int timeAbove,
    int timeBelow,
    int min,
    int max,
  })
  summary;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryDeep,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: AppColors.onDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  '${_dateTitle(selectedDate)} report',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusPill(
                label: '${readings.length} entries',
                color: AppColors.primary,
                icon: Icons.format_list_bulleted_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GlucoseChart(readings: readings, height: 156),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _ReportMetric(
                  label: 'Average',
                  value: '${summary.average}',
                  unit: 'mg/dL',
                  color: AppColors.text,
                ),
              ),
              const _ReportDivider(),
              Expanded(
                child: _ReportMetric(
                  label: 'GMI',
                  value: _estimatedGmi(summary.average),
                  unit: '%',
                  color: AppColors.lilac,
                ),
              ),
              const _ReportDivider(),
              Expanded(
                child: _ReportMetric(
                  label: 'In range',
                  value: '${summary.timeInRange}',
                  unit: '%',
                  color: AppColors.meadow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _estimatedGmi(int average) {
    if (average <= 0) return '--';
    return (3.31 + (0.02392 * average)).toStringAsFixed(1);
  }
}

class _DateSelectorCard extends StatelessWidget {
  const _DateSelectorCard({
    required this.selectedDate,
    required this.minDate,
    required this.maxDate,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onPick,
  });

  final DateTime selectedDate;
  final DateTime minDate;
  final DateTime maxDate;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToday;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final rangeLabel =
        '${DateFormat('MMM d').format(minDate)} - ${DateFormat('MMM d').format(maxDate)}';

    return PremiumCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final dateButton = OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(
              DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
          final todayButton = FilledButton.tonalIcon(
            onPressed: onToday,
            icon: const Icon(Icons.today_rounded),
            label: const Text('Today'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Previous date',
                      onPressed: onPrevious,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: dateButton),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filledTonal(
                      tooltip: 'Next date',
                      onPressed: onNext,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                todayButton,
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Available records: $rangeLabel',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Previous date',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: AppSpacing.sm),
              dateButton,
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                tooltip: 'Next date',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Available records: $rangeLabel',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              todayButton,
            ],
          );
        },
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                unit,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportDivider extends StatelessWidget {
  const _ReportDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: AppColors.border,
    );
  }
}

class _QuickLogPanel extends StatelessWidget {
  const _QuickLogPanel({required this.onMeal});

  final VoidCallback onMeal;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final items = [
          _QuickLogItem(
            Icons.restaurant_menu_rounded,
            'Meal',
            AppColors.honey,
            onMeal,
          ),
          const _QuickLogItem(
            Icons.fitness_center_rounded,
            'Activity',
            AppColors.mint,
            null,
          ),
          const _QuickLogItem(
            Icons.medication_outlined,
            'Insulin',
            AppColors.lilac,
            null,
          ),
          const _QuickLogItem(
            Icons.note_add_outlined,
            'Note',
            AppColors.primary,
            null,
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact ? 2 : 4,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            mainAxisExtent: 68,
          ),
          itemBuilder: (context, index) => _QuickLogButton(item: items[index]),
        );
      },
    );
  }
}

class _QuickLogItem {
  const _QuickLogItem(this.icon, this.label, this.color, this.onTap);

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
}

class _QuickLogButton extends StatelessWidget {
  const _QuickLogButton({required this.item});

  final _QuickLogItem item;

  @override
  Widget build(BuildContext context) {
    final enabled = item.onTap != null;

    return Tooltip(
      message: enabled ? item.label : '${item.label} logging is not connected',
      child: Material(
        color: enabled
            ? item.color.withValues(alpha: 0.1)
            : AppColors.border.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Icon(item.icon, color: enabled ? item.color : AppColors.subtle),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: enabled ? AppColors.text : AppColors.muted,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (!enabled) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.subtle,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogbookList extends StatelessWidget {
  const _LogbookList({required this.readings});

  final List<OptimusGlucoseReading> readings;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          for (var index = 0; index < readings.length; index += 1) ...[
            _LogbookEntry(reading: readings[index], index: index),
            if (index != readings.length - 1)
              const Divider(height: AppSpacing.lg, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _LogbookEntry extends StatelessWidget {
  const _LogbookEntry({required this.reading, required this.index});

  final OptimusGlucoseReading reading;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = glucoseStatusColor(reading.status);
    final event = _eventFor(index, reading.timestamp.hour);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatTime(reading.timestamp),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                formatShortDate(reading.timestamp),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${reading.value}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'mg/dL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onDarkMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      glucoseStatusLabel(reading.status),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  StatusPill(
                    label: trendLabel(reading.trend),
                    color: AppColors.primary,
                    icon: Icons.trending_up_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _LogEventChip(
                    icon: event.icon,
                    label: event.label,
                    color: event.color,
                  ),
                  _LogEventChip(
                    icon: Icons.restaurant_rounded,
                    label: '${event.carbs}g carbs',
                    color: AppColors.honey,
                  ),
                  const _LogEventChip(
                    icon: Icons.water_drop_outlined,
                    label: 'Water',
                    color: AppColors.accentDeep,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  _LogEvent _eventFor(int index, int hour) {
    if (hour >= 6 && hour < 11) {
      return const _LogEvent(
        Icons.breakfast_dining_rounded,
        'Breakfast',
        34,
        AppColors.meadow,
      );
    }
    if (hour >= 11 && hour < 16) {
      return const _LogEvent(
        Icons.lunch_dining_rounded,
        'Lunch',
        48,
        AppColors.clay,
      );
    }
    if (hour >= 17 && hour < 23) {
      return const _LogEvent(
        Icons.dinner_dining_rounded,
        'Dinner',
        42,
        AppColors.lilac,
      );
    }
    return index.isEven
        ? const _LogEvent(
            Icons.bedtime_outlined,
            'Fasting',
            0,
            AppColors.primary,
          )
        : const _LogEvent(
            Icons.directions_walk_rounded,
            'Walk',
            0,
            AppColors.mint,
          );
  }
}

class _LogEvent {
  const _LogEvent(this.icon, this.label, this.carbs, this.color);

  final IconData icon;
  final String label;
  final int carbs;
  final Color color;
}

class _LogEventChip extends StatelessWidget {
  const _LogEventChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
