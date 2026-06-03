import 'package:dio/dio.dart';

import '../../models/optimus_models.dart';
import '../contracts/alert_repository.dart';
import 'remote_model_parsers.dart';

class RemoteAlertRepository implements AlertRepository {
  RemoteAlertRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<GlucoseAlert>> getAlerts({required String patientId}) async {
    final response = await _dio.get<Object?>('/patients/$patientId/alerts');
    return recordsFrom(response.data, 'alerts').map(alertFromJson).toList();
  }

  @override
  Future<void> acknowledgeAlert(String alertId) async {
    await _dio.post<void>('/alerts/$alertId/acknowledge');
  }

  @override
  Future<AlertSettings> getAlertSettings({required String patientId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/patients/$patientId/alert-settings',
    );
    return alertSettingsFromJson(response.data ?? const {});
  }

  @override
  Future<void> updateAlertSettings({
    required String patientId,
    required AlertSettings settings,
  }) async {
    await _dio.put<void>(
      '/patients/$patientId/alert-settings',
      data: {
        'notificationsEnabled': settings.notificationsEnabled,
        'lowThreshold': settings.lowThreshold,
        'highThreshold': settings.highThreshold,
        'quietHoursEnabled': settings.quietHoursEnabled,
      },
    );
  }

  @override
  Future<List<ReportExport>> getReports({required String patientId}) async {
    final response = await _dio.get<Object?>('/patients/$patientId/reports');
    return recordsFrom(response.data, 'reports').map(reportFromJson).toList();
  }

  @override
  Future<ReportExport> generateReport({
    required String patientId,
    required String period,
    required String format,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/patients/$patientId/reports',
      data: {'period': period, 'format': format},
    );
    return reportFromJson(response.data ?? const {});
  }
}
