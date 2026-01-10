import 'dart:convert';
import 'package:http/http.dart' as http;
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

  /// Initialize the auth service - load stored token into API client
  Future<void> init() async {
    await _api.init();

    // Set up callbacks for token refresh events
    _api.onTokenRefreshed = (accessToken, refreshToken, userData) async {
      await _storage.saveUser(
        id: userData['id'],
        email: userData['email'],
        name: userData['name'],
      );
      _currentUser = User.fromJson(userData);
    };

    _api.onRefreshFailed = () async {
      await _storage.clear();
      _currentUser = null;
    };
  }

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

    final accessToken = response['accessToken'] as String;
    final refreshToken = response['refreshToken'] as String;
    final userData = response['user'] as Map<String, dynamic>;

    // Save both tokens
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    _api.setAccessToken(accessToken);

    await _storage.saveUser(
      id: userData['id'],
      email: userData['email'],
      name: userData['name'],
    );

    _currentUser = User.fromJson(userData);
    return _currentUser!;
  }

  Future<User> login({required String email, required String password}) async {
    final response = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    }, auth: false);

    final accessToken = response['accessToken'] as String;
    final refreshToken = response['refreshToken'] as String;
    final userData = response['user'] as Map<String, dynamic>;

    // Save both tokens
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    _api.setAccessToken(accessToken);

    await _storage.saveUser(
      id: userData['id'],
      email: userData['email'],
      name: userData['name'],
    );

    _currentUser = User.fromJson(userData);
    return _currentUser!;
  }

  /// Try to restore session on app start
  /// First tries to use stored access token, then falls back to refresh token
  Future<User?> tryAutoLogin() async {
    // Check if we have a refresh token (more reliable than access token which expires)
    final hasRefresh = await _storage.hasRefreshToken();
    if (!hasRefresh) return null;

    try {
      // Try to refresh the token first (access token might be expired)
      final refreshed = await _api.refreshToken();
      if (!refreshed) {
        // Refresh failed, clear storage
        await _storage.clear();
        return null;
      }

      // Get user info from /auth/me endpoint
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
      _api.clearAccessToken();
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
    // Revoke the refresh token on the server
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await http.post(
          Uri.parse('${ApiClient.baseUrl}/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        );
      }
    } catch (_) {
      // Ignore errors during logout - still clear local storage
    }

    await _storage.clear();
    _api.clearAccessToken();
    _currentUser = null;
  }

  Future<bool> isLoggedIn() async {
    // Check for refresh token (more reliable)
    return await _storage.hasRefreshToken();
  }
}

// Global singleton
final authService = AuthService();
