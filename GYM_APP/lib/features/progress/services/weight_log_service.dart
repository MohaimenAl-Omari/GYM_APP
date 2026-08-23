import 'package:gym_app/core/services/api_client.dart';
import '../models/weight_log.dart';

class WeightLogService {
  final _dio = ApiClient.instance.dio;

  /// Every reading the user has logged, oldest first (chart-ready).
  Future<List<WeightLog>> fetchLogs() async {
    final response = await _dio.get('/weight-logs');
    final raw = response.data as List<dynamic>? ?? const [];
    return raw.map((e) => WeightLog.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Also updates the user's "current" profile weight server-side (see
  /// WeightLogController::store), so this and the Settings screen never
  /// disagree.
  Future<WeightLog> logWeight({required double weight, required String weightUnit}) async {
    final response = await _dio.post(
      '/weight-logs',
      data: {'weight': weight, 'weight_unit': weightUnit},
    );
    return WeightLog.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
