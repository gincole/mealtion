import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';
  static const _userNameKey = 'user_name';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveUser({
    required String id,
    required String email,
    required String name,
  }) async {
    await _storage.write(key: _userIdKey, value: id);
    await _storage.write(key: _userEmailKey, value: email);
    await _storage.write(key: _userNameKey, value: name);
  }

  Future<Map<String, String>?> getUser() async {
    final id = await _storage.read(key: _userIdKey);
    final email = await _storage.read(key: _userEmailKey);
    final name = await _storage.read(key: _userNameKey);

    if (id == null || email == null || name == null) return null;

    return {'id': id, 'email': email, 'name': name};
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
