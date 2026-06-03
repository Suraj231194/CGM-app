import 'package:dio/dio.dart';

import '../../app/theme.dart';
import '../contracts/auth_repository.dart';
import 'remote_model_parsers.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._dio);

  final Dio _dio;
  String? _token;

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/sign-in',
      data: {'email': email, 'password': password},
    );
    final data = response.data ?? const {};
    final userJson = data['user'];
    final user = userJson is Map<String, dynamic>
        ? userFromJson(userJson)
        : null;
    _token = data['token']?.toString();
    return AuthResult(
      success: data['success'] != false && user != null,
      user: user,
      role: user?.role ?? OptimusRole.customer,
      token: _token,
      error: data['error']?.toString(),
    );
  }

  @override
  Future<void> signOut() async {
    await _dio.post<void>('/auth/sign-out');
    _token = null;
  }

  @override
  Future<bool> isSessionValid() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/session');
    return response.data?['valid'] == true;
  }

  @override
  Future<AuthResult?> refreshSession() async {
    final response = await _dio.post<Map<String, dynamic>>('/auth/refresh');
    final data = response.data;
    if (data == null) return null;
    _token = data['token']?.toString() ?? _token;
    return AuthResult(success: data['success'] != false, token: _token);
  }
}
