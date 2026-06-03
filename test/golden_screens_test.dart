import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optimus_cgm_flutter/main.dart';
import 'package:optimus_cgm_flutter/models/optimus_models.dart';
import 'package:optimus_cgm_flutter/state/app_state.dart';
import 'package:optimus_cgm_flutter/state/cgm_sdk_event_bridge.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('golden welcome screen', (tester) async {
    _setGoldenSurface(tester);
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/welcome.png'),
    );
  });

  testWidgets('golden dashboard screen', (tester) async {
    _setGoldenSurface(tester);
    await _openCustomerDashboard(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashboard.png'),
    );
  });

  testWidgets('golden logbook screen', (tester) async {
    _setGoldenSurface(tester);
    await _openCustomerDashboard(tester);
    await _go(tester, '/readings');

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/logbook.png'),
    );
  });

  testWidgets('golden AI screen', (tester) async {
    _setGoldenSurface(tester);
    await _openCustomerDashboard(tester);
    await _go(tester, '/ai');

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/ai.png'),
    );
  });

  testWidgets('golden chart screen', (tester) async {
    _setGoldenSurface(tester);
    await _openCustomerDashboard(tester);
    await _go(tester, '/chart');

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/chart.png'),
    );
  });
}

void _setGoldenSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _openCustomerDashboard(WidgetTester tester) async {
  await tester.pumpWidget(_testApp());
  await tester.pumpAndSettle();

  await tester.tap(find.text('Continue as Customer'));
  await tester.pumpAndSettle();

  for (final label in const [
    'Use health data',
    'Use sensor data',
    'Enable coaching insights',
    'Accept safety terms',
  ]) {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  await tester.ensureVisible(find.text('Finish setup later'));
  await tester.tap(find.text('Finish setup later'));
  await tester.pumpAndSettle();
}

Future<void> _go(WidgetTester tester, String route) async {
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(route);
  await tester.pumpAndSettle();
}

Widget _testApp() {
  return ProviderScope(
    overrides: [
      cgmSdkEventBridgeProvider.overrideWith((ref) {}),
      appControllerProvider.overrideWith(GoldenAppController.new),
    ],
    child: const OptimusCgmApp(),
  );
}

class GoldenAppController extends AppController {
  @override
  AppState build() {
    final base = super.build();
    return base.copyWith(
      readings: _goldenReadings(),
      meals: _goldenMeals(),
      alerts: _goldenAlerts(),
      reportExports: _goldenReports(),
    );
  }
}

List<OptimusGlucoseReading> _goldenReadings() {
  final start = DateTime(2026, 6, 2, 6);
  final values = [
    104,
    108,
    116,
    132,
    151,
    144,
    126,
    118,
    112,
    119,
    138,
    166,
    184,
    171,
    146,
    128,
    121,
    115,
    111,
    109,
  ];

  return values.asMap().entries.map((entry) {
    final index = entry.key;
    final value = entry.value;
    final previous = index == 0 ? value : values[index - 1];
    final trend = value - previous;
    final status = value < 70
        ? GlucoseStatus.low
        : value > 180
        ? GlucoseStatus.high
        : GlucoseStatus.normal;
    return OptimusGlucoseReading(
      id: 'golden-reading-$index',
      sensorId: 'sensor-1',
      patientId: 'patient-1',
      timestamp: start.add(Duration(minutes: index * 36)),
      value: value,
      unit: 'mg/dL',
      trend: trend >= 8
          ? TrendDirection.rising
          : trend <= -8
          ? TrendDirection.falling
          : TrendDirection.steady,
      status: status,
    );
  }).toList();
}

List<MealLog> _goldenMeals() {
  return [
    MealLog(
      id: 'golden-meal-1',
      patientId: 'patient-1',
      timestamp: DateTime(2026, 6, 2, 13),
      type: MealType.lunch,
      title: 'Rice bowl with paneer',
      netCarbs: 52,
      protein: 30,
      fiber: 8,
      activityMinutes: 12,
      score: 76,
      note: 'Smoother recovery after walking.',
    ),
    MealLog(
      id: 'golden-meal-2',
      patientId: 'patient-1',
      timestamp: DateTime(2026, 6, 2, 8),
      type: MealType.breakfast,
      title: 'Oats, eggs, berries',
      netCarbs: 36,
      protein: 24,
      fiber: 9,
      activityMinutes: 8,
      score: 84,
      note: 'Balanced breakfast response.',
    ),
  ];
}

List<GlucoseAlert> _goldenAlerts() {
  return [
    GlucoseAlert(
      id: 'golden-alert-1',
      patientId: 'patient-1',
      timestamp: DateTime(2026, 6, 2, 13, 12),
      title: 'High glucose alert',
      message:
          'Glucose crossed 180 mg/dL. Review food, activity, and care-team guidance.',
      value: 184,
      threshold: 180,
      severity: AlertSeverity.warning,
      acknowledged: false,
    ),
  ];
}

List<ReportExport> _goldenReports() {
  return [
    ReportExport(
      id: 'golden-report-1',
      patientId: 'patient-1',
      period: '7 day',
      generatedAt: DateTime(2026, 6, 2, 16),
      format: 'PDF',
      status: 'ready',
      summary: '96% time in range, 129 mg/dL average, 2 meals, 1 alert.',
    ),
  ];
}
