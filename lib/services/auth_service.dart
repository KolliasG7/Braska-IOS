// lib/services/auth_service.dart
//
// Manages the session token:
//   - Persisted to SharedPreferences so the session survives app restarts
//   - Cleared on 401 (password changed on server)
//   - login() calls POST /auth/login, stores token on success

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override String toString() => message;
}

class AuthService {
  AuthService(this._baseUrl);
  final String _baseUrl;

  static const _kTokenKey = 'braska_token';

  String? _token;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Uri _u(String path) {
    if (_baseUrl.startsWith('http')) return Uri.parse('$_baseUrl$path');
    return Uri.parse('http://$_baseUrl$path');
  }

  /// Load persisted token from SharedPreferences.
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kTokenKey);
  }

  /// Call POST /auth/login with password. Stores token on success.
  /// Throws AuthException on wrong password or network error.
  Future<void> login(String password) async {
    final http.Response r;
    try {
      r = await http.post(
        _u('/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      throw AuthException('Network error: $e');
    }

    if (r.statusCode == 401) {
      throw AuthException('Wrong password');
    }
    if (r.statusCode != 200) {
      String detail = r.body;
      try { detail = jsonDecode(r.body)['detail'] ?? detail; } catch (_) {}
      throw AuthException('Login failed: $detail');
    }

    final token = jsonDecode(r.body)['token'] as String;
    await _storeToken(token);
  }

  /// Clear the stored token (on 401 or manual logout).
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
  }

  Future<void> _storeToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
  }

  /// Authorization header map to inject into every request.
  Map<String, String> get authHeader =>
    _token != null ? {'Authorization': 'Bearer $_token'} : {};
}
