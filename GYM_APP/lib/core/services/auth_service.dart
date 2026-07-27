import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/login_result.dart';
import '../constant/const.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  bool _googleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: googleServerClientId,
    );
    _googleSignInInitialized = true;
  }

  Future<bool> loginWithGoogle() async {
   return false;
  }

  Future<LoginResult> loginWithPhone(String phone, String password) async {
    try {
      final Response response = await _dio.post(
        '/auth/login',
        data: {
          'phone': phone,
          'password': password,
        },
      );
      final String token = response.data['token'];
      final Map<String, dynamic> user = Map<String, dynamic>.from(response.data['user']);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_name', user['name']?.toString() ?? '');
      await prefs.setString('user_phone', user['phone_number']?.toString() ?? '');
      final bool profileComplete = user['age'] != null &&
          user['weight'] != null &&
          user['height'] != null &&
          user['goal'] != null;
      return LoginResult(profileComplete: profileComplete);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return LoginResult(error: data['message'].toString());
      }
      return const LoginResult(
        error: 'Could not connect to the server. Please try again.',
      );
    } catch (e) {
      return const LoginResult(error: 'Something went wrong. Please try again.');
    }
  }

  Future<String?> registerWithPhone({
    required String name,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final Response response = await _dio.post(
        '/auth/signUp',
        data: {
          'name': name,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      final String token = response.data['token'];
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_name', response.data['user']['name']);
      await prefs.setString('user_phone', response.data['user']['phone_number']);
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return 'Could not connect to the server. Please try again.' + '$e';
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> loginWithApple() async {}

  Future<String?> signUpWithGoogleAccount() async {
    try {
      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        return 'Could not get a Google ID token. Please try again.';
      }

      final Response response = await _dio.post(
        '/auth/google',
        data: {'id_token': idToken},
      );
      final String token = response.data['token'];
      final Map<String, dynamic> user =
          Map<String, dynamic>.from(response.data['user']);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_name', user['name']?.toString() ?? '');
      return null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      return 'Google sign-in failed. Please try again.';
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

  Future<void> logout() async {
    await _ensureGoogleSignInInitialized();
    await GoogleSignIn.instance.signOut();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Only clear auth state — not the whole prefs store, so things like
    // the saved language choice survive logging out.
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
  }

  Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    return token != null;
  }

  Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> forgotPassword(String email) async {}
}
