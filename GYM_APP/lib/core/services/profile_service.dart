import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class ProfileService {
  final _dio = ApiClient.instance.dio;

  Future<String?> completeProfile({
    required int age,
    required double weight,
    required double height,
    required String weightUnit,
    required String goal,
  }) async {
    try {
      await _dio.put(
        '/user/profile',
        data: {
          'age': age,
          'weight': weight,
          'height': height,
          'weight_unit': weightUnit,
          'goal': goal,
        },
      );
      // Keep the cached flag in sync so an offline app restart right
      // after this still knows the profile is complete.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profile_complete', true);
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
