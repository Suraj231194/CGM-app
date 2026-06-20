import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../core/security/route_guards.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/customer/ai_interpretation_screen.dart';
import '../screens/customer/alerts_screen.dart';
import '../screens/customer/customer_dashboard_screen.dart';
import '../screens/customer/devices_integrations_screen.dart';
import '../screens/customer/full_screen_chart_screen.dart';
import '../screens/customer/meal_logging_screen.dart';
import '../screens/customer/privacy_settings_screen.dart';
import '../screens/customer/profile_settings_screen.dart';
import '../screens/customer/reading_history_screen.dart';
import '../screens/customer/report_export_screen.dart';
import '../screens/customer/reorder_screens.dart';
import '../screens/doctor/doctor_dashboard_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/sensor/sensor_flow_screens.dart';
import '../screens/support/support_hub_screen.dart';
import '../state/app_state.dart';
import '../widgets/app_shell.dart';
import '../widgets/offline_banner.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, routerState) {
      final appState = ref.read(appControllerProvider);
      final isAuthenticated = appState.isAuthenticated;
      final loggingIn = routerState.matchedLocation == '/login';
      final onboarding = routerState.matchedLocation == '/onboarding';
      if (!isAuthenticated && !loggingIn) return '/login';
      if (isAuthenticated &&
          appState.activeRole == OptimusRole.customer &&
          !appState.onboardingComplete &&
          !onboarding) {
        return '/onboarding';
      }
      if (isAuthenticated && loggingIn) {
        return appState.onboardingComplete ? '/dashboard' : '/onboarding';
      }
      if (isAuthenticated && onboarding && appState.onboardingComplete) {
        return '/dashboard';
      }
      // Role-based route guard
      if (isAuthenticated && !loggingIn && !onboarding) {
        final guardRedirect = RouteGuards.guardRedirect(
          appState.activeRole,
          routerState.matchedLocation,
        );
        if (guardRedirect != null) return guardRedirect;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _appPage(state, const OnboardingScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                _appPage(state, const RoleLandingScreen()),
          ),
          GoRoute(
            path: '/chart',
            pageBuilder: (context, state) =>
                _appPage(state, const FullScreenChartScreen()),
          ),
          GoRoute(
            path: '/readings',
            pageBuilder: (context, state) =>
                _appPage(state, const ReadingHistoryScreen()),
          ),
          GoRoute(
            path: '/meal',
            pageBuilder: (context, state) =>
                _appPage(state, const MealLoggingScreen()),
          ),
          GoRoute(
            path: '/ai',
            pageBuilder: (context, state) =>
                _appPage(state, const AIInterpretationScreen()),
          ),
          GoRoute(
            path: '/alerts',
            pageBuilder: (context, state) =>
                _appPage(state, const AlertsScreen()),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) =>
                _appPage(state, const ReportExportScreen()),
          ),
          GoRoute(
            path: '/sensor',
            pageBuilder: (context, state) =>
                _appPage(state, const SensorActivationIntroScreen()),
            routes: [
              GoRoute(
                path: 'attach',
                pageBuilder: (context, state) =>
                    _appPage(state, const AttachSensorInstructionsScreen()),
              ),
              GoRoute(
                path: 'scan',
                pageBuilder: (context, state) =>
                    _appPage(state, const ScanSensorScreen()),
              ),
              GoRoute(
                path: 'warmup',
                pageBuilder: (context, state) =>
                    _appPage(state, const WarmupCountdownScreen()),
              ),
              GoRoute(
                path: 'status',
                pageBuilder: (context, state) =>
                    _appPage(state, const SensorStatusScreen()),
              ),
            ],
          ),
          GoRoute(
            path: '/devices',
            pageBuilder: (context, state) =>
                _appPage(state, const DevicesIntegrationsScreen()),
          ),
          GoRoute(
            path: '/reorder',
            pageBuilder: (context, state) =>
                _appPage(state, const ReorderSensorScreen()),
          ),
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) =>
                _appPage(state, const OrderHistoryScreen()),
          ),
          GoRoute(
            path: '/support',
            pageBuilder: (context, state) =>
                _appPage(state, const SupportHubScreen()),
          ),
          GoRoute(
            path: '/account',
            pageBuilder: (context, state) =>
                _appPage(state, const ProfileSettingsScreen()),
          ),
          GoRoute(
            path: '/privacy',
            pageBuilder: (context, state) =>
                _appPage(state, const PrivacySettingsScreen()),
          ),
        ],
      ),
    ],
  );
});

