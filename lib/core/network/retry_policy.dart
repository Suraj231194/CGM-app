import 'dart:async';

import 'package:flutter/foundation.dart';

import '../env/app_environment.dart';
import '../error/app_error_handler.dart';

/// Generic retry utility for async operations (BLE connections, API calls).
class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });

  final int? maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  static RetryPolicy get defaultPolicy =>
      RetryPolicy(maxAttempts: EnvConfig.current.maxRetryAttempts);

  /// Retries an async operation with exponential backoff.
  ///
  /// [operation] - the async function to retry.
  /// [shouldRetry] - optional predicate to determine if error is retryable.
  /// [onRetry] - optional callback invoked before each retry.
  Future<T> execute<T>(
    Future<T> Function() operation, {
    bool Function(Object error)? shouldRetry,
    void Function(int attempt, Object error)? onRetry,
  }) async {
    final attempts = maxAttempts ?? EnvConfig.current.maxRetryAttempts;
    var delay = initialDelay;

    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        final isLastAttempt = attempt == attempts;
        final retryable = shouldRetry?.call(error) ?? true;

        if (isLastAttempt || !retryable) {
          AppErrorHandler.report(
            error,
            stackTrace,
            'RetryPolicy (attempt $attempt/$attempts)',
          );
          rethrow;
        }

        onRetry?.call(attempt, error);

        if (kDebugMode) {
          debugPrint(
            '[Retry] Attempt $attempt/$attempts failed: $error. '
            'Retrying in ${delay.inMilliseconds}ms...',
          );
        }

        await Future<void>.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier)
              .round()
              .clamp(0, maxDelay.inMilliseconds),
        );
      }
    }

    // Unreachable, but satisfies the compiler.
    throw StateError('Retry policy exhausted');
  }
}

/// Wraps a future with a timeout.
Future<T> withTimeout<T>(Future<T> Function() operation, {Duration? timeout}) {
  final duration =
      timeout ?? Duration(seconds: EnvConfig.current.connectionTimeoutSeconds);
  return operation().timeout(
    duration,
    onTimeout: () => throw TimeoutException(
      'Operation timed out after ${duration.inSeconds}s',
      duration,
    ),
  );
}
