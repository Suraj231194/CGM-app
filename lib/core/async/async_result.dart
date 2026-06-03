import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_error_handler.dart';

/// Result type for async operations that can succeed or fail.
/// Use this for repository calls to provide consistent error handling.
class AsyncResult<T> {
  const AsyncResult._({this.data, this.error, this.isLoading = false});

  const AsyncResult.loading() : this._(isLoading: true);
  const AsyncResult.success(T value) : this._(data: value);
  const AsyncResult.failure(String message) : this._(error: message);

  final T? data;
  final String? error;
  final bool isLoading;

  bool get isSuccess => data != null && error == null && !isLoading;
  bool get isError => error != null && !isLoading;

  /// Map success value to another type.
  AsyncResult<R> map<R>(R Function(T data) mapper) {
    if (data != null) return AsyncResult.success(mapper(data as T));
    if (error != null) return AsyncResult.failure(error!);
    return const AsyncResult.loading();
  }

  /// Execute a callback based on state.
  R when<R>({
    required R Function(T data) success,
    required R Function(String error) failure,
    required R Function() loading,
  }) {
    if (isLoading) return loading();
    if (error != null) return failure(error!);
    return success(data as T);
  }
}

/// Extension to easily run async operations with error capture.
extension AsyncOperationExtension on Ref {
  /// Executes an async operation, captures errors, and returns an AsyncResult.
  Future<AsyncResult<T>> runAsync<T>(
    Future<T> Function() operation, {
    String? context,
  }) async {
    try {
      final result = await operation();
      return AsyncResult.success(result);
    } catch (e, st) {
      AppErrorHandler.report(e, st, context);
      return AsyncResult.failure(e.toString());
    }
  }
}