NoTransitionPage<void> _appPage(GoRouterState state, Widget child) {
  return NoTransitionPage(key: state.pageKey, child: child);
}

class RoleLandingScreen extends ConsumerWidget {
  const RoleLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(
      appControllerProvider.select((state) => state.activeRole),
    );
    return switch (role) {
      OptimusRole.customer => const CustomerDashboardScreen(),
      OptimusRole.doctor => const DoctorDashboardScreen(),
      OptimusRole.admin => const AdminDashboardScreen(),
    };
  }
}

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(
      appControllerProvider.select((state) => state.activeRole),
    );
    final location = GoRouterState.of(context).matchedLocation;
    final destinations = switch (role) {
      OptimusRole.customer => const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.show_chart_rounded),
          label: 'Chart',
        ),
        NavigationDestination(
          icon: Icon(Icons.list_alt_rounded),
          label: 'Readings',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          label: 'Account',
        ),
      ],
      OptimusRole.doctor => const [
        NavigationDestination(
          icon: Icon(Icons.medical_services_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.show_chart_rounded),
          label: 'Chart',
        ),
        NavigationDestination(
          icon: Icon(Icons.list_alt_rounded),
          label: 'Readings',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          label: 'Account',
        ),
      ],
      OptimusRole.admin => const [
        NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.show_chart_rounded),
          label: 'Chart',
        ),
        NavigationDestination(
          icon: Icon(Icons.list_alt_rounded),
          label: 'Readings',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          label: 'Account',
        ),
      ],
    };
    const paths = ['/dashboard', '/chart', '/readings', '/account'];
    final index = _navigationIndexFor(location, paths);
    final backTarget = _backTargetFor(location);
    final activeAlertCount = role == OptimusRole.customer
        ? ref.watch(activeAlertsProvider).length
        : 0;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: backTarget == null
            ? null
            : IconButton(
                tooltip: 'Back',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.go(backTarget);
                },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: const BrandLockup(compact: true),
        actions: [
          if (role == OptimusRole.customer)
            IconButton(
              tooltip: activeAlertCount == 0
                  ? 'No active alerts'
                  : '$activeAlertCount active glucose alert${activeAlertCount == 1 ? '' : 's'}',
              onPressed: () => context.go('/alerts'),
              icon: Badge.count(
                count: activeAlertCount,
                isLabelVisible: activeAlertCount > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
          IconButton(
            tooltip: '${role.name} profile',
            onPressed: () => context.go('/account'),
            icon: Icon(Icons.account_circle_rounded, color: roleColor(role)),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(child: ClipRect(child: child)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: index,
        destinations: destinations,
        indicatorColor: roleColor(role).withValues(alpha: 0.14),
        onDestinationSelected: (value) {
          final target = paths[value];
          if (location == target) return;
          context.go(target);
        },
      ),
    );
  }
}

int _navigationIndexFor(String location, List<String> paths) {
  final directIndex = paths.indexWhere((path) => location.startsWith(path));
  if (directIndex >= 0) return directIndex;

  if (location == '/orders' ||
      location == '/support' ||
      location == '/privacy' ||
      location == '/alerts' ||
      location == '/reports') {
    return 3;
  }
  if (location == '/meal') return 2;
  return 0;
}

String? _backTargetFor(String location) {
  const primaryRoutes = {'/dashboard', '/chart', '/readings', '/account'};
  if (primaryRoutes.contains(location)) return null;

  return switch (location) {
    '/ai' => '/dashboard',
    '/alerts' => '/dashboard',
    '/reports' => '/dashboard',
    '/meal' => '/dashboard',
    '/devices' => '/dashboard',
    '/sensor' => '/dashboard',
    '/sensor/attach' => '/sensor',
    '/sensor/scan' => '/sensor/attach',
    '/sensor/warmup' => '/sensor/scan',
    '/sensor/status' => '/sensor',
    '/reorder' => '/dashboard',
    '/orders' => '/account',
    '/support' => '/account',
    '/privacy' => '/account',
    _ => null,
  };
}
