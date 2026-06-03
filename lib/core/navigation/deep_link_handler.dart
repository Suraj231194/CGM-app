/// Deep link handler
///
/// Supported deep link patterns:
///   - optimus://alerts           ? /alerts
///   - optimus://alerts/{id}      ? /alerts (with specific alert)
///   - optimus://reports          ? /reports
///   - optimus://sensor           ? /sensor
///   - optimus://dashboard        ? /dashboard
///   - https://app.optimus-cgm.com/reports ? /reports
///
/// Usage in GoRouter:
///   Add this to the redirect logic or use GoRouter's built-in deep link support.
class DeepLinkHandler {
  DeepLinkHandler._();

  /// Parse a deep link URI and return the app route to navigate to.
  static String? parseDeepLink(Uri uri) {
    // Handle custom scheme: optimus://
    if (uri.scheme == 'optimus') {
      return _routeFromPath(uri.path, uri.queryParameters);
    }

    // Handle universal links: https://app.optimus-cgm.com/...
    if (uri.host == 'app.optimus-cgm.com' || uri.host == 'optimus-cgm.com') {
      return _routeFromPath(uri.path, uri.queryParameters);
    }

    return null;
  }

  static String? _routeFromPath(String path, Map<String, String> params) {
    final cleanPath = path.startsWith('/') ? path : '/$path';

    return switch (cleanPath) {
      '/alerts' => '/alerts',
      '/reports' => '/reports',
      '/sensor' => '/sensor',
      '/dashboard' => '/dashboard',
      '/chart' => '/chart',
      '/readings' => '/readings',
      '/meal' => '/meal',
      '/ai' => '/ai',
      '/devices' => '/devices',
      '/support' => '/support',
      '/account' => '/account',
      _ => '/dashboard',
    };
  }

  /// Generate a shareable deep link for a report.
  static Uri reportShareLink(String reportId) {
    return Uri(
      scheme: 'https',
      host: 'app.optimus-cgm.com',
      path: '/reports',
      queryParameters: {'id': reportId},
    );
  }

  /// Generate a shareable deep link for an alert.
  static Uri alertShareLink(String alertId) {
    return Uri(
      scheme: 'https',
      host: 'app.optimus-cgm.com',
      path: '/alerts',
      queryParameters: {'id': alertId},
    );
  }
}
