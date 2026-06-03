import '../../app/theme.dart';

/// Defines which roles can access which routes.
/// Used by the router redirect logic to enforce access control.
class RouteGuards {
  RouteGuards._();

  /// Routes accessible only by customers.
  static const customerOnly = <String>{
    '/meal',
    '/ai',
    '/alerts',
    '/reports',
    '/sensor',
    '/reorder',
    '/orders',
    '/privacy',
    '/profile',
    '/onboarding',
  };

  /// Routes accessible only by doctors.
  static const doctorOnly = <String>{
    // Add doctor-specific routes here when created
  };

  /// Routes accessible only by admins.
  static const adminOnly = <String>{
    // Add admin-specific routes here when created
  };

  /// Routes accessible by all authenticated users.
  static const sharedAuthenticated = <String>{
    '/dashboard',
    '/chart',
    '/readings',
    '/account',
    '/devices',
    '/support',
  };

  /// Check if a role has access to a given route path.
  static bool canAccess(OptimusRole role, String path) {
    // Normalize: strip query params and trailing slash
    final normalizedPath = path.split('?').first.replaceAll(RegExp(r'/$'), '');

    // Check if it's a sub-route (e.g., /sensor/attach)
    final basePath =
        '/${normalizedPath.split('/').where((s) => s.isNotEmpty).firstOrNull ?? ''}';

    // Shared routes are always accessible
    if (sharedAuthenticated.contains(basePath)) return true;

    // Role-specific checks
    switch (role) {
      case OptimusRole.customer:
        return customerOnly.contains(basePath);
      case OptimusRole.doctor:
        return doctorOnly.contains(basePath) ||
            customerOnly.contains(basePath); // doctors can view patient screens
      case OptimusRole.admin:
        return true; // admins have full access
    }
  }

  /// Returns redirect path if user doesn't have access, or null if allowed.
  static String? guardRedirect(OptimusRole role, String path) {
    if (canAccess(role, path)) return null;
    return '/dashboard'; // redirect unauthorized access to dashboard
  }
}
