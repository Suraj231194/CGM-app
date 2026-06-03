import 'dart:async';

import '../../models/optimus_models.dart';

/// Abstract contract for patient data operations.
/// Currently backed by seed data. Replace with API when backend is ready.
abstract class PatientRepository {
  Future<List<Patient>> getPatients({String? doctorId});
  Future<Patient?> getPatientById(String id);
  Future<List<OptimusGlucoseReading>> getReadings({
    required String patientId,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  });
  Future<List<MealLog>> getMeals({required String patientId});
  Future<MealLog> addMeal(MealLog meal);
  Future<List<Sensor>> getSensors({required String patientId});
  Future<List<AIInterpretation>> getInterpretations({
    required String patientId,
  });
  Future<List<Order>> getOrders({required String patientId});
  Future<Order> placeOrder(Order order);
}
