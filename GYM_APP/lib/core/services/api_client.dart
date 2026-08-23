import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gym_app/core/constant/const.dart';
import 'package:gym_app/core/navigation/navigator_key.dart';
import 'package:gym_app/core/services/secure_storage_service.dart';
import 'package:gym_app/features/auth/screens/login_screen.dart';

/// Single shared Dio client used by every service (auth, workout,
/// exercises, weight logs, profile) instead of each one instantiating its
/// own `Dio()`. Two things that used to be duplicated five times over now
/// live in one place:
///
/// 1. Attaching the `Authorization` header — services no longer need their
///    own `_authOptions()` helper reading SharedPreferences by hand.
/// 2. Reacting to a 401 — if the backend ever rejects the stored token
///    (revoked, expired, or just wrong), the token is cleared and the user
///    is dropped back at the login screen automatically, instead of every
///    screen having to detect and handle that itself.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          final path = error.requestOptions.path;
          // Skip the public /auth/* endpoints (a wrong-password login
          // attempt also 401s, but that's a login failure, not an expired
          // session) and /user/me (AuthService.checkSession already
          // handles that 401 itself as part of app-startup routing —
          // letting this interceptor also redirect would just race it).
          final isExemptEndpoint = path.startsWith('/auth/') || path == '/user/me';
          if (error.response?.statusCode == 401 && !isExemptEndpoint) {
            await _handleSessionExpired();
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;
  Dio get dio => _dio;

  bool _handlingExpiry = false;

  Future<void> _handleSessionExpired() async {
    // Several requests can 401 back-to-back right after a token expires
    // (e.g. a screen firing off a few parallel calls) — without this
    // guard each one would independently try to clear the token and
    // navigate, stacking redundant LoginScreen pushes.
    if (_handlingExpiry) return;
    _handlingExpiry = true;
    try {
      await SecureStorageService.deleteToken();
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } finally {
      _handlingExpiry = false;
    }
  }
}
