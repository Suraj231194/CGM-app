import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env/app_environment.dart';
import '../error/app_error_handler.dart';

/// Riverpod ProviderObserver for logging state changes and errors.
base class AppProviderObserver extends ProviderObserver {
  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (EnvConfig.current.enableLogging && kDebugMode) {
      debugPrint(
        '[Riverpod] Provider added: ${context.provider.name ?? context.provider.runtimeType}',
      );
    }
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (EnvConfig.current.enableLogging && kDebugMode) {
      debugPrint(
        '[Riverpod] Provider updated: ${context.provider.name ?? context.provider.runtimeType}',
      );
    }
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    AppErrorHandler.report(
      error,
      stackTrace,
      'Riverpod:${context.provider.name ?? context.provider.runtimeType}',
    );
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    if (EnvConfig.current.enableLogging && kDebugMode) {
      debugPrint(
        '[Riverpod] Provider disposed: ${context.provider.name ?? context.provider.runtimeType}',
      );
    }
  }
}
