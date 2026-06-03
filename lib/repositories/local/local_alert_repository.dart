import 'dart:async';

import '../../data/optimus_seed_data.dart';
import '../../models/optimus_models.dart';
import '../contracts/alert_repository.dart';

/// Local implementation of AlertRepository using seed data.
class LocalAlertRepository implements AlertRepository {
  @override
  Future<List<GlucoseAlert>> getAlerts({required String patientId}) async {
    return optimusAlerts.where((a) => a.patientId == patientId).toList();
  }

  @override
  Future<void> acknowledgeAlert(String alertId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    // State management handles the actual mutation
  }

  @override
  Future<AlertSettings> getAlertSettings({required String patientId}) async {
    return defaultAlertSettings;
  }

  @override
  Future<void> updateAlertSettings({
    required String patientId,
    required AlertSettings settings,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<List<ReportExport>> getReports({required String patientId}) async {
    return optimusReportExports.where((r) => r.patientId == patientId).toList();
  }

  @override
  Future<ReportExport> generateReport({
    required String patientId,
    required String period,
    required String format,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return ReportExport(
      id: 'report-${now.millisecondsSinceEpoch}',
      patientId: patientId,
      period: period,
      generatedAt: now,
      format: format,
      status: 'ready',
      summary: 'Generated locally with seed data.',
    );
  }
}
