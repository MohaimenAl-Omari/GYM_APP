import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';



class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);


  static Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null) return token;

    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_tokenKey);
    if (legacyToken != null) {
      await _storage.write(key: _tokenKey, value: legacyToken);
      await prefs.remove(_tokenKey);
      return legacyToken;
    }
    return null;
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    // Also clear any pre-migration leftover, in case getToken() was
    // never called to trigger the migration above.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
