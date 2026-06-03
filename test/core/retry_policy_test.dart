import 'package:flutter_test/flutter_test.dart';
import 'package:optimus_cgm_flutter/core/network/retry_policy.dart';

void main() {
  group('RetryPolicy', () {
    test('succeeds on first try', () async {
      const policy = RetryPolicy(maxAttempts: 3);
      var callCount = 0;
      final result = await policy.execute(() async {
        callCount++;
        return 'success';
      });
      expect(result, 'success');
      expect(callCount, 1);
    });

    test('retries and eventually succeeds', () async {
      const policy = RetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      var callCount = 0;
      final result = await policy.execute(() async {
        callCount++;
        if (callCount < 3) throw Exception('fail');
        return 'success';
      });
      expect(result, 'success');
      expect(callCount, 3);
    });

    test('throws after all retries exhausted', () async {
      const policy = RetryPolicy(
        maxAttempts: 2,
        initialDelay: Duration(milliseconds: 10),
      );
      expect(
        () => policy.execute(() async => throw Exception('always fails')),
        throwsException,
      );
    });

    test('does not retry when shouldRetry returns false', () async {
      const policy = RetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      var callCount = 0;
      try {
        await policy.execute(() async {
          callCount++;
          throw Exception('non-retryable');
        }, shouldRetry: (_) => false);
      } catch (_) {}
      expect(callCount, 1);
    });

    test('calls onRetry callback', () async {
      const policy = RetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration(milliseconds: 10),
      );
      final retryAttempts = <int>[];
      var callCount = 0;
      await policy.execute(() async {
        callCount++;
        if (callCount < 3) throw Exception('fail');
        return 'ok';
      }, onRetry: (attempt, _) => retryAttempts.add(attempt));
      expect(retryAttempts, [1, 2]);
    });
  });

  group('withTimeout', () {
    test('completes within timeout', () async {
      final result = await withTimeout(
        () async => 'done',
        timeout: const Duration(seconds: 5),
      );
      expect(result, 'done');
    });

    test('throws TimeoutException when exceeded', () async {
      expect(
        () => withTimeout(
          () => Future.delayed(const Duration(seconds: 10), () => 'late'),
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
