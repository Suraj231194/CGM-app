import 'dart:io';

Future<bool> hasInternetAccess() async {
  try {
    final result = await InternetAddress.lookup(
      'example.com',
    ).timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
