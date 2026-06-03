import 'dart:async';

import '../../models/optimus_models.dart';
import '../../app/theme.dart';

/// Abstract contract for authentication.
/// Currently backed by local seed data. Replace implementation
/// with real API calls when backend is ready.
abstract class AuthRepository {
  Future<AuthResult> signIn({required String email, required String password});
  Future<void> signOut();
  Future<bool> isSessionValid();
  Future<AuthResult?> refreshSession();
}

class AuthResult {
  const AuthResult({
    required this.success,
    this.user,
    this.role,
    this.token,
    this.error,
  });

  final bool success;
  final OptimusUser? user;
  final OptimusRole? role;
  final String? token;
  final String? error;
}
