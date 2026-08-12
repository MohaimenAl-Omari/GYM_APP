import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/models/login_result.dart';
import '../constant/const.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

  /// Whether age/weight/height/goal have all been filled in — used both
  /// right after a login/sign-up and again on app startup (via
  /// [checkSession]) to decide if the user still needs the
  /// complete-profile screen.
  bool _isProfileComplete(Map<String, dynamic> user) {
    return user['age'] != null &&
        user['weight'] != null &&
        user['height'] != null &&
        user['goal'] != null;
  }

  Future<LoginResult> loginWithName(String username, String password) async {
    try {
      final Response response = await _dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      final String token = response.data['token'];
      final Map<String, dynamic> user = Map<String, dynamic>.from(response.data['user']);
      final bool profileComplete = _isProfileComplete(user);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_name', user['name']?.toString() ?? '');
      await prefs.setString('user_phone', user['phone_number']?.toString() ?? '');
      await prefs.setBool('profile_complete', profileComplete);
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
    required String username,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final Response response = await _dio.post(
        '/auth/signUp',
        data: {
          'name': name,
          'username': username,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      final String token = response.data['token'];
      final Map<String, dynamic> user =
          Map<String, dynamic>.from(response.data['user']);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_name', user['name']?.toString() ?? '');
      await prefs.setString('user_phone', user['phone_number']?.toString() ?? '');
      // Brand new account — profile fields are always empty at this point.
      await prefs.setBool('profile_complete', _isProfileComplete(user));
      return null;
    } on DioException catch (e) {
      print(e);
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return 'Could not connect to the server. Please try again.' + '$e';
    } catch (e) {

      return 'Something went wrong. Please try again.';
    }
  }

  /// Signs in/up with Apple and reports whether this account (new or
  /// pre-existing, since the backend links by apple_id/email) already has
  /// its profile filled in — so a returning user isn't sent back through
  /// the complete-profile form for info they already gave us.
  Future<LoginResult> signUpWithAppleAccount() async {
    try {
      debugPrint('[AppleAuth] requesting Apple ID credential...');
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      debugPrint(
        '[AppleAuth] got credential. userIdentifier=${credential.userIdentifier} '
        'hasIdentityToken=${credential.identityToken != null} '
        'email=${credential.email}',
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) {
        return const LoginResult(
          error: 'Could not get an Apple identity token. Please try again.',
        );
      }
      final nameParts = [credential.givenName, credential.familyName]
          .whereType<String>()
          .where((s) => s.isNotEmpty);
      final String? fullName = nameParts.isEmpty ? null : nameParts.join(' ');

      debugPrint('[AppleAuth] POST $baseUrl/auth/apple');
      final Response response = await _dio.post(
        '/auth/apple',
        data: {
          'identity_token': identityToken,
          if (fullName != null) 'name': fullName,
        },
      );
      debugPrint('[AppleAuth] backend responded ${response.statusCode}');
      final String token = response.data['token'];
      final Map<String, dynamic> user =
          Map<String, dynamic>.from(response.data['user']);
      final bool profileComplete = _isProfileComplete(user);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_name', user['name']?.toString() ?? '');
      await prefs.setBool('profile_complete', profileComplete);
      return LoginResult(profileComplete: profileComplete);
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('[AppleAuth] SignInWithAppleAuthorizationException '
          'code=${e.code} message=${e.message}');
      if (e.code == AuthorizationErrorCode.canceled) {
        return const LoginResult(canceled: true);
      }
      return const LoginResult(error: 'Apple sign-in failed. Please try again.');
    } on DioException catch (e) {
      debugPrint(
        '[AppleAuth] DioException type=${e.type} message=${e.message} '
        'statusCode=${e.response?.statusCode} body=${e.response?.data}',
      );
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return LoginResult(error: data['message'].toString());
      }
      return const LoginResult(
        error: 'Could not connect to the server. Please try again.',
      );
    } catch (e, st) {
      debugPrint('[AppleAuth] unexpected error: $e\n$st');
      return const LoginResult(error: 'Something went wrong. Please try again.');
    }
  }

  /// Signs in/up with Google and reports whether this account (new or
  /// pre-existing) already has its profile filled in — same reasoning as
  /// [signUpWithAppleAccount].
  Future<LoginResult> signUpWithGoogleAccount() async {
    try {
      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        return const LoginResult(
          error: 'Could not get a Google ID token. Please try again.',
        );
      }

      final Response response = await _dio.post(
        '/auth/google',
        data: {'id_token': idToken},
      );
      final String token = response.data['token'];
      final Map<String, dynamic> user =
          Map<String, dynamic>.from(response.data['user']);
      final bool profileComplete = _isProfileComplete(user);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_name', user['name']?.toString() ?? '');
      await prefs.setBool('profile_complete', profileComplete);
      return LoginResult(profileComplete: profileComplete);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const LoginResult(canceled: true);
      }
      return const LoginResult(error: 'Google sign-in failed. Please try again.');
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

  Future<void> logout() async {
    await _ensureGoogleSignInInitialized();
    await GoogleSignIn.instance.signOut();
    await _clearSession();
  }

  Future<void> _clearSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    await prefs.remove('profile_complete');
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

  /// Asks the backend who the current token belongs to. Used on app
  /// startup to make sure a saved token hasn't been revoked/expired, and
  /// to refresh the cached profile-complete flag from the server instead
  /// of trusting a possibly-stale local copy.
  Future<Map<String, dynamic>> fetchCurrentUser(String token) async {
    final Response response = await _dio.get(
      '/user/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return Map<String, dynamic>.from(response.data['user']);
  }

  /// Decides where the app should land on startup: [AuthStatus.loggedOut]
  /// if there's no saved token (or the server just rejected it),
  /// [AuthStatus.needsProfile] or [AuthStatus.home] otherwise. This is
  /// what lets a user close the app and reopen it straight into Home
  /// instead of having to log in again.
  Future<AuthStatus> checkSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    if (token == null) return AuthStatus.loggedOut;

    try {
      final user = await fetchCurrentUser(token);
      final bool profileComplete = _isProfileComplete(user);
      await prefs.setString('user_name', user['name']?.toString() ?? '');
      await prefs.setBool('profile_complete', profileComplete);
      return profileComplete ? AuthStatus.home : AuthStatus.needsProfile;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token was revoked/expired server-side — back to login.
        await _clearSession();
        return AuthStatus.loggedOut;
      }
      // Network hiccup / server unreachable: don't kick the user out,
      // fall back to the last known profile-complete state.
      final bool cachedComplete = prefs.getBool('profile_complete') ?? false;
      return cachedComplete ? AuthStatus.home : AuthStatus.needsProfile;
    } catch (_) {
      final bool cachedComplete = prefs.getBool('profile_complete') ?? false;
      return cachedComplete ? AuthStatus.home : AuthStatus.needsProfile;
    }
  }

  Future<void> forgotPassword(String email) async {}
}
