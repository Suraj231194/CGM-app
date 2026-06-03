import 'dart:async';

import '../../data/optimus_seed_data.dart';
import '../../models/optimus_models.dart';
import '../contracts/auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  String? _currentToken;
  DateTime? _sessionStart;

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final user = optimusUsers.cast<OptimusUser?>().firstWhere(
      (user) => user!.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => null,
    );

    if (user == null) {
      return const AuthResult(
        success: false,
        error: 'No account found with that email address.',
      );
    }

    if (password.trim().isEmpty) {
      return const AuthResult(success: false, error: 'Password is required.');
    }

    _currentToken = 'local-token-${DateTime.now().millisecondsSinceEpoch}';
    _sessionStart = DateTime.now();

    return AuthResult(
      success: true,
      user: user,
      role: user.role,
      token: _currentToken,
    );
  }

  @override
  Future<void> signOut() async {
    _currentToken = null;
    _sessionStart = null;
  }

  @override
  Future<bool> isSessionValid() async {
    if (_currentToken == null || _sessionStart == null) return false;
    final elapsed = DateTime.now().difference(_sessionStart!);
    return elapsed.inHours < 24;
  }

  @override
  Future<AuthResult?> refreshSession() async {
    if (_currentToken == null) return null;
    _sessionStart = DateTime.now();
    return AuthResult(success: true, token: _currentToken);
  }
}
