import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// Callback type for when tokens are refreshed
typedef TokenRefreshCallback =
    void Function(
      String accessToken,
      String refreshToken,
      Map<String, dynamic> user,
    );

/// Callback type for when refresh fails (user must log in again)
typedef RefreshFailedCallback = void Function();

class ApiClient {
  // Change this to your backend URL
  // For Android emulator: 10.0.2.2:8080
  // For iOS simulator / web: localhost:8080
  // static const String baseUrl = 'http://localhost:8080';
  static const String baseUrl = 'https://mealtion-backend.onrender.com';

  final AuthStorage _authStorage = AuthStorage();

  /// In-memory access token for faster access (refreshed from storage on init)
  String? _accessToken;

  /// Track if we're currently refreshing to prevent multiple simultaneous refreshes
  bool _isRefreshing = false;

  /// Callbacks for token refresh events
  TokenRefreshCallback? onTokenRefreshed;
  RefreshFailedCallback? onRefreshFailed;

  /// Initialize the client with stored access token
  Future<void> init() async {
    _accessToken = await _authStorage.getAccessToken();
  }

  /// Set the access token (called after login/register/refresh)
  void setAccessToken(String token) {
    _accessToken = token;
  }

  /// Clear the access token (called on logout)
  void clearAccessToken() {
    _accessToken = null;
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      // Use in-memory token first, fallback to storage
      final token = _accessToken ?? await _authStorage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
    );
    return _handleResponse(response, () => get(path, auth: auth));
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handleResponse(response, () => post(path, body, auth: auth));
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
    );
    return _handleResponse(response, () => delete(path, auth: auth));
  }

  /// Handle response with automatic token refresh on 401
  dynamic _handleResponse(
    http.Response response,
    Future<dynamic> Function() retry,
  ) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // Try to refresh the token
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Retry the original request with new token
        return await retry();
      }
      // Refresh failed, user must log in again
      throw ApiException('Unauthorized', statusCode: 401);
    } else {
      String message = response.body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] != null) {
          message = decoded['error'];
        }
      } catch (_) {}
      throw ApiException(message, statusCode: response.statusCode);
    }
  }

  /// Attempt to refresh the access token using the refresh token
  Future<bool> _tryRefreshToken() async {
    // Prevent multiple simultaneous refresh attempts
    if (_isRefreshing) {
      // Wait a bit and check if token was refreshed
      await Future.delayed(const Duration(milliseconds: 500));
      return _accessToken != null;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _authStorage.getRefreshToken();
      if (refreshToken == null) {
        onRefreshFailed?.call();
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        // Update tokens
        _accessToken = newAccessToken;
        await _authStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Notify callback
        onTokenRefreshed?.call(newAccessToken, newRefreshToken, userData);

        return true;
      } else {
        // Refresh token is invalid or expired
        await _authStorage.clear();
        _accessToken = null;
        onRefreshFailed?.call();
        return false;
      }
    } catch (e) {
      onRefreshFailed?.call();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Manually refresh the token (e.g., on app init)
  Future<bool> refreshToken() async {
    return await _tryRefreshToken();
  }

  /// Get image URL for a meal
  static String mealImageUrl(String mealId) {
    return '$baseUrl/meals/$mealId/image';
  }
}
