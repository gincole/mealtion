import '../../data/api_client.dart';
import '../../data/auth_storage.dart';

class User {
  final String id;
  final String email;
  final String name;

  User({required this.id, required this.email, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class AuthService {
  final ApiClient _api = ApiClient();
  final AuthStorage _storage = AuthStorage();

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    }, auth: false);

    final token = response['token'] as String;
    final userData = response['user'] as Map<String, dynamic>;

    await _storage.saveToken(token);
    await _storage.saveUser(
      id: userData['id'],
      email: userData['email'],
      name: userData['name'],
    );

    _currentUser = User.fromJson(userData);
    return _currentUser!;
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    }, auth: false);

    final token = response['token'] as String;
    final userData = response['user'] as Map<String, dynamic>;

    await _storage.saveToken(token);
    await _storage.saveUser(
      id: userData['id'],
      email: userData['email'],
      name: userData['name'],
    );

    _currentUser = User.fromJson(userData);
    return _currentUser!;
  }

  Future<User?> tryAutoLogin() async {
    final hasToken = await _storage.hasToken();
    if (!hasToken) return null;

    try {
      final response = await _api.get('/auth/me');
      final userData = response['user'] as Map<String, dynamic>;

      await _storage.saveUser(
        id: userData['id'],
        email: userData['email'],
        name: userData['name'],
      );

      _currentUser = User.fromJson(userData);
      return _currentUser;
    } catch (e) {
      // Token is invalid, clear it
      await _storage.clear();
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final storedUser = await _storage.getUser();
    if (storedUser != null) {
      _currentUser = User(
        id: storedUser['id']!,
        email: storedUser['email']!,
        name: storedUser['name']!,
      );
    }
    return _currentUser;
  }

  Future<void> logout() async {
    await _storage.clear();
    _currentUser = null;
  }

  Future<bool> isLoggedIn() async {
    return await _storage.hasToken();
  }
}

// Global singleton
final authService = AuthService();
