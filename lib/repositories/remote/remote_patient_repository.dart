import 'package:dio/dio.dart';

import '../../models/optimus_models.dart';
import '../contracts/patient_repository.dart';
import 'remote_model_parsers.dart';

class RemotePatientRepository implements PatientRepository {
  RemotePatientRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Patient>> getPatients({String? doctorId}) async {
    final queryParameters = <String, Object?>{};
    if (doctorId != null) {
      queryParameters['doctorId'] = doctorId;
    }

    final response = await _dio.get<Object?>(
      '/patients',
      queryParameters: queryParameters,
    );
    return recordsFrom(response.data, 'patients').map(patientFromJson).toList();
  }

  @override
  Future<Patient?> getPatientById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/patients/$id');
    final data = response.data;
    return data == null ? null : patientFromJson(data);
  }

  @override
  Future<List<OptimusGlucoseReading>> getReadings({
    required String patientId,
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) async {
    final queryParameters = <String, Object?>{};
    if (from != null) {
      queryParameters['from'] = from.toIso8601String();
    }
    if (to != null) {
      queryParameters['to'] = to.toIso8601String();
    }
    if (limit != null) {
      queryParameters['limit'] = limit;
    }
    if (offset != null) {
      queryParameters['offset'] = offset;
    }

    final response = await _dio.get<Object?>(
      '/patients/$patientId/readings',
      queryParameters: queryParameters,
    );
    return recordsFrom(response.data, 'readings').map(readingFromJson).toList();
  }

  @override
  Future<List<MealLog>> getMeals({required String patientId}) async {
    final response = await _dio.get<Object?>('/patients/$patientId/meals');
    return recordsFrom(response.data, 'meals').map(mealFromJson).toList();
  }

  @override
  Future<MealLog> addMeal(MealLog meal) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/patients/${meal.patientId}/meals',
      data: {
        'type': meal.type.name,
        'title': meal.title,
        'netCarbs': meal.netCarbs,
        'protein': meal.protein,
        'fiber': meal.fiber,
        'activityMinutes': meal.activityMinutes,
        'score': meal.score,
        'note': meal.note,
      },
    );
    return mealFromJson(response.data ?? const {});
  }

  @override
  Future<List<Sensor>> getSensors({required String patientId}) async {
    final response = await _dio.get<Object?>('/patients/$patientId/sensors');
    return recordsFrom(response.data, 'sensors').map(sensorFromJson).toList();
  }

  @override
  Future<List<AIInterpretation>> getInterpretations({
    required String patientId,
  }) async {
    final response = await _dio.get<Object?>(
      '/patients/$patientId/interpretations',
    );
    return recordsFrom(
      response.data,
      'interpretations',
    ).map(interpretationFromJson).toList();
  }

  @override
  Future<List<Order>> getOrders({required String patientId}) async {
    final response = await _dio.get<Object?>('/patients/$patientId/orders');
    return recordsFrom(response.data, 'orders').map(orderFromJson).toList();
  }

  @override
  Future<Order> placeOrder(Order order) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/patients/${order.patientId}/orders',
      data: {
        'productName': order.productName,
        'quantity': order.quantity,
        'shippingAddress': order.shippingAddress,
      },
    );
    return orderFromJson(response.data ?? const {});
  }
}
