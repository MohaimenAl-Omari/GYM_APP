import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/const.dart';

class ProfileService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  Future<String?> completeProfile({
    required int age,
    required double weight,
    required double height,
    required String weightUnit,
    required String goal,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      await _dio.put(
        '/user/profile',
        data: {
          'age': age,
          'weight': weight,
          'height': height,
          'weight_unit': weightUnit,
          'goal': goal,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return 'Could not connect to the server. Please try again.';
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }
}
