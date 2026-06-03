import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env/app_environment.dart';
import 'contracts/alert_repository.dart';
import 'contracts/auth_repository.dart';
import 'contracts/patient_repository.dart';
import 'local/local_alert_repository.dart';
import 'local/local_auth_repository.dart';
import 'local/local_patient_repository.dart';
import 'remote/remote_alert_repository.dart';
import 'remote/remote_auth_repository.dart';
import 'remote/remote_patient_repository.dart';

final apiDioProvider = Provider<Dio>((ref) {
  final env = EnvConfig.current;
  return Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: Duration(seconds: env.connectionTimeoutSeconds),
      receiveTimeout: Duration(seconds: env.connectionTimeoutSeconds),
      headers: {'Accept': 'application/json'},
    ),
  );
});

bool get _useLocalPreviewData => EnvConfig.current.isDevelopment;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (_useLocalPreviewData) return LocalAuthRepository();
  return RemoteAuthRepository(ref.watch(apiDioProvider));
});

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  if (_useLocalPreviewData) return LocalPatientRepository();
  return RemotePatientRepository(ref.watch(apiDioProvider));
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  if (_useLocalPreviewData) return LocalAlertRepository();
  return RemoteAlertRepository(ref.watch(apiDioProvider));
});
