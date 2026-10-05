import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/logged_set.dart';

/// One unacknowledged set per exercise. Persist before sending, and retain
/// the exact payload and request ID until the server acknowledges it.
class PendingSetStore {
  PendingSetStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  String _prefix(int sessionId) => 'pending_set_v1_${sessionId}_';
  String _key(int sessionId, int exerciseId) =>
      '${_prefix(sessionId)}$exerciseId';

  Future<LoggedSet?> read(int sessionId, int exerciseId) async {
    final raw = await _storage.read(key: _key(sessionId, exerciseId));
    return raw == null
        ? null
        : LoggedSet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(int sessionId, LoggedSet set) async {
    set.clientRequestId ??= _requestId();
    await _storage.write(
      key: _key(sessionId, set.sessionExerciseId),
      value: jsonEncode(set.toJson()),
    );
  }

  Future<void> remove(int sessionId, int exerciseId) =>
      _storage.delete(key: _key(sessionId, exerciseId));

  Future<bool> hasPending(int sessionId) async => (await _storage.readAll())
      .keys
      .any((key) => key.startsWith(_prefix(sessionId)));

  static String _requestId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

class PendingWorkoutSetsException implements Exception {}
