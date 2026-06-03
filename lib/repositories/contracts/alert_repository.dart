import 'dart:async';

import '../../models/optimus_models.dart';

/// Abstract contract for alert operations.
abstract class AlertRepository {
  Future<List<GlucoseAlert>> getAlerts({required String patientId});
  Future<void> acknowledgeAlert(String alertId);
  Future<AlertSettings> getAlertSettings({required String patientId});
  Future<void> updateAlertSettings({
    required String patientId,
    required AlertSettings settings,
  });
  Future<List<ReportExport>> getReports({required String patientId});
  Future<ReportExport> generateReport({
    required String patientId,
    required String period,
    required String format,
  });
}
