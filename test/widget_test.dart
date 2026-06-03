import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:optimus_cgm_flutter/main.dart';
import 'package:optimus_cgm_flutter/state/cgm_sdk_event_bridge.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('renders welcome screen', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Optimus CGM'), findsOneWidget);
    expect(find.text('Choose your role'), findsOneWidget);
  });

  testWidgets('completes onboarding and opens customer dashboard', (
    tester,
  ) async {
    await _openCustomerDashboard(tester);

    expect(find.text('Current glucose'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(find.text('Glucose curve'), findsOneWidget);
  });

  testWidgets('saves a meal log from the logbook flow', (tester) async {
    await _openCustomerDashboard(tester);
    await _go(tester, '/meal');

    expect(find.text('Log meal impact'), findsOneWidget);
    expect(find.text('Meal score'), findsOneWidget);

    final saveMealButton = find
        .widgetWithText(FilledButton, 'Save meal log')
        .last;
    await tester.ensureVisible(saveMealButton);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(saveMealButton);
    await tester.pumpAndSettle();

    expect(find.text('Daily glucose log'), findsOneWidget);
  });

  testWidgets('shows full readings for a selected previous date', (
    tester,
  ) async {
    await _openCustomerDashboard(tester);
    await _go(tester, '/readings');

    expect(find.text('Daily glucose log'), findsOneWidget);
    expect(find.textContaining('Available records:'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous date'));
    await tester.pumpAndSettle();

    final previousTitle =
        '${DateFormat('MMM d').format(DateTime.now().subtract(const Duration(days: 1)))} report';
    expect(find.text(previousTitle), findsOneWidget);
    expect(find.textContaining('entries'), findsWidgets);
  });

  testWidgets('opens privacy, alerts, reports, AI, and chart screens', (
    tester,
  ) async {
    await _openCustomerDashboard(tester);

    await _go(tester, '/privacy');
    expect(find.text('Consent and data controls'), findsOneWidget);

    await _go(tester, '/alerts');
    expect(find.text('Glucose alert center'), findsOneWidget);

    await _go(tester, '/reports');
    expect(find.text('Export and share'), findsOneWidget);

    await _go(tester, '/ai');
    expect(find.text('Insight report'), findsOneWidget);

    await _go(tester, '/chart');
    expect(find.text('Glucose trends'), findsOneWidget);
  });

  testWidgets('opens account, toggles dark mode, and uses support flow', (
    tester,
  ) async {
    await _openCustomerDashboard(tester);

    await _go(tester, '/account');
    expect(find.text('Customer profile'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);

    await tester.ensureVisible(find.text('Dark mode'));
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();

    await _go(tester, '/support');
    expect(find.text('Support and information'), findsOneWidget);

    await tester.tap(find.text('Generate Quote'));
    await tester.pumpAndSettle();
    expect(find.text('Quote request'), findsOneWidget);

    await tester.ensureVisible(find.text('Prepare Quote'));
    await tester.tap(find.text('Prepare Quote'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Generate Quote request prepared'),
      findsOneWidget,
    );
  });
}

Future<void> _openCustomerDashboard(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(_testApp());
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('Continue as Customer'));
  await tester.tap(find.text('Continue as Customer'));
  await tester.pumpAndSettle();

  expect(find.text('Set up your glucose workspace'), findsOneWidget);

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
    overrides: [cgmSdkEventBridgeProvider.overrideWith((ref) {})],
    child: const OptimusCgmApp(),
  );
}
