import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the auth session (JWT + userId + email) in secure storage and
/// caches it in memory for synchronous reads.
///
/// Replaces Firebase's implicit session + the old `FirebaseAuth.currentUser`
/// reads: call sites that need the current uid now use [currentUserId].
class SessionManager {
  SessionManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kToken = 'auth_token';
  static const _kUserId = 'auth_user_id';
  static const _kEmail = 'auth_email';

  String? _token;
  String? _userId;
  String? _email;

  /// Loads any persisted session into memory. Call once during DI init.
  Future<void> load() async {
    _token = await _storage.read(key: _kToken);
    _userId = await _storage.read(key: _kUserId);
    _email = await _storage.read(key: _kEmail);
  }

  String? get token => _token;
  String? get currentUserId => _userId;
  String? get email => _email;
  bool get isLoggedIn => (_token ?? '').isNotEmpty;

  Future<void> save({
    required String token,
    required String userId,
    String? email,
  }) async {
    _token = token;
    _userId = userId;
    _email = email;
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kUserId, value: userId);
    await _storage.write(key: _kEmail, value: email ?? '');
  }

  Future<void> clear() async {
    _token = null;
    _userId = null;
    _email = null;
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kEmail);
  }
}
