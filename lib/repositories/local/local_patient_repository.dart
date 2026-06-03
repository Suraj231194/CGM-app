import 'dart:async';

import '../../data/optimus_seed_data.dart';
import '../../models/optimus_models.dart';
import '../contracts/patient_repository.dart';

class LocalPatientRepository implements PatientRepository {
  @override
  Future<List<Patient>> getPatients({String? doctorId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (doctorId != null) {
      return optimusPatients.where((patient) {
        return patient.doctorId == doctorId;
      }).toList();
    }
    return optimusPatients;
  }

  @override
  Future<Patient?> getPatientById(String id) async {
    return optimusPatients.cast<Patient?>().firstWhere(
      (patient) => patient!.id == id,
      orElse: () => null,
    );
  }

  @override
  Future<List<OptimusGlucoseReading>> getReadings({
    required String patientId,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    var readings = allOptimusReadings.where((reading) {
      return reading.patientId == patientId;
    }).toList();

    if (from != null) {
      readings = readings.where((reading) {
        return reading.timestamp.isAfter(from);
      }).toList();
    }
    if (to != null) {
      readings = readings.where((reading) {
        return reading.timestamp.isBefore(to);
      }).toList();
    }

    final start = offset ?? 0;
    if (start > 0 && start < readings.length) {
      readings = readings.sublist(start);
    }
    if (limit != null && limit < readings.length) {
      readings = readings.sublist(0, limit);
    }

    return readings;
  }

  @override
  Future<List<MealLog>> getMeals({required String patientId}) async {
    return optimusMealLogs.where((meal) {
      return meal.patientId == patientId;
    }).toList();
  }

  @override
  Future<MealLog> addMeal(MealLog meal) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return meal;
  }

  @override
  Future<List<Sensor>> getSensors({required String patientId}) async {
    return optimusSensors.where((sensor) {
      return sensor.patientId == patientId;
    }).toList();
  }

  @override
  Future<List<AIInterpretation>> getInterpretations({
    required String patientId,
  }) async {
    return optimusAIInterpretations.where((item) {
      return item.patientId == patientId;
    }).toList();
  }

  @override
  Future<List<Order>> getOrders({required String patientId}) async {
    return optimusOrders.where((order) {
      return order.patientId == patientId;
    }).toList();
  }

  @override
  Future<Order> placeOrder(Order order) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return order;
  }
}
