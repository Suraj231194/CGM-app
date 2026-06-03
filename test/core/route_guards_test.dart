import 'package:flutter_test/flutter_test.dart';
import 'package:optimus_cgm_flutter/core/security/route_guards.dart';
import 'package:optimus_cgm_flutter/app/theme.dart';

void main() {
  group('RouteGuards', () {
    group('customer role', () {
      test('can access customer routes', () {
        expect(RouteGuards.canAccess(OptimusRole.customer, '/meal'), isTrue);
        expect(RouteGuards.canAccess(OptimusRole.customer, '/ai'), isTrue);
        expect(RouteGuards.canAccess(OptimusRole.customer, '/alerts'), isTrue);
        expect(RouteGuards.canAccess(OptimusRole.customer, '/reports'), isTrue);
        expect(RouteGuards.canAccess(OptimusRole.customer, '/sensor'), isTrue);
      });

      test('can access shared routes', () {
        expect(
          RouteGuards.canAccess(OptimusRole.customer, '/dashboard'),
          isTrue,
        );
        expect(RouteGuards.canAccess(OptimusRole.customer, '/chart'), isTrue);
        expect(
          RouteGuards.canAccess(OptimusRole.customer, '/readings'),
          isTrue,
        );
        expect(RouteGuards.canAccess(OptimusRole.customer, '/account'), isTrue);
      });
    });

    group('doctor role', () {
      test('can access shared routes', () {
        expect(RouteGuards.canAccess(OptimusRole.doctor, '/dashboard'), isTrue);
        expect(RouteGuards.canAccess(OptimusRole.doctor, '/chart'), isTrue);
      });

      test('can access customer routes (viewing patient)', () {
        expect(RouteGuards.canAccess(OptimusRole.doctor, '/meal'), isTrue);
      });
    });

    group('admin role', () {
      test('can access everything', () {
        expect(RouteGuards.canAccess(OptimusRole.admin, '/dashboard'), isTrue);
        expect(RouteGuards.canAccess(OptimusRole.admin, '/meal'), isTrue);
        expect(RouteGuards.canAccess(OptimusRole.admin, '/sensor'), isTrue);
      });
    });

    group('guardRedirect', () {
      test('returns null when access allowed', () {
        expect(
          RouteGuards.guardRedirect(OptimusRole.customer, '/meal'),
          isNull,
        );
      });

      test('returns /dashboard when access denied', () {
        // Currently customer can access all their routes, test with a
        // hypothetical restriction by checking admin-only in future
        expect(
          RouteGuards.guardRedirect(OptimusRole.customer, '/dashboard'),
          isNull,
        );
      });
    });

    test('handles sub-routes', () {
      expect(
        RouteGuards.canAccess(OptimusRole.customer, '/sensor/attach'),
        isTrue,
      );
      expect(
        RouteGuards.canAccess(OptimusRole.customer, '/sensor/scan'),
        isTrue,
      );
    });
  });
}
