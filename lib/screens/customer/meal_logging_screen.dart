import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/optimus_models.dart';
import '../../state/app_state.dart';
import '../../utils/glucose_utils.dart';
import '../../widgets/app_shell.dart';

class MealLoggingScreen extends ConsumerStatefulWidget {
  const MealLoggingScreen({super.key});

  @override
  ConsumerState<MealLoggingScreen> createState() => _MealLoggingScreenState();
}

class _MealLoggingScreenState extends ConsumerState<MealLoggingScreen> {
  final _titleController = TextEditingController(text: 'Balanced lunch');
  final _noteController = TextEditingController();
  var _type = MealType.lunch;
  var _netCarbs = 42;
  var _protein = 28;
  var _fiber = 8;
  var _activityMinutes = 10;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final score = mealScore(
      netCarbs: _netCarbs,
      protein: _protein,
      fiber: _fiber,
      activityMinutes: _activityMinutes,
    );
    final latestMeals = ref.watch(selectedMealsProvider).take(3).toList();

    return AppScreen(
      children: [
        const SectionHeader(
          showBack: true,
          eyebrow: 'Meal',
          title: 'Log meal impact',
          subtitle:
              'Capture food, movement, and notes so coaching can connect glucose response to context.',
        ),
        _MealScoreHero(score: score),
        const SizedBox(height: AppSpacing.lg),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meal details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<MealType>(
                  segments: const [
                    ButtonSegment(
                      value: MealType.breakfast,
                      icon: Icon(Icons.breakfast_dining_rounded),
                      label: Text('Breakfast'),
                    ),
                    ButtonSegment(
                      value: MealType.lunch,
                      icon: Icon(Icons.lunch_dining_rounded),
                      label: Text('Lunch'),
                    ),
                    ButtonSegment(
                      value: MealType.dinner,
                      icon: Icon(Icons.dinner_dining_rounded),
                      label: Text('Dinner'),
                    ),
                    ButtonSegment(
                      value: MealType.snack,
                      icon: Icon(Icons.local_cafe_rounded),
                      label: Text('Snack'),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (value) =>
                      setState(() => _type = value.first),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Meal name',
                  prefixIcon: Icon(Icons.restaurant_menu_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ScoreSlider(
                label: 'Net carbs',
                value: _netCarbs,
                unit: 'g',
                min: 0,
                max: 120,
                color: AppColors.honey,
                onChanged: (value) => setState(() => _netCarbs = value.round()),
              ),
              _ScoreSlider(
                label: 'Protein',
                value: _protein,
                unit: 'g',
                min: 0,
                max: 80,
                color: AppColors.mint,
                onChanged: (value) => setState(() => _protein = value.round()),
              ),
              _ScoreSlider(
                label: 'Fiber',
                value: _fiber,
                unit: 'g',
                min: 0,
                max: 40,
                color: AppColors.meadow,
                onChanged: (value) => setState(() => _fiber = value.round()),
              ),
              _ScoreSlider(
                label: 'Post-meal activity',
                value: _activityMinutes,
                unit: 'min',
                min: 0,
                max: 60,
                color: AppColors.primary,
                onChanged: (value) =>
                    setState(() => _activityMinutes = value.round()),
              ),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () {
                  ref
                      .read(appControllerProvider.notifier)
                      .addMealLog(
                        type: _type,
                        title: _titleController.text,
                        netCarbs: _netCarbs,
                        protein: _protein,
                        fiber: _fiber,
                        activityMinutes: _activityMinutes,
                        note: _noteController.text,
                      );
                  context.go('/readings');
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Save meal log'),
              ),
            ],
          ),
        ),
        if (latestMeals.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Recent meals',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final meal in latestMeals)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _MealRow(meal: meal),
            ),
        ],
      ],
    );
  }
}

class _MealScoreHero extends StatelessWidget {
  const _MealScoreHero({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppColors.meadow
        : score >= 60
        ? AppColors.honey
        : AppColors.clay;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.wellness,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 96,
                width: 96,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  color: color,
                  backgroundColor: AppColors.onDark.withValues(alpha: 0.16),
                ),
              ),
              Text(
                '$score',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.onDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(
                  label: score >= 80
                      ? 'STRONG BALANCE'
                      : score >= 60
                      ? 'WATCH CARBS'
                      : 'HIGH IMPACT',
                  color: color,
                  icon: Icons.eco_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Meal score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Higher fiber, protein, and post-meal movement improve the score.',
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

class _ScoreSlider extends StatelessWidget {
  const _ScoreSlider({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String unit;
  final double min;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '$value $unit',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Slider(
            min: min,
            max: max,
            divisions: (max - min).round(),
            value: value.toDouble().clamp(min, max),
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.meal});

  final MealLog meal;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          StatusPill(label: '${meal.score}', color: AppColors.meadow),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${meal.netCarbs}g carbs - ${meal.protein}g protein - ${meal.fiber}g fiber',
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
